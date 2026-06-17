//
//  RecapCardView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 08/06/26.
//

import SwiftUI

struct RecapCardView: View {
    let feedback: Feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(feedback.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(feedback.overall)")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text(feedback.unit)
                .font(.title3.bold())

            Text(feedback.subTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }
}

#Preview {
    RecapCardView(feedback: Feedback(
        title: "Speaking Pace",
        overall: 142,
        unit: "WPM",
        tips: "Try slowing down during key points.",
        subTitle: "Your average pace was ideal",
        category: "WPM",
        perSlide: []
    ))
    .frame(width: 248)
    .padding()
}
