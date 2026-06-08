//
//  OnboardingViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 08/06/26.
//

import Combine
import Foundation

final class OnboardingViewModel: ObservableObject {
    let features: [OnboardingFeature]

    @Published private(set) var hasCompletedOnboarding: Bool

    private let defaults: UserDefaults
    private let completionKey: String

    init(
        defaults: UserDefaults = .standard,
        completionKey: String = OnboardingDefaults.hasCompletedOnboardingKey,
        features: [OnboardingFeature] = [
            .speechRate,
            .fillerWords,
            .insights,
        ]
    ) {
        self.defaults = defaults
        self.completionKey = completionKey
        self.features = features
        self.hasCompletedOnboarding = defaults.bool(forKey: completionKey)
    }

    func loadCompletionState() {
        hasCompletedOnboarding = defaults.bool(forKey: completionKey)
    }

    func completeOnboarding() {
        setHasCompletedOnboarding(true)
    }

    func resetOnboarding() {
        setHasCompletedOnboarding(false)
    }

    private func setHasCompletedOnboarding(_ isCompleted: Bool) {
        defaults.set(isCompleted, forKey: completionKey)
        hasCompletedOnboarding = isCompleted
    }
}
