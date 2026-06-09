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


//feedback dina
extension Color { //konvert hexcode rgb
    init(hex: String) {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
            default:
                (r, g, b) = (1, 1, 1)
            }
            self.init(.displayP3, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
        }
}
extension ShapeStyle where Self == Color {
    static var cBtnSecondary: Color {
        Color(hex: "767680")
    }
    static var cBtnPrimary: Color {
        Color(hex: "000000")
    }
}
