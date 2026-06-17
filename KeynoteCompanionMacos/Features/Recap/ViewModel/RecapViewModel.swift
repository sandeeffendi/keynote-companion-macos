//
//  RecapViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import AVFoundation
import Combine
import Foundation
import SwiftData

enum SlideWPMFilter: String, CaseIterable {
    case all      = "All"
    case tooSlow  = "Too Slow"   // < 90 WPM
    case ideal    = "Ideal"      // 90–120 WPM
    case tooFast  = "Too Fast"   // > 120 WPM
}

@MainActor
final class RecapViewModel: ObservableObject {
    @Published var recapData: RecapModel

    // Audio playback
    @Published private(set) var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var hasAudio: Bool = false

    private(set) var hasSaved = false
    private(set) var audioPlayer: AVAudioPlayer?
    private var playerDelegate: AudioPlayerEndDelegate?
    private var progressTimerTask: Task<Void, Never>?

    init(
        recapData: RecapModel = RecapModel(
            sesTitle: "Practice Recording 1",
            sesKeynote: "HIG Reading Materials",
            date: "Monday, 17 August 2945",
            time: "10:00",
            duration: "00:05:00",
            feedback: [
                Feedback(
                    title: "Speaking Pace",
                    overall: 152,
                    unit: "WPM",
                    tips: "On slide 5, your speaking pace was quite fast. Try slowing down.",
                    subTitle: "Your average pace is slightly fast",
                    category: "WPM",
                    perSlide: [
                        Slide(no: 1, value: 120, timestamp: 0),
                        Slide(no: 2, value: 145, timestamp: 63.0),
                        Slide(no: 3, value: 100, timestamp: 130.5)
                    ]
                ),
                Feedback(
                    title: "Filler Words",
                    overall: 60,
                    unit: "words",
                    tips: "On slide 5, you used 15 filler words. Try pausing between sentences.",
                    subTitle: "You used quite a lot of filler words",
                    category: "Filler",
                    perSlide: [
                        Slide(no: 1, value: 120, timestamp: 0),
                        Slide(no: 2, value: 145, timestamp: 63.0),
                        Slide(no: 3, value: 100, timestamp: 130.5)
                    ]
                )
            ]
        )
    ) {
        self.recapData = recapData
    }

    // MARK: - Title editing

    /// Update the in-memory session title. When the session exists in SwiftData
    /// (linked via `recapData.id` ↔ `HistoryModel.sessionID`), also persists.
    func updateTitleInHistory(_ newTitle: String, context: ModelContext) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        updateTitle(trimmed)
        let sessionID = recapData.id
        do {
            let descriptor = FetchDescriptor<HistoryModel>(
                predicate: #Predicate { $0.sessionID == sessionID }
            )
            if let record = try context.fetch(descriptor).first {
                record.sesTitle = trimmed
                try context.save()
            }
        } catch {}
    }

    func updateTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recapData = RecapModel(
            id: recapData.id,
            sesTitle: trimmed,
            sesKeynote: recapData.sesKeynote,
            date: recapData.date,
            time: recapData.time,
            duration: recapData.duration,
            feedback: recapData.feedback,
            audioFileURL: recapData.audioFileURL,
            createdAt: recapData.createdAt
        )
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
        player.currentTime = timestamp
        playbackProgress = timestamp / totalDuration
    }

    func seekByProgress(_ progress: Double) {
        guard let player = audioPlayer, totalDuration > 0 else { return }
        let time = progress * totalDuration
        player.currentTime = time
        playbackProgress = progress
    }

    func autoSave(context: ModelContext) {
        guard !hasSaved else { return }
        hasSaved = true
        saveRecap(context: context)
    }

    func saveRecap(context: ModelContext) {
        let historyFeedbacks = recapData.feedback.map { feedback in
            HistoryFeedback(
                title: feedback.title,
                overall: feedback.overall,
                unit: feedback.unit,
                tips: feedback.tips,
                subTitle: feedback.subTitle,
                category: feedback.category,
                perSlide: feedback.perSlide
            )
        }

        let recap = HistoryModel(
            sesTitle: recapData.sesTitle,
            sesKeynote: recapData.sesKeynote,
            date: recapData.date,
            time: recapData.time,
            duration: recapData.duration,
            feedbacks: historyFeedbacks,
            audioFileURL: recapData.audioFileURL,
            createdAt: recapData.createdAt,
            sessionID: recapData.id
        )

        context.insert(recap)
        try? context.save()
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

    var formattedCurrentTime: String { formatSeconds(playbackProgress * totalDuration) }
    var formattedTotalDuration: String { formatSeconds(totalDuration) }

    private func formatSeconds(_ s: TimeInterval) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }

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
        switch filter {
        case .all:     return wpm.perSlide
        case .tooSlow: return wpm.perSlide.filter { $0.value < 90 }
        case .ideal:   return wpm.perSlide.filter { $0.value >= 90 && $0.value <= 120 }
        case .tooFast: return wpm.perSlide.filter { $0.value > 120 }
        }
    }

    // MARK: - Private

    private func startProgressTimer() {
        progressTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, let player = self.audioPlayer else { break }
                if player.isPlaying {
                    self.playbackProgress = player.currentTime / player.duration
                } else {
                    break
                }
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
