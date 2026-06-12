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
        speech: MockSpeechRecognitionService = MockSpeechRecognitionService()
    ) -> PracticeRecordingCoordinator {
        PracticeRecordingCoordinator(
            audioService: audio,
            speechService: speech,
            slideService: MockSlideTrackingService(),
            pollingIntervalNanoseconds: 10_000_000_000
        )
    }

    func testWordCountUpdatesProduceNonZeroWPM() async throws {
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        await speech.simulateWordCount(30)

        let becameNonZero = await waitUntil {
            await coordinator.currentWPM() > 0
        }
        XCTAssertTrue(becameNonZero, "WPM should become non-zero after word counts arrive")

        _ = await coordinator.stop()
    }

    func testTaskEndedRestartsRecognitionWithFreshRequestAndSwapsAudioTap() async throws {
        let audio = MockAudioCaptureService()
        let speech = MockSpeechRecognitionService()
        let coordinator = makeCoordinator(audio: audio, speech: speech)

        try await coordinator.start(keynoteFileName: "Test.key")
        await speech.simulateWordCount(10)
        await speech.simulateTaskEnded()

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

        // Word count from the expired task is accumulated, not lost. The update
        // hops through a Task, so give it a moment to land before stopping.
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
        await speech.simulateTaskEnded()

        // Restart waits 0.5s before re-arming; give it time to (not) fire.
        try await Task.sleep(nanoseconds: 800_000_000)

        let startCallCount = await speech.startCallCount
        XCTAssertEqual(startCallCount, 1, "No restart should happen after the session stopped")
        let updatedRequests = await audio.updatedRequests
        XCTAssertTrue(updatedRequests.isEmpty)
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
    private var onTaskEnded: (@Sendable () -> Void)?

    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        .authorized
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onWordCount: @Sendable @escaping (Int) -> Void,
        onTaskEnded: @Sendable @escaping () -> Void
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

    func simulateTaskEnded() {
        onTaskEnded?()
    }
}

private actor MockSlideTrackingService: KeynoteSlideTracking {
    func currentSlideNumber() async throws -> Int { 1 }
}
