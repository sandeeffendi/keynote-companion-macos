//
//  HomeViewState.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation
import SwiftUI

enum HomeViewState: CaseIterable {
    case permissionMissing
    case noKeynoteFileOpen
    case noKeynoteSlideshowActive
    case keynoteSlideshowActive
}

/// The single call-to-action surfaced in the center of each home state.
/// `nil` means the state has no button (the user must act in Keynote itself).
enum HomeStatusAction {
    case openPermissions
    case openKeynoteFile
    case recordPractice
}

extension HomeViewState {
    var title: String {
        switch self {
        case .permissionMissing:
            return "Permissions Missing"
        case .noKeynoteFileOpen:
            return "No Keynote File Open"
        case .noKeynoteSlideshowActive:
            return "No Keynote Slideshow Active"
        case .keynoteSlideshowActive:
            return "Keynote Slideshow Active"
        }
    }

    var subtitle: String {
        switch self {
        case .permissionMissing:
            return
                "Click 'Open Permissions' to grant Microphone, Speech, and Keynote access to track your presentation practice."
        case .noKeynoteFileOpen:
            return
                "Click 'Open Keynote File' to open a keynote file that you want to present."
        case .noKeynoteSlideshowActive:
            return "Start to slideshow a keynote."
        case .keynoteSlideshowActive:
            return "Click 'Record Practice' to start practicing."
        }
    }

    var iconName: String? {
        switch self {
        case .permissionMissing:
            return AppIcon.permissionMissing
        case .keynoteSlideshowActive:
            return AppIcon.keynoteSlideshowActive
        case .noKeynoteFileOpen:
            return AppIcon.noKeynoteFileOpen
        case .noKeynoteSlideshowActive:
            return AppIcon.noKeynoteSlideshowActive
        }
    }

    var primaryAction: HomeStatusAction? {
        switch self {
        case .permissionMissing:
            return .openPermissions
        case .noKeynoteFileOpen:
            return .openKeynoteFile
        case .noKeynoteSlideshowActive:
            return nil
        case .keynoteSlideshowActive:
            return .recordPractice
        }
    }

    var primaryActionTitle: String? {
        switch primaryAction {
        case .openPermissions:
            return "Open Permissions"
        case .openKeynoteFile:
            return "Open Keynote File"
        case .recordPractice:
            return "Record Practice"
        case .none:
            return nil
        }
    }

    var isRecordEnabled: Bool {
        switch self {
        case .keynoteSlideshowActive:
            return true
        case .permissionMissing, .noKeynoteFileOpen, .noKeynoteSlideshowActive:
            return false
        }
    }

    var isKeynoteOverlayActive: Bool {
        switch self {
        case .keynoteSlideshowActive:
            return true
        case .permissionMissing, .noKeynoteFileOpen, .noKeynoteSlideshowActive:
            return false
        }
    }

    /// Once Keynote is involved it tends to come frontmost (opening a file launches
    /// Keynote, and the in-app file picker hands focus back to it). Float the Tiempo
    /// window above other apps for these states so the user never loses it behind Keynote.
    var shouldFloatAboveOtherApps: Bool {
        switch self {
        case .noKeynoteFileOpen, .noKeynoteSlideshowActive:
            return true
        case .permissionMissing, .keynoteSlideshowActive:
            return false
        }
    }
}
