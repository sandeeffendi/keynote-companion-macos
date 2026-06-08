//
//  HomeViewModelTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testInternalStatusMapsToVisibleStates() {
        XCTAssertEqual(
            HomeSessionStatus.permissionMissing.visibleState,
            .permissionMissing
        )
        XCTAssertEqual(
            HomeSessionStatus.noKeynoteDocument.visibleState,
            .noKeynoteFileOpen
        )
        XCTAssertEqual(
            HomeSessionStatus.keynoteDocumentOpen.visibleState,
            .noKeynoteSlideshowActive
        )
        XCTAssertEqual(
            HomeSessionStatus.keynoteSlideshowActive.visibleState,
            .keynoteSlideshowActive
        )
        XCTAssertEqual(
            HomeSessionStatus.automationError.visibleState(
                preserving: .noKeynoteSlideshowActive
            ),
            .noKeynoteSlideshowActive
        )
    }

    func testAutomationOSStatusMapping() {
        XCTAssertEqual(
            KeynoteAutomationPermissionState.from(osStatus: noErr),
            .authorized
        )
        XCTAssertEqual(
            KeynoteAutomationPermissionState.from(osStatus: -1744),
            .notDetermined
        )
        XCTAssertEqual(
            KeynoteAutomationPermissionState.from(osStatus: -1743),
            .denied
        )
        XCTAssertEqual(
            KeynoteAutomationPermissionState.from(osStatus: -600),
            .targetNotRunning
        )
    }

    func testOpenFileCancelLeavesStateUnchanged() async {
        let viewModel = makeViewModel(
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false)
            ],
            didOpenFile: false
        )

        await viewModel.refreshSessionStatus()
        XCTAssertEqual(viewModel.state, .noKeynoteFileOpen)
        XCTAssertEqual(viewModel.sessionStatus, .noKeynoteDocument)

        await viewModel.openSelectedKeynoteFile()

        XCTAssertEqual(viewModel.state, .noKeynoteFileOpen)
        XCTAssertEqual(viewModel.sessionStatus, .noKeynoteDocument)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFileOpenCancellationDoesNotApplyError() async {
        let viewModel = makeViewModel(
            initialState: .noKeynoteFileOpen,
            keynoteStatuses: [],
            fileOpenResult: .cancellation
        )

        await viewModel.openSelectedKeynoteFile()

        XCTAssertEqual(viewModel.state, .noKeynoteFileOpen)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testMissingMicrophoneMapsToPermissionMissing() async {
        let viewModel = makeViewModel(
            microphoneStatus: .denied,
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true)
            ]
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(viewModel.state, .permissionMissing)
        XCTAssertEqual(viewModel.sessionStatus, .permissionMissing)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testMissingAutomationMapsToPermissionMissing() async {
        let viewModel = makeViewModel(
            automationStatus: .denied,
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true)
            ]
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(viewModel.state, .permissionMissing)
        XCTAssertEqual(viewModel.sessionStatus, .permissionMissing)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testTargetNotRunningMapsToNoKeynoteFileOpenWithoutError() async {
        let viewModel = makeViewModel(
            initialState: .permissionMissing,
            automationStatus: .targetNotRunning,
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true)
            ]
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(viewModel.state, .noKeynoteFileOpen)
        XCTAssertEqual(viewModel.sessionStatus, .noKeynoteDocument)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAutomationErrorPreservesVisibleState() async {
        let viewModel = makeViewModel(
            initialState: .noKeynoteSlideshowActive,
            automationStatus: .error(-1),
            keynoteStatuses: []
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(viewModel.state, .noKeynoteSlideshowActive)
        XCTAssertEqual(viewModel.sessionStatus, .automationError)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Keynote automation failed with status -1."
        )
    }

    func testMockedDocumentAndSlideshowStatusTransitions() async {
        let viewModel = makeViewModel(
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false),
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: false),
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true)
            ]
        )

        await viewModel.refreshSessionStatus()
        XCTAssertEqual(viewModel.state, .noKeynoteFileOpen)
        XCTAssertEqual(viewModel.sessionStatus, .noKeynoteDocument)

        await viewModel.refreshSessionStatus()
        XCTAssertEqual(viewModel.state, .noKeynoteSlideshowActive)
        XCTAssertEqual(viewModel.sessionStatus, .keynoteDocumentOpen)

        await viewModel.refreshSessionStatus()
        XCTAssertEqual(viewModel.state, .keynoteSlideshowActive)
        XCTAssertEqual(viewModel.sessionStatus, .keynoteSlideshowActive)
    }

    private func makeViewModel(
        initialState: HomeViewState = .permissionMissing,
        microphoneStatus: PermissionStatus = .authorized,
        automationStatus: KeynoteAutomationPermissionState = .authorized,
        keynoteStatuses: [KeynoteRuntimeStatus],
        didOpenFile: Bool = true,
        fileOpenResult: MockKeynoteFileOpenResult? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            state: initialState,
            microphonePermissionService: MockMicrophonePermissionService(
                status: microphoneStatus
            ),
            automationPermissionService: MockAutomationPermissionService(
                status: automationStatus
            ),
            keynoteStatusService: MockKeynoteStatusService(
                statuses: keynoteStatuses
            ),
            keynoteFileOpener: MockKeynoteFileOpener(
                result: fileOpenResult ?? .success(didOpenFile)
            ),
            pollingIntervalNanoseconds: 1_000
        )
    }
}

private struct MockMicrophonePermissionService: MicrophonePermissionChecking {
    let status: PermissionStatus

    func authorizationStatus() -> PermissionStatus {
        status
    }
}

private struct MockAutomationPermissionService: KeynoteAutomationPermissionChecking {
    let status: KeynoteAutomationPermissionState

    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        status
    }
}

private actor MockKeynoteStatusService: KeynoteStatusChecking {
    private var statuses: [KeynoteRuntimeStatus]

    init(statuses: [KeynoteRuntimeStatus]) {
        self.statuses = statuses
    }

    func currentStatus() async throws -> KeynoteRuntimeStatus {
        if statuses.isEmpty {
            return KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false)
        }

        return statuses.removeFirst()
    }
}

private enum MockKeynoteFileOpenResult: Sendable {
    case success(Bool)
    case cancellation
}

private struct MockKeynoteFileOpener: KeynoteFileOpening {
    let result: MockKeynoteFileOpenResult

    func openKeynoteFile() async throws -> Bool {
        switch result {
        case .success(let didOpenFile):
            return didOpenFile
        case .cancellation:
            throw CancellationError()
        }
    }
}
