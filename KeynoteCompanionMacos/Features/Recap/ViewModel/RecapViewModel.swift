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

final class RecapViewModel: ObservableObject {
    @Published var recapData: RecapModel

    // Audio playback
    @Published private(set) var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var hasAudio: Bool = false

    private(set) var audioPlayer: AVAudioPlayer?
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

    func configureAudioPlayer() {
        guard let urlString = recapData.audioFileURL,
              let url = URL(string: urlString),
              FileManager.default.fileExists(atPath: url.path),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            hasAudio = false
            return
        }
        audioPlayer = player
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
            audioFileURL: recapData.audioFileURL
        )

        context.insert(recap)
        try? context.save()
    }

    // MARK: - Private

    private func startProgressTimer() {
        progressTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, let player = self.audioPlayer, player.isPlaying else { break }
                self.playbackProgress = player.currentTime / player.duration
                if !player.isPlaying {
                    self.isPlaying = false
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
