//
//  AppRoute.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation

enum AppRoute: Hashable {
    case home(HomeRoute)
    case settings(SettingsRoute)
    case session(SessionRoute)
    case recap(RecapRoute)
    case loadingScreen(LoadingScreenRoute)
    case history(HistoryRoute)
}
