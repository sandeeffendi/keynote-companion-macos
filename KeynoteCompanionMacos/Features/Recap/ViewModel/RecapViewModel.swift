//
//  RecapViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Combine
import Foundation
import SwiftData

final class RecapViewModel: ObservableObject {
    @Published var recapData: RecapModel

    init(
            recapData: RecapModel = RecapModel(
                sesTitle: "Practice Recording 1",
                sesKeynote: "HIG Reading Materials",
                date: "Monday, 17 August 2026",
                time: "10:00",
                duration: "00:05:00",
                wpm: FeedbackModel(
                    overall: 152,
                    highest: HighlightModel(value: 190, slide: 5),
                    lowest: HighlightModel(value: 100, slide: 3),
                    recommendation: "On slide 5, your speaking pace was quite fast. Try slowing down."
                ),
                filler: FeedbackModel(
                    overall: 60,
                    highest: HighlightModel(value: 15, slide: 5),
                    lowest: HighlightModel(value: 2, slide: 6),
                    recommendation: "On slide 5, you used 15 filler words. Try pausing between sentences."
                ),
                tips: [
                    "An ideal speaking pace is between 120 and 160 WPM.",
                    "If your session exceeds your target duration, try tightening your phrasing."
                ]
            )){
        self.recapData = recapData
    }
    
    func saveRecap(context: ModelContext) {
        print("saving recap...")
        let recap = HistoryModel(
            sesTitle: recapData.sesTitle,
            sesKeynote: recapData.sesKeynote,
            date: recapData.date,
            time: recapData.time,
            duration: recapData.duration,
            wpmOverall: recapData.wpm.overall,
            wpmHighest: recapData.wpm.highest.value,
            wpmLowest: recapData.wpm.highest.slide,
            wpmHighestSlides: recapData.wpm.lowest.value,
            wpmLowestSlides: recapData.wpm.lowest.slide,
            fillerOverall: recapData.filler.overall,
            fillerHighest: recapData.filler.highest.value,
            fillerLowest: recapData.filler.highest.slide,
            fillerHighestSlides: recapData.filler.lowest.value,
            fillerLowestSlides: recapData.filler.lowest.slide
        )
        context.insert(recap)
        try? context.save()
        print("saved: \(recap.sesTitle)")
    }
}
