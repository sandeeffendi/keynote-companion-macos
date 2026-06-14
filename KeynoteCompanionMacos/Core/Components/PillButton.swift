//
//  PillButton.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import SwiftUI

enum PillButtonRole {
    case secondary
    case primary
}

struct PillButton: View {
    let title: String
    var systemImage: String?
    var role: PillButtonRole = .secondary
    var isFullWidth: Bool = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AppFont.smallIcon)
                }

                Text(title)
                    .font(
                        role == .primary
                        ? AppFont.primaryButton : AppFont.button
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(
                isEnabled
                ? AppColor.controlTextPrimary : AppColor.controlTextDisabled
            )
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(
                height: role == .primary
                ? AppSize.mainCTAHeight : AppSize.footerButtonHeight
            )
            .padding(
                .horizontal,
                role == .primary ? AppSpacing.xl : AppSpacing.lg
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(
            isEnabled ? .regular.interactive() : .regular,
            in: Capsule()
        )
        .opacity(isEnabled ? 1 : 0.48)
    }
}
