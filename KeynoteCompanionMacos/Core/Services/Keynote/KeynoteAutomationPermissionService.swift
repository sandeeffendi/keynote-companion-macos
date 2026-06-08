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

    init(appResolver: KeynoteAppResolving) {
        self.appResolver = appResolver
    }

    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        guard let app = appResolver.resolve() else {
            return .keynoteUnavailable
        }

        if promptIfNeeded {
            let isRunning = await launchKeynoteIfNeeded(app)
            guard isRunning else {
                return .targetNotRunning
            }
        } else if appResolver.resolvedRunningBundleIdentifier() == nil {
            return .targetNotRunning
        }

        return await Task.detached(priority: .userInitiated) {
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
}
