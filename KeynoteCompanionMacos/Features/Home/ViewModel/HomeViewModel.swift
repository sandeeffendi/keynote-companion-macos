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

    private(set) var sessionStatus: HomeSessionStatus = .permissionMissing

    private let microphonePermissionService: MicrophonePermissionChecking
    private let automationPermissionService: KeynoteAutomationPermissionChecking
    private let keynoteStatusService: KeynoteStatusChecking
    private let keynoteFileOpener: KeynoteFileOpening
    private let pollingIntervalNanoseconds: UInt64

    private var openFileTask: Task<Void, Never>?
    private var openFileRequestID: UUID?

    convenience init(state: HomeViewState = .permissionMissing) {
        let appResolver = KeynoteAppResolver()
        self.init(
            state: state,
            microphonePermissionService: MicrophonePermissionService(),
            automationPermissionService: KeynoteAutomationPermissionService(
                appResolver: appResolver
            ),
            keynoteStatusService: KeynoteStatusService(appResolver: appResolver),
            keynoteFileOpener: KeynoteFileOpener(appResolver: appResolver),
            pollingIntervalNanoseconds: 1_000_000_000
        )
    }

    init(
        state: HomeViewState,
        microphonePermissionService: MicrophonePermissionChecking,
        automationPermissionService: KeynoteAutomationPermissionChecking,
        keynoteStatusService: KeynoteStatusChecking,
        keynoteFileOpener: KeynoteFileOpening,
        pollingIntervalNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.state = state
        self.microphonePermissionService = microphonePermissionService
        self.automationPermissionService = automationPermissionService
        self.keynoteStatusService = keynoteStatusService
        self.keynoteFileOpener = keynoteFileOpener
        self.pollingIntervalNanoseconds = pollingIntervalNanoseconds
    }

    deinit {
        openFileTask?.cancel()
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
