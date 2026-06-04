//
//  HomeRouteBuilder.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct HomeRouteBuilder {
    @ViewBuilder
    static func build(_ route: HomeRoute) -> some View {
        switch route {
        case .main:
            HomeView(viewModel: HomeViewModel())
        }
    }
}
