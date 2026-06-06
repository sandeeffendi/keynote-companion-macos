//
//  HomeFooterView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import SwiftUI

struct HomeFooterView: View {
    let isRecordEnabled: Bool

    let onOpenSettingsTapped: () -> Void
    let onActivitiesTapped: () -> Void
    let onRecordPracticeTapped: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            footerAction(
                title: "Open Settings",
                action: onOpenSettingsTapped
            )

            Rectangle()
                .fill(AppColor.separator)
                .frame(
                    width: AppSize.footerSeparatorWidth,
                    height: AppSize.footerSeparatorHeight
                )

            footerAction(
                title: "Activities",
                action: onActivitiesTapped
            )

            Spacer(minLength: 0)

            PillButton(
                title: "Record Practice",
                role: .primary,
                action: onRecordPracticeTapped
            )
            .disabled(!isRecordEnabled)
        }
        .frame(height: AppSize.footerHeight)
    }

    private func footerAction(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.button)
                .foregroundStyle(AppColor.controlTextPrimary)
                .lineLimit(1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
