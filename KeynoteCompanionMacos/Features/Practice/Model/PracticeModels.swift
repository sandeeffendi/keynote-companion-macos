//
//  PracticeModels.swift
//  KeynoteCompanionMacos
//

import Foundation

struct PracticeSlideSnapshot: Sendable {
    let slideNumber: Int
    let wordCountAtStart: Int
    let timestampAtStart: TimeInterval
}

struct PracticeResult: Sendable {
    let slideSnapshots: [PracticeSlideSnapshot]
    let finalWordCount: Int
    let duration: TimeInterval
    let audioFileURL: URL?
    let keynoteFileName: String

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

        let perSlide: [Slide] = slideSnapshots.enumerated().map { index, snapshot in
            let nextStart = index + 1 < slideSnapshots.count
                ? slideSnapshots[index + 1].wordCountAtStart
                : finalWordCount
            let wordsOnSlide = max(0, nextStart - snapshot.wordCountAtStart)
            let nextTimestamp = index + 1 < slideSnapshots.count
                ? slideSnapshots[index + 1].timestampAtStart
                : duration
            let slideDuration = max(1, nextTimestamp - snapshot.timestampAtStart)
            let wpm = Int((Double(wordsOnSlide) / slideDuration) * 60)

            return Slide(
                no: snapshot.slideNumber,
                value: wpm,
                timestamp: snapshot.timestampAtStart
            )
        }

        let overallWPM: Int = {
            guard duration > 0 else { return 0 }
            return Int((Double(finalWordCount) / duration) * 60)
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

enum WPMStatus: Sendable {
    case tooSlow   // < 90 WPM
    case good      // 90–120 WPM
    case tooFast   // > 120 WPM

    init(wpm: Int) {
        if wpm < 90 {
            self = .tooSlow
        } else if wpm > 120 {
            self = .tooFast
        } else {
            self = .good
        }
    }
}
