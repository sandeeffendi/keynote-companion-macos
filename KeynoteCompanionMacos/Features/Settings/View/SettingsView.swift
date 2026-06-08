//
//  SettingsView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: SettingsViewModel
#if DEBUG
    @StateObject private var onboardingViewModel = OnboardingViewModel()
#endif

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

                HStack(spacing: AppSpacing.md) {
                    Text("Settings")
                        .font(AppFont.settingHead)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer(minLength: 0)

#if DEBUG
                    resetOnboardingButton
#endif
                }
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
        .onAppear {
            viewModel.refreshAllPermissionStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshAllPermissionStatuses()
        }
    }

    private var permissionsList: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(
                    viewModel.settingsData.permissionItems
                ) { permissionItem in
                    SettingsPermissionRow(
                        icon: permissionItem.icon,
                        title: permissionItem.title,
                        description: permissionItem.description,
                        showsSeparator: permissionItem.id != viewModel.settingsData
                            .permissionItems.last?.id,
                        isOn: Binding(
                            get: {
                                viewModel.isPermissionEnabled(
                                    permissionItem.permissionType
                                )
                            },
                            set: { newValue in
                                viewModel.togglePermission(
                                    for: permissionItem.permissionType,
                                    newValue: newValue
                                )
                            }
                        )
                    )
                }
            }
        }
    }

#if DEBUG
    private var resetOnboardingButton: some View {
        Button(action: resetOnboarding) {
            Text("Reset Onboarding")
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .font(AppFont.button)
        .foregroundStyle(AppColor.controlTextPrimary)
        .padding(.horizontal, AppSpacing.md)
        .frame(height: Metrics.resetOnboardingButtonHeight)
        .contentShape(Capsule())
        .glassEffect(
            onboardingViewModel.hasCompletedOnboarding
                ? .regular.interactive() : .regular,
            in: Capsule()
        )
        .disabled(!onboardingViewModel.hasCompletedOnboarding)
        .opacity(onboardingViewModel.hasCompletedOnboarding ? 1 : 0.48)
        .accessibilityLabel("Reset onboarding")
    }

    private func resetOnboarding() {
        onboardingViewModel.resetOnboarding()
        router.requestSplashRestart()
    }
#endif

    private enum Metrics {
        static let backButtonSize: CGFloat = 36
        static let resetOnboardingButtonHeight: CGFloat = 32
    }
}

private struct SettingsPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let showsSeparator: Bool
    @Binding var isOn: Bool

    var body: some View {
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
