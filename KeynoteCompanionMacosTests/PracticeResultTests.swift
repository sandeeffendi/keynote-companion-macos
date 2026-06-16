//
//  PracticeResultTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

final class PracticeResultTests: XCTestCase {
    private func makeResult(
        words: [TimeInterval],
        intervals: [PracticeSlideInterval],
        duration: TimeInterval
    ) -> PracticeResult {
        PracticeResult(
            wordTimestamps: words,
            slideIntervals: intervals,
            duration: duration,
            audioFileURL: nil,
            keynoteFileName: "Test.key"
        )
    }

    func testPerSlideWPMComputedPerInterval() {
        // slide 1: [0,10) with 20 words -> 120 WPM ; slide 2: [10,30) with 20 words -> 60 WPM
        let words = Array(repeating: 5.0, count: 20) + Array(repeating: 20.0, count: 20)
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 30),
        ]

        let perSlide = makeResult(words: words, intervals: intervals, duration: 30)
            .toRecapModel().feedback[0].perSlide

        XCTAssertEqual(perSlide.map(\.no), [1, 2])
        XCTAssertEqual(perSlide[0].value, 120)
        XCTAssertEqual(perSlide[1].value, 60)
    }

    func testRevisitedSlideMergedByAccumulation() {
        // Visit order 1, 2, 1. Slide 1 appears twice and must merge:
        // slide 1: [0,10)=10 words + [20,30)=20 words -> 30 words / 20s -> 90 WPM
        // slide 2: [10,20)=5 words -> 5 / 10s -> 30 WPM
        let words = Array(repeating: 5.0, count: 10)
            + Array(repeating: 15.0, count: 5)
            + Array(repeating: 25.0, count: 20)
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 20),
            PracticeSlideInterval(slideNumber: 1, start: 20, end: 30),
        ]

        let perSlide = makeResult(words: words, intervals: intervals, duration: 30)
            .toRecapModel().feedback[0].perSlide

        XCTAssertEqual(perSlide.map(\.no), [1, 2], "Merged by slide number, first-appearance order")
        XCTAssertEqual(perSlide[0].value, 90)
        XCTAssertEqual(perSlide[1].value, 30)
    }

    func testIntervalBoundaryIsHalfOpen() {
        // A word at exactly t=10 belongs to slide 2 ([10,20)), not slide 1 ([0,10)).
        let intervals = [
            PracticeSlideInterval(slideNumber: 1, start: 0, end: 10),
            PracticeSlideInterval(slideNumber: 2, start: 10, end: 20),
        ]

        let perSlide = makeResult(words: [10.0], intervals: intervals, duration: 20)
            .toRecapModel().feedback[0].perSlide

        XCTAssertEqual(perSlide[0].value, 0)
        XCTAssertEqual(perSlide[1].value, 6) // 1 / 10 * 60
    }

    func testOverallWPMUsesTotalWordsOverDuration() {
        let words = Array(repeating: 1.0, count: 40)
        let intervals = [PracticeSlideInterval(slideNumber: 1, start: 0, end: 20)]

        let overall = makeResult(words: words, intervals: intervals, duration: 20)
            .toRecapModel().feedback[0].overall

        XCTAssertEqual(overall, 120) // 40 / 20 * 60
    }

    func testZeroDurationDoesNotCrashAndYieldsZero() {
        let result = makeResult(words: [], intervals: [], duration: 0)
        let feedback = result.toRecapModel().feedback[0]

        XCTAssertEqual(feedback.overall, 0)
        XCTAssertTrue(feedback.perSlide.isEmpty)
    }
}
