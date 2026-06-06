//
//  HomeViewModel.swift
//  KeynoteCompanionMacos
//

import Combine

final class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState

    init(state: HomeViewState = .permissionMissing) {
        self.state = state
    }

    func showHelp() {}

    func openSettings() {}

    func showActivities() {}

    func openKeynoteFile() {}

    func recordPractice() {}
}
