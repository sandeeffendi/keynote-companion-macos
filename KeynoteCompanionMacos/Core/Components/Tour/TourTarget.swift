//
//  TourTarget.swift
//  KeynoteCompanionMacos
//
//  Lets any view register itself as the spotlight target for a tour step. Bounds are
//  published as anchor preferences, which propagate up through the NavigationStack so
//  RootView can resolve each target's frame in a single coordinate space.
//

import SwiftUI

struct TourTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [TourStep: Anchor<CGRect>] { [:] }

    static func reduce(
        value: inout [TourStep: Anchor<CGRect>],
        nextValue: () -> [TourStep: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Marks this view as the spotlight target for `step`.
    func tourTarget(_ step: TourStep) -> some View {
        anchorPreference(
            key: TourTargetPreferenceKey.self,
            value: .bounds
        ) { [step: $0] }
    }
}
