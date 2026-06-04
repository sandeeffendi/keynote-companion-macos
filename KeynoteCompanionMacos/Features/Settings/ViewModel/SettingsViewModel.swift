//
//  SettingsViewModel.swift
//  KeynoteCompanionMacos
//

import Combine
import Foundation

final class SettingsViewModel: ObservableObject {

    @Published var settingData: SettingsModel

    init(
        settingData: SettingsModel = SettingsModel(
            title: "Ini adalah setting screen",
            subTitle: "PIC: Arfian"
        )
    ) {
        self.settingData = settingData
    }

    func loadSettings() {
        // Placeholder untuk load settings.
    }
}
