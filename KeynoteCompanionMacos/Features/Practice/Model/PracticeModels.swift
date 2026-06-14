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

    func toRecapModel() -> RecapModel {
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

        let wpmSubTitle = overallWPM > 120
            ? "Your average pace was too fast"
            : overallWPM < 90
            ? "Your average pace was too slow"
            : "Your average pace was ideal"

        let feedback = Feedback(
            title: "Speaking Pace",
            overall: overallWPM,
            unit: "WPM",
            tips: wpmTip,
            subTitle: wpmSubTitle,
            category: "WPM",
            perSlide: perSlide
        )

        return RecapModel(
            sesTitle: "Practice Recording",
            sesKeynote: keynoteFileName,
            date: dateStr,
            time: timeStr,
            duration: durationStr,
            feedback: [feedback],
            audioFileURL: audioFileURL?.absoluteString
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
            return Slide(no: slideNumber, value: wpm, timestamp: total.firstStart)
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
    /// Live sliding-window length (seconds).
    static let windowSeconds: TimeInterval = 15
    /// EMA smoothing factor for the live indicator (0 disables smoothing).
    static let emaAlpha: Double = 0.3
    /// How often the live indicator recomputes against "now".
    static let liveRefreshInterval: Duration = .milliseconds(500)
    /// Ideal speaking-pace band (gross WPM).
    static let wpmLowerBand = 90
    static let wpmUpperBand = 120
    /// Extra WPM beyond a band edge required before the status switches — prevents
    /// the more volatile instantaneous metric from flickering the indicator color.
    static let statusHysteresis = 5
    /// Minimum delay before re-arming recognition after a normal (final) end — a
    /// floor that stops a rapidly-finalizing recognizer from spinning in a loop.
    static let recognitionRestartDelayNanos: UInt64 = 150_000_000
    /// Longer back-off when recognition ended with an error.
    static let recognitionErrorBackoffNanos: UInt64 = 500_000_000
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
