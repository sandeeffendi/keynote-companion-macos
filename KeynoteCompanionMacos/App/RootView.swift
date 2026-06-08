//
//  RootView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @AppStorage(OnboardingDefaults.hasCompletedOnboardingKey)
    private var hasCompletedOnboarding = false
    @State private var isShowingSplash = true

    var body: some View {
        AppWindowSurface(
            width: windowWidth,
            height: windowHeight
        ) {
            if isShowingSplash {
                LoadingScreenView(
                    onFinished: showHome
                )
            } else {
                NavigationStack(path: $router.path) {
                    HomeRouteBuilder.build(.main)
                        .navigationDestination(
                            for: AppRoute.self
                        ) { route in
                            AppRouteBuilder.build(route)
                        }
                }
            }
        }
    }

    private var windowWidth: CGFloat {
        if isShowingSplash {
            return AppSize.splashWindowWidth
        }

        if isShowingOnboarding {
            return AppSize.onboardingWindowWidth
        }

        return AppSize.homeWindowWidth
    }

    private var windowHeight: CGFloat {
        if isShowingSplash {
            return AppSize.splashWindowHeight
        }

        if isShowingOnboarding {
            return AppSize.onboardingWindowHeight
        }

        return AppSize.homeWindowHeight
    }

    private var isShowingOnboarding: Bool {
        if case .onboarding = router.activeRoute {
            return true
        }

        return false
    }

    @MainActor
    private func showHome() {
        guard isShowingSplash else {
            return
        }

        if hasCompletedOnboarding {
            router.popToRoot()
        } else {
            router.replace(with: .onboarding(.main))
        }

        isShowingSplash = false
    }
}
