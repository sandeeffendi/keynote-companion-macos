//
//  LoadingScreenView.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 07/06/26.
//

import SwiftUI

struct LoadingScreenView: View {

    @EnvironmentObject private var router: AppRouter

    @StateObject private var viewModel: LoadingScreenViewModel

    init(viewModel: LoadingScreenViewModel) {
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                Text("TIEMPO.")
                    .font(
                        .system(
                            size: 25,
                            weight: .semibold
                        )
                    )
                    .tracking(6)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )

                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(1.5)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.75
                    )
            }
        }
        .frame(
            width: 300,
            height: 400
        )
        .background(
            WindowAccessor { window in

                guard let window else {
                    return
                }

                WindowManager.shared
                    .configureSplashWindow(window)
            }
        )
        .task {

            try? await Task.sleep(
                for: .seconds(3)
            )

            router.replace(
                with: .home(.main)
            )
        }
    }
}

#Preview {
    LoadingScreenView(
        viewModel: LoadingScreenViewModel()
    )
}
