//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 03/06/26.
//

import SwiftUI

struct RecapView: View {
    
    @EnvironmentObject private var route: AppRouter
    @StateObject var viewModel: RecapViewModel

    var body: some View {
        VStack(spacing: 16) {
            
            
            
            Text("Ini halaman recap")

            Button("pencet ini balik home") {
                route.popToRoot()
            }
            Button("pencet ini balik home") {
                route.pop()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Recap")
    }
}

#Preview {
    RecapView(
        viewModel: RecapViewModel()
    )
}
