//
//  SettingsViewModel.swift
//  KeynoteCompanionMacos
//

import Combine
import Foundation
import AVFoundation
import AppKit

final class SettingsViewModel: ObservableObject {

    @Published var settingsData: SettingsModel

    init(
        settingsData: SettingsModel =
        SettingsModel (
            permissionItems: [
                .microphone,
                .screen,
                .wpmDetector
            ]
        )
    ) {
        self.settingsData = settingsData
        refreshAllPermissionStatuses()
    }

    func currentStatus(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .microphone:
            return microphoneStatus()
//        case .screenCapture:
//            return screenCaptureStatus()
//        case .wpmDetector:
//            return speechStatus()
        }
    }
    
    private func microphoneStatus() -> PermissionStatus {
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
    
//    private func screenCaptureStatus() -> PermissionStatus {
//        
//    }
    
//    private func speechStatus() -> PermissionStatus {
//        
//    }

    func refreshAllPermissionStatuses() {
        for index in settingsData.permissionItems.indices {
            let type = settingsData.permissionItems[index].permissionType
            let status = currentStatus(for: type)
            settingsData.permissionItems[index].isEnabled = (status == .authorized)
        }
    }

    func togglePermission(at index: Int, newValue: Bool) {
        let permissionItem = settingsData.permissionItems[index]
        let status = currentStatus(for: permissionItem.permissionType)

        if newValue {
            switch status {
            case .notDetermined:
                requestPermission(for: permissionItem.permissionType, at: index)

            case .denied:
                settingsData.permissionItems[index].isEnabled = false
                openSystemSettings(for: permissionItem.permissionType)

            case .authorized:
                settingsData.permissionItems[index].isEnabled = true
            }
        } else {
            settingsData.permissionItems[index].isEnabled = true
            openSystemSettings(for: permissionItem.permissionType)
        }
    }

    private func requestPermission(for type: PermissionType, at index: Int) {
        switch type {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.settingsData.permissionItems[index].isEnabled = granted
                }
            }
        }
    }

    private func openSystemSettings(for type: PermissionType) {
        let urlString: String
        switch type {
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
//            case .
//            case .
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    func loadSettings() {
        // Placeholder untuk load settings.
    }
}
