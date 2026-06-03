//
//  AppRouterBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct AppRouteBuilder {
    @ViewBuilder
    static func build(_ route: AppRoute) -> some View {
        switch route {
        case .home(let homeRoute):
            HomeRouteBuilder.build(homeRoute)

        case .settings(let settingsRoute):
            SettingsRouteBuilder.build(settingsRoute)

        case .session(let sessionRoute):
            SessionRouteBuilder.build(sessionRoute)
            
        case .recap(let recapRoute):
            RecapRouteBuilder.build(recapRoute)
        }
    }
}
