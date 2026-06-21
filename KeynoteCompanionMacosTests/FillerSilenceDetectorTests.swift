//
//  FillerSilenceDetectorTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

final class FillerSilenceDetectorTests: XCTestCase {

    /// Deterministic config: noise floor frozen (both alphas 0) so the speech
    /// threshold is fixed at initialNoiseFloor × energyFactor = 0.01 × 4 = 0.04.
    private func makeDetector(
        minPause: TimeInterval = 1.0,
        exitHysteresis: Float = 1.0
    ) -> SilenceDetector {
        SilenceDetector(config: .init(
            minPauseSeconds: minPause,
            energyFactor: 4,
            exitHysteresis: exitHysteresis,
            floorDownAlpha: 0,
            floorUpAlpha: 0,
            absoluteFloor: 0,
            initialNoiseFloor: 0.01
        ))
    }

    private let speech: Float = 0.2     // well above threshold 0.04
    private let silence: Float = 0.001  // well below threshold 0.04

    func testPauseEmittedWhenSpeechResumesAfterLongSilence() {
        var d = makeDetector()
        XCTAssertNil(d.ingest(level: speech, now: 0))     // speaking
        XCTAssertNil(d.ingest(level: silence, now: 1))    // silence begins
        XCTAssertNil(d.ingest(level: silence, now: 2.5))  // still silent
        let event = d.ingest(level: speech, now: 3)       // resume after 2s

        guard let event, case .silentPause(let duration) = event.kind else {
            return XCTFail("Expected a silent-pause event on resume")
        }
        XCTAssertEqual(duration, 2.0, accuracy: 0.0001)
        XCTAssertEqual(event.time, 3.0, accuracy: 0.0001)
    }

    func testShortGapIsNotCounted() {
        var d = makeDetector(minPause: 1.0)
        XCTAssertNil(d.ingest(level: speech, now: 0))
        XCTAssertNil(d.ingest(level: silence, now: 1))
        XCTAssertNil(d.ingest(level: speech, now: 1.5)) // only 0.5s — below min
    }

    func testTrailingSilenceWithoutResumeIsNotEmitted() {
        var d = makeDetector()
        XCTAssertNil(d.ingest(level: speech, now: 0))
        XCTAssertNil(d.ingest(level: silence, now: 1))
        XCTAssertNil(d.ingest(level: silence, now: 10)) // never resumes → no event
    }

    func testTwoSeparatePausesEmitTwoEvents() {
        var d = makeDetector()
        _ = d.ingest(level: speech, now: 0)
        _ = d.ingest(level: silence, now: 1)
        let first = d.ingest(level: speech, now: 3)     // pause 1: 2s
        _ = d.ingest(level: silence, now: 5)
        let second = d.ingest(level: speech, now: 8)    // pause 2: 3s

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
    }

    func testHysteresisKeepsSilentUntilLevelClearsMargin() {
        // threshold 0.04, hysteresis 2.0 → must exceed 0.08 to count as speech again.
        var d = makeDetector(minPause: 1.0, exitHysteresis: 2.0)
        XCTAssertNil(d.ingest(level: speech, now: 0))
        XCTAssertNil(d.ingest(level: silence, now: 1))
        XCTAssertNil(d.ingest(level: 0.05, now: 3))   // above threshold but below margin → still silent
        let event = d.ingest(level: 0.2, now: 4)      // clears margin → resume, pause = 3s

        guard case .silentPause(let duration)? = event?.kind else {
            return XCTFail("Expected a silent-pause event once the margin is cleared")
        }
        XCTAssertEqual(duration, 3.0, accuracy: 0.0001)
    }

    func testResetClearsInProgressSilence() {
        var d = makeDetector()
        _ = d.ingest(level: speech, now: 0)
        _ = d.ingest(level: silence, now: 1)
        d.reset()
        // After reset there is no silence in progress, so a lone speech sample emits nothing.
        XCTAssertNil(d.ingest(level: speech, now: 5))
    }
}
