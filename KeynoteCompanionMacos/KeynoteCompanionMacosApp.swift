//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import SwiftUI
import TipKit
import SwiftData

@main
struct KeynoteCompanionMacosApp: App {
    @StateObject private var router = AppRouter()
    private let container: ModelContainer

    init() {
        try? Tips.resetDatastore()
        try? Tips.configure()

        let schema = Schema([HistoryModel.self, HistoryFeedback.self])
        let config = ModelConfiguration(schema: schema)
        container = (try? ModelContainer(
            for: schema,
            migrationPlan: HistoryMigrationPlan.self,
            configurations: config
        )) ?? (try! ModelContainer(for: schema, configurations: config))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .modelContainer(container)
                .preferredColorScheme(.light)
        }
        .defaultSize(
            width: AppSize.splashWindowWidth,
            height: AppSize.splashWindowHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
