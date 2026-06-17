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
    let date: String
    let time: String
    let duration: String
    let feedback: [Feedback]
    let audioFileURL: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sesTitle: String,
        sesKeynote: String,
        date: String,
        time: String,
        duration: String,
        feedback: [Feedback],
        audioFileURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.date = date
        self.time = time
        self.duration = duration
        self.feedback = feedback
        self.audioFileURL = audioFileURL
        self.createdAt = createdAt
    }

    static func placeholder() -> RecapModel {
        RecapModel(
            sesTitle: "Practice Recording",
            sesKeynote: "",
            date: "",
            time: "",
            duration: "00:00",
            feedback: []
        )
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: RecapModel, rhs: RecapModel) -> Bool { lhs.id == rhs.id }
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
