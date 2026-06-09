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
    @State private var saveToHistory: Bool = false

    // Audio player state
    @State private var isPlaying: Bool = false
    @State private var isMuted: Bool = false
    @State private var playbackProgress: Double = 0.0
    @State private var totalDuration: TimeInterval = 300.0

    
    init(isFromHistory: Bool, viewModel: RecapViewModel) {
        self.isFromHistory = isFromHistory
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        let _ = print("isFromHistory: \(isFromHistory)")
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 20)

            Divider()
                .padding(.bottom, 20)

            audioPlayer
                .padding(.bottom, 20)

            feedbackCards
                .padding(.bottom, 20)

            Spacer()

            footer
        }
        .frame(alignment: .leading)
        .padding(24)
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden(!isFromHistory).onAppear {
            print("isFromHistory: \(isFromHistory)")
        }}

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
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

    // MARK: - Audio Player

    private var audioPlayer: some View {
        HStack(spacing: 12) {
            Button {
                // TODO: rewind
            } label: {
                Image(systemName: "backward.fill")
            }
            .buttonStyle(.plain)

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Button {
                // TODO: forward
            } label: {
                Image(systemName: "forward.fill")
            }
            .buttonStyle(.plain)

            // Scrubber
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)

                    Capsule()
                        .fill(Color.primary)
                        .frame(width: geo.size.width * playbackProgress, height: 4)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 12, height: 12)
                        .offset(x: geo.size.width * playbackProgress - 6)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    playbackProgress = min(max(value.location.x / geo.size.width, 0), 1)
                                }
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)

            Button {
                isMuted.toggle()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.slash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Feedback Cards

    private var feedbackCards: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(viewModel.recapData.feedback, id: \.category) { feedback in
                RecapCardView(feedback: feedback){
                    timestamp in
                        playbackProgress = totalDuration > 0 ? timestamp / totalDuration : 0
                }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button {
                guard !saveToHistory else { return }
                viewModel.saveRecap(context: modelContext)
                saveToHistory = true
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
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .popoverTip(newTip)
        }
    }
}

#Preview {
    RecapView(isFromHistory: false, viewModel: RecapViewModel())
}

