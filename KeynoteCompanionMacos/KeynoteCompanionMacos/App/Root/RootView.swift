//
//  RootView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
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
