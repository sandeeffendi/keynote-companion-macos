//
//  RecapViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import AVFoundation
import Combine
import Foundation

/// Mutually-exclusive ordering/filter applied to the per-slide WPM list, chosen
/// from the "Highlight" section's filter menu. Ascending/Descending sort by slide
/// number; Ideal/Not ideal filter on the speaking-rate band (kept in slide order).
enum SlideWPMFilter: String, CaseIterable, Identifiable {
    case ascending  = "Ascending"
    case descending = "Descending"
    case ideal      = "Ideal"
    case notIdeal   = "Not ideal"

    var id: String { rawValue }
}

/// Speaking-rate classification for a slide, surfaced as a text label in Recap.
enum WPMRateStatus {
    case tooSlow
    case ideal
    case tooFast

    /// Bold row label shown for out-of-range slides; `nil` for ideal.
    var label: String? {
        switch self {
        case .tooSlow: return "Speak too slow!"
        case .tooFast: return "Speak too fast!"
        case .ideal:   return nil
        }
    }
}

@MainActor
final class RecapViewModel: ObservableObject {
    /// Ideal speaking-rate band (WPM), inclusive. Matches the live Practice band.
    static let wpmLowerBand = 90
    static let wpmUpperBand = 120

    @Published var recapData: RecapModel

    // Audio playback
    @Published private(set) var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var hasAudio: Bool = false
    @Published private(set) var isMuted: Bool = false

    private(set) var hasSaved = false
    private(set) var audioPlayer: AVAudioPlayer?
    private var playerDelegate: AudioPlayerEndDelegate?
    private var progressTimerTask: Task<Void, Never>?
    /// When set, playback stops automatically once `currentTime` reaches it
    /// (per-slide isolated playback). Cleared by any full-session action.
    private var segmentEnd: TimeInterval?

    private let store: SessionStoring

    convenience init(recapData: RecapModel = .placeholder()) {
        self.init(recapData: recapData, store: SwiftDataSessionStore())
    }

    init(recapData: RecapModel, store: SessionStoring) {
        self.recapData = recapData
        self.store = store
    }

    // MARK: - Title editing

    /// Rename the session: update the in-memory recap and persist the new title
    /// for the matching history record (linked via `recapData.id`).
    func updateTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recapData = RecapModel(
            id: recapData.id,
            sesTitle: trimmed,
            sesKeynote: recapData.sesKeynote,
            durationSeconds: recapData.durationSeconds,
            feedback: recapData.feedback,
            audioFileURL: recapData.audioFileURL,
            createdAt: recapData.createdAt
        )
        store.updateTitle(of: recapData.id, to: trimmed)
    }

    @discardableResult
    func deleteSession() -> Bool {
        store.delete(sessionID: recapData.id)
    }

    // MARK: - Audio

    func configureAudioPlayer() {
        guard let urlString = recapData.audioFileURL,
              let url = URL(string: urlString),
              FileManager.default.fileExists(atPath: url.path(percentEncoded: false)),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            hasAudio = false
            return
        }
        let delegate = AudioPlayerEndDelegate { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.isPlaying = false
                self.playbackProgress = 0
                self.stopProgressTimer()
            }
        }
        playerDelegate = delegate
        audioPlayer = player
        audioPlayer?.delegate = delegate
        audioPlayer?.prepareToPlay()
        totalDuration = player.duration
        hasAudio = true
    }

    func togglePlayback() {
        guard let player = audioPlayer else { return }
        // Toggling the main transport always plays the full session, not a segment.
        segmentEnd = nil
        if isPlaying {
            player.pause()
            stopProgressTimer()
        } else {
            player.play()
            startProgressTimer()
        }
        isPlaying = player.isPlaying
    }

    func seek(to timestamp: TimeInterval) {
        guard let player = audioPlayer, totalDuration > 0 else { return }
        segmentEnd = nil
        player.currentTime = timestamp
        playbackProgress = timestamp / totalDuration
    }

    func seekByProgress(_ progress: Double) {
        guard let player = audioPlayer, totalDuration > 0 else { return }
        segmentEnd = nil
        let time = progress * totalDuration
        player.currentTime = time
        playbackProgress = progress
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        audioPlayer?.volume = muted ? 0 : 1
    }

    // MARK: - Per-slide isolated playback

    /// Inclusive start / exclusive end of slide `slide`'s audio segment. Delegates to
    /// `RecapSlideAnalysis.segmentBounds` (pure — that helper carries the unit tests).
    func segmentBounds(for slide: Slide) -> (start: TimeInterval, end: TimeInterval) {
        let slides = recapData.feedback.first(where: { $0.category == "WPM" })?.perSlide ?? []
        return RecapSlideAnalysis.segmentBounds(for: slide, in: slides, totalDuration: totalDuration)
    }

    /// Play only `slide`'s segment, stopping automatically at its end boundary.
    func playSlideSegment(_ slide: Slide) {
        guard let player = audioPlayer, totalDuration > 0 else { return }
        let bounds = segmentBounds(for: slide)
        segmentEnd = bounds.end
        player.currentTime = bounds.start
        playbackProgress = bounds.start / totalDuration
        player.play()
        isPlaying = player.isPlaying
        startProgressTimer()
    }

    /// Persist this session once, the first time the recap is shown for a live run.
    func autoSave() {
        guard !hasSaved else { return }
        hasSaved = true
        store.save(recapData)
    }

    // MARK: - Slide navigation & filter

    /// Flat list of (slideNo, startTimestamp) for every visit, including re-visits.
    /// Sorted ascending by start time so callers can binary-search for current slide.
    private func allSlideVisits() -> [(slideNo: Int, start: TimeInterval)] {
        guard let wpm = recapData.feedback.first(where: { $0.category == "WPM" }) else { return [] }
        return wpm.perSlide
            .flatMap { slide -> [(slideNo: Int, start: TimeInterval)] in
                guard !slide.attempts.isEmpty else { return [(slide.no, slide.timestamp)] }
                return slide.attempts.map { (slide.no, $0.startTimestamp) }
            }
            .sorted { $0.start < $1.start }
    }

    /// Slide number currently playing based on `playbackProgress`. Updates automatically
    /// as the timer drives `playbackProgress` every 200ms.
    var currentSlideNumber: Int {
        guard totalDuration > 0 else { return 1 }
        let t = playbackProgress * totalDuration
        let visits = allSlideVisits()
        guard !visits.isEmpty else { return 1 }
        var result = visits[0].slideNo
        for v in visits { if v.start <= t { result = v.slideNo } else { break } }
        return result
    }

    var formattedCurrentTime: String { SessionFormatting.clock(playbackProgress * totalDuration) }
    var formattedTotalDuration: String { SessionFormatting.clock(totalDuration) }

    func skipToPreviousSlide() {
        guard let player = audioPlayer else { return }
        let t = player.currentTime
        let starts = allSlideVisits().map(\.start)
        // If more than 2s into current visit, jump to its start; otherwise previous.
        if let prev = starts.last(where: { $0 < t - 2.0 }) {
            seek(to: prev)
        } else if let first = starts.first {
            seek(to: first)
        }
    }

    func skipToNextSlide() {
        guard let player = audioPlayer else { return }
        let t = player.currentTime
        let starts = allSlideVisits().map(\.start)
        if let next = starts.first(where: { $0 > t + 0.5 }) {
            seek(to: next)
        }
    }

    func wpmSlides(for filter: SlideWPMFilter) -> [Slide] {
        guard let wpm = recapData.feedback.first(where: { $0.category == "WPM" }) else { return [] }
        return RecapSlideAnalysis.filteredSlides(
            wpm.perSlide,
            filter: filter,
            lowerBand: Self.wpmLowerBand,
            upperBand: Self.wpmUpperBand
        )
    }

    /// Classify a WPM value against the ideal band.
    func status(for wpm: Int) -> WPMRateStatus {
        RecapSlideAnalysis.status(for: wpm, lowerBand: Self.wpmLowerBand, upperBand: Self.wpmUpperBand)
    }

    // MARK: - Filler words

    /// The "Filler Words" feedback, if this session has one. Mirrors how the WPM card
    /// looks up its feedback by `category`.
    var fillerFeedback: Feedback? {
        recapData.feedback.first(where: { $0.category == "Filler Words" })
    }

    /// Per-slide filler counts (`Slide.value` = count) in slide order.
    var fillerSlides: [Slide] {
        (fillerFeedback?.perSlide ?? []).sorted { $0.no < $1.no }
    }

    // MARK: - Private

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, let player = self.audioPlayer else { break }
                guard player.isPlaying else { break }
                // Per-slide isolated playback: stop at the segment boundary.
                if let end = self.segmentEnd, player.currentTime >= end {
                    player.pause()
                    self.isPlaying = false
                    self.segmentEnd = nil
                    break
                }
                self.playbackProgress = player.currentTime / player.duration
            }
        }
    }

    private func stopProgressTimer() {
        progressTimerTask?.cancel()
        progressTimerTask = nil
    }
}

// MARK: - AVAudioPlayerDelegate helper

/// Thin NSObject delegate that forwards `audioPlayerDidFinishPlaying` to a closure,
/// avoiding the need to make RecapViewModel an NSObject subclass.
private final class AudioPlayerEndDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
