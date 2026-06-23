//
//  PracticeRecordingCoordinator.swift
//  KeynoteCompanionMacos
//

import Foundation
import Speech
import os

private let log = Logger(subsystem: "com.tiempo.practice", category: "Coordinator")
// Dedicated channel for filler-threshold calibration (RMS / floor / threshold / gaps /
// filled-pause candidates / raw transcript). Stream with:
//   log stream --level debug --predicate 'subsystem == "com.tiempo.practice" && category == "Calibration"'
private let calibrationLog = Logger(subsystem: "com.tiempo.practice", category: "Calibration")

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

    // Parallel filler timeline (silent pauses + filled pauses + lexical fillers),
    // bucketed into the SAME slideIntervals as words and surfaced as a second recap
    // Feedback. Never pruned.
    private var fillerEvents: [FillerEvent] = []
    private var silenceDetector = SilenceDetector()
    private var filledPauseDetector = FilledPauseDetector()
    // Throttle counter for the per-sample calibration log (see FillerTuning).
    private var calibrationSampleTick: Int = 0
    // High-water mark of transcript tokens already scanned for lexical fillers in the
    // CURRENT task; reset on rotation (like maxCountCurrentTask) so the recognizer's
    // cumulative transcript isn't re-counted.
    private var processedTokenCount: Int = 0

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
    private var fillerLevelsTask: Task<Void, Never>?
    private var stateContinuation: AsyncStream<PracticeSessionState>.Continuation?

    /// One recognition task's lifecycle, delivered in order to a single consumer so
    /// ingest is serialized (no non-FIFO Task-hop races) and a finished task can't
    /// leak a late word into the next one.
    private enum RecognitionEvent: Sendable {
        case words(Int)
        case transcript(String)
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
        ),
        silenceDetector: SilenceDetector = SilenceDetector(),
        filledPauseDetector: FilledPauseDetector = FilledPauseDetector()
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.slideService = slideService
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
        self.clock = clock
        self.wpmCalculator = wpmCalculator
        self.silenceDetector = silenceDetector
        self.filledPauseDetector = filledPauseDetector
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
        resetFillerState()

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

        // Silent-pause detection rides on raw audio energy, so start it before the
        // speech-auth check — pauses still register even if recognition is unavailable.
        await startAudioLevelMonitoring()

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
        fillerLevelsTask?.cancel()
        fillerLevelsTask = nil

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
            keynoteFileName: keynoteFileName,
            fillerEvents: fillerEvents
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
        processedTokenCount = 0
        lastProgressMedia = clock.now()
        let (events, continuation) = AsyncStream<RecognitionEvent>.makeStream()
        do {
            try await speechService.startRecognition(
                request: request,
                onWordCount: { continuation.yield(.words($0)) },
                onTranscript: { continuation.yield(.transcript($0)) },
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
                    case .transcript(let text):
                        await self?.handleTranscript(text)
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

    /// Scan the recognizer's (cumulative) transcript for lexical fillers. Only the
    /// tokens past `processedTokenCount` are inspected, so re-emitted partial results
    /// can't double-count; a shrinking partial is ignored (high-water never lowers).
    /// Sync so the array mutation has no suspension between read and write.
    private func handleTranscript(_ transcript: String) {
        guard isSessionActive else { return }
        let tokens = FillerLexicon.tokenize(transcript)
        guard tokens.count > processedTokenCount else { return }
        // Calibration: see exactly what the recognizer emits, to judge which fillers it
        // keeps vs. silently normalises away.
        calibrationLog.debug("transcript(\(tokens.count) tok): \(transcript, privacy: .private)")
        let matches = FillerLexicon.detect(tokens: tokens, newStart: processedTokenCount)
        processedTokenCount = tokens.count
        guard !matches.isEmpty else { return }
        let now = clock.now()
        for token in matches {
            fillerEvents.append(FillerEvent(time: now, kind: .lexical(token: token)))
        }
        log.debug("Lexical fillers +\(matches.count) at \(now, format: .fixed(precision: 2)): \(matches.joined(separator: ","), privacy: .private)")
    }

    /// Feed one captured RMS sample to BOTH the silence and filled-pause detectors and
    /// record any completed filler. The sample carries its capture host-time, mapped to
    /// media time here so a pause is measured on the audio timeline rather than at
    /// actor-processing time. Sync (mutates the value-type detectors) and gated on pause
    /// so a frozen clock can't inflate a duration. Driven by the audio-levels stream.
    private func ingestAudioLevel(_ sample: AudioLevelSample) {
        guard isSessionActive, !clock.isPaused else { return }
        let now = clock.mediaTime(forWall: sample.hostTime)
        let level = sample.rms

        if let event = silenceDetector.ingest(level: level, now: now) {
            fillerEvents.append(event)
            if case .silentPause(let duration) = event.kind {
                log.debug("Silent pause \(duration, format: .fixed(precision: 2))s ending at \(event.time, format: .fixed(precision: 2))")
            }
        }

        // Filled pause ("eeee"): sustained, steady, voiced, with no word progress. The
        // detector reads how long words have been absent via `lastProgressMedia` (the
        // same word-arrival clock the watchdog uses); emitting one does NOT rotate
        // recognition — it stays a parallel, additive signal.
        let timeSinceLastWord = now - lastProgressMedia
        if let event = filledPauseDetector.ingest(level: level, now: now, timeSinceLastWord: timeSinceLastWord) {
            fillerEvents.append(event)
            if case .filledPause(let duration) = event.kind {
                log.debug("Filled pause \(duration, format: .fixed(precision: 2))s ending at \(event.time, format: .fixed(precision: 2))")
            }
        }

        logCalibrationSample(level: level, timeSinceLastWord: timeSinceLastWord)
    }

    /// Emit calibration data on the dedicated channel: every completed silence gap
    /// (including ones too short to count, so the pause threshold can be chosen from the
    /// real distribution) plus a throttled RMS / floor / threshold snapshot.
    private func logCalibrationSample(level: Float, timeSinceLastWord: TimeInterval) {
        if let gap = silenceDetector.lastCompletedGap {
            calibrationLog.debug("gap=\(gap, format: .fixed(precision: 2))s (min=\(FillerTuning.minSilencePauseSeconds, format: .fixed(precision: 2))) floor=\(self.silenceDetector.currentNoiseFloor, format: .fixed(precision: 4)) thr=\(self.silenceDetector.lastThreshold, format: .fixed(precision: 4))")
        }
        calibrationSampleTick &+= 1
        if calibrationSampleTick % FillerTuning.calibrationLogEverySamples == 0 {
            calibrationLog.debug("rms=\(level, format: .fixed(precision: 4)) floor=\(self.silenceDetector.currentNoiseFloor, format: .fixed(precision: 4)) thr=\(self.silenceDetector.lastThreshold, format: .fixed(precision: 4)) silent=\(self.silenceDetector.isInSilence) sinceWord=\(timeSinceLastWord, format: .fixed(precision: 2))")
        }
    }

    /// Drains the audio-levels stream into the detectors for the whole session.
    /// The stream finishes when capture stops, ending the loop.
    private func startAudioLevelMonitoring() async {
        let stream = await audioService.audioLevels()
        fillerLevelsTask = Task { [weak self] in
            for await sample in stream {
                if Task.isCancelled { break }
                await self?.ingestAudioLevel(sample)
            }
        }
    }

    /// Clears the filler timeline + detectors for a fresh session (sync: the detectors
    /// are value types, mutated outside any async suspension).
    private func resetFillerState() {
        fillerEvents = []
        silenceDetector.reset()
        filledPauseDetector.reset()
        processedTokenCount = 0
        calibrationSampleTick = 0
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

    /// Close the current slide's interval and open a fresh one for the same slide.
    /// Recording and recognition keep running uninterrupted; the extra interval
    /// shows up as an additional attempt in the per-slide recap breakdown.
    func retakeCurrentSlide() {
        let now = clock.now()
        closeLastInterval(at: now)
        slideIntervals.append(
            PracticeSlideInterval(slideNumber: currentSlideNumber, start: now, end: now)
        )
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
