//
//  RecapModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation

struct RecapModel {
    let sesTitle: String
    let sesKeynote: String
    let date: String
    let time: String
    let duration: String
    let wpm: FeedbackModel
    let filler: FeedbackModel
    let tips: [String]
}

struct FeedbackModel {
    let overall: Int
    let highest: HighlightModel
    let lowest: HighlightModel
    let recommendation: String
}

struct HighlightModel {
    let value: Int
    let slide: Int
}
