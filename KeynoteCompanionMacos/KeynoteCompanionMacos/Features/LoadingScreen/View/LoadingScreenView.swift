//
//  LoadingScreenView.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 03/06/26.
//

import Foundation
import SwiftUI

struct LoadingScreenView: View {
    
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: LoadingScreenViewModel
    
    init(viewModel: LoadingScreenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.largeTitle)
        }
        .padding()
        .navigationTitle("Home")
    }
}
