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

    nonisolated static let screen = PermissionItem(
        icon: AppIcon.permissionScreen,
        title: "Allow Screen Access",
        description: "For detecting your keynote slideshow mode",
        permissionType: .screenPlaceholder
    )

    nonisolated static let wpmDetector = PermissionItem(
        icon: AppIcon.permissionWPMDetector,
        title: "WPM Detector",
        description: "For detecting your speech rate, if needed",
        permissionType: .wpmPlaceholder
    )
}

enum PermissionType: Sendable {
    case microphone
    case screenPlaceholder
    case wpmPlaceholder
}

enum PermissionStatus: Sendable {
    case notDetermined
    case authorized
    case denied
}
