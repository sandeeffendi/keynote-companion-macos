//
//  HomeView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.largeTitle)

            Button("Go To Settings") {
                router.push(.settings(.main))
            }
            
            Button("Go To Loading Screen (Dummy)") {
                router.push(.loadingScreen(.main))
            }

        }
        .padding()
        .navigationTitle("Home")
    }
}
