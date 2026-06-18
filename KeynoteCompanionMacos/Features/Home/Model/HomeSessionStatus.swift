//
//  HomeSessionStatus.swift
//  KeynoteCompanionMacos
//

import Foundation

enum HomeSessionStatus: Equatable, Sendable {
    case permissionMissing
    case keynoteUnavailable
    case openFileFailed
    case startSlideshowFailed
    case automationError
    case noKeynoteDocument
    case keynoteDocumentOpen
    case keynoteSlideshowActive

    var visibleState: HomeViewState {
        switch self {
        case .permissionMissing:
            return .permissionMissing
        case .keynoteUnavailable, .openFileFailed, .startSlideshowFailed, .automationError:
            return .permissionMissing
        case .noKeynoteDocument:
            return .noKeynoteFileOpen
        case .keynoteDocumentOpen:
            return .noKeynoteSlideshowActive
        case .keynoteSlideshowActive:
            return .keynoteSlideshowActive
        }
    }

    var isTechnicalFailure: Bool {
        switch self {
        case .keynoteUnavailable, .openFileFailed, .startSlideshowFailed, .automationError:
            return true
        case .permissionMissing, .noKeynoteDocument, .keynoteDocumentOpen,
                .keynoteSlideshowActive:
            return false
        }
    }

    func visibleState(preserving currentState: HomeViewState) -> HomeViewState {
        isTechnicalFailure ? currentState : visibleState
    }
}
