//
//  KeynoteSlideshowStopService.swift
//  KeynoteCompanionMacos
//

import Foundation

protocol KeynoteSlideshowStopping: Sendable {
    func stopSlideshow() async
}

struct KeynoteSlideshowStopService: KeynoteSlideshowStopping {
    private let bundleIdentifiers = [
        "com.apple.Keynote",
        "com.apple.iWork.Keynote"
    ]

    func stopSlideshow() async {
        for bundleID in bundleIdentifiers {
            let source = """
            tell application id "\(bundleID)"
                try
                    tell front document
                        stop slideshow
                    end tell
                on error
                    try
                        tell document 1
                            stop slideshow
                        end tell
                    end try
                end try
            end tell
            """
            guard let script = NSAppleScript(source: source) else { continue }
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if error == nil { return }
        }
    }
}
