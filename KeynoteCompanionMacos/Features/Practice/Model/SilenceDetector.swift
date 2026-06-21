//
//  SilenceDetector.swift
//  KeynoteCompanionMacos
//
//  Pure, on-device silent-pause detector. Same shape as `WPMCalculator`/`MediaClock`:
//  a value type that owns only its small state, takes (level, now) inputs, and is fully
//  unit-testable without any audio. The coordinator feeds it RMS levels sampled from the
//  ONE audio tap and stamps emitted pauses with the media clock.
//
//  Why energy VAD instead of the recognizer: on server `id-ID` recognition the
//  speech-segment timestamps are unreliable (≈0), so pauses can't be read from the
//  recognizer. The audio is already captured, so measuring energy is the natural,
//  internet-free way to detect "jeda berbicara".
//

import Foundation

struct SilenceDetector: Sendable {
    /// Tunables, injectable so tests can freeze the noise floor for deterministic
    /// assertions (set both adaptation alphas to 0 and pick a fixed initial floor).
    struct Config: Sendable {
        var minPauseSeconds: TimeInterval
        var energyFactor: Float
        var exitHysteresis: Float
        var floorDownAlpha: Float
        var floorUpAlpha: Float
        var absoluteFloor: Float
        var initialNoiseFloor: Float

        static let `default` = Config(
            minPauseSeconds: FillerTuning.minSilencePauseSeconds,
            energyFactor: FillerTuning.silenceEnergyFactor,
            exitHysteresis: FillerTuning.exitHysteresis,
            floorDownAlpha: FillerTuning.noiseFloorDownAlpha,
            floorUpAlpha: FillerTuning.noiseFloorUpAlpha,
            absoluteFloor: FillerTuning.absoluteSilenceFloor,
            initialNoiseFloor: FillerTuning.initialNoiseFloor
        )
    }

    private let config: Config
    private var noiseFloor: Float
    private var isSilent = false
    private var silenceStart: TimeInterval?

    init(config: Config = .default) {
        self.config = config
        self.noiseFloor = config.initialNoiseFloor
    }

    /// Feed one RMS level (0…1) sampled at media time `now`. Returns a completed
    /// pause event when speech RESUMES after a silence of at least `minPauseSeconds`
    /// — so a gap is only counted as a between-speech pause, never the trailing
    /// silence at the end of a session. Returns `nil` otherwise.
    mutating func ingest(level: Float, now: TimeInterval) -> FillerEvent? {
        adaptNoiseFloor(to: level)
        let threshold = max(config.absoluteFloor, noiseFloor * config.energyFactor)

        if isSilent {
            // Need to clear the threshold by the hysteresis margin to count as speech.
            if level > threshold * config.exitHysteresis {
                isSilent = false
                defer { silenceStart = nil }
                if let start = silenceStart {
                    let duration = now - start
                    if duration >= config.minPauseSeconds {
                        return FillerEvent(time: now, kind: .silentPause(duration: duration))
                    }
                }
            }
        } else if level < threshold {
            isSilent = true
            silenceStart = now
        }
        return nil
    }

    /// Clears transient state for a fresh session, keeping the configured tunables.
    mutating func reset() {
        noiseFloor = config.initialNoiseFloor
        isSilent = false
        silenceStart = nil
    }

    /// The noise floor tracks the quiet baseline: it snaps DOWN quickly toward a newly
    /// quieter level and creeps UP very slowly, so ongoing speech barely lifts it while
    /// a genuinely louder room is still followed over time.
    private mutating func adaptNoiseFloor(to level: Float) {
        let alpha = level < noiseFloor ? config.floorDownAlpha : config.floorUpAlpha
        noiseFloor += (level - noiseFloor) * alpha
    }
}
