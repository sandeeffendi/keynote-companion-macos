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
    @EnvironmentObject private var route: AppRouter
    var isFromHistory: Bool
    @StateObject private var viewModel: RecapViewModel
    @Environment(\.modelContext) private var modelContext
    let saveTip = SaveSessionTip()
    let newTip = NewSessionTip()
    init(isFromHistory: Bool, viewModel: RecapViewModel) {
        self.isFromHistory = isFromHistory
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        let _ = print("isFromHistory: \(isFromHistory)")
        VStack(alignment: .leading, spacing: 0) {
            RecapHeaderView {}
            header
                .padding(.bottom, 20)
            
            Divider()
                .padding(.bottom, 20)
            
            AudioPlayerView(viewModel: RecapViewModel())
                .padding(.bottom, 20)
            
            feedbackCards
                .padding(.bottom, 20)
            
            Spacer()
            if !isFromHistory {
                RecapFooterView(viewModel: RecapViewModel())
            }
        }
        .frame(alignment: .leading)
        .padding(24)
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden().overlay(alignment: .bottom) {
            if viewModel.showSavedToast {
                Text("This session already saved to history")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.leading)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showSavedToast)
            }
        }
        
        
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isFromHistory {
                Button {
                    route.pop()
                    route.push(.history(.main))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                }
                .clipShape(Circle()).padding(.bottom,12)
            }
            Text(viewModel.recapData.sesTitle)
                .font(.largeTitle.bold())

            Text(viewModel.recapData.sesKeynote)
                .font(.title3)
                .padding(.top, 8)

            HStack(spacing: 8) {
                Label(viewModel.recapData.date, systemImage: "calendar")
                Divider().frame(height: 14)
                Label(viewModel.recapData.time, systemImage: "clock")
                Divider().frame(height: 14)
                Label(viewModel.recapData.duration, systemImage: "stopwatch")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 16)
        }
    }

    // Feedback Cards
    private var feedbackCards: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(viewModel.recapData.feedback, id: \.category) { feedback in
                RecapCardView(feedback: feedback){
                    timestamp in
                    viewModel.playbackProgress = viewModel.totalDuration > 0 ? timestamp / viewModel.totalDuration : 0
                }
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    RecapView(isFromHistory: true, viewModel: RecapViewModel())
}

