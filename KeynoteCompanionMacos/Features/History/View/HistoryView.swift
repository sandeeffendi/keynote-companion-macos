//
//  HistoryView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: HistoryViewModel
    
    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
                HistoryWindowControl{}
                HistoryHeaderView()
                HistoryRowView(viewModel: viewModel)
            }.padding(24)
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
}
