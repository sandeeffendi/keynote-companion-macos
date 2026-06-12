//
//  AudioPlayerView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var viewModel: RecapViewModel
    var body: some View {
        HStack(spacing: 12) {
            Button {
                // TODO: rewind
            } label: {
                Image(systemName: "backward.fill")
            }
            .buttonStyle(.plain)

            Button {
                viewModel.isPlaying.toggle()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
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
                        .frame(width: geo.size.width * viewModel.playbackProgress, height: 4)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 12, height: 12)
                        .offset(x: geo.size.width * viewModel.playbackProgress - 6)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    viewModel.playbackProgress = min(max(value.location.x / geo.size.width, 0), 1)
                                }
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)

            Button {
                viewModel.isMuted.toggle()
            } label: {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.slash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    AudioPlayerView(viewModel: RecapViewModel())
    
}
