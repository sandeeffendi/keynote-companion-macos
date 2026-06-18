//
//  ColorToken.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import AppKit
import SwiftUI

// PIC: arfian
enum AppColor {
    // text app color
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    // icon app color
    static let iconPrimary = Color.primary
    static let iconSecondary = Color.secondary

    // control app color
    static let controlTextPrimary = Color.primary
    static let controlTextDisabled = Color(nsColor: .disabledControlTextColor)
    static let controlAccent = Color(nsColor: .systemBlue)
    static let onControlAccent = Color(light: .white, dark: .white)
    static let destructive = Color(nsColor: .systemRed)

    // aditional color
    static let borderSubtle = Color(
        light: NSColor.white.withAlphaComponent(0.28),
        dark: NSColor.white.withAlphaComponent(0.12)
    )
    static let separator = Color(nsColor: .separatorColor)
    static let shadow = Color.black.opacity(0.14)  // shadows stay black in both modes

    static let cardSurface = Color(nsColor: .windowBackgroundColor)
    static let scrim = Color.black.opacity(0.42)  // dimming scrim is black in both modes
    static let spotlightRing = Color.white.opacity(0.5)  // ring sits on the dimmed scrim
    static let permissionGranted = Color(nsColor: .systemGreen)

    // Traffic light dots mirror macOS brand colors — identical in light & dark.
    static let trafficClose = Color(red: 1.00, green: 0.37, blue: 0.34)
    static let trafficMinimize = Color(red: 1.00, green: 0.75, blue: 0.18)
    static let trafficZoom = Color(red: 0.20, green: 0.80, blue: 0.34)
    static let trafficSymbol = Color.black.opacity(0.58)

    // wpm indicator color
    static let wpmSlow = Color(nsColor: .systemYellow)  // < 90 WPM
    static let wpmGood = Color(nsColor: .systemGreen)  // 90–120 WPM
    static let wpmFast = Color(nsColor: .systemRed)  // > 120 WPM
}

extension Color {
    init(light: NSColor, dark: NSColor) {
        self.init(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? dark : light
            }
        )
    }
}
