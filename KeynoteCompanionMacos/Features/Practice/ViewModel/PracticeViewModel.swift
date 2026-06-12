//
//  PracticeViewModel.swift
//  KeynoteCompanionMacos
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published private(set) var currentWPM: Int = 0
    @Published private(set) var wpmStatus: WPMStatus = .good
    @Published private(set) var elapsedTime: String = "00:00"
    @Published private(set) var currentSlide: Int = 1
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isPaused: Bool = false

    private let coordinator: PracticeRecordingCoordinator
    private var observationTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    var onSessionFinished: ((PracticeResult) -> Void)?

    convenience init() {
        self.init(coordinator: PracticeRecordingCoordinator())
    }

    init(coordinator: PracticeRecordingCoordinator) {
        self.coordinator = coordinator
    }

    deinit {
        timerTask?.cancel()
        observationTask?.cancel()
        let coord = coordinator
        Task.detached {
            _ = await coord.stop()
        }
    }

    func startSession(keynoteFileName: String) async {
        do {
            try await coordinator.start(keynoteFileName: keynoteFileName)
            isRecording = true
            isPaused = false
            startObservation()
            startTimer()
        } catch {
            isRecording = false
        }
    }

    func pause() {
        Task {
            await coordinator.pause()
            isPaused = true
        }
    }

    func resume() {
        Task {
            try? await coordinator.resume()
            isPaused = false
        }
    }

    func retake() {
        Task {
            await coordinator.retakeCurrentSlide()
            currentWPM = 0
            wpmStatus = .good
        }
    }

    func stop() {
        timerTask?.cancel()
        observationTask?.cancel()
        Task {
            let result = await coordinator.stop()
            isRecording = false
            isPaused = false
            onSessionFinished?(result)
        }
    }

    // MARK: - Private

    private func startObservation() {
        observationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.coordinator.stateStream
            for await state in stream {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    if case .finished = state {
                        self.isRecording = false
                    }
                }
            }
        }
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { break }

                let elapsed = await self.coordinator.elapsedSeconds()
                let wpm = await self.coordinator.currentWPM()
                let slide = await self.coordinator.currentSlide()

                await MainActor.run {
                    self.elapsedTime = self.formatElapsed(elapsed)
                    self.currentWPM = wpm
                    self.wpmStatus = WPMStatus(wpm: wpm)
                    self.currentSlide = slide
                }
            }
        }
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
