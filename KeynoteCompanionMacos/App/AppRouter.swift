//
//  AppRouter.swift
//  KeynoteCompanionMacos
//

import Combine
import SwiftUI

final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var shouldRestartSplash = false

    var activeRoute: AppRoute? {
        path.last
    }

    var isShowingHomeRoute: Bool {
        AppRoute.isHomeRoute(activeRoute)
    }

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func replace(with route: AppRoute) {
        path.removeLast(path.count)
        path.append(route)
    }

    func requestSplashRestart() {
        shouldRestartSplash = true
    }

    func consumeSplashRestartRequest() {
        shouldRestartSplash = false
    }
}
