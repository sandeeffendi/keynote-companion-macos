//
//  RecapDummyData.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 14/06/26.
//

import Foundation
import SwiftData

extension HistoryModel {
    static var dummy: HistoryModel {
        let wpm = Feedback(category: "Words per Minute", overall: 142, unit: "wpm", tips: "Try to slow down on key slides.", perSlide: [
            Slide(page: 1, attempt: [Attempt(no: 1, value: "160", timestamp: 12.0)]),
            Slide(page: 3, attempt: [Attempt(no: 1, value: "178", timestamp: 45.0)]),
            Slide(page: 5, attempt: [Attempt(no: 1, value: "155", timestamp: 90.0)])]
        )
        let filler = Feedback(
            category: "Filler Words",
            overall: 8,
            unit: "words",
            tips: "Pause instead of saying 'um'.",
            perSlide: [
                Slide(page: 2, attempt: [Attempt(no: 1, value: "3", timestamp: 28.0)]),
                Slide(page: 4, attempt: [Attempt(no: 1, value: "5", timestamp: 72.0)])]
        )
        let dummydata = HistoryModel(
            title: "Product Pitch",
            keynote: "ProductPitch.key",
            date: "14 Jun 2026",
            time: "09:00",
            duration: "5:12",
            feedback: [wpm, filler]
        )
        return dummydata
    }

    @MainActor
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: HistoryModel.self, Feedback.self,
            configurations: config
        )
        let wpm = Feedback(
            category: "Words per Minute", overall: 142, unit: "wpm",
            tips: "Try to slow down on key slides.",
            perSlide: [
                Slide(page: 1, attempt: [Attempt(no: 1, value: "160", timestamp: 12.0)]),
                Slide(page: 3, attempt: [Attempt(no: 1, value: "178", timestamp: 45.0)]),
                Slide(page: 5, attempt: [Attempt(no: 1, value: "155", timestamp: 90.0)])
            ]
        )
        let filler = Feedback(
            category: "Filler Words", overall: 8, unit: "words",
            tips: "Pause instead of saying 'um'.",
            perSlide: [
                Slide(page: 2, attempt: [Attempt(no: 1, value: "3", timestamp: 28.0)]),
                Slide(page: 4, attempt: [Attempt(no: 1, value: "5", timestamp: 72.0)])
            ]
        )
        let session = HistoryModel(
            title: "Product Pitch", keynote: "ProductPitch.key",
            date: "14 Jun 2026", time: "09:00", duration: "5:12",
            feedback: [wpm, filler]
        )
        container.mainContext.insert(session)
        return container
    }
}
