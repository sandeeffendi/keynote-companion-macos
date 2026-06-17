//
//  RecapSlideAnalysis.swift
//  KeynoteCompanionMacos
//
//  Pure, side-effect-free analysis of per-slide WPM used by Recap. Extracted from
//  RecapViewModel so it can be unit-tested without instantiating the @MainActor view
//  model (which owns audio/Task state). All functions take their inputs explicitly.
//

import Foundation

enum RecapSlideAnalysis {

    /// Classify a WPM value against the inclusive ideal band.
    static func status(for wpm: Int, lowerBand: Int, upperBand: Int) -> WPMRateStatus {
        if wpm < lowerBand { return .tooSlow }
        if wpm > upperBand { return .tooFast }
        return .ideal
    }

    /// Sort/filter the slide list per the chosen menu option. Ascending/Descending
    /// order by slide number; Ideal/Not-ideal filter on the band, kept in slide order.
    static func filteredSlides(
        _ slides: [Slide],
        filter: SlideWPMFilter,
        lowerBand: Int,
        upperBand: Int
    ) -> [Slide] {
        switch filter {
        case .ascending:
            return slides.sorted { $0.no < $1.no }
        case .descending:
            return slides.sorted { $0.no > $1.no }
        case .ideal:
            return slides
                .filter { status(for: $0.value, lowerBand: lowerBand, upperBand: upperBand) == .ideal }
                .sorted { $0.no < $1.no }
        case .notIdeal:
            return slides
                .filter { status(for: $0.value, lowerBand: lowerBand, upperBand: upperBand) != .ideal }
                .sorted { $0.no < $1.no }
        }
    }

    /// Chronological visit start times across all slides, expanding re-visit attempts
    /// so the result matches the audio playback timeline.
    static func visitStarts(_ slides: [Slide]) -> [TimeInterval] {
        slides
            .flatMap { slide -> [TimeInterval] in
                slide.attempts.isEmpty ? [slide.timestamp] : slide.attempts.map(\.startTimestamp)
            }
            .sorted()
    }

    /// Inclusive start / exclusive end of `slide`'s audio segment: end = the next visit
    /// start after this slide's start, or `totalDuration` for the final segment. The end
    /// is clamped to never precede the start.
    static func segmentBounds(
        for slide: Slide,
        in slides: [Slide],
        totalDuration: TimeInterval
    ) -> (start: TimeInterval, end: TimeInterval) {
        let start = slide.timestamp
        let end = visitStarts(slides).first(where: { $0 > start }) ?? totalDuration
        return (start, max(start, end))
    }
}
