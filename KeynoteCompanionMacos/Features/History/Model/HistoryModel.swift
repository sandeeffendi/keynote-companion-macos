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
    var date: String
    var time: String
    var duration: String
    var audioFileURL: String?

    @Relationship(deleteRule: .cascade)
    var feedbacks: [HistoryFeedback]

    init(
        sesTitle: String,
        sesKeynote: String,
        date: String,
        time: String,
        duration: String,
        feedbacks: [HistoryFeedback] = [],
        audioFileURL: String? = nil
    ) {
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.date = date
        self.time = time
        self.duration = duration
        self.feedbacks = feedbacks
        self.audioFileURL = audioFileURL
    }

    func toRecapModel() -> RecapModel {
        RecapModel(
            sesTitle: sesTitle,
            sesKeynote: sesKeynote,
            date: date,
            time: time,
            duration: duration,
            feedback: feedbacks.map { $0.toFeedback() },
            audioFileURL: audioFileURL
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
