//
//  SettingsViewModel.swift
//  KeynoteCompanionMacos
//

import Combine
import Foundation

final class SettingsViewModel: ObservableObject {

    @Published var settingsData: SettingsModel

    init(
        settingsData: SettingsModel =
        SettingsModel (
            permissionItems: [
                .microphone,
                .screen,
                .wpmDetector
            ]
        )
    ) {
        self.settingsData = settingsData
    }

    func loadSettings() {
        // Placeholder untuk load settings.
    }
}
