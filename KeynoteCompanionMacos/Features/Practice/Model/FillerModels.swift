//
//  FillerModels.swift
//  KeynoteCompanionMacos
//
//  Filler-word detection data model. A filler timeline runs in PARALLEL to the
//  word-event history: both are media-second timestamps bucketed into the same
//  `slideIntervals`, and both surface as a `Feedback` in the recap. Adding filler
//  detection never touches the WPM path — see `tiempo-practice` invariants.
//

import Foundation

/// One detected filler. Three kinds: a silent gap, a drawn-out voiced hesitation,
/// and a spoken lexical filler word.
enum FillerKind: Sendable, Equatable {
    /// A silent gap in speech longer than `FillerTuning.minSilencePauseSeconds`,
    /// detected on-device by `SilenceDetector` from audio energy. `duration` is the
    /// measured length of the gap in media seconds.
    case silentPause(duration: TimeInterval)
    /// A drawn-out voiced filler ("eeee"/"emmm"/"mmm") that the server recognizer
    /// drops as a non-word: detected on-device by `FilledPauseDetector` as sustained,
    /// steady voiced energy with no word progress. `duration` is its length in media
    /// seconds.
    case filledPause(duration: TimeInterval)
    /// A spoken filler word matched against `FillerLexicon` (e.g. "kayak", "gitu").
    case lexical(token: String)
}

/// One filler event on the session timeline. `time` is media seconds since session
/// start (paused time excluded), assigned at arrival — consistent with how words are
/// timestamped (see `PracticeRecordingCoordinator.history`).
struct FillerEvent: Sendable, Equatable {
    let time: TimeInterval
    let kind: FillerKind

    var isSilentPause: Bool { if case .silentPause = kind { return true }; return false }
    var isFilledPause: Bool { if case .filledPause = kind { return true }; return false }
    var isLexical: Bool { if case .lexical = kind { return true }; return false }
    var lexicalToken: String? { if case .lexical(let t) = kind { return t }; return nil }
}

/// One place to tune filler detection, mirroring `PracticeTuning`. These values are
/// starting points and are meant to be calibrated against real sessions.
enum FillerTuning {
    // MARK: Silent pause (energy VAD)

    /// A silence must last at least this long (media seconds) to count as a pause.
    /// Shorter gaps are normal between-phrase breathing and are ignored.
    static let minSilencePauseSeconds: TimeInterval = 0.7 // PROVISIONAL — calibrate
    /// Speech threshold = adaptive noise floor × this factor. Higher = stricter
    /// (only loud speech counts as "talking", so more gaps register as silence).
    static let silenceEnergyFactor: Float = 5.0
    /// To leave the silent state the level must exceed `threshold × this`, a
    /// hysteresis margin that stops the detector chattering at the boundary.
    static let exitHysteresis: Float = 1.6
    /// How fast the noise floor tracks DOWN toward a newly-quieter level (0…1).
    static let noiseFloorDownAlpha: Float = 0.5
    /// How slowly the noise floor creeps UP (0…1). Tiny so speech energy barely
    /// raises the floor while a genuinely louder room is still tracked over time.
    static let noiseFloorUpAlpha: Float = 0.002
    /// Absolute lower bound for the speech threshold, so near-digital-silence input
    /// can't drive the threshold to ~0 and treat faint noise as speech.
    static let absoluteSilenceFloor: Float = 0.0008
    /// Starting noise-floor estimate before any audio adapts it.
    static let initialNoiseFloor: Float = 0.005

    // MARK: Filled pause (acoustic "eeee" — sustained voiced energy + word-arrival)

    /// A voiced-but-wordless stretch must last at least this long (media seconds) to
    /// count as a drawn-out "eeee"/"emmm" filler. Short enough to catch real um's.
    static let filledPauseMinSeconds: TimeInterval = 0.6 // PROVISIONAL — calibrate
    /// Minimum RMS for audio to count as "voiced" (the speaker is making sound, not
    /// silent) when hunting for a filled pause. Sits above the silence threshold.
    static let filledPauseMinLevel: Float = 0.02 // PROVISIONAL — calibrate
    /// Max coefficient of variation (stddev ÷ mean) of RMS over the rolling window for
    /// the sound to count as a STEADY held vowel rather than articulated speech that
    /// the recognizer simply hasn't transcribed yet (server STT lags ~1–3s). This is
    /// what stops normal speech onset from registering as a filled pause.
    static let filledPauseMaxVariation: Float = 0.4 // PROVISIONAL — calibrate
    /// Number of recent RMS samples used to judge steadiness. Must fill within
    /// `filledPauseMinSeconds` at the tap's buffer cadence (~43/s).
    static let filledPauseWindowSamples: Int = 12 // PROVISIONAL — calibrate

    // MARK: Recap classification

    /// At or below this fillers-per-minute the delivery is considered clean.
    static let idealFillersPerMinute: Double = 3

    // MARK: Calibration instrumentation

    /// Log one per-sample RMS/floor/threshold calibration line every N samples, so the
    /// `Calibration` log isn't flooded at the tap's ~43 samples/s cadence.
    static let calibrationLogEverySamples: Int = 15
}

/// Indonesian filler-word lexicon + matcher. Deliberately CONSERVATIVE for v1:
/// ambiguous everyday words ("jadi", "ya", "apa", "itu") are excluded as singles to
/// avoid false positives; a few only count as part of a fixed two-word filler.
/// Tokens are normalised (lowercased, punctuation-stripped, elongation collapsed)
/// before matching, so "Eeee," and "eee" both map to "ee".
enum FillerLexicon {
    /// Single-token fillers, stored in normalised (elongation-collapsed) form.
    static let singles: Set<String> = [
        "ee", "em", "emm", "mm", "hmm", "eh", "anu", "apaan",
        "kayak", "gitu", "gini", "pokoknya", "maksudnya", "intinya",
    ]

    /// Two-word fillers, normalised and space-joined. Lets us catch "apa ya" without
    /// flagging the very common standalone "apa".
    static let bigrams: Set<String> = [
        "apa ya", "gitu loh", "he eh", "kayak gini", "kayak gitu",
    ]

    /// Word-like fillers worth biasing the recognizer toward via the request's
    /// `contextualStrings`, so the server LM is less likely to silently drop them.
    /// Pure vocalisations ("ee"/"mm"/"hmm") are intentionally omitted — they aren't
    /// dictionary words, so hinting them does nothing; those are caught acoustically
    /// by `FilledPauseDetector`. Kept deliberately small (contextualStrings is most
    /// effective with a short, high-signal list).
    static let recognizerHints: [String] = [
        "eh", "anu", "apaan", "kayak", "gitu", "gini",
        "pokoknya", "maksudnya", "intinya",
        "apa ya", "gitu loh", "kayak gini", "kayak gitu",
    ]

    /// Normalise one raw token: lowercase, strip non-letters, collapse a run of 3+
    /// identical letters to 2 ("eeee" → "ee", "hmmm" → "hmm").
    static func normalize(_ raw: String) -> String {
        let lowered = raw.lowercased()
        let lettersOnly = lowered.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        let collapsed = collapseElongation(String(String.UnicodeScalarView(lettersOnly)))
        return collapsed
    }

    /// Tokenise a transcript into normalised tokens, dropping empties.
    static func tokenize(_ transcript: String) -> [String] {
        transcript
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
    }

    /// Return the filler tokens that COMPLETE within `tokens[newStart...]`. A bigram
    /// is counted at its second token, so it's emitted exactly once even though its
    /// first token may sit before `newStart` (the recognizer delivers cumulative
    /// transcripts; `newStart` is the caller's high-water mark to prevent re-counting).
    static func detect(tokens: [String], newStart: Int) -> [String] {
        guard newStart < tokens.count else { return [] }
        var matches: [String] = []
        for i in newStart..<tokens.count {
            if i >= 1 {
                let bigram = tokens[i - 1] + " " + tokens[i]
                if bigrams.contains(bigram) {
                    matches.append(bigram)
                    continue // don't also match the singles inside a bigram
                }
            }
            if singles.contains(tokens[i]) {
                matches.append(tokens[i])
            }
        }
        return matches
    }

    private static func collapseElongation(_ s: String) -> String {
        guard s.count >= 3 else { return s }
        var result = ""
        var runChar: Character?
        var runLen = 0
        for ch in s {
            if ch == runChar {
                runLen += 1
                if runLen <= 2 { result.append(ch) } // keep first two of a run
            } else {
                runChar = ch
                runLen = 1
                result.append(ch)
            }
        }
        return result
    }
}
