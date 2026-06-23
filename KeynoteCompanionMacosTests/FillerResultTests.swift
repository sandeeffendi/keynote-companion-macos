//
//  FillerResultTests.swift
//  KeynoteCompanionMacosTests
//
//  Covers the filler-words Feedback that PracticeResult.toRecapModel() adds alongside
//  the WPM feedback: per-slide bucketing, reconciliation (Σ per-slide == total), and
//  that WPM stays feedback[0] / fillers are feedback[1].
//

import XCTest
@testable import KeynoteCompanionMacos

final class FillerResultTests: XCTestCase {
    private func makeResult(
        fillers: [FillerEvent],
        intervals: [PracticeSlideInterval],
        duration: TimeInterval
    ) -> PracticeResult {
        PracticeResult(
            wordTimestamps: [],
            slideIntervals: intervals,
            duration: duration,
            audioFileURL: nil,
            keynoteFileName: "Test.key",
            fillerEvents: fillers
        )
    }

    private func fillerFeedback(of result: PracticeResult) -> Feedback {
        let feedback = result.toRecapModel().feedback
        XCTAssertEqual(feedback[0].category, "WPM", "WPM must remain feedback[0]")
        XCTAssertEqual(feedback[1].category, "Filler Words", "Fillers are feedback[1]")
        return feedback[1]
    }

    func testFillerFeedbackAlwaysAddedEvenWhenEmpty() {
        let result = makeResult(
            fillers: [],
            intervals: [PracticeSlideInterval(slideNumber: 1, start: 0, end: 10)],
            duration: 10
        )
        let filler = fillerFeedback(of: result)
        XCTAssertEqual(filler.overall, 0)
        XCTAssertEqual(filler.subTitle, "No filler words detected")
    }

    func testOverallEqualsTotalFillerCount() {
        let fillers = [
            FillerEvent(time: 2, kind: .silentPause(duration: 2)),
            FillerEvent(time: 5, kind: .lexical(token: "kayak")),
            FillerEvent(time: 8, kind: .lexical(token: "gitu")),
        ]
        let result = makeResult(
            fillers: fillers,
            intervals: [PracticeSlideInterval(slideNumber: 1, start: 0, end: 10)],
            duration: 10
        )
        XCTAssertEqual(fillerFeedback(of: result).overall, 3)
    }

    func testPerSlideCountsBucketByInterval() {
        // slide 1: [0,10) gets the pause at t=5 ; slide 2: [10,20] gets t=12 and t=18.
        let fillers = [
            FillerEvent(time: 5, kind: .silentPause(duration: 2)),
            FillerEvent(time: 12, kind: .lexical(token: "kayak")),
            FillerEvent(time: 18, kind: .lexical(token: "gitu")),
        ]
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 20),
        ]
        let perSlide = fillerFeedback(of: makeResult(fillers: fillers, intervals: intervals, duration: 20)).perSlide

        XCTAssertEqual(perSlide.map(\.no), [1, 2])
        XCTAssertEqual(perSlide[0].value, 1)
        XCTAssertEqual(perSlide[1].value, 2)
    }

    func testPerSlideSumReconcilesToTotal() {
        let fillers = [
            FillerEvent(time: 1, kind: .lexical(token: "kayak")),
            FillerEvent(time: 9.5, kind: .silentPause(duration: 3)),
            FillerEvent(time: 15, kind: .lexical(token: "gitu")),
            FillerEvent(time: 20, kind: .silentPause(duration: 2)), // exactly at duration → last interval inclusive
        ]
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 20),
        ]
        let filler = fillerFeedback(of: makeResult(fillers: fillers, intervals: intervals, duration: 20))

        let sum = filler.perSlide.reduce(0) { $0 + $1.value }
        XCTAssertEqual(sum, filler.overall, "Σ per-slide filler counts must equal the total")
        XCTAssertEqual(sum, 4)
    }

    func testRevisitedSlideMergesFillerCounts() {
        // Visit order 1, 2, 1 — slide 1's two intervals must merge.
        let fillers = [
            FillerEvent(time: 5, kind: .lexical(token: "kayak")),   // slide 1, first visit
            FillerEvent(time: 15, kind: .lexical(token: "gitu")),   // slide 2
            FillerEvent(time: 25, kind: .silentPause(duration: 2)), // slide 1, second visit
        ]
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 20),
            PracticeSlideInterval(slideNumber: 1, start: 20, end: 30),
        ]
        let perSlide = fillerFeedback(of: makeResult(fillers: fillers, intervals: intervals, duration: 30)).perSlide

        XCTAssertEqual(perSlide.map(\.no), [1, 2], "Merged by slide number, first-appearance order")
        XCTAssertEqual(perSlide[0].value, 2, "Slide 1 merges both visits")
        XCTAssertEqual(perSlide[1].value, 1)
    }

    func testFilledPauseCountsAndIsLabeledSeparately() {
        // Regression guard: the breakdown must split silent / filled / lexical three
        // ways. If filled pauses were folded into lexicalCount, "drawn-out" would be
        // missing and the spoken-filler count would be wrong.
        let fillers = [
            FillerEvent(time: 2, kind: .silentPause(duration: 2)),
            FillerEvent(time: 4, kind: .filledPause(duration: 1)),
            FillerEvent(time: 6, kind: .lexical(token: "kayak")),
        ]
        let result = makeResult(
            fillers: fillers,
            intervals: [PracticeSlideInterval(slideNumber: 1, start: 0, end: 10)],
            duration: 10
        )
        let filler = fillerFeedback(of: result)
        XCTAssertEqual(filler.overall, 3, "All three kinds count toward the total")
        XCTAssertTrue(filler.tips.contains("1 long pause"), "tips=\(filler.tips)")
        XCTAssertTrue(filler.tips.contains("drawn-out"), "tips=\(filler.tips)")
        XCTAssertTrue(filler.tips.contains("1 spoken filler"), "tips=\(filler.tips)")
    }
}
