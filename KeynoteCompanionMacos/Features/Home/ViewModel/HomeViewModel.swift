//
//  HomeViewModel.swift
//  KeynoteCompanionMacos
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState

    init(state: HomeViewState = .permissionMissing) {
        self.state = state
    }

    func loadData() {
        print("HomeViewModel.loadData")
    }

    func showHelp() {
        print("HomeViewModel.showHelp")
    }

    func openSettings() {
        print("HomeViewModel.openSettings")
    }

    func showActivities() {
        print("HomeViewModel.showActivities")
    }

    func openKeynoteFile() {
        print("HomeViewModel.openKeynoteFile")
    }

    func recordPractice() {
        print("HomeViewModel.recordPractice")
    }
}
