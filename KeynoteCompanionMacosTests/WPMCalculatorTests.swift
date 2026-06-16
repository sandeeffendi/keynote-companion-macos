//
//  WPMCalculatorTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

final class WPMCalculatorTests: XCTestCase {

    // MARK: - Windowing (smoothing disabled for exact assertions)

    func testFullWindowComputesGrossWPM() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)
        // 30 words evenly across (0, 15] -> 30 / 15 * 60 = 120 WPM.
        let words = stride(from: 0.5, through: 15.0, by: 0.5).map { $0 }
        XCTAssertEqual(words.count, 30)

        let wpm = calc.recompute(timestamps: words, now: 15)

        XCTAssertEqual(wpm, 120, accuracy: 0.0001)
    }

    func testWarmUpDividesByElapsedNotFullWindow() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)
        // 5 words in the first 5 seconds; window not yet full.
        // Denominator = min(15, 5) = 5 -> 5 / 5 * 60 = 60 WPM.
        let words: [TimeInterval] = [1, 2, 3, 4, 5]

        let wpm = calc.recompute(timestamps: words, now: 5)

        XCTAssertEqual(wpm, 60, accuracy: 0.0001)
    }

    func testSilenceDecaysToZeroAsWordsLeaveWindow() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)
        // Words only in the first 5s; at t=30 they are all older than the window.
        let words: [TimeInterval] = [1, 2, 3, 4, 5]

        let wpm = calc.recompute(timestamps: words, now: 30)

        XCTAssertEqual(wpm, 0, accuracy: 0.0001)
    }

    func testOnlyWordsInsideWindowAreCounted() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)
        // now=30, window=15 -> cutoff=15. Only 20, 25, 28 are inside.
        let words: [TimeInterval] = [10, 20, 25, 28]

        let wpm = calc.recompute(timestamps: words, now: 30)

        XCTAssertEqual(wpm, 3.0 / 15.0 * 60, accuracy: 0.0001) // = 12
    }

    func testWindowBoundariesAreHalfOpenLowExclusiveHighInclusive() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)
        // now=15, cutoff=0. Word at 0.0 is excluded (> cutoff), 15.0 is included (<= now).
        let words: [TimeInterval] = [0.0, 15.0]

        let wpm = calc.recompute(timestamps: words, now: 15)

        XCTAssertEqual(wpm, 1.0 / 15.0 * 60, accuracy: 0.0001) // = 4
    }

    func testEmptyHistoryIsZero() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)

        XCTAssertEqual(calc.recompute(timestamps: [], now: 10), 0, accuracy: 0.0001)
    }

    func testZeroNowIsZeroAndDoesNotDivideByZero() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0)

        XCTAssertEqual(calc.recompute(timestamps: [0], now: 0), 0, accuracy: 0.0001)
    }

    // MARK: - EMA smoothing

    func testEMAMovesGraduallyTowardRawAcrossTicks() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0.3)
        let words = stride(from: 0.5, through: 15.0, by: 0.5).map { $0 } // raw = 120

        // smoothed_1 = 0.3*120 + 0.7*0 = 36
        XCTAssertEqual(calc.recompute(timestamps: words, now: 15), 36, accuracy: 0.0001)
        // smoothed_2 = 0.3*120 + 0.7*36 = 61.2
        XCTAssertEqual(calc.recompute(timestamps: words, now: 15), 61.2, accuracy: 0.0001)
        XCTAssertEqual(calc.smoothedWPM, 61.2, accuracy: 0.0001)
    }

    func testResetClearsSmoothedValue() {
        var calc = WPMCalculator(window: 15, smoothingFactor: 0.3)
        let words = stride(from: 0.5, through: 15.0, by: 0.5).map { $0 }
        _ = calc.recompute(timestamps: words, now: 15)
        XCTAssertGreaterThan(calc.smoothedWPM, 0)

        calc.reset()

        XCTAssertEqual(calc.smoothedWPM, 0, accuracy: 0.0001)
    }
}
