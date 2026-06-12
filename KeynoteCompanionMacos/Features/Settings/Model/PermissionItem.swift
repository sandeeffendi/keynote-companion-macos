//
//  PermissionItem.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 06/06/26.
//

extension PermissionItem {
    nonisolated static let microphone = PermissionItem(
        icon: AppIcon.permissionMicrophone,
        title: "Allow Microphone Access",
        description: "For recording your sound",
        permissionType: .microphone
    )

    nonisolated static let keynoteAutomation = PermissionItem(
        icon: AppIcon.permissionKeynoteAutomation,
        title: "Allow Keynote Automation",
        description: "For detecting your Keynote slideshow mode",
        permissionType: .keynoteAutomation
    )

    nonisolated static let wpmDetector = PermissionItem(
        icon: AppIcon.permissionWPMDetector,
        title: "WPM Detector",
        description: "For detecting your speech rate, if needed",
        permissionType: .wpmPlaceholder
    )

    nonisolated static let speechRecognition = PermissionItem(
        icon: AppIcon.permissionWPMDetector,
        title: "Allow Speech Recognition",
        description: "For measuring your live words-per-minute",
        permissionType: .speechRecognition
    )
}

enum PermissionType: Sendable {
    case microphone
    case keynoteAutomation
    case speechRecognition
    case wpmPlaceholder
}

enum PermissionStatus: Sendable {
    case notDetermined
    case authorized
    case denied
}
