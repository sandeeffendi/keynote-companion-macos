//
//  TourStep.swift
//  KeynoteCompanionMacos
//
//  The five steps of the guided setup tour (Home -> Settings -> Home).
//  Each case carries its callout copy and icon. Order is the declaration order.
//

import Foundation

enum TourStep: String, CaseIterable, Identifiable, Sendable {
    case openSettings
    case micPermission
    case screenPermission
    case wpmPermission
    case backToHome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openSettings: return "Setting Up The Access"
        case .micPermission: return "Turn On Mic Access"
        case .screenPermission: return "Turn On Screen Access"
        case .wpmPermission: return "Maintain Your Speech Rate"
        case .backToHome: return "Let's Go Back to Main Screen!"
        }
    }

    var message: String {
        switch self {
        case .openSettings:
            return "Click 'Open Settings' to turn on microphone and screen access."
        case .micPermission:
            return "Tiempo would like to listen to you when you are practicing."
        case .screenPermission:
            return "Tiempo would like to see your screen when you are practicing."
        case .wpmPermission:
            return "Tiempo can remind your speech rate when you are practicing."
        case .backToHome:
            return "You just need to slideshow your Keynote before practicing."
        }
    }

    var iconSystemName: String {
        switch self {
        case .openSettings: return "hand.raised"
        case .micPermission: return AppIcon.permissionMicrophone
        case .screenPermission: return AppIcon.permissionKeynoteAutomation
        case .wpmPermission: return AppIcon.permissionWPMDetector
        case .backToHome: return "arrow.uturn.backward"
        }
    }

    /// The last step advances with a prominent "Next"; the others offer "Skip".
    var isFinalStep: Bool { self == .backToHome }

    var actionTitle: String { isFinalStep ? "Next" : "Skip" }

    /// Shape of the spotlight cut-out, matched to the highlighted control.
    var spotlightShape: SpotlightShape {
        switch self {
        case .openSettings: return .capsule
        case .backToHome: return .circle
        case .micPermission, .screenPermission, .wpmPermission: return .rounded
        }
    }

    /// Where the callout sits relative to its target (matches the UIDesign reference).
    /// The back button is at the top, so its callout drops below; everything else floats
    /// above its target.
    var calloutPlacement: CalloutPlacement {
        self == .backToHome ? .below : .above
    }
}

enum CalloutPlacement {
    /// Card above the target; beak on the card's bottom edge.
    case above
    /// Card below the target; beak on the card's top edge.
    case below
}

enum SpotlightShape {
    case capsule
    case circle
    case rounded

    /// Corner radius for a cut-out of the given size.
    func cornerRadius(for size: CGSize) -> CGFloat {
        switch self {
        case .capsule, .circle:
            return min(size.width, size.height) / 2
        case .rounded:
            return 14
        }
    }
}
