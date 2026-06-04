//
//  SettingsView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

// Feature ini masih belum ada PICnya

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            //title
            Text(viewModel.settingData.title)
                .font(.largeTitle)

            //subtitle
            Text(viewModel.settingData.subTitle)
                .font(.title).bold()

            // back button
            Button("Back") {
                router.pop()
            }

        }
        .padding()
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden(true)
    }
}
