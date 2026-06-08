//
//  OnboardingRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 08/06/26.
//

import SwiftUI

struct OnboardingRouteBuilder {
    @ViewBuilder
    static func build(_ route: OnboardingRoute) -> some View {
        switch route {
        case .main:
            OnboardingView(viewModel: OnboardingViewModel())
        }
    }
}
