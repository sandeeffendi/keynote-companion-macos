//
//  KeynoteAutomationStatusStore.swift
//  KeynoteCompanionMacos
//
//  Caches the last *determinable* Keynote automation (Apple Events) authorization so the
//  app can still gate correctly while Keynote is closed — when the system can't report a
//  status. The cache is kept in sync with System Settings: every time the status IS
//  readable (Keynote running) the caller writes the real value here, so revocations and
//  grants both propagate on the next determinable read.
//

import Foundation

protocol KeynoteAutomationStatusStoring: Sendable {
    var lastKnownStatus: PermissionStatus { get }
    func update(_ status: PermissionStatus)
}

// `UserDefaults` is documented thread-safe; the `@unchecked` conformance reflects that.
struct UserDefaultsKeynoteAutomationStatusStore: KeynoteAutomationStatusStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "keynote.automation.lastKnownStatus"
    ) {
        self.defaults = defaults
        self.key = key
    }

    var lastKnownStatus: PermissionStatus {
        switch defaults.string(forKey: key) {
        case "authorized":
            return .authorized
        case "denied":
            return .denied
        default:
            return .notDetermined
        }
    }

    func update(_ status: PermissionStatus) {
        let raw: String
        switch status {
        case .authorized:
            raw = "authorized"
        case .denied:
            raw = "denied"
        case .notDetermined:
            raw = "notDetermined"
        }
        defaults.set(raw, forKey: key)
    }
}
