//
//  SessionView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct SessionView: View {

    @EnvironmentObject private var route: AppRouter
    @StateObject var viewModel: SessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)

            Button("pencet ini jadi setting") {
                route.push(.settings(.general))
            }
        }
    }
}
