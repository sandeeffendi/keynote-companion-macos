//
//  SettingsRouteBuilder.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import SwiftUI

struct SettingsRouteBuilder {
    @ViewBuilder
    static func build(_ route: SettingsRoute) -> some View {
        switch route {
        case .general:
            SettingsView(
                viewModel: SettingsViewModel()
            )

        case .account:
            SettingsView(viewModel: SettingsViewModel())

        case .preference:
            SettingsView(viewModel: SettingsViewModel())
        }

    }
}
