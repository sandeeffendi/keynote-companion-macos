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
                "Allow microphone and Keynote Automation access to record your voice and detect your slideshow"
        case .noKeynoteFileOpen:
            return "Open a keynote file that you want to present"
        case .noKeynoteSlideshowActive:
            return "Start to slideshow a keynote"
        case .keynoteSlideshowActive:
            return "Click 'Record Practice' to start practicing"
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

    var iconText: String? {
        switch self {
        case .noKeynoteFileOpen:
            return "!!!"
        case .noKeynoteSlideshowActive:
            return "!!"
        case .permissionMissing, .keynoteSlideshowActive:
            return nil
        }
    }

    var showsOpenKeynoteButton: Bool {
        switch self {
        case .noKeynoteFileOpen:
            return true
        case .permissionMissing, .noKeynoteSlideshowActive,
            .keynoteSlideshowActive:
            return false
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
}
