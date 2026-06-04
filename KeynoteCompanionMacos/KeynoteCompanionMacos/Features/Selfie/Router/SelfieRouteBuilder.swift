//
//  SelfieRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 04/06/26.
//

import SwiftUI

struct SelfieRouteBuilder {
    @ViewBuilder
    static func build(_ route: SelfieRoute) -> some View {
        switch route {
        case .selfie:
            SelfieView(
                viewModel: SelfieViewModel()
            )
        }
    }
}
