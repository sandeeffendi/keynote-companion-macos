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
        VStack(alignment: .leading, spacing: 0) {
            // Label atas
            Text(feedback.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            // Big number
            Text("\(feedback.overall)")
                .font(.system(size: 48, weight: .bold))

            Text(feedback.unit)
                .font(.title3.bold())
                .padding(.bottom, 4)

            Text(feedback.subTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Divider()
                .padding(.bottom, 12)

            // Per slide alerts
            Text(feedback.category + " alert")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(feedback.perSlide, id: \.no) { slide in
                    VStack(spacing: 0) {
                        HStack {
                            Circle()
                                .fill(.primary)
                                .frame(width: 6, height: 6)
                            Text("Slide \(slide.no)")
                                .font(.subheadline)
                            Spacer()
                            Text("\(slide.value) \(feedback.unit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                // TODO: jump to slide audio
                            } label: {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 12)

                        if slide.no != feedback.perSlide.last?.no {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RecapCardView(feedback: Feedback(
        title: "Average Speaking Rate",
        overall: 150,
        unit: "Words per Minute",
        tips: "Try to slow down during key points.",
        subTitle: "The ideal speech rate is 110 to 160 WPM",
        category: "Speaking rate",
        perSlide: [
            Slide(no: 5, value: 170),
            Slide(no: 8, value: 180)
        ]
    ))
    .frame(width: 280)
    .padding()
    .background(Color(nsColor: .windowBackgroundColor))
}
