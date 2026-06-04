//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation
import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var route: AppRouter
    @StateObject private var viewModel: RecapViewModel

    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            // title
            Text("ini adalah recap view")
                .font(.largeTitle)

            //subtitle
            Text("PIC: Dina")
                .font(.title).bold()

            Text("Recap Data: \(viewModel.recapData.title)")

            // back button
            Button("Back") {
                route.pop()
            }
        }
    }
}
