//
//  KeynoteCompanionMacosApp.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 26/05/26.
//

import SwiftUI
import TipKit

@main
struct KeynoteCompanionMacosApp: App {
    @StateObject private var router = AppRouter()

    init() {
        try? Tips.resetDatastore()
        try? Tips.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
        }
    }
}
