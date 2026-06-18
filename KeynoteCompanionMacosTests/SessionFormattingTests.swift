//
//  SessionFormattingTests.swift
//  KeynoteCompanionMacosTests
//
//  Pure formatting used by Recap/History/Practice. Date/time strings are
//  locale/timezone dependent, so those assertions check shape, not content.
//

import XCTest
@testable import KeynoteCompanionMacos

final class SessionFormattingTests: XCTestCase {

    func testDurationZeroPadsMinutesAndSeconds() {
        XCTAssertEqual(SessionFormatting.duration(0), "00:00")
        XCTAssertEqual(SessionFormatting.duration(5), "00:05")
        XCTAssertEqual(SessionFormatting.duration(65), "01:05")
        XCTAssertEqual(SessionFormatting.duration(300), "05:00")
    }

    func testDurationCountsMinutesBeyondAnHourWithoutHoursField() {
        // MM:SS, not HH:MM:SS — 61 minutes stays in the minutes field.
        XCTAssertEqual(SessionFormatting.duration(3661), "61:01")
    }

    func testDurationClampsNegativeToZero() {
        XCTAssertEqual(SessionFormatting.duration(-10), "00:00")
    }

    func testClockOmitsLeadingZeroMinute() {
        XCTAssertEqual(SessionFormatting.clock(5), "0:05")
        XCTAssertEqual(SessionFormatting.clock(65), "1:05")
        XCTAssertEqual(SessionFormatting.clock(125), "2:05")
    }

    func testSessionTimeMatchesHHmmShape() {
        let time = SessionFormatting.sessionTime(Date())
        XCTAssertNotNil(
            time.range(of: #"^\d{2}:\d{2}$"#, options: .regularExpression),
            "Expected HH:mm, got \(time)"
        )
    }

    func testSessionDateIsNonEmpty() {
        XCTAssertFalse(SessionFormatting.sessionDate(Date()).isEmpty)
    }
}
