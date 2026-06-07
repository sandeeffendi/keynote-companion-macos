//
//  IconCircleButton.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct IconCircleButton: View {
    let systemName: String
    var size: CGFloat = AppSize.headerIconButtonSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppFont.smallIcon)
                .foregroundStyle(AppColor.iconSecondary)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
    }
}
