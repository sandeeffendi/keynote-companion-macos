//
//  MicrophonePermissionService.swift
//  KeynoteCompanionMacos
//

import AVFoundation
import Foundation

protocol MicrophonePermissionChecking: Sendable {
    func authorizationStatus() -> PermissionStatus
}

struct MicrophonePermissionService: MicrophonePermissionChecking {
    func authorizationStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
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
}
