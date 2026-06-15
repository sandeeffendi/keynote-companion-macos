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

    init(
        id: UUID = UUID(),
        sesTitle: String,
        sesKeynote: String,
        date: String,
        time: String,
        duration: String,
        feedback: [Feedback],
        audioFileURL: String? = nil
    ) {
        self.id = id
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.date = date
        self.time = time
        self.duration = duration
        self.feedback = feedback
        self.audioFileURL = audioFileURL
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RecapModel, rhs: RecapModel) -> Bool {
        lhs.id == rhs.id
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



