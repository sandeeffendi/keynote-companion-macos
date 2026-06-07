//
//  LoadingScreenRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 07/06/26.
//

import SwiftUI

struct LoadingScreenRouteBuilder {

    @ViewBuilder
    static func build(
        _ route: LoadingScreenRoute
    ) -> some View {

        switch route {

        case .main:
            LoadingScreenView(
                viewModel: LoadingScreenViewModel()
            )
        }
    }
}
