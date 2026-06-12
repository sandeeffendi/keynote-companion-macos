//
//  PracticeRecordingCoordinator.swift
//  KeynoteCompanionMacos
//

import Foundation
import Speech
import os

private let log = Logger(subsystem: "com.tiempo.practice", category: "Coordinator")

actor PracticeRecordingCoordinator {
    private let audioService: AudioCapturing
    private let speechService: SpeechRecognizing
    private let slideService: KeynoteSlideTracking
    private let pollingIntervalNanoseconds: UInt64

    // Live session state
    private var accumulatedWordCount: Int = 0
    private var currentTaskWordCount: Int = 0
    private var wordCountAtCurrentSlideStart: Int = 0
    private var currentSlideNumber: Int = 1
    private var sessionStartDate: Date?
    private var currentSlideStartDate: Date?
    private var slideSnapshots: [PracticeSlideSnapshot] = []
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var isSessionActive = false

    private var slidePollingTask: Task<Void, Never>?
    private var stateContinuation: AsyncStream<PracticeSessionState>.Continuation?

    convenience init() {
        self.init(
            audioService: AudioCaptureService(),
            speechService: SpeechRecognitionService(),
            slideService: KeynoteSlideTrackingService(),
            pollingIntervalNanoseconds: 1_000_000_000
        )
    }

    init(
        audioService: AudioCapturing,
        speechService: SpeechRecognizing,
        slideService: KeynoteSlideTracking,
        pollingIntervalNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.slideService = slideService
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
    }

    var stateStream: AsyncStream<PracticeSessionState> {
        let (stream, continuation) = AsyncStream.makeStream(of: PracticeSessionState.self)
        stateContinuation = continuation
        continuation.yield(.idle)
        return stream
    }

    func start(keynoteFileName: String) async throws {
        let now = Date()
        isSessionActive = true
        sessionStartDate = now
        currentSlideStartDate = now
        accumulatedWordCount = 0
        currentTaskWordCount = 0
        wordCountAtCurrentSlideStart = 0
        slideSnapshots = []

        // Detect initial slide
        let initialSlide: Int
        do {
            initialSlide = try await slideService.currentSlideNumber()
        } catch {
            log.info("Initial slide detection failed, defaulting to 1: \(error.localizedDescription, privacy: .public)")
            initialSlide = 1
        }
        currentSlideNumber = initialSlide
        slideSnapshots.append(PracticeSlideSnapshot(
            slideNumber: initialSlide,
            wordCountAtStart: 0,
            timestampAtStart: 0
        ))

        let request = SFSpeechAudioBufferRecognitionRequest()
        activeRequest = request

        try await audioService.start(speechRequest: request)

        // Lazy safety-net: ensure speech recognition is authorized before starting.
        let speechStatus = await speechService.requestAuthorization()
        guard speechStatus == .authorized else {
            log.error("Speech recognition not authorized: \(String(describing: speechStatus), privacy: .public)")
            emit(.speechUnavailable)
            startSlidePolling()
            emit(.recording)
            return
        }

        do {
            try await beginRecognition(request: request)
        } catch {
            log.error("startRecognition failed: \(error.localizedDescription, privacy: .public)")
            emit(.speechUnavailable)
        }

        startSlidePolling()
        emit(.recording)
    }

    func pause() async {
        await audioService.pause()
        emit(.paused)
    }

    func resume() async throws {
        try await audioService.resume()
        emit(.recording)
    }

    // Sync — no await, so no reentrancy risk
    func retakeCurrentSlide() {
        let total = accumulatedWordCount + currentTaskWordCount
        wordCountAtCurrentSlideStart = total
        currentSlideStartDate = Date()
    }

    func stop() async -> PracticeResult {
        emit(.finishing)
        isSessionActive = false
        slidePollingTask?.cancel()
        slidePollingTask = nil

        await speechService.stopRecognition()
        let audioURL = await audioService.stop()
        activeRequest = nil

        let duration = sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0
        let finalWordCount = accumulatedWordCount + currentTaskWordCount

        let result = PracticeResult(
            slideSnapshots: slideSnapshots,
            finalWordCount: finalWordCount,
            duration: duration,
            audioFileURL: audioURL,
            keynoteFileName: ""
        )

        emit(.finished(result))
        stateContinuation?.finish()
        stateContinuation = nil
        return result
    }

    func currentWPM() -> Int {
        guard let slideStart = currentSlideStartDate else { return 0 }
        let total = accumulatedWordCount + currentTaskWordCount
        let wordsOnSlide = max(0, total - wordCountAtCurrentSlideStart)
        let elapsed = max(1, Date().timeIntervalSince(slideStart))
        return Int((Double(wordsOnSlide) / elapsed) * 60)
    }

    func elapsedSeconds() -> TimeInterval {
        guard let start = sessionStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    func currentSlide() -> Int {
        currentSlideNumber
    }

    // MARK: - Private

    private func beginRecognition(request: SFSpeechAudioBufferRecognitionRequest) async throws {
        try await speechService.startRecognition(
            request: request,
            onWordCount: { [weak self] count in
                guard let self else { return }
                Task { await self.handleWordCountUpdate(count) }
            },
            onTaskEnded: { [weak self] in
                guard let self else { return }
                Task { await self.handleTaskEnded() }
            }
        )
    }

    private func handleWordCountUpdate(_ count: Int) {
        log.debug("Word count update: \(count)")
        currentTaskWordCount = count
    }

    private func handleTaskEnded() async {
        guard isSessionActive else { return }
        accumulatedWordCount += currentTaskWordCount
        currentTaskWordCount = 0

        // Brief pause so a permanently failing recognizer doesn't restart in a tight loop.
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard isSessionActive else { return }

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        activeRequest = newRequest
        await audioService.updateSpeechRequest(newRequest)

        do {
            try await beginRecognition(request: newRequest)
            log.info("Recognition restarted after task end (accumulated words: \(self.accumulatedWordCount))")
        } catch {
            log.error("Recognition restart failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func startSlidePolling() {
        slidePollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }

                do {
                    try await Task.sleep(nanoseconds: await self.pollingIntervalNanoseconds)
                } catch {
                    break
                }

                guard !Task.isCancelled else { break }

                do {
                    let slideNumber = try await self.slideService.currentSlideNumber()
                    await self.handleSlideChange(to: slideNumber)
                } catch {
                    log.debug("Slide poll failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    private func handleSlideChange(to newSlide: Int) {
        guard newSlide != currentSlideNumber else { return }

        let now = Date()
        let sessionStart = sessionStartDate ?? now
        let timestamp = now.timeIntervalSince(sessionStart)
        let total = accumulatedWordCount + currentTaskWordCount

        currentSlideNumber = newSlide
        wordCountAtCurrentSlideStart = total
        currentSlideStartDate = now

        slideSnapshots.append(PracticeSlideSnapshot(
            slideNumber: newSlide,
            wordCountAtStart: total,
            timestampAtStart: timestamp
        ))
    }

    private func emit(_ state: PracticeSessionState) {
        stateContinuation?.yield(state)
    }
}
