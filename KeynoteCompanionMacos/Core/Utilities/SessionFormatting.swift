//
//  SessionFormatting.swift
//  KeynoteCompanionMacos
//
//  Single source of truth for how a practice session's timestamp and length are
//  rendered for display. Sessions store only `createdAt: Date` and
//  `durationSeconds: TimeInterval`; every human-readable date/time/duration string
//  is derived here so Recap, History, and the live Practice timer stay consistent.
//

import Foundation

enum SessionFormatting {

    /// Full weekday + date, e.g. "Monday, 17 August 2026". Used as the History
    /// section grouping key and the Recap metadata date.
    static func sessionDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// 24-hour wall-clock time, e.g. "10:00".
    static func sessionTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Zero-padded session length, e.g. "05:00". Used for the stored session
    /// duration shown in Recap metadata and the live Practice elapsed timer.
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Compact playback clock without a leading-zero minute, e.g. "5:03". Used by
    /// the Recap audio player's current/total time readout.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Cached formatters

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
