//
//  SettingsViewModel.swift
//  KeynoteCompanionMacos
//

import Combine
import Foundation
import AVFoundation
import AppKit

@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var settingsData: SettingsModel
    private let automationPermissionService: KeynoteAutomationPermissionChecking
    private var automationRefreshTask: Task<Void, Never>?
    private var automationRefreshRequestID: UUID?

    convenience init() {
        self.init(
            settingsData: SettingsModel(
                permissionItems: [
                    .microphone,
                    .keynoteAutomation,
                    .wpmDetector
                ]
            ),
            automationPermissionService: KeynoteAutomationPermissionService(
                appResolver: KeynoteAppResolver()
            )
        )
    }

    init(
        settingsData: SettingsModel =
        SettingsModel(
            permissionItems: [
                .microphone,
                .keynoteAutomation,
                .wpmDetector
            ]
        ),
        automationPermissionService: KeynoteAutomationPermissionChecking
    ) {
        self.settingsData = settingsData
        self.automationPermissionService = automationPermissionService
        refreshAllPermissionStatuses()
    }

    deinit {
        automationRefreshTask?.cancel()
    }

    func currentStatus(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .microphone:
            return microphoneStatus()
        case .keynoteAutomation:
            return storedStatus(for: type)
        case .wpmPlaceholder:
            return .denied
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
    func refreshAllPermissionStatuses() {
        for index in settingsData.permissionItems.indices {
            let type = settingsData.permissionItems[index].permissionType
            let status = currentStatus(for: type)
            settingsData.permissionItems[index].status = status
            settingsData.permissionItems[index].isEnabled = (status == .authorized)
        }

        startAutomationRefresh(promptIfNeeded: false)
    }

    func isPermissionEnabled(_ type: PermissionType) -> Bool {
        switch type {
        case .microphone:
            return currentStatus(for: type) == .authorized
        case .keynoteAutomation:
            return storedStatus(for: type) == .authorized
        case .wpmPlaceholder:
            return false
        }
    }

    func togglePermission(for type: PermissionType, newValue: Bool) {
        switch type {
        case .microphone:
            toggleMicrophonePermission(newValue: newValue)
        case .keynoteAutomation:
            toggleKeynoteAutomationPermission(newValue: newValue)
        case .wpmPlaceholder:
            setPermissionEnabled(false, for: type)
        }
    }

    private func toggleMicrophonePermission(newValue: Bool) {
        let status = currentStatus(for: .microphone)

        if newValue {
            switch status {
            case .notDetermined:
                requestPermission(for: .microphone)
            case .denied:
                setPermissionEnabled(false, for: .microphone)
                openSystemSettings(for: .microphone)
            case .authorized:
                setPermissionEnabled(true, for: .microphone)
            }
        } else {
            setPermissionEnabled(status == .authorized, for: .microphone)

            if status == .authorized {
                openSystemSettings(for: .microphone)
            }
        }
    }

    private func requestPermission(for type: PermissionType) {
        switch type {
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshAllPermissionStatuses()
                }
            }
        case .keynoteAutomation, .wpmPlaceholder:
            break
        }
    }

    private func openSystemSettings(for type: PermissionType) {
        let urlString: String
        switch type {
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .keynoteAutomation:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        case .wpmPlaceholder:
            return
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func setPermissionEnabled(
        _ isEnabled: Bool,
        for type: PermissionType
    ) {
        guard let index = settingsData.permissionItems.firstIndex(
            where: { $0.permissionType == type }
        ) else {
            return
        }

        settingsData.permissionItems[index].isEnabled = isEnabled
    }

    private func toggleKeynoteAutomationPermission(newValue: Bool) {
        let status = storedStatus(for: .keynoteAutomation)

        if newValue {
            switch status {
            case .notDetermined:
                startAutomationRefresh(promptIfNeeded: true)
            case .denied:
                setPermissionEnabled(false, for: .keynoteAutomation)
                openSystemSettings(for: .keynoteAutomation)
            case .authorized:
                setPermissionEnabled(true, for: .keynoteAutomation)
            }
        } else {
            setPermissionEnabled(status == .authorized, for: .keynoteAutomation)

            if status == .authorized {
                openSystemSettings(for: .keynoteAutomation)
            }
        }
    }

    private func startAutomationRefresh(promptIfNeeded: Bool) {
        automationRefreshTask?.cancel()
        let requestID = UUID()
        automationRefreshRequestID = requestID
        automationRefreshTask = Task { [weak self] in
            await self?.refreshKeynoteAutomationStatus(
                promptIfNeeded: promptIfNeeded,
                requestID: requestID
            )
        }
    }

    private func refreshKeynoteAutomationStatus(
        promptIfNeeded: Bool,
        requestID: UUID
    ) async {
        defer {
            clearAutomationRefreshTaskIfCurrent(requestID: requestID)
        }

        let status = await automationPermissionService.authorizationStatus(
            promptIfNeeded: promptIfNeeded
        )

        guard !Task.isCancelled else {
            return
        }

        updatePermissionStatus(
            mapAutomationStatus(status),
            for: .keynoteAutomation
        )
    }

    private func clearAutomationRefreshTaskIfCurrent(requestID: UUID) {
        if automationRefreshRequestID == requestID {
            automationRefreshTask = nil
            automationRefreshRequestID = nil
        }
    }

    private func mapAutomationStatus(
        _ status: KeynoteAutomationPermissionState
    ) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .keynoteUnavailable, .targetNotRunning, .error:
            return .denied
        }
    }

    private func updatePermissionStatus(
        _ status: PermissionStatus,
        for type: PermissionType
    ) {
        guard let index = settingsData.permissionItems.firstIndex(
            where: { $0.permissionType == type }
        ) else {
            return
        }

        settingsData.permissionItems[index].status = status
        settingsData.permissionItems[index].isEnabled = (status == .authorized)
    }

    private func storedStatus(for type: PermissionType) -> PermissionStatus {
        settingsData.permissionItems.first {
            $0.permissionType == type
        }?.status ?? .notDetermined
    }
}
