//
//  PracticeModels.swift
//  KeynoteCompanionMacos
//

import Foundation

/// A contiguous span during which one slide was on screen, in media seconds.
/// Intervals tile the whole session: [0,t1) [t1,t2) … [tn,duration].
/// A slide visited more than once produces multiple intervals with the same
/// `slideNumber`; recap merges them per slide number.
struct PracticeSlideInterval: Sendable {
    let slideNumber: Int
    let start: TimeInterval
    var end: TimeInterval
}

struct PracticeResult: Sendable {
    /// Full, sorted word-event timestamps (media seconds) — the single source of
    /// truth for both the live indicator and the recap. Never pruned.
    let wordTimestamps: [TimeInterval]
    let slideIntervals: [PracticeSlideInterval]
    let duration: TimeInterval
    let audioFileURL: URL?
    let keynoteFileName: String

    var finalWordCount: Int { wordTimestamps.count }

    func toRecapModel() -> HistoryModel {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: now)

        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: now)

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationStr = String(format: "%02d:%02d", minutes, seconds)

        let perSlide = mergedPerSlide()

        let overallWPM: Int = {
            guard duration > 0 else { return 0 }
            return Int((Double(wordTimestamps.count) / duration) * 60)
        }()

        let wpmTip = overallWPM > 120
            ? "Your overall pace was a bit fast. Try slowing down for clearer delivery."
            : overallWPM < 90
            ? "Your overall pace was slow. Try maintaining a steady rhythm."
            : "Great job! Your speaking pace was in the ideal range."

        let feedback = Feedback(
            category: "WPM",
            overall: overallWPM,
            unit: "WPM",
            tips: wpmTip,
            perSlide: perSlide
        )

        return HistoryModel(
            title: "Practice Recording",
            keynote: keynoteFileName,
            date: dateStr,
            time: timeStr,
            duration: durationStr,
            feedback: [feedback]
        )
    }

    /// Per-slide WPM, merging revisited slides within this session: words and
    /// durations accumulate across every interval that shares a slide number, and
    /// WPM = Σwords / Σdurations × 60 (gross). Ordered by first appearance.
    private func mergedPerSlide() -> [Slide] {
        var totals: [Int: (words: Int, duration: TimeInterval, firstStart: TimeInterval)] = [:]
        var order: [Int] = []

        for (index, interval) in slideIntervals.enumerated() {
            // Intervals are half-open [start, end) so a word on a boundary lands in
            // the next slide — except the final interval, whose end is the session
            // duration: close it inclusively so a word at exactly `duration` is not
            // dropped (which would make Σ per-slide words < total words).
            let isLast = index == slideIntervals.count - 1
            let words = wordTimestamps.reduce(into: 0) { count, t in
                let withinUpper = isLast ? (t <= interval.end) : (t < interval.end)
                if t >= interval.start && withinUpper { count += 1 }
            }
            let span = max(0, interval.end - interval.start)

            if let existing = totals[interval.slideNumber] {
                totals[interval.slideNumber] = (
                    existing.words + words,
                    existing.duration + span,
                    existing.firstStart
                )
            } else {
                totals[interval.slideNumber] = (words, span, interval.start)
                order.append(interval.slideNumber)
            }
        }

        return order.map { slideNumber in
            let total = totals[slideNumber]!
            let wpm = total.duration > 0
                ? Int((Double(total.words) / total.duration) * 60)
                : 0
            return Slide(
                page: slideNumber,
                attempt: [Attempt(no: 1, value: String(wpm), timestamp: total.firstStart)]
            )
        }
    }
}

enum PracticeSessionState: Sendable {
    case idle
    case recording
    case paused
    case finishing
    case finished(PracticeResult)
    case failed(String)
    case speechUnavailable
}

/// One place to tune the live WPM behavior. Live and recap read these so the
/// numbers stay consistent and are easy to adjust after real-session testing.
enum PracticeTuning {
    /// Live sliding-window length (seconds). Shorter = more responsive / snappier.
    static let windowSeconds: TimeInterval = 10
    /// EMA smoothing factor for the live indicator (0 disables smoothing). Higher =
    /// rises faster / tracks pace changes quicker, slightly less smooth.
    static let emaAlpha: Double = 0.45
    /// How often the live indicator recomputes against "now".
    static let liveRefreshInterval: Duration = .milliseconds(500)
    /// Ideal speaking-pace band (gross WPM).
    static let wpmLowerBand = 90
    static let wpmUpperBand = 120
    /// Extra WPM beyond a band edge required before the status switches — prevents
    /// the more volatile instantaneous metric from flickering the indicator color.
    static let statusHysteresis = 5

    // MARK: Recognition supervisor

    /// Minimum gap between consecutive recognition re-arms — a rate limit that stops
    /// a rapidly-finalizing recognizer from spinning, without delaying a normal
    /// rotation enough to drop audible words.
    static let recognitionMinRestartIntervalNanos: UInt64 = 120_000_000
    /// First back-off after a failed arm / error end; doubles up to the cap.
    static let recognitionErrorBackoffBaseNanos: UInt64 = 400_000_000
    static let recognitionErrorBackoffCapNanos: UInt64 = 3_000_000_000
    /// How often the liveness watchdog checks for a stalled recognition task.
    static let recognitionWatchdogPollNanos: UInt64 = 1_000_000_000
    /// Media seconds with neither a word nor a task-end before the watchdog rotates
    /// the recognition task. Must exceed the recognizer's natural silence-final delay
    /// so legitimate silence (which ends the task normally) doesn't trip it.
    static let recognitionStallSeconds: TimeInterval = 6
}

/// Health of the live speech-recognition stream, surfaced so the UI can show a
/// "reconnecting" affordance instead of a misleading 0 while recognition is down.
enum RecognitionHealth: Sendable {
    /// A recognition task is armed and the stream is flowing (the user may be silent).
    case live
    /// The supervisor is actively re-arming after a failed start or an error end.
    case reconnecting
}

enum WPMStatus: Sendable {
    case tooSlow   // below the ideal band
    case good      // inside the ideal band
    case tooFast   // above the ideal band

    /// Hysteresis transition: only leave the current band once WPM crosses its edge
    /// by `statusHysteresis`, so the live color doesn't chatter at the boundary.
    func next(for wpm: Int) -> WPMStatus {
        let lower = PracticeTuning.wpmLowerBand
        let upper = PracticeTuning.wpmUpperBand
        let margin = PracticeTuning.statusHysteresis
        switch self {
        case .good:
            if wpm > upper + margin { return .tooFast }
            if wpm < lower - margin { return .tooSlow }
            return .good
        case .tooFast:
            if wpm < lower - margin { return .tooSlow }
            if wpm < upper - margin { return .good }
            return .tooFast
        case .tooSlow:
            if wpm > upper + margin { return .tooFast }
            if wpm > lower + margin { return .good }
            return .tooSlow
        }
    }
}
