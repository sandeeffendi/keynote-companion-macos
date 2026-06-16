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

/// Capsule call-to-action on Liquid Glass.
/// - `.primary`   → glass tinted monochrome (`AppColor.controlAccent`) so it reads as a
///   prominent dark/light pill against the clear glass window surface, with a contrasting
///   `onControlAccent` label.
/// - `.secondary` → plain translucent glass.
///
/// Uses `.glassEffect(in: Capsule())` rather than `.buttonStyle(.glassProminent)` on purpose:
/// the explicit Capsule shape keeps the exact pill metrics (`mainCTAHeight`/`footerButtonHeight`,
/// padding) intact, which the native prominent style would otherwise resize.
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
            .foregroundStyle(foregroundColor)
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
            isEnabled
            ? (role == .primary
               ? .regular.tint(AppColor.controlAccent).interactive()
               : .regular.interactive())
            : (role == .primary
               ? .regular.tint(AppColor.controlAccent)
               : .regular),
            in: Capsule()
        )
        .opacity(isEnabled ? 1 : 0.48)
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return AppColor.onControlAccent
        case .secondary:
            return isEnabled ? AppColor.controlTextPrimary : AppColor.controlTextDisabled
        }
    }
}
