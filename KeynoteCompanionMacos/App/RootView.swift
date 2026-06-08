//
//  RootView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
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
        isShowingSplash
            ? AppSize.splashWindowWidth
            : AppSize.homeWindowWidth
    }

    private var windowHeight: CGFloat {
        isShowingSplash
            ? AppSize.splashWindowHeight
            : AppSize.homeWindowHeight
    }

    @MainActor
    private func showHome() {
        guard isShowingSplash else {
            return
        }

        router.popToRoot()
        isShowingSplash = false
    }
}
