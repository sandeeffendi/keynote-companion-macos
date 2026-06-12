//
//  PracticeOverlayView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeOverlayView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    PracticeControlBarView(
                        currentSlide: viewModel.currentSlide,
                        elapsedTime: viewModel.elapsedTime
                    )

                    HStack(spacing: AppSpacing.lg) {
                        IconCircleButton(
                            systemName: viewModel.isPaused ? "play.fill" : "pause.fill",
                            action: {
                                if viewModel.isPaused {
                                    viewModel.resume()
                                } else {
                                    viewModel.pause()
                                }
                            }
                        )

                        IconCircleButton(systemName: "arrow.counterclockwise") {
                            viewModel.retake()
                        }

                        IconCircleButton(systemName: "stop.fill") {
                            viewModel.stop()
                        }
                        .tint(.red)
                    }
                }

                Spacer()

                PracticeWPMIndicatorView(
                    wpm: viewModel.currentWPM,
                    status: viewModel.wpmStatus
                )
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
    }
}
