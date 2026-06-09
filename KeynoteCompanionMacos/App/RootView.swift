//
//  RootView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var onboardingViewModel = OnboardingViewModel()
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
        .onChange(of: router.shouldRestartSplash) { _, shouldRestartSplash in
            guard shouldRestartSplash else {
                return
            }

            restartSplash()
        }
    }

    private var windowWidth: CGFloat {
        if isShowingSplash {
            return AppSize.splashWindowWidth
        }

        if isShowingOnboarding {
            return AppSize.onboardingWindowWidth
        }
        
        if isShowingRecap {
            return AppSize.recapWindowWidth
        }
        
        if isShowingHistory {
            return AppSize.recapWindowWidth
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

        if isShowingRecap {
            return AppSize.recapWindowHeight
        }
        
        if isShowingHistory {
            return AppSize.recapWindowHeight
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

        onboardingViewModel.loadCompletionState()

        if onboardingViewModel.hasCompletedOnboarding {
            router.popToRoot()
        } else {
            router.replace(with: .onboarding(.main))
        }

        isShowingSplash = false
    }

    private var windowWidth: CGFloat {
        if isShowingSplash {
            return AppSize.splashWindowWidth
        }

        if isShowingOnboarding {
            return AppSize.onboardingWindowWidth
        }
        
        if isShowingRecap {
            return AppSize.recapWindowWidth
        }
        
        if isShowingHistory {
            return AppSize.recapWindowWidth
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

        if isShowingRecap {
            return AppSize.recapWindowHeight
        }
        
        if isShowingHistory {
            return AppSize.recapWindowHeight
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

        onboardingViewModel.loadCompletionState()

        if onboardingViewModel.hasCompletedOnboarding {
            router.popToRoot()
        } else {
            router.replace(with: .onboarding(.main))
        }

        isShowingSplash = false
    }

    @MainActor
    private func restartSplash() {
        router.popToRoot()
        isShowingSplash = true
        router.consumeSplashRestartRequest()
    }
    
    private var isShowingRecap: Bool {
        if case .recap = router.activeRoute {
            return true
        }
        return false
    }
    private var isShowingHistory: Bool {
        if case .history = router.activeRoute {
            return true
        }

        return false
    }
}
