//
//  RecapModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation

struct RecapModel: Hashable {
    let id: UUID
    let sesTitle: String
    let sesKeynote: String
    /// Session length in seconds; the displayed duration string is derived via
    /// `SessionFormatting`. Date/time are likewise derived from `createdAt`.
    let durationSeconds: TimeInterval
    let feedback: [Feedback]
    let audioFileURL: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sesTitle: String,
        sesKeynote: String,
        durationSeconds: TimeInterval,
        feedback: [Feedback],
        audioFileURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.durationSeconds = durationSeconds
        self.feedback = feedback
        self.audioFileURL = audioFileURL
        self.createdAt = createdAt
    }

    static func placeholder() -> RecapModel {
        RecapModel(
            sesTitle: "Practice Recording",
            sesKeynote: "",
            durationSeconds: 0,
            feedback: []
        )
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: RecapModel, rhs: RecapModel) -> Bool { lhs.id == rhs.id }
}

#if DEBUG
extension RecapModel {
    /// Rich sample used only by SwiftUI previews — never shipped in a release path.
    static let preview = RecapModel(
        sesTitle: "Practice Recording 1",
        sesKeynote: "HIG Reading Materials",
        durationSeconds: 300,
        feedback: [
            Feedback(
                title: "Speaking Pace",
                overall: 152,
                unit: "WPM",
                tips: "On slide 5, your speaking pace was quite fast. Try slowing down.",
                subTitle: "Your average pace is slightly fast",
                category: "WPM",
                perSlide: [
                    Slide(no: 1, value: 120, timestamp: 0),
                    Slide(no: 2, value: 145, timestamp: 63.0),
                    Slide(no: 3, value: 100, timestamp: 130.5)
                ]
            )
        ]
    )
}
#endif

struct Feedback: Hashable {
    let title: String
    let overall: Int
    let unit: String
    let tips: String
    let subTitle: String
    let category: String
    let perSlide: [Slide]
}

/// One attempt at a slide — each time a presenter returns to the same slide
/// during a Keynote session, a new attempt is recorded with its own WPM.
struct SlideAttempt: Codable, Hashable, Sendable {
    let attemptNo: Int
    let wpm: Int
    let startTimestamp: TimeInterval
}

struct Slide: Codable, Hashable, Sendable {
    let no: Int
    let value: Int              // merged WPM across all attempts
    let timestamp: TimeInterval // first visit start, used for audio seek
    let attempts: [SlideAttempt]

    init(no: Int, value: Int, timestamp: TimeInterval, attempts: [SlideAttempt] = []) {
        self.no = no
        self.value = value
        self.timestamp = timestamp
        self.attempts = attempts
    }

    // Backward-compat decoder: old JSON has no "attempts" key → decode as []
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        no        = try c.decode(Int.self,               forKey: .no)
        value     = try c.decode(Int.self,               forKey: .value)
        timestamp = try c.decode(TimeInterval.self,      forKey: .timestamp)
        attempts  = (try? c.decode([SlideAttempt].self,  forKey: .attempts)) ?? []
    }
}

struct Feedback: Hashable {
    let title: String
    let overall: Int
    let unit: String
    let tips: String
    let subTitle: String
    let category: String
    let perSlide: [Slide]
}

struct Slide: Codable, Hashable {
    let no: Int
    let value: Int
    let timestamp: TimeInterval
}



