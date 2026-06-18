//
//  PracticeOverlayView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeOverlayView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            PracticeRecordingPulseView(
                wpmStatus: viewModel.wpmStatus,
                isPaused: viewModel.isPaused,
                isReconnecting: viewModel.isReconnecting
            )

            Text(viewModel.wpmFeedbackText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            VStack(spacing: AppSpacing.xxs) {
                Text("Current slide: \(viewModel.currentSlide)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColor.textSecondary)
                Text(viewModel.elapsedTime)
                    .font(.system(size: 11, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack(spacing: AppSpacing.lg) {
                overlayButton(
                    systemName: viewModel.isPaused ? "play.fill" : "pause.fill",
                    label: viewModel.isPaused ? "Resume" : "Pause"
                ) {
                    if viewModel.isPaused { viewModel.resume() } else { viewModel.pause() }
                }

                overlayButton(
                    systemName: "arrow.2.circlepath",
                    label: "Retake"
                ) {
                    viewModel.retake()
                }

                overlayButton(
                    systemName: "stop.fill",
                    label: "Stop",
                    foreground: .red
                ) {
                    viewModel.stop()
                }
            }
        }
        .padding(AppSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .frame(
            width: AppSize.practiceOverlayWidth,
            height: AppSize.practiceOverlayHeight
        )
    }

    @ViewBuilder
    private func overlayButton(
        systemName: String,
        label: String,
        foreground: Color = AppColor.iconSecondary,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            IconCircleButton(
                systemName: systemName,
                size: AppSize.practiceOverlayButtonSize,
                foregroundColor: foreground,
                action: action
            )
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
