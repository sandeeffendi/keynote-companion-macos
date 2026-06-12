//
//  RecapFooterView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import SwiftUI
import SwiftData
import TipKit


struct RecapFooterView: View {
    @ObservedObject var viewModel: RecapViewModel
    @EnvironmentObject private var route: AppRouter
    
    let saveTip = SaveSessionTip()
    let newTip = NewSessionTip()
    
    var body: some View {
        Divider()
        HStack {
            
            PillButton(
                title: "Record New Practice",
                role: .primary,
                action: navigateToHome
            )
            .popoverTip(newTip)
        }
    }
    
    
    private func navigateToHome() {
        route.pop()
        route.push(.home(.main))
    }
    
}

#Preview {
    RecapFooterView(viewModel: RecapViewModel())
}
