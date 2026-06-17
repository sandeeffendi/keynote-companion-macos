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
#if DEBUG
        try? Tips.resetDatastore()
#endif
        try? Tips.configure()

        let schema = Schema([HistoryModel.self, HistoryFeedback.self])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: HistoryMigrationPlan.self,
                configurations: config
            )
        } catch {
            // Migration failed — fall back to a plain container (data loss accepted
            // at pre-production stage) or in-memory if that also fails.
            if let plain = try? ModelContainer(for: schema, configurations: config) {
                container = plain
            } else {
                container = try! ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .modelContainer(container)
        }
        .defaultSize(
            width: AppSize.splashWindowWidth,
            height: AppSize.splashWindowHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
