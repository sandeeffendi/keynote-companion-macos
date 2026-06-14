//
//  HistoryRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import Foundation
import SwiftUI

struct HistoryRouteBuilder {
    @ViewBuilder
    static func build(_ route: HistoryRoute) -> some View {

        switch route {
        case .main:
            HistoryView()
        case .home:
            HomeView(viewModel: HomeViewModel())
        case .historyDetail:
            RecapView(viewModel: RecapViewModel())
        }

    }
}
