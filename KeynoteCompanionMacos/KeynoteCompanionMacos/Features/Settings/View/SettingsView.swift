//
//  SettingsView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.largeTitle)

            Button("Back") {
                router.pop()
            }
        }
        .padding()
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden(true)
    }
}
