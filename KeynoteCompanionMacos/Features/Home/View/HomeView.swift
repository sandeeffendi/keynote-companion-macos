//
//  HomeView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var tourController: TourController
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var practiceViewModel = PracticeViewModel()

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        homeContent
            .background(
                SlideshowOverlayWindowPresenter(
                    isActive: shouldShowSlideshowOverlay,
                    size: CGSize(
                        width: AppSize.homeWindowWidth,
                        height: AppSize.homeWindowHeight
                    )
                ) {
                    if practiceViewModel.isRecording {
                        PracticeOverlayView(viewModel: practiceViewModel)
                    } else {
                        AppWindowSurface(
                            width: AppSize.homeWindowWidth,
                            height: AppSize.homeWindowHeight
                        ) {
                            homeContent
                        }
                    }
                }
            )
            .task {
                await viewModel.observeSession()
            }
            .navigationBarBackButtonHidden()
            .onAppear {
                practiceViewModel.onSessionFinished = { [weak router] result in
                    let recapModel = result.toRecapModel()
                    router?.push(.recap(.main(recapModel)))
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if practiceViewModel.isRecording && newState != .keynoteSlideshowActive {
                    practiceViewModel.stop()
                }
            }
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            HomeHeaderView {
                viewModel.showHelp()
                tourController.start()
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
                onActivitiesTapped: showActivities,
                onRecordPracticeTapped: startRecording
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
    }

    private var shouldShowSlideshowOverlay: Bool {
        viewModel.state.isKeynoteOverlayActive && router.isShowingHomeRoute
    }

    private func openSettings() {
        viewModel.openSettings()
        tourController.complete(.openSettings)
        router.push(.settings(.main))
    }

    private func showActivities() {
        viewModel.showActivities()
        router.push(.history(.main))
    }

    private func startRecording() {
        let fileName = viewModel.currentDocumentName
        Task {
            await practiceViewModel.startSession(keynoteFileName: fileName)
        }
    }
}
