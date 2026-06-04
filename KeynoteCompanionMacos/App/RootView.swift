//
//  RootView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeRouteBuilder.build(.main)
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteBuilder.build(route)
                }
        }
    }
}
