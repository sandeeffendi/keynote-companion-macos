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
        VStack(spacing: 0) {
            HomeHeaderView {
                viewModel.showHelp()
            }

            Spacer(minLength: 0)

            HomeStatusContentView(
                state: viewModel.state,
                errorMessage: viewModel.errorMessage,
                onOpenKeynoteFileTapped: viewModel.openKeynoteFile
            )

            Spacer(minLength: 0)

            HomeFooterView(
                isRecordEnabled: viewModel.state.isRecordEnabled,
                onOpenSettingsTapped: openSettings,
                onActivitiesTapped: showRecap,
                onRecordPracticeTapped: showRecap
            )
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .frame(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
        .background(Color.clear)
        .task {
            await viewModel.observeSession()
        }.navigationBarBackButtonHidden()
    }

    private func openSettings() {
        viewModel.openSettings()
        router.push(.settings(.main))
    }

    private func showActivities() {
        viewModel.showActivities()
        router.push(.history(.main))
    }
    
    private func showRecap() {
        viewModel.showRecap()
        router.push(.recap(.main))
    }
}
