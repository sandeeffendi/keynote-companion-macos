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

    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Average Speaking Rate").font(.subheadline)
            Text("150").font(.largeTitle).padding(.top,15)
            Text("Words per Minute").font(.title2)
            Divider().padding(.vertical,8)
            Text("Top 3 slides with highest WPM").font(.body)
            SlideRowView()
            Button{
                showDetail()
            }label: {
                Text("More...")
            }.frame(maxWidth: .infinity,alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .bgFeedback)
                .fill(Color.white)
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
    RecapCardView(viewModel: RecapViewModel()).frame(width: 248, height: 389)
}
