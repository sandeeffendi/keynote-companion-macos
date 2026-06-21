//
//  TourController.swift
//  KeynoteCompanionMacos
//
//  Drives the guided setup tour. Unlike TipKit, the whole flow is owned here so it
//  always runs to completion and is trivially restartable (the `?` replay button).
//

import Combine
import Foundation

@MainActor
final class TourController: ObservableObject {
    /// The step currently highlighted, or `nil` when the tour is inactive.
    @Published private(set) var activeStep: TourStep?

    private let order = TourStep.allCases

    /// Called when the tour reaches the end (or is finished early). RootView wires this
    /// to `router.popToRoot()` so the final step returns the user to Home.
    var onFinish: (() -> Void)?

    var isActive: Bool { activeStep != nil }

    func start() {
        activeStep = order.first
    }

    /// "Skip"/"Next" tapped — advance to the next step regardless of which is active.
    func skipCurrent() {
        advance()
    }

    /// An action completed (e.g. the user tapped the real control or granted a
    /// permission). Advances only if `step` is the one currently shown, so stale
    /// callbacks can't skip ahead.
    func complete(_ step: TourStep) {
        guard activeStep == step else { return }
        advance()
    }

    func finish() {
        activeStep = nil
        onFinish?()
    }

    private func advance() {
        guard
            let current = activeStep,
            let index = order.firstIndex(of: current)
        else {
            return
        }

        let next = order.index(after: index)
        if next < order.count {
            activeStep = order[next]
        } else {
            finish()
        }
    }
}
