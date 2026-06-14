//
//  WPMCalculator.swift
//  KeynoteCompanionMacos
//

import Foundation

/// Pure live-WPM math: a sliding window over word-event timestamps plus optional
/// EMA smoothing. It owns NO word history — the coordinator owns the single
/// source-of-truth history (also consumed by recap) and passes it in on each
/// `recompute`. The only state here is the smoothed value carried between ticks.
///
/// All times are in **media seconds since session start** (origin 0, paused time
/// excluded). The metric is **gross** WPM: words divided by wall-clock span, so
/// silence naturally pulls the value toward zero as old words leave the window.
struct WPMCalculator: Sendable {
    /// Sliding window length, in seconds.
    let window: TimeInterval
    /// EMA factor in [0, 1]. `0` disables smoothing (raw passthrough); higher is
    /// more responsive / less smooth.
    let smoothingFactor: Double

    /// Last smoothed WPM, carried across `recompute` calls.
    private(set) var smoothedWPM: Double = 0

    nonisolated init(window: TimeInterval = 15, smoothingFactor: Double = 0.3) {
        self.window = window
        self.smoothingFactor = smoothingFactor
    }

    /// Recompute the live WPM against `now`, counting `timestamps` that fall in
    /// the window `(now - window, now]`. During the first `window` seconds the
    /// denominator is the elapsed time (`min(window, now)`) so the value is not
    /// under-reported before the window has had time to fill.
    ///
    /// - Parameters:
    ///   - timestamps: word-event times (media seconds), assumed non-decreasing.
    ///   - now: current media time (seconds since session start).
    /// - Returns: the smoothed WPM.
    mutating func recompute(timestamps: [TimeInterval], now: TimeInterval) -> Double {
        let denominator = min(window, now)
        let raw: Double
        if denominator > 0 {
            let cutoff = now - window
            let count = timestamps.reduce(into: 0) { partial, t in
                if t > cutoff && t <= now { partial += 1 }
            }
            raw = Double(count) / denominator * 60
        } else {
            raw = 0
        }

        if smoothingFactor <= 0 {
            smoothedWPM = raw
        } else {
            smoothedWPM = smoothingFactor * raw + (1 - smoothingFactor) * smoothedWPM
        }
        return smoothedWPM
    }

    /// Clears the smoothed value. Call when starting a fresh session.
    mutating func reset() {
        smoothedWPM = 0
    }
}
