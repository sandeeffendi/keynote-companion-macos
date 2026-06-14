//
//  RecapHeaderView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import SwiftUI
import Combine

struct RecapHeaderView: View {
    @EnvironmentObject private var route: AppRouter
    @ObservedObject var viewModel: RecapViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Practice Recording 1").font(Font.largeTitle.bold()).padding(.bottom, 4)
            Text("Human Interface Guidelines Reading Materials")
            HStack{
                Label("Monday, 17 August 2026", systemImage: "calendar").font(.body)
                Divider()
                Label("Monday, 17 August 2026", systemImage: "calendar")
                Divider()
                Label("Monday, 17 August 2026", systemImage: "calendar")
            }.fixedSize().padding(.top, 8)
            Divider().padding(.vertical, 24)
        }.frame(maxWidth: .infinity,alignment: .leading)
    }
}

#Preview {
    RecapHeaderView(viewModel: RecapViewModel()).frame(maxWidth: .infinity)
}
