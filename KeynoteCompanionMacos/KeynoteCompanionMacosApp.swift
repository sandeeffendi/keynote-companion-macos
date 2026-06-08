//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import AppKit
import SwiftUI
import TipKit
import SwiftData

@main
struct KeynoteCompanionMacosApp: App {
    @StateObject private var router = AppRouter()

    init() {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }

    var body: some Scene {
        WindowGroup {
            AppWindowSurface {
                RootView()
                    .environmentObject(router)
            }
            .preferredColorScheme(.light)
            RootView()
                .environmentObject(router)
                .modelContainer(for: HistoryModel.self) 
        }
        .defaultSize(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
