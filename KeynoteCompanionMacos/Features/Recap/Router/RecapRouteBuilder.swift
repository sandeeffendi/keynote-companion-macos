//
//  RecapRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import SwiftUI

struct RecapRouteBuilder {
    @ViewBuilder
    static func build(_ route: RecapRoute) -> some View {
        switch route {
        case .main:
            RecapView(isFromHistory: false, viewModel: RecapViewModel())
        case .fromHistory:
            RecapView(isFromHistory: true, viewModel: RecapViewModel())
        case .home:
            HomeView(viewModel: HomeViewModel())
        }
    }
}
