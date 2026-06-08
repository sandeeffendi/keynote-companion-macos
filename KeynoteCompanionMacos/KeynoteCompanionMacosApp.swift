//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import AppKit
import SwiftUI

@main
struct KeynoteCompanionMacosApp: App {
    @StateObject private var router = AppRouter()

    init() {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
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
