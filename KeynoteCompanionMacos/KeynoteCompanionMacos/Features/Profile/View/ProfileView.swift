//
//  ProfileView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var route: AppRouter
    @StateObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Ini adalah profile view")

            Button("Back") {
                route.pop()
            }
        }
    }
}
