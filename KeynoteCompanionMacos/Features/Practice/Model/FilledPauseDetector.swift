//
//  FilledPauseDetector.swift
//  KeynoteCompanionMacos
//
//  Pure, on-device detector for DRAWN-OUT VOICED fillers — the held "eeee"/"emmm"/
//  "mmm" hesitations. Same shape as `SilenceDetector`/`WPMCalculator`: a value type
//  owning only its small state, taking (level, now, timeSinceLastWord) inputs, fully
//  unit-testable without any audio.
//
//  Why this exists: server `id-ID` recognition normalises non-lexical disfluencies
//  out of the transcript, so a held "eeee" never reaches `FillerLexicon`; and it
//  isn't silent, so `SilenceDetector` ignores it. The acoustic signature is instead
//  "sustained, STEADY voiced energy while the recognizer produces no new words".
//
//  The steadiness gate is essential, not cosmetic: server STT lags ~1–3s, so the
//  first seconds of *normal* speech are also voiced-with-no-words-yet. A held vowel
//  has near-constant RMS (low coefficient of variation); articulated speech fluctuates
//  (syllables, consonants). That distinction is what keeps normal speech onset from
//  registering as a filled pause.
//

import Foundation

struct FilledPauseDetector: Sendable {
    /// Tunables, injectable so tests can make detection deterministic (small window,
    /// permissive variation) the way `SilenceDetector` freezes its noise floor.
    struct Config: Sendable {
        /// Min length (media seconds) of a voiced-but-wordless stretch to emit.
        var minSeconds: TimeInterval
        /// Min RMS for a sample to count as "voiced" (not silence).
        var minLevel: Float
        /// Max coefficient of variation (stddev ÷ mean) over the window to count as a
        /// STEADY held vowel rather than articulated speech.
        var maxVariation: Float
        /// Rolling-window size (samples) used to judge steadiness.
        var windowSamples: Int

        static let `default` = Config(
            minSeconds: FillerTuning.filledPauseMinSeconds,
            minLevel: FillerTuning.filledPauseMinLevel,
            maxVariation: FillerTuning.filledPauseMaxVariation,
            windowSamples: FillerTuning.filledPauseWindowSamples
        )
    }

    private let config: Config
    private var window: [Float] = []
    private var voicedStart: TimeInterval?
    private var emittedForRun = false

    init(config: Config = .default) {
        self.config = config
    }

    /// Feed one RMS level (0…1) sampled at media time `now`, plus how long since the
    /// last recognized word (`timeSinceLastWord`, media seconds). Returns a filled-pause
    /// event when audio has been continuously voiced AND STEADY for `minSeconds` with
    /// no word recognized during that whole stretch — a held "eeee". Emits once per
    /// run (latched until the sound stops). Returns `nil` otherwise.
    mutating func ingest(level: Float, now: TimeInterval, timeSinceLastWord: TimeInterval) -> FillerEvent? {
        guard level >= config.minLevel else {
            // Silence (or sub-voiced) breaks the run.
            resetRun()
            return nil
        }

        if voicedStart == nil {
            voicedStart = now
            emittedForRun = false
        }
        push(level)

        guard !emittedForRun, let start = voicedStart else { return nil }
        let voicedDuration = now - start
        guard voicedDuration >= config.minSeconds else { return nil }
        // No word recognized during this voiced run: the last word predates its start.
        guard timeSinceLastWord >= voicedDuration else { return nil }
        // The sound is a STEADY held vowel, not articulated speech awaiting transcription.
        guard window.count >= config.windowSamples, isSteady() else { return nil }

        emittedForRun = true
        return FillerEvent(time: now, kind: .filledPause(duration: voicedDuration))
    }

    /// Clears transient state for a fresh session, keeping the configured tunables.
    mutating func reset() {
        resetRun()
    }

    private mutating func resetRun() {
        window.removeAll(keepingCapacity: true)
        voicedStart = nil
        emittedForRun = false
    }

    private mutating func push(_ level: Float) {
        window.append(level)
        if window.count > config.windowSamples {
            window.removeFirst(window.count - config.windowSamples)
        }
    }

    /// True when the rolling window's coefficient of variation is within the configured
    /// max — i.e. the energy is near-constant, the hallmark of a held vowel.
    private func isSteady() -> Bool {
        let n = Float(window.count)
        guard n > 0 else { return false }
        let mean = window.reduce(0, +) / n
        guard mean > 0 else { return false }
        let variance = window.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / n
        let coefficientOfVariation = variance.squareRoot() / mean
        return coefficientOfVariation <= config.maxVariation
    }
}
