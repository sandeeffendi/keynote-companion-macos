//
//  WindowHeaderView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct WindowHeaderView<TrailingAccessory: View>: View {
    let title: String
    private let trailingAccessory: TrailingAccessory

    init(
        title: String,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory
    ) {
        self.title = title
        self.trailingAccessory = trailingAccessory()
    }

    var body: some View {
        HStack(spacing: 0) {
            WindowTrafficLightControlsView()

            Text(title)
                .font(AppFont.windowTitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.leading, AppSpacing.md)

            Spacer(minLength: 0)

            trailingAccessory
        }
        .frame(height: AppSize.headerHeight)
    }
}
