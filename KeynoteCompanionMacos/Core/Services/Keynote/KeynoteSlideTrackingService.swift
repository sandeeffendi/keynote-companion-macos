//
//  KeynoteSlideTrackingService.swift
//  KeynoteCompanionMacos
//

import AppKit
import Foundation

protocol KeynoteSlideTracking: Sendable {
    func currentSlideNumber() async throws -> Int
}

actor KeynoteSlideTrackingService: KeynoteSlideTracking {
    private let appResolver: KeynoteAppResolving

    convenience init() {
        self.init(appResolver: KeynoteAppResolver())
    }

    init(appResolver: KeynoteAppResolving) {
        self.appResolver = appResolver
    }

    func currentSlideNumber() async throws -> Int {
        guard await appResolver.resolve() != nil else {
            throw KeynoteStatusError.keynoteUnavailable
        }

        guard let bundleIdentifier = await appResolver.resolvedRunningBundleIdentifier() else {
            throw KeynoteStatusError.appleScriptFailed("Keynote is not running")
        }

        return try runSlideNumberScript(bundleIdentifier: bundleIdentifier)
    }

    private func runSlideNumberScript(bundleIdentifier: String) throws -> Int {
        let source = """
        tell application id "\(bundleIdentifier)"
            set slideNum to 0
            try
                set slideNum to slide number of current slide of front document
            on error
                try
                    set slideNum to slide number of current slide of document 1
                end try
            end try
            return slideNum
        end tell
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

        let slideNumber = Int(result.int32Value)
        guard slideNumber > 0 else {
            throw KeynoteStatusError.invalidAppleScriptResult
        }

        return slideNumber
    }
}
