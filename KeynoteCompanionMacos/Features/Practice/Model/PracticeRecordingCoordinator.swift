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

    // Single source of truth: every recognized word becomes one timestamp (media
    // seconds). Sorted because the media clock is monotonic and we append at "now".
    // Feeds BOTH the live sliding window and the recap per-slide breakdown; never pruned.
    private var history: [TimeInterval] = []
    // Monotonic high-water mark for the CURRENT recognition task. The recognizer
    // reports an absolute, sometimes-revised cumulative count; we only commit
    // increases, which makes ingest order-insensitive (Task hops to the actor are
    // not FIFO) and immune to partial-result shrink. Reset on task rotation.
    private var maxCountCurrentTask: Int = 0

    private var clock: MediaClock
    private var wpmCalculator: WPMCalculator

    private var currentSlideNumber: Int = 1
    private var slideIntervals: [PracticeSlideInterval] = []
    private var keynoteFileName: String = ""

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
        pollingIntervalNanoseconds: UInt64 = 1_000_000_000,
        clock: MediaClock = MediaClock(),
        wpmCalculator: WPMCalculator = WPMCalculator(
            window: PracticeTuning.windowSeconds,
            smoothingFactor: PracticeTuning.emaAlpha
        )
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.slideService = slideService
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
        self.clock = clock
        self.wpmCalculator = wpmCalculator
    }

    var stateStream: AsyncStream<PracticeSessionState> {
        let (stream, continuation) = AsyncStream.makeStream(of: PracticeSessionState.self)
        stateContinuation = continuation
        continuation.yield(.idle)
        return stream
    }

    func start(keynoteFileName: String) async throws {
        isSessionActive = true
        self.keynoteFileName = keynoteFileName
        beginSessionClocks()
        history = []
        maxCountCurrentTask = 0
        slideIntervals = []

        // Detect initial slide
        let initialSlide: Int
        do {
            initialSlide = try await slideService.currentSlideNumber()
        } catch {
            log.info("Initial slide detection failed, defaulting to 1: \(error.localizedDescription, privacy: .public)")
            initialSlide = 1
        }
        currentSlideNumber = initialSlide
        slideIntervals.append(PracticeSlideInterval(slideNumber: initialSlide, start: 0, end: 0))

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
        pauseClock()
        emit(.paused)
    }

    func resume() async throws {
        try await audioService.resume()
        resumeClock()
        emit(.recording)
    }

    func stop() async -> PracticeResult {
        emit(.finishing)
        isSessionActive = false
        slidePollingTask?.cancel()
        slidePollingTask = nil

        await speechService.stopRecognition()
        let audioURL = await audioService.stop()
        activeRequest = nil

        let duration = clock.now()
        closeLastInterval(at: duration)

        let result = PracticeResult(
            wordTimestamps: history,
            slideIntervals: slideIntervals,
            duration: duration,
            audioFileURL: audioURL,
            keynoteFileName: keynoteFileName
        )

        emit(.finished(result))
        stateContinuation?.finish()
        stateContinuation = nil
        return result
    }

    /// Samples the live WPM: gross pace over the sliding window against media time,
    /// continuous across slide boundaries (a speedometer, not a per-slide reset).
    ///
    /// This ADVANCES the EMA smoothing state, so call it exactly once per refresh
    /// tick — calling it more often would over-smooth and skew the displayed value.
    func sampleWPM() -> Int {
        let value = wpmCalculator.recompute(timestamps: history, now: clock.now())
        return Int(value.rounded())
    }

    func elapsedSeconds() -> TimeInterval {
        clock.now()
    }

    func currentSlide() -> Int {
        currentSlideNumber
    }

    // MARK: - Private

    // Mutating methods on the value-type clock/calculator must run in a synchronous
    // context — the compiler forbids `inout` access to actor-isolated stored
    // properties across the suspension points of an `async` method.
    private func beginSessionClocks() {
        clock.start()
        wpmCalculator.reset()
    }

    private func pauseClock() {
        clock.pause()
    }

    private func resumeClock() {
        clock.resume()
    }

    private func beginRecognition(request: SFSpeechAudioBufferRecognitionRequest) async throws {
        try await speechService.startRecognition(
            request: request,
            onWordCount: { [weak self] count in
                guard let self else { return }
                Task { await self.handleWordCountUpdate(count) }
            },
            onTaskEnded: { [weak self] endedWithError in
                guard let self else { return }
                Task { await self.handleTaskEnded(endedWithError: endedWithError) }
            }
        )
    }

    private func handleWordCountUpdate(_ count: Int) {
        // A word-update Task may hop in after stop(); drop it so it can't append to
        // history past the captured result or bleed into a later session.
        guard isSessionActive else { return }
        guard count > maxCountCurrentTask else { return }
        let newWords = count - maxCountCurrentTask
        maxCountCurrentTask = count
        let now = clock.now()
        history.append(contentsOf: Array(repeating: now, count: newWords))
        log.debug("Word count update: \(count) (+\(newWords) at \(now, format: .fixed(precision: 2)))")
    }

    private func handleTaskEnded(endedWithError: Bool) async {
        guard isSessionActive else { return }
        // Words from the ended task are already in `history`; reset the high-water
        // mark so the next task's cumulative count starts from zero.
        maxCountCurrentTask = 0

        // Always throttle the restart so a recognizer that ends rapidly (final OR
        // error) can't spin in a tight loop. The normal-end floor is small to keep
        // the recognition gap short (dropping few words from the window); errors
        // back off longer.
        let backoff = endedWithError
            ? PracticeTuning.recognitionErrorBackoffNanos
            : PracticeTuning.recognitionRestartDelayNanos
        try? await Task.sleep(nanoseconds: backoff)
        guard isSessionActive else { return }

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        activeRequest = newRequest
        await audioService.updateSpeechRequest(newRequest)

        do {
            try await beginRecognition(request: newRequest)
            log.info("Recognition restarted after task end (history words: \(self.history.count), error: \(endedWithError))")
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

        let now = clock.now()
        closeLastInterval(at: now)
        currentSlideNumber = newSlide
        slideIntervals.append(PracticeSlideInterval(slideNumber: newSlide, start: now, end: now))
    }

    private func closeLastInterval(at time: TimeInterval) {
        guard !slideIntervals.isEmpty else { return }
        let last = slideIntervals.count - 1
        slideIntervals[last].end = max(slideIntervals[last].start, time)
    }

    private func emit(_ state: PracticeSessionState) {
        stateContinuation?.yield(state)
    }
}
