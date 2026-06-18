//
//  RadiusToken.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation

//Dina
extension CGFloat {
    // Buttons
    static let btnCircle: CGFloat = 100
    static let btnNonCircle: CGFloat = 24

    // Card
    static let card: CGFloat = 8
    static let bgFeedback: CGFloat = 16
}

//sande
// App size token
enum AppSize {
    // splash/loading screen radius
    static let splashWindowWidth: CGFloat = 300
    static let splashWindowHeight: CGFloat = 400

    // main window radius
    static let homeWindowWidth: CGFloat = 560
    static let homeWindowHeight: CGFloat = 374

    // onboarding window size
    static let onboardingWindowWidth: CGFloat = 560
    static let onboardingWindowHeight: CGFloat = 586

    // component size related
    static let headerHeight: CGFloat = 32
    static let trafficLightSize: CGFloat = 12
    static let iconCircleSize: CGFloat = 64
    static let headerIconButtonSize: CGFloat = 28
    static let searchFieldHeight: CGFloat = 36
    static let statusContentWidth: CGFloat = 360
    static let footerHeight: CGFloat = 38
    static let footerSeparatorWidth: CGFloat = 1
    static let footerSeparatorHeight: CGFloat = 16
    static let footerButtonHeight: CGFloat = 38
    static let mainCTAHeight: CGFloat = 40

    // recap window size
    static let recapWindowWidth: CGFloat = 560
    static let recapWindowHeight: CGFloat = 732

    // practice overlay size
    static let practiceOverlayWidth: CGFloat = 172
    static let practiceOverlayHeight: CGFloat = 205

    // practice overlay button size
    static let practiceOverlayPulseSize: CGFloat = 60
    static let practiceOverlayButtonSize: CGFloat = 36
}

// App radius token
enum AppRadius {
    static let window: CGFloat = 28
    static let card: CGFloat = 24
    static let button: CGFloat = 999
    static let iconCircle: CGFloat = 999
}
