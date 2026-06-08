//
//  KeynoteFileOpener.swift
//  KeynoteCompanionMacos
//

import AppKit
import Foundation
import UniformTypeIdentifiers

enum KeynoteFileOpenError: LocalizedError, Sendable {
    case keynoteUnavailable
    case openFailed

    var errorDescription: String? {
        switch self {
        case .keynoteUnavailable:
            return "Keynote is not installed on this Mac."
        case .openFailed:
            return "The selected Keynote file could not be opened."
        }
    }
}

protocol KeynoteFileOpening: Sendable {
    func openKeynoteFile() async throws -> Bool
}

struct KeynoteFileOpener: KeynoteFileOpening {
    private let appResolver: KeynoteAppResolving

    init(appResolver: KeynoteAppResolving) {
        self.appResolver = appResolver
    }

    @MainActor
    func openKeynoteFile() async throws -> Bool {
        guard let app = appResolver.resolve() else {
            throw KeynoteFileOpenError.keynoteUnavailable
        }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "key") ?? .data]
        panel.title = "Open Keynote File"
        panel.prompt = "Open"

        let response = await panel.begin()
        guard response == .OK, let fileURL = panel.url else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        let opened = await withCheckedContinuation { continuation in
            NSWorkspace.shared.open(
                [fileURL],
                withApplicationAt: app.applicationURL,
                configuration: configuration
            ) { _, error in
                continuation.resume(returning: error == nil)
            }
        }

        if opened {
            return true
        }

        throw KeynoteFileOpenError.openFailed
    }
}
