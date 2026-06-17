//
//  RecapCardView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 08/06/26.
//

import SwiftUI

struct RecapCardView: View {
    
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecapViewModel
    @State private var detail: Bool = false
    
    var prev: RecapRoute

    init(viewModel: RecapViewModel, prev: RecapRoute) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.prev = prev
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Average Speaking Rate").font(.subheadline)
            Text("150").font(.largeTitle).padding(.top,15)
            Text("Words per Minute").font(.title2)
            Divider().padding(.vertical,8)
            Text("Top 3 slides with highest WPM").font(.body)
            SlideRowView(prev: prev)
            PillButton(title: "More...", role: .secondary, action: showDetail).frame(maxWidth: .infinity,alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .bgFeedback)
                .stroke(.black, lineWidth: 1).frame(maxWidth: .infinity,maxHeight: .infinity)
        )
    }
    
    private func showDetail(){
        viewModel.showDetail()
        router.pop()
        router.push(.recap(.detail))
        
    }
}

#Preview {
    RecapCardView(viewModel: RecapViewModel(), prev: .main).frame(width: 248, height: 389)
}
