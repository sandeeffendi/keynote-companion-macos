//
//  AudioPlayerView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import SwiftUI

struct AudioPlayerView: View {
    @StateObject var viewModel: AudioViewModel
    
    init(viewModel: AudioViewModel = AudioViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.rewind) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            Button(action: viewModel.togglePlay) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            Button(action: viewModel.forward) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: geo.size.width * viewModel.progress, height: 4)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.seek(to: value.location.x / geo.size.width)
                        }
                )
            }
            .frame(height: 20)
            
            Button(action: viewModel.toggleMute) {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            
            Text(viewModel.timestampText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 34, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        .onDisappear { viewModel.stop() }
    }
}

#Preview {
    AudioPlayerView()
        .frame(width: 420)
        .padding()
}
