//
//  SearchField.swift
//  KeynoteCompanionMacos
//
//  Reusable glass search field. Replaces the ad-hoc magnifying-glass + TextField
//  stacks that previously hard-coded fonts, colors, and corner radii.
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AppFont.smallIcon)
                .foregroundStyle(AppColor.iconSecondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(AppFont.recapRow)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: AppSize.searchFieldHeight)
        .glassEffect(.regular, in: Capsule())
    }
}
