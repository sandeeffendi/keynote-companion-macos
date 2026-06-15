//
//  PermissionsSheetViewModelTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

@MainActor
final class PermissionsSheetViewModelTests: XCTestCase {
    func testInitialRefreshReflectsAuthorizedServices() async {
        let viewModel = makeViewModel(
            automation: .authorized,
            microphone: .authorized,
            speech: .authorized
        )

        // The automation status is refreshed asynchronously; let it settle.
        await waitUntil { viewModel.allGranted }

        XCTAssertTrue(viewModel.allGranted)
        XCTAssertTrue(viewModel.rows.allSatisfy { $0.status == .authorized })
    }

    func testNotAllAuthorizedKeepsAllGrantedFalse() async {
        let viewModel = makeViewModel(
            automation: .authorized,
            microphone: .denied,
            speech: .authorized
        )

        await Task.yield()
        await Task.yield()

        XCTAssertFalse(viewModel.allGranted)
    }

    /// Polls `condition` until true or a short timeout elapses, yielding to let the
    /// view model's async automation refresh complete.
    private func waitUntil(
        _ condition: () -> Bool,
        iterations: Int = 50
    ) async {
        for _ in 0..<iterations where !condition() {
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    func testRowsAreOrderedKeynoteMicrophoneSpeech() {
        let viewModel = makeViewModel(
            automation: .notDetermined,
            microphone: .notDetermined,
            speech: .notDetermined
        )

        XCTAssertEqual(
            viewModel.rows.map(\.type),
            [.keynoteAutomation, .microphone, .speechRecognition]
        )
    }

    private func makeViewModel(
        automation: KeynoteAutomationPermissionState,
        microphone: PermissionStatus,
        speech: PermissionStatus
    ) -> PermissionsSheetViewModel {
        PermissionsSheetViewModel(
            automationPermissionService: StubAutomationPermissionService(
                status: automation
            ),
            microphonePermissionService: StubMicrophonePermissionService(
                status: microphone
            ),
            speechPermissionService: StubSpeechRecognitionPermissionService(
                status: speech
            )
        )
    }
}

private struct StubMicrophonePermissionService: MicrophonePermissionChecking {
    let status: PermissionStatus
    func authorizationStatus() -> PermissionStatus { status }
}

private struct StubSpeechRecognitionPermissionService: SpeechRecognitionPermissionChecking {
    let status: PermissionStatus
    func authorizationStatus() -> PermissionStatus { status }
    func requestPermission() async -> PermissionStatus { status }
}

private struct StubAutomationPermissionService: KeynoteAutomationPermissionChecking {
    let status: KeynoteAutomationPermissionState
    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        status
    }
}
