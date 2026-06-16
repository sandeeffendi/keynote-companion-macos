//
//  AudioCaptureService.swift
//  KeynoteCompanionMacos
//

import AVFoundation
import Foundation
import os
import Speech

private let log = Logger(subsystem: "com.tiempo.practice", category: "Audio")

protocol AudioCapturing: Sendable {
    func start(speechRequest: SFSpeechAudioBufferRecognitionRequest) async throws
    func updateSpeechRequest(_ request: SFSpeechAudioBufferRecognitionRequest) async
    func pause() async
    func resume() async throws
    func stop() async -> URL?
}

/// Holds the current recognition request so the audio tap (real-time thread) can read it
/// while the coordinator swaps in a fresh request when a recognition task ends.
private nonisolated final class SpeechRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    func get() -> SFSpeechAudioBufferRecognitionRequest? {
        lock.lock()
        defer { lock.unlock() }
        return request
    }

    /// Returns the previous request so the caller can finish it.
    @discardableResult
    func swap(_ newRequest: SFSpeechAudioBufferRecognitionRequest?) -> SFSpeechAudioBufferRecognitionRequest? {
        lock.lock()
        defer { lock.unlock() }
        let old = request
        request = newRequest
        return old
    }
}

actor AudioCaptureService: AudioCapturing {
    // nonisolated(unsafe) because these are read from the audio tap thread, which
    // runs outside actor isolation. The tap is installed/removed while actor-isolated,
    // so the writes happen-before the tap reads.
    nonisolated(unsafe) private var engine: AVAudioEngine?
    nonisolated(unsafe) private var audioFile: AVAudioFile?

    private let requestBox = SpeechRequestBox()
    private var recordingURL: URL?

    func start(speechRequest: SFSpeechAudioBufferRecognitionRequest) async throws {
        let url = makeRecordingURL()
        recordingURL = url

        let eng = AVAudioEngine()
        let inputNode = eng.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        let file = try AVAudioFile(forWriting: url, settings: recordingFormat.settings)
        audioFile = file
        engine = eng

        requestBox.swap(speechRequest)

        log.info("Starting capture: sampleRate=\(recordingFormat.sampleRate) channels=\(recordingFormat.channelCount)")

        let box = requestBox
        let firstBufferLogged = OSAllocatedUnfairLock(initialState: false)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            let shouldLog = firstBufferLogged.withLock { logged -> Bool in
                defer { logged = true }
                return !logged
            }
            if shouldLog {
                log.info("First buffer appended (frames=\(buffer.frameLength), request alive=\(box.get() != nil))")
            }
            box.get()?.append(buffer)
            try? file.write(from: buffer)
        }

        eng.prepare()
        try eng.start()
    }

    func updateSpeechRequest(_ request: SFSpeechAudioBufferRecognitionRequest) async {
        let old = requestBox.swap(request)
        old?.endAudio()
        log.info("Speech request swapped (previous alive=\(old != nil))")
    }

    func pause() async {
        engine?.pause()
    }

    func resume() async throws {
        try engine?.start()
    }

    func stop() async -> URL? {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        audioFile = nil
        let old = requestBox.swap(nil)
        old?.endAudio()
        return recordingURL
    }

    private func makeRecordingURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("TiempoMacOS/recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(UUID().uuidString).caf")
    }
}
