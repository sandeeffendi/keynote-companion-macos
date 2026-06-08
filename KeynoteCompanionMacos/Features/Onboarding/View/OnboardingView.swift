//
//  Onboarding.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 08/06/26.
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject private var route: AppRouter
    @AppStorage(OnboardingDefaults.hasCompletedOnboardingKey)
    private var hasCompletedOnboarding = false
    private let features: [OnboardingFeature] = [
        .speechRate,
        .fillerWords,
        .insights,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TIEMPO.")
                .font(AppFont.onboardingLogo)
                .foregroundStyle(AppColor.textPrimary)
                .tracking(6)
                .accessibilityLabel("Tiempo")

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Welcome")
                    .font(AppFont.onboardingTitle)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Tiempo helps you stay prepared for public speaking.")
                    .font(AppFont.onboardingSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Metrics.titleTopPadding)

            VStack(alignment: .leading, spacing: Metrics.featureSpacing) {
                ForEach(features) { feature in
                    OnboardingFeatureRow(feature: feature)
                }
            }
            .padding(.top, Metrics.featuresTopPadding)

            Spacer(minLength: 0)

            PillButton(title: "Continue", role: .primary) {
                completeOnboarding()
            }
            .frame(width: Metrics.ctaWidth)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, Metrics.topPadding)
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.bottom, Metrics.bottomPadding)
        .frame(
            width: AppSize.onboardingWindowWidth,
            height: AppSize.onboardingWindowHeight
        )
        .background(Color.clear)
        .navigationBarBackButtonHidden(true)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        route.popToRoot()
    }

    private enum Metrics {
        static let topPadding: CGFloat = 52
        static let horizontalPadding: CGFloat = 52
        static let bottomPadding: CGFloat = 51
        static let titleTopPadding: CGFloat = 36
        static let featuresTopPadding: CGFloat = 40
        static let featureSpacing: CGFloat = 20
        static let ctaWidth: CGFloat = 162
    }
}

private struct OnboardingFeatureRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.contentSpacing) {
            Image(systemName: feature.icon)
                .font(Metrics.iconFont)
                .foregroundStyle(AppColor.iconPrimary)
                .frame(width: Metrics.iconWidth, height: Metrics.iconHeight)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(feature.title)
                    .font(AppFont.onboardingFeatureTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(feature.description)
                    .font(AppFont.onboardingFeatureDescription)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private enum Metrics {
        static let contentSpacing: CGFloat = 12
        static let iconWidth: CGFloat = 24
        static let iconHeight: CGFloat = 24
        static let iconFont = Font.system(
            size: 24,
            weight: .regular,
            design: .default
        )
    }
}


