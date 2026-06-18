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

    func testOverlayOnlyActivatesForKeynoteSlideshowActiveState() {
        for state in HomeViewState.allCases {
            XCTAssertEqual(
                state.isKeynoteOverlayActive,
                state == .keynoteSlideshowActive
            )
        }
    }

    func testRouteHelperTreatsRootAndHomeRouteAsShowingHome() {
        XCTAssertTrue(AppRoute.isHomeRoute(nil))
        XCTAssertTrue(AppRoute.isHomeRoute(.home(.main)))
        XCTAssertFalse(AppRoute.isHomeRoute(.recap(.main(.placeholder()))))
    }

    func testOpenFileCancelLeavesStateUnchanged() async {
        let viewModel = makeViewModel(
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false, documentName: "")
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
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true, documentName: "")
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
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true, documentName: "")
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
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true, documentName: "")
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
                KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false, documentName: ""),
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: false, documentName: ""),
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true, documentName: "")
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
        speechStatus: PermissionStatus = .authorized,
        keynoteStatuses: [KeynoteRuntimeStatus],
        didOpenFile: Bool = true,
        fileOpenResult: MockKeynoteFileOpenResult? = nil,
        startSlideshowShouldThrow: Bool = false,
        automationStore: MockKeynoteAutomationStatusStore =
            MockKeynoteAutomationStatusStore(initial: .authorized)
    ) -> HomeViewModel {
        HomeViewModel(
            state: initialState,
            microphonePermissionService: MockMicrophonePermissionService(
                status: microphoneStatus
            ),
            automationPermissionService: MockAutomationPermissionService(
                status: automationStatus
            ),
            speechPermissionService: MockSpeechRecognitionPermissionService(
                status: speechStatus
            ),
            keynoteStatusService: MockKeynoteStatusService(
                statuses: keynoteStatuses
            ),
            keynoteFileOpener: MockKeynoteFileOpener(
                result: fileOpenResult ?? .success(didOpenFile)
            ),
            slideshowStarter: MockKeynoteSlideshowStarter(
                shouldThrow: startSlideshowShouldThrow
            ),
            automationStatusStore: automationStore,
            pollingIntervalNanoseconds: 1_000
        )
    }

    func testStartSlideshowSuccessTransitionsToActive() async {
        let viewModel = makeViewModel(
            initialState: .noKeynoteSlideshowActive,
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: true, isPlaying: true, documentName: "Deck")
            ]
        )

        await viewModel.startSelectedSlideshow()

        XCTAssertEqual(viewModel.state, .keynoteSlideshowActive)
        XCTAssertEqual(viewModel.sessionStatus, .keynoteSlideshowActive)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStartSlideshowFailureShowsErrorAndPreservesState() async {
        let viewModel = makeViewModel(
            initialState: .noKeynoteSlideshowActive,
            keynoteStatuses: [],
            startSlideshowShouldThrow: true
        )

        await viewModel.startSelectedSlideshow()

        XCTAssertEqual(viewModel.state, .noKeynoteSlideshowActive)
        XCTAssertEqual(viewModel.sessionStatus, .startSlideshowFailed)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testTargetNotRunningWithUnauthorizedCacheShowsPermissionMissing() async {
        for cached in [PermissionStatus.notDetermined, .denied] {
            let viewModel = makeViewModel(
                automationStatus: .targetNotRunning,
                keynoteStatuses: [],
                automationStore: MockKeynoteAutomationStatusStore(initial: cached)
            )

            await viewModel.refreshSessionStatus()

            XCTAssertEqual(
                viewModel.state, .permissionMissing,
                "cached \(cached) should gate to permissionMissing"
            )
        }
    }

    func testAuthorizedAutomationSyncsCacheToAuthorized() async {
        let store = MockKeynoteAutomationStatusStore(initial: .notDetermined)
        let viewModel = makeViewModel(
            automationStatus: .authorized,
            keynoteStatuses: [
                KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false, documentName: "")
            ],
            automationStore: store
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(store.lastKnownStatus, .authorized)
    }

    func testDeniedAutomationSyncsCacheAndGates() async {
        let store = MockKeynoteAutomationStatusStore(initial: .authorized)
        let viewModel = makeViewModel(
            automationStatus: .denied,
            keynoteStatuses: [],
            automationStore: store
        )

        await viewModel.refreshSessionStatus()

        XCTAssertEqual(store.lastKnownStatus, .denied)
        XCTAssertEqual(viewModel.state, .permissionMissing)
    }
}

final class MockKeynoteAutomationStatusStore: KeynoteAutomationStatusStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var status: PermissionStatus

    init(initial: PermissionStatus = .notDetermined) {
        self.status = initial
    }

    var lastKnownStatus: PermissionStatus {
        lock.withLock { status }
    }

    func update(_ status: PermissionStatus) {
        lock.withLock { self.status = status }
    }
}

private struct MockMicrophonePermissionService: MicrophonePermissionChecking {
    let status: PermissionStatus

    func authorizationStatus() -> PermissionStatus {
        status
    }
}

private struct MockSpeechRecognitionPermissionService: SpeechRecognitionPermissionChecking {
    let status: PermissionStatus

    func authorizationStatus() -> PermissionStatus {
        status
    }

    func requestPermission() async -> PermissionStatus {
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
            return KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false, documentName: "")
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

private struct MockKeynoteSlideshowStarter: KeynoteSlideshowStarting {
    let shouldThrow: Bool

    func startSlideshow() async throws {
        if shouldThrow {
            throw KeynoteStatusError.appleScriptFailed("mock start failure")
        }
    }
}
