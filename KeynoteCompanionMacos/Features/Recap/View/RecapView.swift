//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation
import SwiftUI
import TipKit
import SwiftData

struct RecapView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecapViewModel
    let prev: RecapRoute

    init(viewModel: RecapViewModel, prev: RecapRoute) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.prev = prev
    }
    var body: some View {
        VStack{
            RecapWindowControl{}.padding(.horizontal, 10) //minmaxclose
            VStack(alignment: .leading){
                RecapHeaderView(viewModel: viewModel, prev: prev)
                Text("Slides Highlights").font(.title).bold().padding(.horizontal)
                HStack(spacing:10){
                    RecapCardView(viewModel: viewModel, prev: .main)
                    RecapCardView(viewModel: viewModel, prev: .main)
                }
                Text("Replay your session").font(.title3).padding(.horizontal).padding(.top)
                AudioPlayerView(viewModel: viewModel.audioViewModel)
                RecapFooterView(viewModel: viewModel)
            }.padding(.horizontal,24).padding(.bottom,24)
        }
    }
    

}

#Preview {
    RecapView(viewModel: RecapViewModel(),prev: .main).frame(maxWidth: 700, minHeight: 740)
        .environmentObject(AppRouter())
}
