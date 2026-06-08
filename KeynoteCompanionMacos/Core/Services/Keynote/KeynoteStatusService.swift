//
//  KeynoteStatusService.swift
//  KeynoteCompanionMacos
//

import AppKit
import Foundation

struct KeynoteRuntimeStatus: Equatable, Sendable {
    let hasOpenDocuments: Bool
    let isPlaying: Bool
}

enum KeynoteStatusError: LocalizedError, Sendable {
    case keynoteUnavailable
    case appleScriptFailed(String)
    case invalidAppleScriptResult

    var errorDescription: String? {
        switch self {
        case .keynoteUnavailable:
            return "Keynote is not installed on this Mac."
        case .appleScriptFailed(let message):
            return "Keynote automation failed: \(message)"
        case .invalidAppleScriptResult:
            return "Keynote returned an unexpected automation response."
        }
    }
}

protocol KeynoteStatusChecking: Sendable {
    func currentStatus() async throws -> KeynoteRuntimeStatus
}

actor KeynoteStatusService: KeynoteStatusChecking {
    private let appResolver: KeynoteAppResolving

    init(appResolver: KeynoteAppResolving) {
        self.appResolver = appResolver
    }

    func currentStatus() async throws -> KeynoteRuntimeStatus {
        guard await appResolver.resolve() != nil else {
            throw KeynoteStatusError.keynoteUnavailable
        }

        guard let bundleIdentifier = await appResolver.resolvedRunningBundleIdentifier() else {
            return KeynoteRuntimeStatus(hasOpenDocuments: false, isPlaying: false)
        }

        return try runStatusScript(bundleIdentifier: bundleIdentifier)
    }

    private func runStatusScript(
        bundleIdentifier: String
    ) throws -> KeynoteRuntimeStatus {
        let source = """
        tell application id "\(bundleIdentifier)"
            set documentCount to count of documents
            set slideshowPlaying to playing
        end tell
        return {documentCount, slideshowPlaying}
        """

        guard let script = NSAppleScript(source: source) else {
            throw KeynoteStatusError.invalidAppleScriptResult
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        if let error {
            let message = error[NSAppleScript.errorMessage] as? String
                ?? "Unknown AppleScript error"
            throw KeynoteStatusError.appleScriptFailed(message)
        }

        guard let countDescriptor = result.atIndex(1),
              let playingDescriptor = result.atIndex(2) else {
            throw KeynoteStatusError.invalidAppleScriptResult
        }

        return KeynoteRuntimeStatus(
            hasOpenDocuments: countDescriptor.int32Value > 0,
            isPlaying: playingDescriptor.booleanValue
        )
    }
}
