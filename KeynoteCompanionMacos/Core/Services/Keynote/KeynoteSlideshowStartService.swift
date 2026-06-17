//
//  KeynoteSlideshowStartService.swift
//  KeynoteCompanionMacos
//

import Foundation

protocol KeynoteSlideshowStarting: Sendable {
    func startSlideshow() async throws
}

/// Starts the front Keynote document's slideshow from the first slide via AppleScript.
/// Keynote's `start slideshow` plays from the currently-selected slide, so we first set
/// `current slide` to slide 1 to force a from-the-top run. Mirrors the throwing actor +
/// `appResolver` pattern of `KeynoteSlideTrackingService` so failures surface as
/// `KeynoteStatusError` and the Home flow can show them to the user; uses the
/// `front document` → `document 1` fallback convention (`stop slideshow` sibling).
actor KeynoteSlideshowStartService: KeynoteSlideshowStarting {
    private let appResolver: KeynoteAppResolving

    convenience init() {
        self.init(appResolver: KeynoteAppResolver())
    }

    init(appResolver: KeynoteAppResolving) {
        self.appResolver = appResolver
    }

    func startSlideshow() async throws {
        guard await appResolver.resolve() != nil else {
            throw KeynoteStatusError.keynoteUnavailable
        }

        guard let bundleIdentifier = await appResolver.resolvedRunningBundleIdentifier() else {
            throw KeynoteStatusError.appleScriptFailed("Keynote is not running")
        }

        try runStartScript(bundleIdentifier: bundleIdentifier)
    }

    private func runStartScript(bundleIdentifier: String) throws {
        let source = """
        tell application id "\(bundleIdentifier)"
            try
                tell front document
                    set current slide to slide 1
                    start slideshow
                end tell
            on error
                try
                    tell document 1
                        set current slide to slide 1
                        start slideshow
                    end tell
                end try
            end try
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            throw KeynoteStatusError.invalidAppleScriptResult
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)

        if let error {
            let message = error[NSAppleScript.errorMessage] as? String
                ?? "Unknown AppleScript error"
            throw KeynoteStatusError.appleScriptFailed(message)
        }
    }
}
