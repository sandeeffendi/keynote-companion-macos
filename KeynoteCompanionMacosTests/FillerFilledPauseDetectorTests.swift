//
//  FillerFilledPauseDetectorTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

final class FillerFilledPauseDetectorTests: XCTestCase {
    /// Deterministic config: short min duration, small steadiness window, generous
    /// variation tolerance — so a handful of synthetic samples can drive the detector.
    private func makeDetector(maxVariation: Float = 0.5) -> FilledPauseDetector {
        FilledPauseDetector(config: .init(
            minSeconds: 0.5,
            minLevel: 0.1,
            maxVariation: maxVariation,
            windowSamples: 3
        ))
    }

    private let noWords: TimeInterval = 100 // last word far in the past

    func testEmitsWhenVoicedSteadyAndWordless() {
        var detector = makeDetector()
        // Steady 0.3 held across 0.6s with no words → a drawn-out "eeee".
        XCTAssertNil(detector.ingest(level: 0.3, now: 0.0, timeSinceLastWord: noWords))
        XCTAssertNil(detector.ingest(level: 0.3, now: 0.2, timeSinceLastWord: noWords))
        XCTAssertNil(detector.ingest(level: 0.3, now: 0.4, timeSinceLastWord: noWords)) // dur 0.4 < 0.5
        let event = detector.ingest(level: 0.3, now: 0.6, timeSinceLastWord: noWords)
        guard case .filledPause(let duration)? = event?.kind else {
            return XCTFail("Expected a filled pause, got \(String(describing: event))")
        }
        XCTAssertEqual(duration, 0.6, accuracy: 0.001)
    }

    func testDoesNotEmitWhileWordsAreArriving() {
        var detector = makeDetector()
        // Voiced & steady, but words keep arriving (small timeSinceLastWord) → normal
        // speech the recognizer simply hasn't transcribed, not a held vowel.
        for now in stride(from: 0.0, through: 1.2, by: 0.2) {
            XCTAssertNil(detector.ingest(level: 0.3, now: now, timeSinceLastWord: 0.1))
        }
    }

    func testDoesNotEmitOnSilence() {
        var detector = makeDetector()
        for now in stride(from: 0.0, through: 1.2, by: 0.2) {
            XCTAssertNil(detector.ingest(level: 0.01, now: now, timeSinceLastWord: noWords))
        }
    }

    func testDoesNotEmitWhenEnergyIsNotSteady() {
        var detector = makeDetector(maxVariation: 0.2) // strict steadiness
        // Voiced and wordless, but the level swings wildly (articulated speech).
        let levels: [Float] = [0.2, 0.9, 0.15, 0.95, 0.2, 0.9, 0.15]
        for (i, level) in levels.enumerated() {
            let now = Double(i) * 0.2
            XCTAssertNil(detector.ingest(level: level, now: now, timeSinceLastWord: noWords))
        }
    }

    func testEmitsOncePerVoicedRunThenAgainAfterSilence() {
        var detector = makeDetector()
        // First held vowel: emits exactly once at 0.6s.
        _ = detector.ingest(level: 0.3, now: 0.0, timeSinceLastWord: noWords)
        _ = detector.ingest(level: 0.3, now: 0.2, timeSinceLastWord: noWords)
        _ = detector.ingest(level: 0.3, now: 0.4, timeSinceLastWord: noWords)
        XCTAssertEqual(detector.ingest(level: 0.3, now: 0.6, timeSinceLastWord: noWords)?.isFilledPause, true)
        // Further voiced samples in the same run must NOT re-emit.
        XCTAssertNil(detector.ingest(level: 0.3, now: 0.8, timeSinceLastWord: noWords))
        XCTAssertNil(detector.ingest(level: 0.3, now: 1.0, timeSinceLastWord: noWords))
        // Silence breaks the run.
        XCTAssertNil(detector.ingest(level: 0.01, now: 1.2, timeSinceLastWord: noWords))
        // A fresh held vowel emits again.
        _ = detector.ingest(level: 0.3, now: 2.0, timeSinceLastWord: noWords)
        _ = detector.ingest(level: 0.3, now: 2.2, timeSinceLastWord: noWords)
        _ = detector.ingest(level: 0.3, now: 2.4, timeSinceLastWord: noWords)
        XCTAssertEqual(detector.ingest(level: 0.3, now: 2.6, timeSinceLastWord: noWords)?.isFilledPause, true)
    }

    func testResetClearsInProgressRun() {
        var detector = makeDetector()
        _ = detector.ingest(level: 0.3, now: 0.0, timeSinceLastWord: noWords)
        _ = detector.ingest(level: 0.3, now: 0.4, timeSinceLastWord: noWords)
        detector.reset()
        // After reset the voiced run restarts, so a single sample can't satisfy the
        // min duration or fill the steadiness window.
        XCTAssertNil(detector.ingest(level: 0.3, now: 0.6, timeSinceLastWord: noWords))
    }
}
