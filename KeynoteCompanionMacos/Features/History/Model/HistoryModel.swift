//
//  HistoryModel.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import Foundation
import SwiftData

@Model
class HistoryModel {
    var sesTitle: String
    var sesKeynote: String
    /// Session length in seconds. Display date/time/duration are derived from
    /// `createdAt` + this value via `SessionFormatting` — never stored as strings.
    var durationSeconds: TimeInterval
    var audioFileURL: String?
    /// Chronological sort key; set to session end time when the session is saved.
    var createdAt: Date
    /// Links this record back to the RecapModel.id that created it, enabling
    /// title edits from RecapView to persist.
    var sessionID: UUID?

    @Relationship(deleteRule: .cascade)
    var feedbacks: [HistoryFeedback]

    init(
        sesTitle: String,
        sesKeynote: String,
        durationSeconds: TimeInterval,
        feedbacks: [HistoryFeedback] = [],
        audioFileURL: String? = nil,
        createdAt: Date = Date(),
        sessionID: UUID? = nil
    ) {
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.durationSeconds = durationSeconds
        self.feedbacks = feedbacks
        self.audioFileURL = audioFileURL
        self.createdAt = createdAt
        self.sessionID = sessionID
    }

    /// The single Recap→History mapper; the reverse is `toRecapModel()`. Adding a
    /// field means touching only these two converters, not every call site.
    /// A static factory (not a `convenience init`): SwiftData's `@Model` macro only
    /// wires backing storage through the designated init, so a convenience init traps
    /// on insert.
    static func make(from recap: RecapModel) -> HistoryModel {
        HistoryModel(
            sesTitle: recap.sesTitle,
            sesKeynote: recap.sesKeynote,
            durationSeconds: recap.durationSeconds,
            feedbacks: recap.feedback.map(HistoryFeedback.make(from:)),
            audioFileURL: recap.audioFileURL,
            createdAt: recap.createdAt,
            sessionID: recap.id
        )
    }

    func toRecapModel() -> RecapModel {
        RecapModel(
            id: sessionID ?? UUID(),
            sesTitle: sesTitle,
            sesKeynote: sesKeynote,
            durationSeconds: durationSeconds,
            feedback: feedbacks.map { $0.toFeedback() },
            audioFileURL: audioFileURL,
            createdAt: createdAt
        )
    }
}

@Model
class HistoryFeedback {
    var title: String
    var overall: Int
    var unit: String
    var tips: String
    var subTitle: String
    var category: String
    var perSlideJSON: String

    init(
        title: String,
        overall: Int,
        unit: String,
        tips: String,
        subTitle: String,
        category: String,
        perSlide: [Slide]
    ) {
        self.title = title
        self.overall = overall
        self.unit = unit
        self.tips = tips
        self.subTitle = subTitle
        self.category = category
        self.perSlideJSON = HistoryFeedback.encode(perSlide)
    }

    static func make(from feedback: Feedback) -> HistoryFeedback {
        HistoryFeedback(
            title: feedback.title,
            overall: feedback.overall,
            unit: feedback.unit,
            tips: feedback.tips,
            subTitle: feedback.subTitle,
            category: feedback.category,
            perSlide: feedback.perSlide
        )
    }

    func toFeedback() -> Feedback {
        Feedback(
            title: title,
            overall: overall,
            unit: unit,
            tips: tips,
            subTitle: subTitle,
            category: category,
            perSlide: HistoryFeedback.decode(perSlideJSON)
        )
    }

    private static func encode(_ slides: [Slide]) -> String {
        guard let data = try? JSONEncoder().encode(slides),
              let string = String(data: data, encoding: .utf8)
        else { return "[]" }
        return string
    }

    private static func decode(_ json: String) -> [Slide] {
        guard let data = json.data(using: .utf8),
              let slides = try? JSONDecoder().decode([Slide].self, from: data)
        else { return [] }
        return slides
    }
}
