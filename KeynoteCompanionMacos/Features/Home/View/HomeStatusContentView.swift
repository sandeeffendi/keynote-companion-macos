//
//  HomeStatusContentView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation
import SwiftUI

struct HomeStatusContentView: View {
    let state: HomeViewState
    let errorMessage: String?
    let onPrimaryAction: (HomeStatusAction) -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            statusIcon

            VStack(spacing: AppSpacing.sm) {
                Text(state.title)
                    .font(AppFont.statusTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(state.subtitle)
                    .font(AppFont.statusSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: AppSize.statusContentWidth)
            }

            if let action = state.primaryAction,
               let title = state.primaryActionTitle {
                PillButton(
                    title: title,
                    role: .primary
                ) {
                    onPrimaryAction(action)
                }
                .padding(.top, AppSpacing.xs)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.settingDescription)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: AppSize.statusContentWidth)
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let iconName = state.iconName {
            Image(systemName: iconName)
                .font(AppFont.icon)
                .foregroundStyle(AppColor.iconPrimary)
                .frame(
                    width: AppSize.iconCircleSize,
                    height: AppSize.iconCircleSize
                )
        }
    }
}
