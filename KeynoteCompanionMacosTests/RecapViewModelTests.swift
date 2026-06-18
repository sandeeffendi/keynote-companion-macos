//
//  RecapViewModelTests.swift
//  KeynoteCompanionMacosTests
//
//  Exercises the pure per-slide analysis (filter/sort/segment/status) that backs
//  RecapViewModel. Tests target `RecapSlideAnalysis` directly so they don't have to
//  spin up the @MainActor view model (which owns audio + Task state).
//

import XCTest
@testable import KeynoteCompanionMacos

final class RecapViewModelTests: XCTestCase {

    private let lower = RecapViewModel.wpmLowerBand   // 90
    private let upper = RecapViewModel.wpmUpperBand   // 120

    // MARK: - Status classification

    func testStatusClassifiesAgainstBand() {
        XCTAssertEqual(RecapSlideAnalysis.status(for: 80, lowerBand: lower, upperBand: upper), .tooSlow)
        XCTAssertEqual(RecapSlideAnalysis.status(for: lower, lowerBand: lower, upperBand: upper), .ideal)   // 90 inclusive
        XCTAssertEqual(RecapSlideAnalysis.status(for: 100, lowerBand: lower, upperBand: upper), .ideal)
        XCTAssertEqual(RecapSlideAnalysis.status(for: upper, lowerBand: lower, upperBand: upper), .ideal)   // 120 inclusive
        XCTAssertEqual(RecapSlideAnalysis.status(for: 145, lowerBand: lower, upperBand: upper), .tooFast)
    }

    func testStatusLabelsOnlyShowForOutOfRange() {
        XCTAssertEqual(WPMRateStatus.tooSlow.label, "Speak too slow!")
        XCTAssertNil(WPMRateStatus.ideal.label)
        XCTAssertEqual(WPMRateStatus.tooFast.label, "Speak too fast!")
    }

    // MARK: - Filter / sort

    private var unsortedSlides: [Slide] {
        [
            Slide(no: 3, value: 80,  timestamp: 75),   // too slow
            Slide(no: 1, value: 120, timestamp: 0),    // ideal
            Slide(no: 4, value: 100, timestamp: 110),  // ideal
            Slide(no: 2, value: 145, timestamp: 30)    // too fast
        ]
    }

    private func filtered(_ filter: SlideWPMFilter) -> [Int] {
        RecapSlideAnalysis
            .filteredSlides(unsortedSlides, filter: filter, lowerBand: lower, upperBand: upper)
            .map(\.no)
    }

    func testAscendingSortsBySlideNumber() {
        XCTAssertEqual(filtered(.ascending), [1, 2, 3, 4])
    }

    func testDescendingSortsBySlideNumberDescending() {
        XCTAssertEqual(filtered(.descending), [4, 3, 2, 1])
    }

    func testIdealFiltersInBandKeepsSlideOrder() {
        XCTAssertEqual(filtered(.ideal), [1, 4])
    }

    func testNotIdealFiltersOutOfBandKeepsSlideOrder() {
        XCTAssertEqual(filtered(.notIdeal), [2, 3])
    }

    // MARK: - Per-slide segment bounds

    func testSegmentEndIsNextVisitStart() {
        let slides = [
            Slide(no: 1, value: 100, timestamp: 0),
            Slide(no: 2, value: 100, timestamp: 30),
            Slide(no: 3, value: 100, timestamp: 75)
        ]

        let first = RecapSlideAnalysis.segmentBounds(for: slides[0], in: slides, totalDuration: 200)
        XCTAssertEqual(first.start, 0)
        XCTAssertEqual(first.end, 30)

        let second = RecapSlideAnalysis.segmentBounds(for: slides[1], in: slides, totalDuration: 200)
        XCTAssertEqual(second.start, 30)
        XCTAssertEqual(second.end, 75)
    }

    func testLastSegmentEndsAtTotalDuration() {
        let slides = [
            Slide(no: 1, value: 100, timestamp: 0),
            Slide(no: 2, value: 100, timestamp: 40)
        ]

        let last = RecapSlideAnalysis.segmentBounds(for: slides[1], in: slides, totalDuration: 200)
        XCTAssertEqual(last.start, 40)
        XCTAssertEqual(last.end, 200)
    }

    func testSegmentBoundsExpandsRevisitAttempts() {
        // Slide 1 is visited at t=0 then re-visited at t=120; slide 2 at t=50.
        // Slide 1's first segment should end at the next chronological visit (t=50).
        let slide1 = Slide(
            no: 1, value: 100, timestamp: 0,
            attempts: [
                SlideAttempt(attemptNo: 1, wpm: 100, startTimestamp: 0),
                SlideAttempt(attemptNo: 2, wpm: 100, startTimestamp: 120)
            ]
        )
        let slide2 = Slide(no: 2, value: 100, timestamp: 50)
        let slides = [slide1, slide2]

        let bounds = RecapSlideAnalysis.segmentBounds(for: slide1, in: slides, totalDuration: 200)
        XCTAssertEqual(bounds.start, 0)
        XCTAssertEqual(bounds.end, 50)
    }
}
