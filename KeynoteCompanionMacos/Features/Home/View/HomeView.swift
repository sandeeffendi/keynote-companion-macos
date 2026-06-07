//
//  HomeView.swift
//  KeynoteCompanionMacos
//

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

            Button("Go to Settings") {
                router.push(.settings(.main))
            }

            Button("Go to Recap Screen") {
                router.push(.recap(.main))
            }
        }
        .padding()
        .navigationTitle("Home")
        .background(
            WindowAccessor { window in

                guard let window else {
                    return
                }

                WindowManager.shared
                    .configureMainWindow(window)
            }
        )
    }
}

