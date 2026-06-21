//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import SwiftUI
import SwiftData

@main
struct KeynoteCompanionMacosApp: App {
    @StateObject private var router = AppRouter()
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .modelContainer(persistence.container)
        }
        .defaultSize(
            width: AppSize.splashWindowWidth,
            height: AppSize.splashWindowHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
