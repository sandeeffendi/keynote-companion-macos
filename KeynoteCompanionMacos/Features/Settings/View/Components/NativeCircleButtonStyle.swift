//
//  PillButton.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 06/06/26.
//

import SwiftUI

struct NativeCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NativeCircleButtonStyle {
    static var nativeCircle: NativeCircleButtonStyle {
        NativeCircleButtonStyle()
    }
}
