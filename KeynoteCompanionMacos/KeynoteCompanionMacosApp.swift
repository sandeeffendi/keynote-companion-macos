//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import AppKit
import SwiftUI
import TipKit

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
        }
        .defaultSize(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
