//
//  HomeViewModel.swift
//  KeynoteCompanionMacos
//

import Foundation
import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState
    @Published var errorMessage: String?
    @Published var isShowingPermissions = false

    private(set) var sessionStatus: HomeSessionStatus = .permissionMissing
    private(set) var currentDocumentName: String = ""

    private let microphonePermissionService: MicrophonePermissionChecking
    private let automationPermissionService: KeynoteAutomationPermissionChecking
    private let speechPermissionService: SpeechRecognitionPermissionChecking
    private let keynoteStatusService: KeynoteStatusChecking
    private let keynoteFileOpener: KeynoteFileOpening
    private let slideshowStarter: KeynoteSlideshowStarting
    private let automationStatusStore: KeynoteAutomationStatusStoring
    private let pollingIntervalNanoseconds: UInt64

    private var openFileTask: Task<Void, Never>?
    private var openFileRequestID: UUID?
    private var startSlideshowTask: Task<Void, Never>?
    private var startSlideshowRequestID: UUID?

    convenience init(state: HomeViewState = .permissionMissing) {
        let appResolver = KeynoteAppResolver()
        self.init(
            state: state,
            microphonePermissionService: MicrophonePermissionService(),
            automationPermissionService: KeynoteAutomationPermissionService(
                appResolver: appResolver
            ),
            speechPermissionService: SpeechRecognitionPermissionService(),
            keynoteStatusService: KeynoteStatusService(appResolver: appResolver),
            keynoteFileOpener: KeynoteFileOpener(appResolver: appResolver),
            slideshowStarter: KeynoteSlideshowStartService(appResolver: appResolver),
            automationStatusStore: UserDefaultsKeynoteAutomationStatusStore(),
            pollingIntervalNanoseconds: 1_000_000_000
        )
    }

    init(
        state: HomeViewState,
        microphonePermissionService: MicrophonePermissionChecking,
        automationPermissionService: KeynoteAutomationPermissionChecking,
        speechPermissionService: SpeechRecognitionPermissionChecking,
        keynoteStatusService: KeynoteStatusChecking,
        keynoteFileOpener: KeynoteFileOpening,
        slideshowStarter: KeynoteSlideshowStarting = KeynoteSlideshowStartService(),
        automationStatusStore: KeynoteAutomationStatusStoring =
            UserDefaultsKeynoteAutomationStatusStore(),
        pollingIntervalNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.state = state
        self.microphonePermissionService = microphonePermissionService
        self.automationPermissionService = automationPermissionService
        self.speechPermissionService = speechPermissionService
        self.keynoteStatusService = keynoteStatusService
        self.keynoteFileOpener = keynoteFileOpener
        self.slideshowStarter = slideshowStarter
        self.automationStatusStore = automationStatusStore
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
    }

    deinit {
        openFileTask?.cancel()
        startSlideshowTask?.cancel()
    }

    func observeSession() async {
        while !Task.isCancelled {
            await refreshSessionStatus()

            do {
                try await Task.sleep(nanoseconds: pollingIntervalNanoseconds)
            } catch {
                break
            }
        }
    }

    func openPermissions() {
        isShowingPermissions = true
    }

    func showActivities() {}

    func openKeynoteFile() {
        openFileTask?.cancel()
        let requestID = UUID()
        openFileRequestID = requestID
        openFileTask = Task { [weak self] in
            await self?.openSelectedKeynoteFile(requestID: requestID)
        }
    }

    func startSlideshow() {
        startSlideshowTask?.cancel()
        let requestID = UUID()
        startSlideshowRequestID = requestID
        startSlideshowTask = Task { [weak self] in
            await self?.startSelectedSlideshow(requestID: requestID)
        }
    }

    func refreshSessionStatus() async {
        guard microphonePermissionService.authorizationStatus() == .authorized else {
            apply(.permissionMissing)
            return
        }

        guard speechPermissionService.authorizationStatus() == .authorized else {
            apply(.permissionMissing)
            return
        }

        let automationStatus = await automationPermissionService.authorizationStatus(
            promptIfNeeded: false
        )

        guard !Task.isCancelled else {
            return
        }

        switch automationStatus {
        case .authorized:
            // Determinable read — keep the cache in sync with System Settings.
            automationStatusStore.update(.authorized)
        case .notDetermined:
            automationStatusStore.update(.notDetermined)
            apply(.permissionMissing)
            return
        case .denied:
            automationStatusStore.update(.denied)
            apply(.permissionMissing)
            return
        case .keynoteUnavailable:
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
            return
        case .targetNotRunning:
            // Status is undeterminable while Keynote is closed. Fall back to the last
            // System-Settings-synced value so a not-yet-granted permission still gates,
            // but a merely-closed Keynote (previously authorized) does not.
            if automationStatusStore.lastKnownStatus == .authorized {
                apply(.noKeynoteDocument)
            } else {
                apply(.permissionMissing)
            }
            return
        case .error(let status):
            apply(
                .automationError,
                errorMessage: "Keynote automation failed with status \(status)."
            )
            return
        }

        guard !Task.isCancelled else {
            return
        }

        do {
            let runtimeStatus = try await keynoteStatusService.currentStatus()

            guard !Task.isCancelled else {
                return
            }

            if runtimeStatus.hasOpenDocuments {
                currentDocumentName = runtimeStatus.documentName
            }

            if runtimeStatus.hasOpenDocuments && runtimeStatus.isPlaying {
                apply(.keynoteSlideshowActive)
            } else if runtimeStatus.hasOpenDocuments {
                apply(.keynoteDocumentOpen)
            } else {
                apply(.noKeynoteDocument)
            }
        } catch is CancellationError {
            return
        } catch KeynoteStatusError.keynoteUnavailable {
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
        } catch {
            apply(
                .automationError,
                errorMessage: error.localizedDescription
            )
        }
    }

    func openSelectedKeynoteFile() async {
        await openSelectedKeynoteFile(requestID: nil)
    }

    private func openSelectedKeynoteFile(requestID: UUID?) async {
        defer {
            clearOpenFileTaskIfCurrent(requestID: requestID)
        }

        do {
            let didOpenFile = try await keynoteFileOpener.openKeynoteFile()

            guard !Task.isCancelled else {
                return
            }

            if didOpenFile {
                await refreshSessionStatus()
            }
        } catch is CancellationError {
            return
        } catch KeynoteFileOpenError.keynoteUnavailable {
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
        } catch {
            apply(
                .openFileFailed,
                errorMessage: error.localizedDescription
            )
        }
    }

    func startSelectedSlideshow() async {
        await startSelectedSlideshow(requestID: nil)
    }

    private func startSelectedSlideshow(requestID: UUID?) async {
        defer {
            clearStartSlideshowTaskIfCurrent(requestID: requestID)
        }

        do {
            try await slideshowStarter.startSlideshow()

            guard !Task.isCancelled else {
                return
            }

            // Reflect the new playing state immediately; the poll loop is the backup.
            await refreshSessionStatus()
        } catch is CancellationError {
            return
        } catch KeynoteStatusError.keynoteUnavailable {
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
        } catch {
            apply(
                .startSlideshowFailed,
                errorMessage: error.localizedDescription
            )
        }
    }

    private func clearStartSlideshowTaskIfCurrent(requestID: UUID?) {
        guard let requestID else {
            return
        }

        if startSlideshowRequestID == requestID {
            startSlideshowTask = nil
            startSlideshowRequestID = nil
        }
    }

    private func clearOpenFileTaskIfCurrent(requestID: UUID?) {
        guard let requestID else {
            return
        }

        if openFileRequestID == requestID {
            openFileTask = nil
            openFileRequestID = nil
        }
    }

    private func apply(
        _ status: HomeSessionStatus,
        errorMessage: String? = nil
    ) {
        sessionStatus = status
        state = status.visibleState(preserving: state)
        self.errorMessage = status.isTechnicalFailure ? errorMessage : nil
    }

    func showHelp() {}

    func openSettings() {}

    func showActivities() {}
    
    func showRecap() {}

    func openKeynoteFile() {
        openFileTask?.cancel()
        let requestID = UUID()
        openFileRequestID = requestID
        openFileTask = Task { [weak self] in
            await self?.openSelectedKeynoteFile(requestID: requestID)
        }
    }

    func recordPractice() {}

    func refreshSessionStatus() async {
        guard microphonePermissionService.authorizationStatus() == .authorized else {
            apply(.permissionMissing)
            return
        }

        guard speechPermissionService.authorizationStatus() == .authorized else {
            apply(.permissionMissing)
            return
        }

        let automationStatus = await automationPermissionService.authorizationStatus(
            promptIfNeeded: false
        )

        guard !Task.isCancelled else {
            return
        }

        switch automationStatus {
        case .authorized:
            break
        case .notDetermined, .denied:
            apply(.permissionMissing)
            return
        case .keynoteUnavailable:
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
            return
        case .targetNotRunning:
            apply(.noKeynoteDocument)
            return
        case .error(let status):
            apply(
                .automationError,
                errorMessage: "Keynote automation failed with status \(status)."
            )
            return
        }

        guard !Task.isCancelled else {
            return
        }

        do {
            let runtimeStatus = try await keynoteStatusService.currentStatus()

            guard !Task.isCancelled else {
                return
            }

            if runtimeStatus.hasOpenDocuments {
                currentDocumentName = runtimeStatus.documentName
            }

            if runtimeStatus.hasOpenDocuments && runtimeStatus.isPlaying {
                apply(.keynoteSlideshowActive)
            } else if runtimeStatus.hasOpenDocuments {
                apply(.keynoteDocumentOpen)
            } else {
                apply(.noKeynoteDocument)
            }
        } catch is CancellationError {
            return
        } catch KeynoteStatusError.keynoteUnavailable {
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
        } catch {
            apply(
                .automationError,
                errorMessage: error.localizedDescription
            )
        }
    }

    func openSelectedKeynoteFile() async {
        await openSelectedKeynoteFile(requestID: nil)
    }

    private func openSelectedKeynoteFile(requestID: UUID?) async {
        defer {
            clearOpenFileTaskIfCurrent(requestID: requestID)
        }

        do {
            let didOpenFile = try await keynoteFileOpener.openKeynoteFile()

            guard !Task.isCancelled else {
                return
            }

            if didOpenFile {
                await refreshSessionStatus()
            }
        } catch is CancellationError {
            return
        } catch KeynoteFileOpenError.keynoteUnavailable {
            apply(
                .keynoteUnavailable,
                errorMessage: "Keynote is not installed on this Mac."
            )
        } catch {
            apply(
                .openFileFailed,
                errorMessage: error.localizedDescription
            )
        }
    }

    private func clearOpenFileTaskIfCurrent(requestID: UUID?) {
        guard let requestID else {
            return
        }

        if openFileRequestID == requestID {
            openFileTask = nil
            openFileRequestID = nil
        }
    }

    private func apply(
        _ status: HomeSessionStatus,
        errorMessage: String? = nil
    ) {
        sessionStatus = status
        state = status.visibleState(preserving: state)
        self.errorMessage = status.isTechnicalFailure ? errorMessage : nil
    }
}
