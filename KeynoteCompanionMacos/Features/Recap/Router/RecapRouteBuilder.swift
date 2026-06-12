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
        case .main(let recapModel):
            RecapView(isFromHistory: false, viewModel: RecapViewModel(recapData: recapModel))
        case .fromHistory(let recapModel):
            RecapView(isFromHistory: true, viewModel: RecapViewModel(recapData: recapModel))
        case .home:
            HomeView(viewModel: HomeViewModel())
        }
    }
}
