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
        mediaTime(forWall: wallNow())
    }

    /// Convert an arbitrary wall timestamp (same source domain as `wallNow`) into media
    /// seconds, excluding paused spans — so a sample captured on the audio thread can be
    /// placed on the media timeline instead of being stamped at actor-processing time.
    /// A timestamp from before the in-progress pause began is not reduced by it (the
    /// inner `max(0, …)`), and the result is clamped at 0.
    func mediaTime(forWall wall: TimeInterval) -> TimeInterval {
        guard let start = startWall else { return 0 }
        let inProgressPause = pauseBeganWall.map { max(0, wall - $0) } ?? 0
        return max(0, (wall - start) - accumulatedPause - inProgressPause)
    }
}
