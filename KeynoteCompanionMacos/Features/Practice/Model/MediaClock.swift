//
//  MediaClock.swift
//  KeynoteCompanionMacos
//

import Foundation

/// A monotonic session clock that EXCLUDES paused time. It is the single source
/// of "now" for the whole Practice pipeline — word-event timestamps, slide
/// interval bounds, the live sliding window, and the recap duration all read it,
/// so a pause is invisible to the timeline (no decay during pause, no dead-zone
/// after resume).
///
/// `now()` returns media seconds since `start()`. While paused, `now()` is frozen
/// because the in-progress pause duration is subtracted as it grows.
///
/// The underlying wall source is injectable so tests can drive time deterministically.
struct MediaClock: Sendable {
    private let wallNow: @Sendable () -> TimeInterval
    private var startWall: TimeInterval?
    private var accumulatedPause: TimeInterval = 0
    private var pauseBeganWall: TimeInterval?

    nonisolated init(wallNow: @Sendable @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.wallNow = wallNow
    }

    var isRunning: Bool { startWall != nil }
    var isPaused: Bool { pauseBeganWall != nil }

    mutating func start() {
        startWall = wallNow()
        accumulatedPause = 0
        pauseBeganWall = nil
    }

    mutating func pause() {
        guard startWall != nil, pauseBeganWall == nil else { return }
        pauseBeganWall = wallNow()
    }

    mutating func resume() {
        guard let began = pauseBeganWall else { return }
        accumulatedPause += wallNow() - began
        pauseBeganWall = nil
    }

    func now() -> TimeInterval {
        guard let start = startWall else { return 0 }
        let inProgressPause = pauseBeganWall.map { wallNow() - $0 } ?? 0
        return max(0, (wallNow() - start) - accumulatedPause - inProgressPause)
    }
}
