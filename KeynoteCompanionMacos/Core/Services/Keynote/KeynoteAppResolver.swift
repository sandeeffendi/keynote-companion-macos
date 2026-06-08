//
//  KeynoteAppResolver.swift
//  KeynoteCompanionMacos
//

import AppKit
import Foundation

struct KeynoteAppIdentity: Equatable, Sendable {
    let bundleIdentifier: String
    let applicationURL: URL
}

@MainActor
protocol KeynoteAppResolving: Sendable {
    func resolve() -> KeynoteAppIdentity?
    func resolvedRunningBundleIdentifier() -> String?
}

@MainActor
struct KeynoteAppResolver: KeynoteAppResolving {
    private let bundleIdentifiers = [
        "com.apple.Keynote",
        "com.apple.iWork.Keynote"
    ]

    func resolve() -> KeynoteAppIdentity? {
        for bundleIdentifier in bundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
            ) {
                return KeynoteAppIdentity(
                    bundleIdentifier: bundleIdentifier,
                    applicationURL: url
                )
            }
        }

        return nil
    }

    func resolvedRunningBundleIdentifier() -> String? {
        for bundleIdentifier in bundleIdentifiers {
            if !NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ).isEmpty {
                return bundleIdentifier
            }
        }

        return nil
    }
}
