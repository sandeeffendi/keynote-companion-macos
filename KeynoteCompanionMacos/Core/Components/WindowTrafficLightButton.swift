//
//  WindowTrafficLightButton.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct WindowTrafficLightButton: View {
    let color: Color
    let systemName: String
    let showsSymbol: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)

                Image(systemName: systemName)
                    .font(AppFont.trafficLightSymbol)
                    .foregroundStyle(AppColor.trafficSymbol)
                    .opacity(showsSymbol ? 1 : 0)
            }
            .frame(
                width: AppSize.trafficLightSize,
                height: AppSize.trafficLightSize
            )
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
