//
//  PracticeControlBarView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct PracticeControlBarView: View {
    let currentSlide: Int
    let elapsedTime: String

    var body: some View {
        HStack {
            Text("Current slide: \(currentSlide)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            Text(elapsedTime)
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
