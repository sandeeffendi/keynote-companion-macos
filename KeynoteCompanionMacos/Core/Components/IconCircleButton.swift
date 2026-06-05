//
//  GlassPanelView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import SwiftUI

struct IconCircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppFont.smallIcon)
                .foregroundStyle(AppColor.iconSecondary)
                .frame(
                    width: AppSize.headerIconButtonSize,
                    height: AppSize.headerIconButtonSize
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
    }
}
