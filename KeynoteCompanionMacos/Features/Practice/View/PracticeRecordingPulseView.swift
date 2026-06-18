//
//  PracticeRecordingPulseView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeRecordingPulseView: View {
    let wpmStatus: WPMStatus
    let isPaused: Bool
    let isReconnecting: Bool

    @State private var scale: CGFloat = 1.0

    private var statusColor: Color {
        if isReconnecting || isPaused { return AppColor.iconSecondary }
        switch wpmStatus {
        case .tooSlow: return AppColor.wpmSlow
        case .good:    return AppColor.wpmGood
        case .tooFast: return AppColor.wpmFast
        }
    }

    var body: some View {
        Circle()
            .fill(statusColor.opacity(isPaused ? 0.10 : 0.18))
            .overlay(
                Circle()
                    .strokeBorder(
                        statusColor.opacity(isPaused ? 0.18 : 0.5),
                        lineWidth: 2
                    )
            )
            .frame(
                width: AppSize.practiceOverlayPulseSize,
                height: AppSize.practiceOverlayPulseSize
            )
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.35), value: wpmStatus)
            .animation(.easeInOut(duration: 0.25), value: isReconnecting)
            .animation(.easeInOut(duration: 0.25), value: isPaused)
            .onAppear { startPulsing() }
            .onChange(of: isPaused) { _, paused in
                if paused {
                    withAnimation(.easeOut(duration: 0.3)) { scale = 1.0 }
                } else {
                    startPulsing()
                }
            }
    }

    private func startPulsing() {
        scale = 1.0
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            scale = 1.08
        }
    }
}
