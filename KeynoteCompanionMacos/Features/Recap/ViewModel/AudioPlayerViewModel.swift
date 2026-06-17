//
//  AudioPlayerViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 14/06/26.
//

//
//  AudioPlayerViewModel.swift
//  KeynoteCompanionMacos
//

import SwiftUI
import Combine

class AudioViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var progress: Double = 0.0
    
    var duration: Double = 120
    private var timer: Timer?
    
    var currentTime: Double { progress * duration }
    
    var timestampText: String {
        let total = Int(currentTime)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
    
    func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.progress += (1.0 / self.duration) * 0.1
                if self.progress >= 1.0 {
                    self.progress = 0
                    self.isPlaying = false
                    self.timer?.invalidate()
                }
            }
        } else {
            timer?.invalidate()
        }
    }
    
    func rewind() {
        progress = max(0, progress - (10 / duration))
    }
    
    func forward() {
        progress = min(1, progress + (10 / duration))
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    func seek(to value: Double) {
        progress = max(0, min(1, value))
    }
    
    func stop() {
        timer?.invalidate()
        isPlaying = false
    }
}
