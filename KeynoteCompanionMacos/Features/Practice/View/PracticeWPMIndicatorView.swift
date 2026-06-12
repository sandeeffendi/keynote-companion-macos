//
//  PracticeWPMIndicatorView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeWPMIndicatorView: View {
    let wpm: Int
    let status: WPMStatus

    private var statusColor: Color {
        switch status {
        case .tooSlow: return AppColor.wpmSlow
        case .good:    return AppColor.wpmGood
        case .tooFast: return AppColor.wpmFast
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.18))
                .overlay(
                    Circle()
                        .strokeBorder(statusColor, lineWidth: 2.5)
                )
                .frame(width: 88, height: 88)

            VStack(spacing: 2) {
                Text("\(wpm)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textPrimary)

                Text("WPM")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: status)
    }
}
