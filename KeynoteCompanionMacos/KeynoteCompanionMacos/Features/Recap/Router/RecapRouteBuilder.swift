//
//  RecapRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 03/06/26.
//

import Foundation
import SwiftUI

struct RecapRouteBuilder {
    @ViewBuilder

    static func build(_ route: RecapRoute) -> some View {
        switch route {
        case .biawak:
            RecapView(
                viewModel: RecapViewModel()
            )
        }
    }
}
