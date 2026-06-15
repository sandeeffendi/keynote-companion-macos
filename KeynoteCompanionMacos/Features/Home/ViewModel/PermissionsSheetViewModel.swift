//
//  PermissionsSheetViewModel.swift
//  KeynoteCompanionMacos
//
//  Drives the first-run Permissions modal: shows the three accesses Tiempo needs,
//  requests them all from the single "Allow" button, and reports when every access
//  is granted so the sheet can auto-dismiss.
//

import AVFoundation
import AppKit
import Combine
import Foundation

@MainActor
final class PermissionsSheetViewModel: ObservableObject {

    /// One row per required permission, in the order shown in the design
    /// (Keynote → Microphone → Speech).
    struct Row: Identifiable {
        let id = UUID()
        let type: PermissionType
        let icon: String
        let title: String
        let subtitle: String
        let info: String
        var status: PermissionStatus
    }

    @Published private(set) var rows: [Row]
    @Published private(set) var isRequesting = false

    private let automationPermissionService: KeynoteAutomationPermissionChecking
    private let microphonePermissionService: MicrophonePermissionChecking
    private let speechPermissionService: SpeechRecognitionPermissionChecking

    /// True once all three accesses are authorized — HomeView watches this to dismiss.
    var allGranted: Bool {
        rows.allSatisfy { $0.status == .authorized }
    }

    convenience init() {
        let appResolver = KeynoteAppResolver()
        self.init(
            automationPermissionService: KeynoteAutomationPermissionService(
                appResolver: appResolver
            ),
            microphonePermissionService: MicrophonePermissionService(),
            speechPermissionService: SpeechRecognitionPermissionService()
        )
    }

    init(
        automationPermissionService: KeynoteAutomationPermissionChecking,
        microphonePermissionService: MicrophonePermissionChecking,
        speechPermissionService: SpeechRecognitionPermissionChecking
    ) {
        self.automationPermissionService = automationPermissionService
        self.microphonePermissionService = microphonePermissionService
        self.speechPermissionService = speechPermissionService
        self.rows = Self.makeRows()
        refresh()
    }

    private static func makeRows() -> [Row] {
        [
            Row(
                type: .keynoteAutomation,
                icon: AppIcon.permissionSheetKeynote,
                title: "Allow Keynote Access",
                subtitle: "For detecting your keynote slideshow mode.",
                info:
                    "Tiempo reads Keynote's state to know when your slideshow starts and which slide you're on, so it can track your practice automatically.",
                status: .notDetermined
            ),
            Row(
                type: .microphone,
                icon: AppIcon.permissionSheetMicrophone,
                title: "Allow Microphone Access",
                subtitle: "For recording your sound.",
                info:
                    "Your microphone captures your voice while you present so you can listen back to the recording in your recap.",
                status: .notDetermined
            ),
            Row(
                type: .speechRecognition,
                icon: AppIcon.permissionSheetSpeech,
                title: "Speech Recognition",
                subtitle: "For detecting your speaking rate.",
                info:
                    "Speech recognition measures your words-per-minute live so you can keep an ideal pace during your delivery.",
                status: .notDetermined
            ),
        ]
    }

    /// Re-reads the current authorization of every row. Called on appear and whenever the
    /// app returns to the foreground (the user may have toggled access in System Settings).
    func refresh() {
        updateStatus(microphoneStatus(), for: .microphone)
        updateStatus(speechPermissionService.authorizationStatus(), for: .speechRecognition)
        Task { await refreshAutomationStatus(promptIfNeeded: false) }
    }

    /// Single "Allow" entry point. Requests every not-yet-determined access in turn, and
    /// deep-links to System Settings for any that were previously denied.
    func requestAll() {
        guard !isRequesting else { return }
        isRequesting = true

        Task {
            await requestAutomation()
            await requestMicrophone()
            await requestSpeech()
            isRequesting = false
        }
    }

    private func requestAutomation() async {
        switch status(for: .keynoteAutomation) {
        case .authorized:
            return
        case .notDetermined:
            await refreshAutomationStatus(promptIfNeeded: true)
        case .denied:
            openSystemSettings(for: .keynoteAutomation)
        }
    }

    private func requestMicrophone() async {
        switch microphoneStatus() {
        case .authorized:
            return
        case .notDetermined:
            _ = await AVCaptureDevice.requestAccess(for: .audio)
            updateStatus(microphoneStatus(), for: .microphone)
        case .denied:
            openSystemSettings(for: .microphone)
        }
    }

    private func requestSpeech() async {
        switch speechPermissionService.authorizationStatus() {
        case .authorized:
            return
        case .notDetermined:
            let status = await speechPermissionService.requestPermission()
            updateStatus(status, for: .speechRecognition)
        case .denied:
            openSystemSettings(for: .speechRecognition)
        }
    }

    private func refreshAutomationStatus(promptIfNeeded: Bool) async {
        let state = await automationPermissionService.authorizationStatus(
            promptIfNeeded: promptIfNeeded
        )

        switch state {
        case .targetNotRunning, .keynoteUnavailable:
            // Keynote merely being closed must not downgrade a previously authorized
            // permission — keep the last-known status.
            return
        default:
            updateStatus(mapAutomationStatus(state), for: .keynoteAutomation)
        }
    }

    private func microphoneStatus() -> PermissionStatus {
        microphonePermissionService.authorizationStatus()
    }

    private func status(for type: PermissionType) -> PermissionStatus {
        rows.first { $0.type == type }?.status ?? .notDetermined
    }

    private func updateStatus(_ status: PermissionStatus, for type: PermissionType) {
        guard let index = rows.firstIndex(where: { $0.type == type }) else { return }
        rows[index].status = status
    }

    private func mapAutomationStatus(
        _ state: KeynoteAutomationPermissionState
    ) -> PermissionStatus {
        switch state {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .keynoteUnavailable, .targetNotRunning, .error:
            return .denied
        }
    }

    private func openSystemSettings(for type: PermissionType) {
        let urlString: String
        switch type {
        case .microphone:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .keynoteAutomation:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        case .speechRecognition:
            urlString =
                "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition"
        case .wpmPlaceholder:
            return
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
