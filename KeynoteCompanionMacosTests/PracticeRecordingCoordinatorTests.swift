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

    func start(speechRequest: SFSpeechAudioBufferRecognitionRequest) async throws {
        startCallCount += 1
    }

    func updateSpeechRequest(_ request: SFSpeechAudioBufferRecognitionRequest) async {
        updatedRequests.append(request)
    }

    func pause() async {}
    func resume() async throws {}
    func stop() async -> URL? { nil }
}

private actor MockSpeechRecognitionService: SpeechRecognizing {
    private(set) var startCallCount = 0
    private(set) var requests: [SFSpeechAudioBufferRecognitionRequest] = []
    private var onWordCount: (@Sendable (Int) -> Void)?
    private var onTaskEnded: (@Sendable (Bool) -> Void)?

    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        .authorized
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onWordCount: @Sendable @escaping (Int) -> Void,
        onTaskEnded: @Sendable @escaping (Bool) -> Void
    ) async throws {
        startCallCount += 1
        requests.append(request)
        self.onWordCount = onWordCount
        self.onTaskEnded = onTaskEnded
    }

    func stopRecognition() async {}

    func simulateWordCount(_ count: Int) {
        onWordCount?(count)
    }

    func simulateTaskEnded(error: Bool) {
        onTaskEnded?(error)
    }
}

private actor MockSlideTrackingService: KeynoteSlideTracking {
    func currentSlideNumber() async throws -> Int { 1 }
}
