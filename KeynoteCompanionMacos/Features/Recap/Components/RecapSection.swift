//
//  RecapSection.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import SwiftUI

struct RecapSection: View {
    let title: String
        let metric: FeedbackModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.title2.bold())
                HStack(spacing: 30) {
                    CardComponent(label: "Overall", value: "\(metric.overall)")
                    CardComponent(label: "Highest", value: "\(metric.highest.value)", detail: "Slide \(metric.highest.slide)")
                    CardComponent(label: "Lowest",  value: "\(metric.lowest.value)",  detail: "Slide \(metric.lowest.slide)")
                }
                .frame(maxWidth: .infinity)
                Text("• \(metric.recommendation)")
            }
        }
}
