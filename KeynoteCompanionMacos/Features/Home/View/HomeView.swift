//
//  HomeView.swift
//  KeynoteCompanionMacos
//

import AppKit
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
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
                    size: practiceViewModel.isRecording
                        ? CGSize(
                            width: AppSize.practiceOverlayWidth,
                            height: AppSize.practiceOverlayHeight
                        )
                        : CGSize(
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
            .sheet(isPresented: $viewModel.isShowingPermissions) {
                PermissionsSheetView()
            }
            .onAppear {
                practiceViewModel.onSessionFinished = { [weak router] result in
                    let recapModel = result.toRecapModel()
                    router?.push(.recap(.main(recapModel)))
                }
                applyWindowFloating(for: viewModel.state)
            }
            .onDisappear {
                setWindowFloating(false)
            }
            .onChange(of: viewModel.state) { _, newState in
                if practiceViewModel.isRecording && newState != .keynoteSlideshowActive {
                    practiceViewModel.stop()
                }
                applyWindowFloating(for: newState)
            }
    }

    private var homeContent: some View {
        VStack(spacing: 0) {
            HomeHeaderView()

            Spacer(minLength: 0)

            HomeStatusContentView(
                state: viewModel.state,
                errorMessage: viewModel.errorMessage,
                onPrimaryAction: handlePrimaryAction
            )

            Spacer(minLength: 0)

            HomeFooterView(onActivitiesTapped: showActivities)
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

    private func handlePrimaryAction(_ action: HomeStatusAction) {
        switch action {
        case .openPermissions:
            viewModel.openPermissions()
        case .openKeynoteFile:
            viewModel.openKeynoteFile()
        case .recordPractice:
            startRecording()
        }
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

    /// Float the Tiempo window above other apps for states where Keynote tends to come
    /// frontmost, so the user never loses Tiempo behind their slideshow. The recording
    /// overlay manages its own window level, so we leave the level alone there.
    private func applyWindowFloating(for state: HomeViewState) {
        guard router.isShowingHomeRoute else {
            setWindowFloating(false)
            return
        }
        setWindowFloating(state.shouldFloatAboveOtherApps)
    }

    private func setWindowFloating(_ floating: Bool) {
        for window in NSApp.windows where !(window is NSPanel) {
            window.level = floating ? .floating : .normal
        }
    }
}
