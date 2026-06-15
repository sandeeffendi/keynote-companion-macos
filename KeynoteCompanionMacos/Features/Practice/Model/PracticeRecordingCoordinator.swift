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

    // Media time of the last committed word — drives the liveness watchdog. The
    // recognition stream is healthy if a task is armed (the user may simply be
    // silent), so the watchdog only acts on "no words AND no task-end for a while".
    private var lastProgressMedia: TimeInterval = 0
    private var recognitionHealth: RecognitionHealth = .live

    private var recognitionSupervisorTask: Task<Void, Never>?
    private var slidePollingTask: Task<Void, Never>?
    private var stateContinuation: AsyncStream<PracticeSessionState>.Continuation?

    /// One recognition task's lifecycle, delivered in order to a single consumer so
    /// ingest is serialized (no non-FIFO Task-hop races) and a finished task can't
    /// leak a late word into the next one.
    private enum RecognitionEvent: Sendable {
        case words(Int)
        case ended(error: Bool)
    }

    private enum RecognitionOutcome: Sendable {
        case endedNormally
        case endedWithError
        case stalled
    }

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
        lastProgressMedia = 0
        recognitionHealth = .live
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

        // Arm the first recognition task synchronously so the stream is live the moment
        // start() returns, then hand its events to the supervisor, which owns every
        // rotation and retry from here on. A failed first arm still launches the
        // supervisor so it can recover once the recognizer becomes available.
        let firstEvents = await armRecognition(request: request)
        if firstEvents == nil {
            recognitionHealth = .reconnecting
            emit(.speechUnavailable)
        }
        recognitionSupervisorTask = Task { [weak self] in
            await self?.runRecognitionSupervisor(firstEvents: firstEvents)
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
        recognitionSupervisorTask?.cancel()
        recognitionSupervisorTask = nil
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

    /// Live recognition health, sampled by the view model so the indicator can show a
    /// "reconnecting" affordance instead of a misleading 0 while recognition is down.
    func recognitionStatus() -> RecognitionHealth {
        recognitionHealth
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

    /// Owns the whole recognition lifecycle for the session: consume the current
    /// task's events, then rotate to a fresh task — forever while the session is
    /// active. A recognizer that ends (normal final on a speech pause), errors, or
    /// silently stalls is always re-armed, so the live stream can never die for good.
    private func runRecognitionSupervisor(firstEvents: AsyncStream<RecognitionEvent>?) async {
        var pendingEvents = firstEvents
        var errorBackoff = PracticeTuning.recognitionErrorBackoffBaseNanos

        while isSessionActive && !Task.isCancelled {
            let events: AsyncStream<RecognitionEvent>
            if let pending = pendingEvents {
                events = pending
            } else {
                // Rotate: swap a fresh request into the live audio tap immediately (no
                // pre-sleep) so no spoken audio is dropped between tasks.
                let request = SFSpeechAudioBufferRecognitionRequest()
                activeRequest = request
                await audioService.updateSpeechRequest(request)
                guard let armed = await armRecognition(request: request) else {
                    // Transient arm failure (e.g. recognizer momentarily unavailable):
                    // back off and retry; never give up while the session is active.
                    recognitionHealth = .reconnecting
                    try? await Task.sleep(nanoseconds: errorBackoff)
                    errorBackoff = min(errorBackoff * 2, PracticeTuning.recognitionErrorBackoffCapNanos)
                    continue
                }
                errorBackoff = PracticeTuning.recognitionErrorBackoffBaseNanos
                events = armed
            }
            pendingEvents = nil

            let outcome = await consumeTaskEvents(events)
            await speechService.stopRecognition()
            guard isSessionActive && !Task.isCancelled else { break }

            switch outcome {
            case .endedWithError:
                recognitionHealth = .reconnecting
                try? await Task.sleep(nanoseconds: PracticeTuning.recognitionErrorBackoffBaseNanos)
            case .endedNormally, .stalled:
                // A normal final (typical at a speech pause) or a watchdog rotation.
                // We can't distinguish a silent-but-alive task from a dead one, so a
                // stall rotates quietly without flagging "reconnecting".
                recognitionHealth = .live
                try? await Task.sleep(nanoseconds: PracticeTuning.recognitionMinRestartIntervalNanos)
            }
        }
    }

    /// Arms one recognition task and returns its ordered event stream, or `nil` if the
    /// recognizer refused to start. Resets the per-task high-water mark so the new
    /// task's cumulative count starts from zero.
    private func armRecognition(request: SFSpeechAudioBufferRecognitionRequest) async -> AsyncStream<RecognitionEvent>? {
        maxCountCurrentTask = 0
        lastProgressMedia = clock.now()
        let (events, continuation) = AsyncStream<RecognitionEvent>.makeStream()
        do {
            try await speechService.startRecognition(
                request: request,
                onWordCount: { continuation.yield(.words($0)) },
                onTaskEnded: { continuation.yield(.ended(error: $0)); continuation.finish() }
            )
            recognitionHealth = .live
            return events
        } catch {
            log.error("startRecognition failed: \(error.localizedDescription, privacy: .public)")
            continuation.finish()
            return nil
        }
    }

    /// Consumes one task's events on a single serialized reader (so ingest is FIFO and
    /// a finished task can't leak a late word) while a watchdog races it: if no word
    /// and no task-end arrive within `recognitionStallSeconds` of media time, the task
    /// is treated as stalled so the supervisor can rotate it.
    private func consumeTaskEvents(_ events: AsyncStream<RecognitionEvent>) async -> RecognitionOutcome {
        await withTaskGroup(of: RecognitionOutcome.self) { group in
            group.addTask { [weak self] in
                for await event in events {
                    switch event {
                    case .words(let count):
                        await self?.handleWordCountUpdate(count)
                    case .ended(let error):
                        return error ? .endedWithError : .endedNormally
                    }
                }
                return .endedNormally
            }
            group.addTask { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: PracticeTuning.recognitionWatchdogPollNanos)
                    if await self?.isRecognitionStalled() == true { return .stalled }
                }
                return .endedNormally
            }
            let outcome = await group.next() ?? .endedNormally
            group.cancelAll()
            return outcome
        }
    }

    private func isRecognitionStalled() -> Bool {
        guard isSessionActive, !clock.isPaused else { return false }
        return clock.now() - lastProgressMedia > PracticeTuning.recognitionStallSeconds
    }

    private func handleWordCountUpdate(_ count: Int) {
        // A word-update may arrive after stop(); drop it so it can't append to history
        // past the captured result or bleed into a later session.
        guard isSessionActive else { return }
        // The recognizer reports an absolute, sometimes-revised cumulative count for
        // the current task; commit only increases. The serialized event stream means
        // a previous task's stream is finished before the next is armed, so the
        // high-water reset in armRecognition() can't race an in-flight update.
        guard count > maxCountCurrentTask else { return }
        let newWords = count - maxCountCurrentTask
        maxCountCurrentTask = count
        let now = clock.now()
        lastProgressMedia = now
        history.append(contentsOf: Array(repeating: now, count: newWords))
        log.debug("Word count update: \(count) (+\(newWords) at \(now, format: .fixed(precision: 2)))")
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
