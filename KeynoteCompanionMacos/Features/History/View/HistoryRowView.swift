//
//  HistoryRowView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 15/06/26.
//

import SwiftUI

struct HistoryRowView: View {
    
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: HistoryViewModel
    
    struct Attempt: Identifiable {
        let name: String
        let id = UUID()
    }
    
    private var attempts = [
        Attempt(name: "Attempt 1"),
        Attempt(name: "Attempt 2"),
        Attempt(name: "Attempt 3")
    ]
    
    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    var body: some View {
        List{
            Text("Monday, 17 August 2026").font(.title2).bold().padding(.vertical,16)
            ForEach(attempts){ attempt in
                Button{
                        historyDetail()
                    }label:{
                        HStack{
                            Image(systemName: "text.document").font(.title).padding(.horizontal)
                            VStack(alignment: .leading){
                                HStack{
                                    Text("Pratice 1").font(.title3)
                                    Spacer()
                                    Text("10:00 AM").font(.title3)
                                    Image(systemName: "chevron.right").font(.title3).padding(.leading)
                                }
                                Divider()
                            }
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }.buttonStyle(PlainButtonStyle())
            }.listRowSeparator(.hidden)
        }.listStyle(.plain).scrollContentBackground(.hidden)
    }
    
    private func historyDetail(){
        router.pop()
        router.push(.history(.historyDetail))
    }
}

#Preview {
    HistoryRowView(viewModel: HistoryViewModel())
}
