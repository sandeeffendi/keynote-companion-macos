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
    let prev: RecapRoute
    
    init(viewModel: RecapDetailViewModel, prev: RecapRoute) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.prev = prev
    }
    
    @State private var selectedFilter: String = "All"
    
    var body: some View {
        VStack{ //minmaxclose
            VStack(alignment:.leading){
                RecapWindowControl{}
                Button{
                        backRecap()
                }label:{
                    Image(systemName: "chevron.left").foregroundStyle(AppColor.textPrimary).font(.title).padding(5)
                }.clipShape(Circle()).padding(.bottom, 16)
                VStack(alignment:.leading){
                    HStack{
                        Text("Practice 1 Speaking Rate").font(.largeTitle).bold()
                        Spacer()
                        Menu{
                            Picker("Slides Filter", selection: $selectedFilter) {
                                Text("All").tag("all")
                                Text("Ideal").tag("ideal")
                                Text("Not Ideal").tag("unideal")
                            }
                            .pickerStyle(.inline)
                        }label:{
                            Image(systemName: "line.3.horizontal.decrease").font(.largeTitle)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Text("List detail attempt of speaking rate data per slide")
                    Divider().padding()
                    SlideRowView(prev: prev)
                    AudioPlayerView().padding(.vertical,24)
                    
                }.padding(.leading, 8)
            }.padding(24)
                
        }
    }
    
    private func backRecap(){
        router.pop()
    }
}

#Preview {
    RecapDetailView(viewModel: RecapDetailViewModel(), prev: .detail)
        .environmentObject(AppRouter())
}
