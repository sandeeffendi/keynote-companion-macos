//
//  SettingsRouteBuilder.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct SettingsRouteBuilder {
    @ViewBuilder
    static func build(_ route: SettingsRoute) -> some View {
        switch route {
        case .main:
            SettingsView(viewModel: SettingsViewModel())
        }
    }
}
