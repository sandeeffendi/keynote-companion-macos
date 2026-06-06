//
//  PermissionItem.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 06/06/26.
//

import SwiftUI

extension PermissionItem {
    static let microphone = PermissionItem(
        icon: AppIcon.permissionMicrophone,
        title: "Allow Microphone Access",
        description: "For recording your sound"
    )

    static let screen = PermissionItem(
        icon: AppIcon.permissionScreen,
        title: "Allow Screen Access",
        description: "For detecting your keynote slideshow mode"
    )

    static let wpmDetector = PermissionItem(
        icon: AppIcon.permissionWPMDetector,
        title: "WPM Detector",
        description: "For detecting your speech rate, if needed"
    )
}
