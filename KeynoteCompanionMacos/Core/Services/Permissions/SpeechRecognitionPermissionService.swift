//
//  SpeechRecognitionPermissionService.swift
//  KeynoteCompanionMacos
//

import Foundation
import Speech

protocol SpeechRecognitionPermissionChecking: Sendable {
    func authorizationStatus() -> PermissionStatus
    func requestPermission() async -> PermissionStatus
}

struct SpeechRecognitionPermissionService: SpeechRecognitionPermissionChecking {
    func authorizationStatus() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestPermission() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume(returning: .authorized)
                case .notDetermined:
                    continuation.resume(returning: .notDetermined)
                case .denied, .restricted:
                    continuation.resume(returning: .denied)
                @unknown default:
                    continuation.resume(returning: .denied)
                }
            }
        }
    }
}
