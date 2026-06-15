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

    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        VStack{
            RecapWindowControlView{}.padding(.horizontal, 10) //minmaxclose
            VStack(alignment: .leading){
                RecapHeaderView(viewModel: viewModel)
                Text("Slides Highlights").font(.title).bold().padding(.horizontal)
                HStack(spacing:10){
                    RecapCardView(viewModel: viewModel)
                    RecapCardView(viewModel: viewModel)
                }
                Text("Replay your session").font(.title3).padding(.horizontal).padding(.top)
                AudioPlayerView(viewModel: viewModel.audioViewModel)
                RecapFooterView(viewModel: viewModel)
            }.padding(24)
        }
    }
    

}

#Preview {
    RecapView(viewModel: RecapViewModel()).frame(maxWidth: 700, minHeight: 740)
        .environmentObject(AppRouter())
}
