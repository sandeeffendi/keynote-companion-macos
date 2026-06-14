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
        title: "Allow Screen Access",
        description: "For detecting your keynote slideshow mode",
        permissionType: .keynoteAutomation
    )

    nonisolated static let speechRecognition = PermissionItem(
        icon: AppIcon.permissionWPMDetector,
        title: "WPM Indicator",
        description: "For seeing your speech rate during practice",
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
