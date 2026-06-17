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

//        let schema = Schema([HistoryModel.self, HistoryFeedback.self])
//        let config = ModelConfiguration(schema: schema)
//        container = (try? ModelContainer(
//            for: schema,
//            migrationPlan: HistoryMigrationPlan.self,
//            configurations: config
//        )) ?? (try! ModelContainer(for: schema, configurations: config))
        let schema = Schema([HistoryModel.self, Feedback.self])
        let config = ModelConfiguration("TiempoDB", schema: schema)
        container = try! ModelContainer(for: schema, configurations: config)
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
