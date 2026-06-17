//
//  ColorToken.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import AppKit
import SwiftUI

// PIC: arfian
//
// Monochrome, system-adaptive palette. Prefer Apple semantic colors (label /
// secondaryLabel / separator / windowBackground …) so the UI follows the user's
// macOS appearance automatically. Use the `Color(light:dark:)` helper only where
// no semantic color expresses the intent (translucent glass rims, overlays).
enum AppColor {
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    static let iconPrimary = Color.primary
    static let iconSecondary = Color.secondary

    static let controlTextPrimary = Color.primary
    static let controlTextDisabled = Color(nsColor: .disabledControlTextColor)

    // Blue accent for prominent (primary) controls — identical in light & dark so the
    // CTA reads as a brand-blue pill against the clear glass window surface. Native
    // `.buttonStyle(.glassProminent)` derives the contrasting label automatically; for
    // the manually-tinted glass used by `PillButton` (which preserves exact pill metrics)
    // pair it with `onControlAccent` for the label. `onControlAccent` is white in both
    // appearances because the label always sits on blue glass.
    static let controlAccent = Color(nsColor: .systemBlue)
    static let onControlAccent = Color(light: .white, dark: .white)

    // Subtle highlight rim on glass surfaces — a light hairline in both modes,
    // softened in dark so it doesn't glare.
    static let borderSubtle = Color(light: NSColor.white.withAlphaComponent(0.28),
                                    dark: NSColor.white.withAlphaComponent(0.12))
    static let separator = Color(nsColor: .separatorColor)
    static let shadow = Color.black.opacity(0.14) // shadows stay black in both modes

    static let cardSurface = Color(nsColor: .windowBackgroundColor)
    static let scrim = Color.black.opacity(0.42)        // dimming scrim is black in both modes
    static let spotlightRing = Color.white.opacity(0.5) // ring sits on the dimmed scrim
    static let permissionGranted = Color(nsColor: .systemGreen)

    // Traffic-light dots mirror macOS brand colors — identical in light & dark.
    static let trafficClose = Color(red: 1.00, green: 0.37, blue: 0.34)
    static let trafficMinimize = Color(red: 1.00, green: 0.75, blue: 0.18)
    static let trafficZoom = Color(red: 0.20, green: 0.80, blue: 0.34)
    static let trafficSymbol = Color.black.opacity(0.58)

    static let wpmSlow = Color(nsColor: .systemYellow)  // < 90 WPM
    static let wpmGood = Color(nsColor: .systemGreen)   // 90–120 WPM
    static let wpmFast = Color(nsColor: .systemRed)     // > 120 WPM
}

extension Color {
    /// Builds an appearance-adaptive color from explicit light/dark `NSColor`s.
    /// Used for translucent surfaces that have no matching semantic system color.
    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
