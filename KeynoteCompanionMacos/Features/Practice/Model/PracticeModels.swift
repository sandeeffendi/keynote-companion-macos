//
//  PracticeModels.swift
//  KeynoteCompanionMacos
//

import Foundation

/// A contiguous span during which one slide was on screen, in media seconds.
/// Intervals tile the whole session: [0,t1) [t1,t2) … [tn,duration].
/// A slide visited more than once produces multiple intervals with the same
/// `slideNumber`; each interval becomes a separate attempt in the recap.
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
        let perSlide = perSlideWithAttempts()

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
            sesTitle: derivedSessionTitle(),
            sesKeynote: keynoteFileName,
            durationSeconds: duration,
            feedback: [feedback],
            audioFileURL: audioFileURL?.absoluteString,
            createdAt: now
        )
    }

    /// Derives a display title from the Keynote filename, stripping the extension
    /// and truncating to 30 characters so long filenames don't overflow the UI.
    private func derivedSessionTitle() -> String {
        guard !keynoteFileName.isEmpty else { return "Practice Recording" }
        let parts = keynoteFileName.components(separatedBy: ".")
        let nameWithoutExt = parts.count > 1 ? parts.dropLast().joined(separator: ".") : keynoteFileName
        let display = nameWithoutExt.isEmpty ? keynoteFileName : nameWithoutExt
        return display.count > 30 ? String(display.prefix(30)) + "…" : display
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

    /// Per-slide WPM with per-attempt breakdown: each interval for a given slide
    /// becomes a separate `SlideAttempt`. The `Slide.value` is the merged WPM
    /// (Σwords / Σdurations × 60) for display in summary cards. Ordered by first
    /// appearance, matching `mergedPerSlide()`.
    private func perSlideWithAttempts() -> [Slide] {
        var order: [Int] = []
        var groups: [Int: [(interval: PracticeSlideInterval, originalIndex: Int)]] = [:]

        for (idx, interval) in slideIntervals.enumerated() {
            if groups[interval.slideNumber] == nil {
                order.append(interval.slideNumber)
                groups[interval.slideNumber] = []
            }
            groups[interval.slideNumber]!.append((interval, idx))
        }

        return order.compactMap { slideNumber -> Slide? in
            guard let entries = groups[slideNumber], !entries.isEmpty else { return nil }

            var attempts: [SlideAttempt] = []
            var totalWords = 0
            var totalDuration: TimeInterval = 0

            for (attemptIdx, entry) in entries.enumerated() {
                let interval = entry.interval
                // Last interval overall uses inclusive upper bound (same rule as mergedPerSlide).
                let isLastOverall = entry.originalIndex == slideIntervals.count - 1
                let words = wordTimestamps.reduce(into: 0) { count, t in
                    let inUpper = isLastOverall ? (t <= interval.end) : (t < interval.end)
                    if t >= interval.start && inUpper { count += 1 }
                }
                let span = max(0, interval.end - interval.start)
                let wpm = span > 0 ? Int((Double(words) / span) * 60) : 0

                attempts.append(SlideAttempt(
                    attemptNo: attemptIdx + 1,
                    wpm: wpm,
                    startTimestamp: interval.start
                ))
                totalWords += words
                totalDuration += span
            }

            let mergedWPM = totalDuration > 0 ? Int((Double(totalWords) / totalDuration) * 60) : 0
            return Slide(
                no: slideNumber,
                value: mergedWPM,
                timestamp: entries[0].interval.start,
                attempts: attempts
            )
        }
    }

    /// Per-slide WPM with per-attempt breakdown: each interval for a given slide
    /// becomes a separate `SlideAttempt`. The `Slide.value` is the merged WPM
    /// (Σwords / Σdurations × 60) for display in summary cards. Ordered by first
    /// appearance, matching `mergedPerSlide()`.
    private func perSlideWithAttempts() -> [Slide] {
        var order: [Int] = []
        var groups: [Int: [(interval: PracticeSlideInterval, originalIndex: Int)]] = [:]

        for (idx, interval) in slideIntervals.enumerated() {
            if groups[interval.slideNumber] == nil {
                order.append(interval.slideNumber)
                groups[interval.slideNumber] = []
            }
            groups[interval.slideNumber]!.append((interval, idx))
        }

        return order.compactMap { slideNumber -> Slide? in
            guard let entries = groups[slideNumber], !entries.isEmpty else { return nil }

            var attempts: [SlideAttempt] = []
            var totalWords = 0
            var totalDuration: TimeInterval = 0

            for (attemptIdx, entry) in entries.enumerated() {
                let interval = entry.interval
                // Last interval overall uses inclusive upper bound (same rule as mergedPerSlide).
                let isLastOverall = entry.originalIndex == slideIntervals.count - 1
                let words = wordTimestamps.reduce(into: 0) { count, t in
                    let inUpper = isLastOverall ? (t <= interval.end) : (t < interval.end)
                    if t >= interval.start && inUpper { count += 1 }
                }
                let span = max(0, interval.end - interval.start)
                let wpm = span > 0 ? Int((Double(words) / span) * 60) : 0

                attempts.append(SlideAttempt(
                    attemptNo: attemptIdx + 1,
                    wpm: wpm,
                    startTimestamp: interval.start
                ))
                totalWords += words
                totalDuration += span
            }

            let mergedWPM = totalDuration > 0 ? Int((Double(totalWords) / totalDuration) * 60) : 0
            return Slide(
                no: slideNumber,
                value: mergedWPM,
                timestamp: entries[0].interval.start,
                attempts: attempts
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
