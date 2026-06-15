//
//  RecapDetailView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 15/06/26.
//

import SwiftUI
import Foundation
import SwiftData
import Combine

struct RecapDetailView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: RecapDetailViewModel
    
    init(viewModel: RecapDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    @State private var selectedFilter: String = "All"
    
    var body: some View {
        VStack{
            RecapWindowControlView{}.padding(.horizontal, 10) //minmaxclose
            VStack(alignment:.leading){
                Button{
                    backRecap()
                }label:{
                    Image(systemName: "chevron.left.circle.fill").font(.largeTitle)
                }.buttonStyle(PlainButtonStyle()).padding(.bottom, 16)
                HStack{
                    Text("Practice 1 Speaking Rate").font(.largeTitle).bold()
                    Spacer()
                    Menu{
                        Picker("Slides Filter", selection: $selectedFilter) {
                            Text("All Slides").tag("all")
                            Text("Ideal Slides").tag("ideal")
                            Text("Not Ideal Slides").tag("unideal")
                        }
                        .pickerStyle(.inline)
                    }label:{
                        Image(systemName: "line.3.horizontal.decrease.circle.fill").font(.largeTitle)
                    }.buttonStyle(PlainButtonStyle())
                }
                Text("List detail attempt of speaking rate data per slide")
                AudioPlayerView().padding(.vertical,24)
                SlideRowView()
            }.padding(24)
                
        }
    }
    
    private func backRecap(){
        router.pop()
        router.push(.recap(.main))
    }
}

#Preview {
    RecapDetailView(viewModel: RecapDetailViewModel())
        .environmentObject(AppRouter())
}
