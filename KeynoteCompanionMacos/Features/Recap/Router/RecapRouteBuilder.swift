//
//  RecapRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation
import SwiftUI

struct RecapRouteBuilder {
    @ViewBuilder
    static func build(_ route: RecapRoute) -> some View {
        switch route {
            case .main:
            RecapView(viewModel: RecapViewModel(), prev: .main)
            case .home:
                HomeView(viewModel: HomeViewModel())
            case .historyDetail:
                RecapView(viewModel: RecapViewModel(), prev: .main)
            case .detail:
            RecapDetailView(viewModel: RecapDetailViewModel(), prev: .detail)
        }

    }
}
