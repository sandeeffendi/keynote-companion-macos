//
//  RecapFooterView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import TipKit


struct RecapFooterView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecapViewModel
    
    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack{
            Divider().padding(.vertical, 24)
            HStack{
                Spacer()
                PillButton(title: "Back Home", systemImage: "house.fill", role: .primary){
                    backHome()
                }
            }.frame(alignment: .trailing)
        }
    }
    
    private func backHome() {
        router.pop()
        router.push(.home(.main))
    }
    
}

#Preview {
    RecapFooterView(viewModel: RecapViewModel())
}
