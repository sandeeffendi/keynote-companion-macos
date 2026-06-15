//
//  OnboardingFeature.swift
//  KeynoteCompanionMacos
//
//  Created by Codex on 08/06/26.
//

import Foundation

struct OnboardingFeature: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
}

extension OnboardingFeature {
    static let speechRate = OnboardingFeature(
        id: "speech-rate",
        icon: AppIcon.onboardingSpeechRate,
        title: "Track Your Speech Rate",
        description: "See your speech rate and know when you are speaking too fast or too slow."
    )

    static let fillerWords = OnboardingFeature(
        id: "filler-words",
        icon: AppIcon.onboardingFillerWords,
        title: "Catch Your Filler Words",
        description: "Detect \"um\", \"ah\", and \"eee\" to build better speaking awareness."
    )

    static let insights = OnboardingFeature(
        id: "insights",
        icon: AppIcon.onboardingInsights,
        title: "Get Actionable Insights",
        description: "Receive personalized feedback and practical tips after every practice session."
    )
}
