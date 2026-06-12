//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import AVFoundation
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
    @State private var saveToHistory: Bool = false
    @State private var showSavedToast: Bool = false

    @State private var isMuted: Bool = false

    
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
            
            audioPlayer
                .padding(.bottom, 20)
            
            feedbackCards
                .padding(.bottom, 20)
            
            Spacer()
            if !isFromHistory {
                footer
            }
        }
        .frame(alignment: .leading)
        .padding(24)
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden().overlay(alignment: .bottom) {
            if showSavedToast {
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
                    .animation(.easeInOut, value: showSavedToast)
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

    // Audio Player
    private var audioPlayer: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

            // Scrubber
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)

                    Capsule()
                        .fill(viewModel.hasAudio ? Color.primary : Color.secondary.opacity(0.4))
                        .frame(width: geo.size.width * viewModel.playbackProgress, height: 4)

                    Circle()
                        .fill(viewModel.hasAudio ? Color.primary : Color.secondary.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .offset(x: geo.size.width * viewModel.playbackProgress - 6)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let progress = min(max(value.location.x / geo.size.width, 0), 1)
                                    viewModel.seekByProgress(progress)
                                }
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)

            Button {
                isMuted.toggle()
                viewModel.audioPlayer?.volume = isMuted ? 0 : 1
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.slash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            viewModel.configureAudioPlayer()
        }
    }

    // Feedback Cards

    private var feedbackCards: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(viewModel.recapData.feedback, id: \.category) { feedback in
                RecapCardView(feedback: feedback) { timestamp in
                    viewModel.seek(to: timestamp)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // Footer

    private var footer: some View {
        HStack {
            Button {
                if !saveToHistory {
                    viewModel.saveRecap(context: modelContext)
                    saveToHistory = true
                }
                showSavedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showSavedToast = false
                }
            } label: {
                Image(systemName: saveToHistory ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .frame(width: 48, height: 48)
            }
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
            .popoverTip(saveTip) { action in
                guard action.id == "next" else { return }
                SaveSessionTip.doneTip = true
                saveTip.invalidate(reason: .actionPerformed)
            }

            Spacer()

            Button {
                route.pop()
                route.push(.home(.main))
            } label: {
                Text("Record New Practice")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .frame(width: 194, height: 48)
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .popoverTip(newTip)
        }
    }
}

#Preview {
    RecapView(isFromHistory: true, viewModel: RecapViewModel())
}

