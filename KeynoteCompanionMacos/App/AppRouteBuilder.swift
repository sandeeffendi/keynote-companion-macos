//
//  AppRouteBuilder.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct AppRouteBuilder {
    @ViewBuilder
    static func build(_ route: AppRoute) -> some View {
        switch route {
        case .home(let homeRoute):
            HomeRouteBuilder.build(homeRoute)

        case .settings(let settingsRoute):
            SettingsRouteBuilder.build(settingsRoute)

        case .recap(let recapRoute):
            RecapRouteBuilder.build(recapRoute)
        }

    }
}
