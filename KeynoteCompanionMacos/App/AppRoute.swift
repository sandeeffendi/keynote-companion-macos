//
//  AppRoute.swift
//  KeynoteCompanionMacos
//

import Foundation

enum AppRoute: Hashable {
    case home(HomeRoute)
    case settings(SettingsRoute)
    case recap(RecapRoute)
    case history(HistoryRoute)
    case onboarding(OnboardingRoute)
}

extension AppRoute {
    static func isHomeRoute(_ route: AppRoute?) -> Bool {
        guard let route else {
            return true
        }

        if case .home = route {
            return true
        }

        return false
    }
}
