//
//  HomeRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import SwiftUI

struct HomeRouteBuilder {
    @ViewBuilder
    static func build(_ route: HomeRoute) -> some View {
        switch route {
            case .main:
            HomeView(
                viewModel: HomeViewModel()
            )
        }
    }
}
