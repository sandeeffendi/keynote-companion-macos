//
//  AppRoute.swift
//  KeynoteCompanionMacos
//

import Foundation

enum AppRoute: Hashable {
    case loadingScreen(LoadingScreenRoute)
    case home(HomeRoute)
    case settings(SettingsRoute)
    case recap(RecapRoute)
}
