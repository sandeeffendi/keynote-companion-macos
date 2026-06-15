//
//  PracticeWPMIndicatorView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeWPMIndicatorView: View {
    let wpm: Int
    let status: WPMStatus
    /// When recognition is down and re-arming, show a neutral "reconnecting" state
    /// instead of a misleading 0.
    var isReconnecting: Bool = false

    private var statusColor: Color {
        if isReconnecting { return AppColor.iconSecondary }
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
                Text(isReconnecting ? "—" : "\(wpm)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textPrimary)

                Text(isReconnecting ? "reconnecting…" : "WPM")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 6)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: status)
        .animation(.easeInOut(duration: 0.35), value: isReconnecting)
    }
}
