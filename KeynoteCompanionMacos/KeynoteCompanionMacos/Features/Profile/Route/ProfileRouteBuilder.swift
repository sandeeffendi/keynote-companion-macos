//
//  ProfileRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import SwiftUI

struct ProfileRouteBuilder {
    @ViewBuilder
    static func build(_ route: ProfileRoute) -> some View {
        switch route {
        case .main:
            ProfileView(viewModel: ProfileViewModel())
        }
    }
}
