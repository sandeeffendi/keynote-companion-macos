//
//  PracticeRecordingCoordinatorTests.swift
//  KeynoteCompanionMacosTests
//

import Speech
import XCTest
@testable import KeynoteCompanionMacos

final class PracticeRecordingCoordinatorTests: XCTestCase {
    private func makeCoordinator(
        audio: MockAudioCaptureService = MockAudioCaptureService(),
        speech: MockSpeechRecognitionService = MockSpeechRecognitionService(),
        slide: MockSlideTrackingService = MockSlideTrackingService(),
        clock: MediaClock = MediaClock()
    ) -> PracticeRecordingCoordinator {
        PracticeRecordingCoordinator(
            audioService: audio,
            speechService: speech,
            slideService: slide,
            pollingIntervalNanoseconds: 10_000_000_000,
            clock: clock,
            wpmCalculator: WPMCalculator(smoothingFactor: 0) // raw, no EMA lag in tests
        )
    }

    func testWordCountUpdatesProduceNonZeroWPM() async throws {
        let wall = TestWall()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech, clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")
        wall.advance(to: 5)
        await speech.simulateWordCount(30)

        let becameNonZero = await waitUntil {
            await coordinator.sampleWPM() > 0
        }
        XCTAssertTrue(becameNonZero, "WPM should become non-zero after word counts arrive")

        _ = await coordinator.stop()
    }

    func testMonotonicMaxIgnoresShrinkingAndOutOfOrderCounts() async throws {
        let wall = TestWall()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech, clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")
        wall.advance(to: 1); await speech.simulateWordCount(5)
        try await Task.sleep(nanoseconds: 100_000_000)
        wall.advance(to: 2); await speech.simulateWordCount(3) // partial revision shrank: ignore
        try await Task.sleep(nanoseconds: 100_000_000)
        wall.advance(to: 3); await speech.simulateWordCount(8) // +3
        try await Task.sleep(nanoseconds: 100_000_000)

        let result = await coordinator.stop()
        XCTAssertEqual(result.finalWordCount, 8, "Only monotonic increases are committed")
    }

    func testTaskEndedAccumulatesAndRestartsWithFreshRequestAndSwapsAudioTap() async throws {
        let audio = MockAudioCaptureService()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(audio: audio, speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        await speech.simulateWordCount(10)
        await speech.simulateTaskEnded(error: false)

        let restarted = await waitUntil {
            await speech.startCallCount == 2
        }
        XCTAssertTrue(restarted, "Recognition should restart after the task ends")

        let requests = await speech.requests
        XCTAssertEqual(requests.count, 2)
        XCTAssertFalse(requests[0] === requests[1], "Restart must use a fresh recognition request")

        let updatedRequests = await audio.updatedRequests
        XCTAssertEqual(updatedRequests.count, 1)
        XCTAssertTrue(updatedRequests[0] === requests[1], "Audio tap must be swapped to the new request")

        // Words from the expired task stay in history; new task starts a fresh count.
        await speech.simulateWordCount(5)
        try await Task.sleep(nanoseconds: 200_000_000)
        let result = await coordinator.stop()
        XCTAssertEqual(result.finalWordCount, 15)
    }

    func testStopPreventsRestartAfterTaskEnded() async throws {
        let audio = MockAudioCaptureService()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(audio: audio, speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        _ = await coordinator.stop()
        await speech.simulateTaskEnded(error: false)

        // Give any (erroneous) restart time to fire.
        try await Task.sleep(nanoseconds: 800_000_000)

        let startCallCount = await speech.startCallCount
        XCTAssertEqual(startCallCount, 1, "No restart should happen after the session stopped")
        let updatedRequests = await audio.updatedRequests
        XCTAssertTrue(updatedRequests.isEmpty)
    }

    func testRecognitionRecoversAfterTransientStartFailure() async throws {
        // Regression: a failed re-arm used to be swallowed, leaving WPM at 0 forever.
        let wall = TestWall()
        let speech = MockSpeechRecognitionService()
        await speech.setFailNextStarts(1) // first arm throws, supervisor must retry
        let coordinator = makeCoordinator(speech: speech, clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")

        let retried = await waitUntil { await speech.startCallCount >= 2 }
        XCTAssertTrue(retried, "Supervisor must re-arm after a failed recognition start")

        wall.advance(to: 3)
        await speech.simulateWordCount(12)
        let resumed = await waitUntil { await coordinator.sampleWPM() > 0 }
        XCTAssertTrue(resumed, "Ingest must resume once recognition recovers")

        _ = await coordinator.stop()
    }

    func testWatchdogRotatesStalledRecognition() async throws {
        // Regression: a silently stalled task (no words, no end) used to freeze WPM at 0.
        let wall = TestWall()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech, clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")
        let armed = await waitUntil { await speech.startCallCount == 1 }
        XCTAssertTrue(armed)

        wall.advance(to: 1)
        await speech.simulateWordCount(4)
        try await Task.sleep(nanoseconds: 100_000_000)
        // Advance media time past the stall threshold with no further words and no end.
        wall.advance(to: 1 + PracticeTuning.recognitionStallSeconds + 2)

        let rotated = await waitUntil(timeout: 6) { await speech.startCallCount >= 2 }
        XCTAssertTrue(rotated, "Watchdog must rotate a stalled recognition task so ingest can resume")

        _ = await coordinator.stop()
    }

    func testPauseFreezesMediaTimeAndResumeContinues() async throws {
        let wall = TestWall()
        let coordinator = makeCoordinator(clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")
        wall.advance(to: 10)
        var elapsed = await coordinator.elapsedSeconds()
        XCTAssertEqual(elapsed, 10, accuracy: 0.001)

        await coordinator.pause()
        wall.advance(to: 30) // 20s pass while paused
        elapsed = await coordinator.elapsedSeconds()
        XCTAssertEqual(elapsed, 10, accuracy: 0.001, "Media time is frozen while paused")

        try await coordinator.resume()
        wall.advance(to: 35) // 5s more after resume
        elapsed = await coordinator.elapsedSeconds()
        XCTAssertEqual(elapsed, 15, accuracy: 0.001, "Paused span is excluded from elapsed time")

        _ = await coordinator.stop()
    }

    func testStopClosesSingleInitialSlideIntervalToDuration() async throws {
        let wall = TestWall()
        let coordinator = makeCoordinator(clock: MediaClock(wallNow: wall.source()))

        try await coordinator.start(keynoteFileName: "Test.key")
        wall.advance(to: 12)
        let result = await coordinator.stop()

        XCTAssertEqual(result.slideIntervals.count, 1)
        XCTAssertEqual(result.slideIntervals[0].slideNumber, 1)
        XCTAssertEqual(result.slideIntervals[0].start, 0, accuracy: 0.001)
        XCTAssertEqual(result.slideIntervals[0].end, 12, accuracy: 0.001)
        XCTAssertEqual(result.duration, 12, accuracy: 0.001)
    }

    // MARK: - Filler detection

    func testTranscriptProducesLexicalFillerEvents() async throws {
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        await speech.simulateTranscript("halo kayak banget gini")
        try await Task.sleep(nanoseconds: 200_000_000)

        let result = await coordinator.stop()
        let lexical = Set(result.fillerEvents.compactMap(\.lexicalToken))
        XCTAssertEqual(lexical, ["kayak", "gini"], "Only lexicon tokens are recorded as fillers")
    }

    func testCumulativeTranscriptDoesNotDoubleCountFillers() async throws {
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        // Recognizer re-emits a growing cumulative transcript; "kayak" appears in both
        // but must be counted once, and only the newly-added "gini" is added.
        await speech.simulateTranscript("kayak")
        await speech.simulateTranscript("kayak banget gini")
        try await Task.sleep(nanoseconds: 200_000_000)

        let result = await coordinator.stop()
        let lexical = result.fillerEvents.compactMap(\.lexicalToken).sorted()
        XCTAssertEqual(lexical, ["gini", "kayak"], "Each filler is counted exactly once")
    }

    func testSilentPauseFromAudioLevelsProducesFillerEvent() async throws {
        let wall = TestWall()
        let audio = MockAudioCaptureService()
        // Frozen noise floor → fixed speech threshold 0.04; min pause 1s.
        let detector = SilenceDetector(config: .init(
            minPauseSeconds: 1.0, energyFactor: 4, exitHysteresis: 1.0,
            floorDownAlpha: 0, floorUpAlpha: 0, absoluteFloor: 0, initialNoiseFloor: 0.01
        ))
        let coordinator = PracticeRecordingCoordinator(
            audioService: audio,
            speechService: MockSpeechRecognitionService(),
            slideService: MockSlideTrackingService(),
            pollingIntervalNanoseconds: 10_000_000_000,
            clock: MediaClock(wallNow: wall.source()),
            wpmCalculator: WPMCalculator(smoothingFactor: 0),
            silenceDetector: detector
        )

        try await coordinator.start(keynoteFileName: "Test.key")
        await audio.simulateAudioLevel(0.2)                 // speaking at now=0
        try await Task.sleep(nanoseconds: 100_000_000)
        wall.advance(to: 1)
        await audio.simulateAudioLevel(0.001)               // silence begins at now=1
        try await Task.sleep(nanoseconds: 100_000_000)
        wall.advance(to: 3)
        await audio.simulateAudioLevel(0.2)                 // resume at now=3 → 2s pause
        try await Task.sleep(nanoseconds: 150_000_000)

        let result = await coordinator.stop()
        XCTAssertEqual(result.fillerEvents.filter(\.isSilentPause).count, 1)
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @escaping () async -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() { return true }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return await condition()
    }
}

// MARK: - Test helpers

/// Deterministic, thread-safe wall-time source for the media clock.
private final class TestWall: @unchecked Sendable {
    private let lock = NSLock()
    private var t: TimeInterval

    init(_ start: TimeInterval = 0) { t = start }

    func advance(to value: TimeInterval) {
        lock.lock(); t = value; lock.unlock()
    }

    func source() -> @Sendable () -> TimeInterval {
        { [self] in
            lock.lock(); defer { lock.unlock() }
            return t
        }
    }
}

// MARK: - Mocks

private actor MockAudioCaptureService: AudioCapturing {
    private(set) var startCallCount = 0
    private(set) var updatedRequests: [SFSpeechAudioBufferRecognitionRequest] = []
    private var levelContinuation: AsyncStream<Float>.Continuation?

    func start(speechRequest: SFSpeechAudioBufferRecognitionRequest) async throws {
        startCallCount += 1
    }

    func updateSpeechRequest(_ request: SFSpeechAudioBufferRecognitionRequest) async {
        updatedRequests.append(request)
    }

    func audioLevels() async -> AsyncStream<Float> {
        let (stream, continuation) = AsyncStream.makeStream(of: Float.self)
        levelContinuation = continuation
        return stream
    }

    /// Push one RMS sample into the live audio-levels stream (test driver).
    func simulateAudioLevel(_ level: Float) {
        levelContinuation?.yield(level)
    }

    func pause() async {}
    func resume() async throws {}
    func stop() async -> URL? {
        levelContinuation?.finish()
        return nil
    }
}

private actor MockSpeechRecognitionService: SpeechRecognizing {
    private(set) var startCallCount = 0
    private(set) var requests: [SFSpeechAudioBufferRecognitionRequest] = []
    private var onWordCount: (@Sendable (Int) -> Void)?
    private var onTranscript: (@Sendable (String) -> Void)?
    private var onTaskEnded: (@Sendable (Bool) -> Void)?
    private var failNextStarts = 0

    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        .authorized
    }

    /// Make the next `n` `startRecognition` calls throw, simulating a transiently
    /// unavailable recognizer.
    func setFailNextStarts(_ n: Int) {
        failNextStarts = n
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onWordCount: @Sendable @escaping (Int) -> Void,
        onTranscript: @Sendable @escaping (String) -> Void,
        onTaskEnded: @Sendable @escaping (Bool) -> Void
    ) async throws {
        startCallCount += 1
        requests.append(request)
        if failNextStarts > 0 {
            failNextStarts -= 1
            throw SpeechRecognitionError.recognizerUnavailable
        }
        self.onWordCount = onWordCount
        self.onTranscript = onTranscript
        self.onTaskEnded = onTaskEnded
    }

    func stopRecognition() async {}

    func simulateWordCount(_ count: Int) {
        onWordCount?(count)
    }

    func simulateTranscript(_ transcript: String) {
        onTranscript?(transcript)
    }

    func simulateTaskEnded(error: Bool) {
        onTaskEnded?(error)
    }
}

private actor MockSlideTrackingService: KeynoteSlideTracking {
    func currentSlideNumber() async throws -> Int { 1 }
}
