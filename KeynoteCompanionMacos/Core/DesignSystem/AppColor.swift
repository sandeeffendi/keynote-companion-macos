//
//  ColorToken.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation
import SwiftUI

// PIC: arfian
enum AppColor {
    static let textPrimary = Color.black.opacity(0.72)
    static let textSecondary = Color.black.opacity(0.48)
    static let textTertiary = Color.black.opacity(0.32)

    static let iconPrimary = Color.black.opacity(0.68)
    static let iconSecondary = Color.black.opacity(0.42)

    static let controlTextPrimary = Color.black.opacity(0.68)
    static let controlTextDisabled = Color.black.opacity(0.28)

    static let borderSubtle = Color.white.opacity(0.28)
    static let shadow = Color.black.opacity(0.14)

    static let trafficClose = Color(red: 1.00, green: 0.37, blue: 0.34)
    static let trafficMinimize = Color(red: 1.00, green: 0.75, blue: 0.18)
    static let trafficZoom = Color(red: 0.20, green: 0.80, blue: 0.34)
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
