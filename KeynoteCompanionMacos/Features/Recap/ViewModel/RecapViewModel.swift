//
//  RecapViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

final class RecapViewModel: ObservableObject {
    @Published var recapData: RecapModel
    
    //tip
    @Published var saveToHistory: Bool = false
    @Published var showSavedToast: Bool = false

    // Audio player state
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published var totalDuration: TimeInterval = 300.0
    
    
    func saveRecap(context: ModelContext) {
        print("saving recap...")

        let historyFeedbacks = recapData.feedback.map { feedback in
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

        let recap = HistoryModel(
            sesTitle: recapData.sesTitle,
            sesKeynote: recapData.sesKeynote,
            date: recapData.date,
            time: recapData.time,
            duration: recapData.duration,
            feedbacks: historyFeedbacks
        )

        context.insert(recap)
        try? context.save()
        print("saved: \(recap.sesTitle)")
    }
    
    init(
        recapData: RecapModel = RecapModel(
            sesTitle: "Practice Recording 1",
            sesKeynote: "HIG Reading Materials",
            date: "Monday, 17 August 2945",
            time: "10:00",
            duration: "00:05:00",
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
                ),
                Feedback(
                    title: "Filler Words",
                    overall: 60,
                    unit: "words",
                    tips: "On slide 5, you used 15 filler words. Try pausing between sentences.",
                    subTitle: "You used quite a lot of filler words",
                    category: "Filler",
                    perSlide: [
                        Slide(no: 1, value: 120, timestamp: 0),
                        Slide(no: 2, value: 145, timestamp: 63.0),
                        Slide(no: 3, value: 100, timestamp: 130.5)
                    ]
                )
            ]
        )
    ) {
        self.recapData = recapData
    }

    
}
