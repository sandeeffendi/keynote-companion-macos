//
//  HistoryMappingTests.swift
//  KeynoteCompanionMacosTests
//
//  The Recap<->History mapping is the single point where fields are copied, so a
//  round-trip must preserve every field (including nested feedback/slide attempts).
//

import XCTest
@testable import KeynoteCompanionMacos

@MainActor
final class HistoryMappingTests: XCTestCase {

    private func sampleRecap() -> RecapModel {
        RecapModel(
            id: UUID(),
            sesTitle: "Quarterly Review",
            sesKeynote: "Deck.key",
            durationSeconds: 312,
            feedback: [
                Feedback(
                    title: "Speaking Pace",
                    overall: 134,
                    unit: "WPM",
                    tips: "Slow down on slide 3.",
                    subTitle: "Slightly fast",
                    category: "WPM",
                    perSlide: [
                        Slide(no: 1, value: 110, timestamp: 0),
                        Slide(
                            no: 2, value: 150, timestamp: 40,
                            attempts: [
                                SlideAttempt(attemptNo: 1, wpm: 150, startTimestamp: 40),
                                SlideAttempt(attemptNo: 2, wpm: 120, startTimestamp: 90)
                            ]
                        )
                    ]
                )
            ],
            audioFileURL: "file:///tmp/session.caf",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    func testRoundTripPreservesScalarFields() {
        let recap = sampleRecap()
        let back = HistoryModel.make(from: recap).toRecapModel()

        XCTAssertEqual(back.id, recap.id)
        XCTAssertEqual(back.sesTitle, recap.sesTitle)
        XCTAssertEqual(back.sesKeynote, recap.sesKeynote)
        XCTAssertEqual(back.durationSeconds, recap.durationSeconds)
        XCTAssertEqual(back.audioFileURL, recap.audioFileURL)
        XCTAssertEqual(back.createdAt, recap.createdAt)
    }

    func testRoundTripPreservesFeedbackAndSlideAttempts() {
        let recap = sampleRecap()
        let back = HistoryModel.make(from: recap).toRecapModel()

        XCTAssertEqual(back.feedback.count, recap.feedback.count)
        let original = recap.feedback[0]
        let mapped = back.feedback[0]
        XCTAssertEqual(mapped.title, original.title)
        XCTAssertEqual(mapped.overall, original.overall)
        XCTAssertEqual(mapped.category, original.category)
        // Slide is Hashable/Codable — attempts must survive the JSON encode/decode.
        XCTAssertEqual(mapped.perSlide, original.perSlide)
    }
}
