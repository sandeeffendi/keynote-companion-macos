//
//  HistoryModel.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import Foundation
import SwiftData

@Model
class HistoryModel{
    var sesTitle: String
    var sesKeynote: String
    var date: String
    var time: String
    var duration: String

    var wpmOverall: Int
    var wpmHighest: Int
    var wpmLowest: Int
    var wpmHighestSlides: Int
    var wpmLowestSlides: Int

    var fillerOverall: Int
    var fillerHighest: Int
    var fillerLowest: Int
    var fillerHighestSlides: Int
    var fillerLowestSlides: Int
    
    init(
        sesTitle: String,
        sesKeynote: String,
        date: String,
        time: String,
        duration: String,
        wpmOverall: Int,
        wpmHighest: Int,
        wpmLowest: Int,
        wpmHighestSlides: Int,
        wpmLowestSlides: Int,
        fillerOverall: Int,
        fillerHighest: Int,
        fillerLowest: Int,
        fillerHighestSlides: Int,
        fillerLowestSlides: Int
    )
    {
        self.sesTitle = sesTitle
        self.sesKeynote = sesKeynote
        self.date = date
        self.time = time
        self.duration = duration
        self.wpmOverall = wpmOverall
        self.wpmHighest = wpmHighest
        self.wpmLowest = wpmLowest
        self.wpmHighestSlides = wpmHighestSlides
        self.wpmLowestSlides = wpmLowestSlides
        self.fillerOverall = fillerOverall
        self.fillerHighest = fillerHighest
        self.fillerLowest = fillerLowest
        self.fillerHighestSlides = fillerHighestSlides
        self.fillerLowestSlides = fillerHighestSlides
    }
}



