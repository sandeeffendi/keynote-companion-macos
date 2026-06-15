//
//  KeynoteAutomationPermissionService.swift
//  KeynoteCompanionMacos
//

import ApplicationServices
import AppKit
import Foundation

enum KeynoteAutomationPermissionState: Equatable, Sendable {
    case authorized
    case notDetermined
    case denied
    case keynoteUnavailable
    case targetNotRunning
    case error(OSStatus)

    nonisolated static func from(osStatus: OSStatus) -> KeynoteAutomationPermissionState {
        switch osStatus {
        case noErr:
            return .authorized
        case OSStatus(errAEEventWouldRequireUserConsent):
            return .notDetermined
        case OSStatus(errAEEventNotPermitted):
            return .denied
        case OSStatus(procNotFound):
            return .targetNotRunning
        default:
            return .error(osStatus)
        }
    }
}

protocol KeynoteAutomationPermissionChecking: Sendable {
    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState
}

struct KeynoteAutomationPermissionService: KeynoteAutomationPermissionChecking {
    private let appResolver: KeynoteAppResolving
    private let statusService: KeynoteStatusChecking

    init(
        appResolver: KeynoteAppResolving,
        statusService: KeynoteStatusChecking? = nil
    ) {
        self.appResolver = appResolver
        self.statusService = statusService
            ?? KeynoteStatusService(appResolver: appResolver)
    }

    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        guard let app = appResolver.resolve() else {
            return .keynoteUnavailable
        }

        // We only clean Keynote up if *we* launched it just to surface the prompt.
        let wasRunningBefore = appResolver.resolvedRunningBundleIdentifier() != nil

        if promptIfNeeded {
            let isRunning = await launchKeynoteIfNeeded(app)
            guard isRunning else {
                return .targetNotRunning
            }
        } else if !wasRunningBefore {
            return .targetNotRunning
        }

        let state = await determinePermission(for: app, promptIfNeeded: promptIfNeeded)

        // Issue 1: launching Keynote with no open document makes it show its own document
        // browser ("Page Finder"). If we were the one who launched it and it holds nothing
        // the user opened, quit that instance so the chooser doesn't linger on screen.
        if !wasRunningBefore {
            await dismissKeynoteWeLaunched()
        }

        return state
    }

    private func determinePermission(
        for app: KeynoteAppIdentity,
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        await Task.detached(priority: .userInitiated) {
            var target = AEAddressDesc()
            let bundleIdentifierData = Data(app.bundleIdentifier.utf8)
            let createStatus = bundleIdentifierData.withUnsafeBytes { buffer in
                AECreateDesc(
                    typeApplicationBundleID,
                    buffer.baseAddress,
                    bundleIdentifierData.count,
                    &target
                )
            }

            guard createStatus == noErr else {
                return .error(OSStatus(createStatus))
            }

            defer {
                AEDisposeDesc(&target)
            }

            let status = AEDeterminePermissionToAutomateTarget(
                &target,
                typeWildCard,
                typeWildCard,
                promptIfNeeded
            )

            return KeynoteAutomationPermissionState.from(osStatus: status)
        }.value
    }

    @MainActor
    private func launchKeynoteIfNeeded(_ app: KeynoteAppIdentity) async -> Bool {
        if appResolver.resolvedRunningBundleIdentifier() != nil {
            return true
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.createsNewApplicationInstance = false

        let didLaunch = await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(
                at: app.applicationURL,
                configuration: configuration
            ) { _, error in
                continuation.resume(returning: error == nil)
            }
        }

        guard didLaunch else {
            return false
        }

        for _ in 0..<20 {
            if appResolver.resolvedRunningBundleIdentifier() != nil {
                // Hide as soon as it's up so its document browser doesn't flash on screen
                // while the TCC prompt (a separate system dialog) is shown.
                runningKeynoteApplication()?.hide()
                return true
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                return false
            }
        }

        return false
    }

    /// Cleans up the Keynote instance we launched solely to surface the automation prompt.
    /// If Keynote has since gained an open document, we leave it (it stays hidden); otherwise
    /// we quit it so its document browser doesn't remain on screen.
    @MainActor
    private func dismissKeynoteWeLaunched() async {
        let hasOpenDocuments =
            (try? await statusService.currentStatus())?.hasOpenDocuments ?? false
        guard !hasOpenDocuments else {
            return
        }
        runningKeynoteApplication()?.terminate()
    }

    @MainActor
    private func runningKeynoteApplication() -> NSRunningApplication? {
        guard let bundleIdentifier = appResolver.resolvedRunningBundleIdentifier() else {
            return nil
        }
        return NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first
    }
}
