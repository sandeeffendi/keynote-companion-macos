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
}
