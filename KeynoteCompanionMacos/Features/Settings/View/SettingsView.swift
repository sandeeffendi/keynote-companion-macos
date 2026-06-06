//
//  SettingsView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WindowHeaderView(title: "Tiempo")

            VStack(alignment: .leading, spacing: 0) {
                IconCircleButton(
                    systemName: "chevron.left",
                    size: Metrics.backButtonSize
                ) {
                    router.popToRoot()
                }

                Text("Settings")
                    .font(AppFont.settingHead)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, AppSpacing.md)

                permissionsList
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.top, AppSpacing.sm)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .frame(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
    }

    private var permissionsList: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(
                    viewModel.settingsData.permissionItems.indices,
                    id: \.self
                ) { index in
                    let permissionItem = viewModel.settingsData.permissionItems[
                        index
                    ]

                    SettingsPermissionRow(
                        icon: permissionItem.icon,
                        title: permissionItem.title,
                        description: permissionItem.description,
                        isHighlighted: false,
                        showsSeparator: index < viewModel.settingsData
                            .permissionItems.count - 1,
                        isOn: $viewModel.settingsData.permissionItems[index]
                            .isEnabled
                    )
                }
            }
        }
    }

    private enum Metrics {
        static let backButtonSize: CGFloat = 36
    }
}

private struct SettingsPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isHighlighted: Bool
    let showsSeparator: Bool
    @Binding var isOn: Bool

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        if isHighlighted {
            rowContent
                .glassEffect(.regular, in: shape)
                .overlay {
                    shape.stroke(AppColor.borderSubtle, lineWidth: 1)
                }
        } else {
            rowContent
                .overlay(alignment: .bottom) {
                    if showsSeparator {
                        Rectangle()
                            .fill(AppColor.separator)
                            .frame(height: 1)
                            .padding(.leading, Metrics.separatorLeadingPadding)
                    }
                }
        }
    }

    private var rowContent: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(AppFont.sizeIcon)
                .foregroundStyle(AppColor.iconPrimary)
                .frame(width: Metrics.iconWidth)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.settingTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(description)
                    .font(AppFont.settingDescription)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.md)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: Metrics.rowHeight)
        .contentShape(Rectangle())
    }

    private enum Metrics {
        static let rowHeight: CGFloat = 72
        static let cornerRadius: CGFloat = 8
        static let iconWidth: CGFloat = 36
        static let separatorLeadingPadding: CGFloat = 68
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
            .environmentObject(AppRouter())
    }
}
