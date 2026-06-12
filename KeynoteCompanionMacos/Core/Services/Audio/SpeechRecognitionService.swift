//
//  SpeechRecognitionService.swift
//  KeynoteCompanionMacos
//

import Foundation
import os
import Speech

private let log = Logger(subsystem: "com.tiempo.practice", category: "Speech")

protocol SpeechRecognizing: Sendable {
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onWordCount: @Sendable @escaping (Int) -> Void,
        onTaskEnded: @Sendable @escaping () -> Void
    ) async throws
    func stopRecognition() async
}

actor SpeechRecognitionService: SpeechRecognizing {
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        self.init(locale: Locale(identifier: "id-ID"))
    }

    init(locale: Locale) {
        let rec = SFSpeechRecognizer(locale: locale)
        rec?.defaultTaskHint = .dictation
        self.recognizer = rec
    }

    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onWordCount: @Sendable @escaping (Int) -> Void,
        onTaskEnded: @Sendable @escaping () -> Void
    ) async throws {
        guard let recognizer, recognizer.isAvailable else {
            log.error("Recognizer unavailable (recognizer nil: \(self.recognizer == nil))")
            throw SpeechRecognitionError.recognizerUnavailable
        }

        request.shouldReportPartialResults = true
        // Never force on-device: supportsOnDeviceRecognition can report true while the
        // dictation model asset is missing, which fails with kAFAssistantErrorDomain 1101
        // without ever producing a result. Let the system pick on-device or server.
        request.requiresOnDeviceRecognition = false

        log.info("Starting recognition: locale=\(recognizer.locale.identifier, privacy: .public) available=\(recognizer.isAvailable) onDeviceSupported=\(recognizer.supportsOnDeviceRecognition)")

        let taskEnded = OSAllocatedUnfairLock(initialState: false)
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let transcription = result.bestTranscription.formattedString
                let wordCount = transcription
                    .split(separator: " ")
                    .filter { !$0.isEmpty }
                    .count
                log.debug("Partial result: words=\(wordCount) final=\(result.isFinal) text=\(transcription.suffix(60), privacy: .private)")
                onWordCount(wordCount)
            }

            if let error = error as NSError? {
                log.error("Recognition task error: domain=\(error.domain, privacy: .public) code=\(error.code) \(error.localizedDescription, privacy: .public)")
            }

            // Any terminal event (error or final result) ends the task; the coordinator
            // decides whether to restart with a fresh request.
            if error != nil || result?.isFinal == true {
                let alreadyEnded = taskEnded.withLock { ended -> Bool in
                    defer { ended = true }
                    return ended
                }
                guard !alreadyEnded else { return }
                onTaskEnded()
            }
        }
    }

    func stopRecognition() async {
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

enum SpeechRecognitionError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        "Speech recognizer is not available. WPM tracking will be disabled."
    }
}
