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
    let feedback: [Feedback]
}

struct Feedback {
    let title: String
    let overall: Int
    let unit: String //satuan
    let tips: String
    let subTitle: String
    let category: String
    let perSlide: [Slide]
}

struct Slide: Codable {
    let no: Int
    let value: Int
    let timestamp: TimeInterval 
}



