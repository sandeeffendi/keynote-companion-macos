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
    var title: String
    var keynote: String
    var date: String
    var time: String
    var duration: String
    
    @Relationship(deleteRule: .cascade)
    var feedback: [Feedback]
    
    init(title: String, keynote: String, date: String, time: String, duration: String, feedback: [Feedback]) {
        self.title = title
        self.keynote = keynote
        self.date = date
        self.time = time
        self.duration = duration
        self.feedback = feedback
    }
}

@Model
class Feedback {
    var category: String
    var overall: Int
    var unit: String //satuan
    var tips: String
    
    var perSlideJSON: String
    
    var perSlide: [Slide] {
        Feedback.decode(perSlideJSON)
    }
    
    init (category: String, overall: Int, unit: String, tips: String, perSlide: [Slide]) {
        self.category = category
        self.overall = overall
        self.unit = unit
        self.tips = tips
        self.perSlideJSON = Feedback.encode(perSlide)
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

struct Slide: Codable {
    let page: Int
    let attempt: [Attempt]
}

struct Attempt: Codable {
    let no: Int
    let value: String
    let timestamp: TimeInterval
}
