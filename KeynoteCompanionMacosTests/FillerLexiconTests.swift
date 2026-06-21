//
//  FillerLexiconTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

final class FillerLexiconTests: XCTestCase {

    // MARK: - Normalisation

    func testNormalizeLowercasesAndStripsPunctuation() {
        XCTAssertEqual(FillerLexicon.normalize("Kayak."), "kayak")
        XCTAssertEqual(FillerLexicon.normalize("GITU!"), "gitu")
        XCTAssertEqual(FillerLexicon.normalize("  anu,  "), "anu")
    }

    func testNormalizeCollapsesElongation() {
        XCTAssertEqual(FillerLexicon.normalize("eeee"), "ee")
        XCTAssertEqual(FillerLexicon.normalize("hmmm"), "hmm")
        XCTAssertEqual(FillerLexicon.normalize("Emmmm"), "emm")
    }

    // MARK: - Single-token matching

    func testDetectsSingleFillers() {
        let tokens = FillerLexicon.tokenize("saya kayak bingung gitu")
        XCTAssertEqual(FillerLexicon.detect(tokens: tokens, newStart: 0), ["kayak", "gitu"])
    }

    func testElongatedFilledPauseMatchesViaCollapse() {
        let tokens = FillerLexicon.tokenize("eeee terus")
        XCTAssertEqual(FillerLexicon.detect(tokens: tokens, newStart: 0), ["ee"])
    }

    func testAmbiguousEverydayWordsAreNotSingles() {
        // "jadi", "ya", "apa", "itu" are deliberately excluded to avoid false positives.
        let tokens = FillerLexicon.tokenize("jadi ya apa itu")
        XCTAssertTrue(FillerLexicon.detect(tokens: tokens, newStart: 0).isEmpty)
    }

    // MARK: - Bigrams

    func testDetectsBigramFiller() {
        let tokens = FillerLexicon.tokenize("apa ya")
        XCTAssertEqual(FillerLexicon.detect(tokens: tokens, newStart: 0), ["apa ya"])
    }

    func testStandaloneApaIsNotAFiller() {
        let tokens = FillerLexicon.tokenize("apa kabar")
        XCTAssertTrue(FillerLexicon.detect(tokens: tokens, newStart: 0).isEmpty)
    }

    // MARK: - High-water mark (dedup against cumulative transcripts)

    func testNewStartSkipsAlreadyCountedTokens() {
        let tokens = FillerLexicon.tokenize("em kayak")
        // "em" (index 0) already processed; only "kayak" (index 1) is new.
        XCTAssertEqual(FillerLexicon.detect(tokens: tokens, newStart: 1), ["kayak"])
    }

    func testBigramStraddlingTheBoundaryIsCountedOnce() {
        // "apa" arrived earlier (index 0); "ya" is the new token (index 1). The bigram
        // completes at the new token, so it's emitted exactly once.
        let tokens = FillerLexicon.tokenize("apa ya")
        XCTAssertEqual(FillerLexicon.detect(tokens: tokens, newStart: 1), ["apa ya"])
    }

    func testNothingNewYieldsNoMatches() {
        let tokens = FillerLexicon.tokenize("kayak gitu")
        XCTAssertTrue(FillerLexicon.detect(tokens: tokens, newStart: tokens.count).isEmpty)
    }
}
