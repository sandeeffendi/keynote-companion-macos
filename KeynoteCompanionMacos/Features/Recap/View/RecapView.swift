//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import AVFoundation
import Foundation
import SwiftUI
import SwiftData

struct RecapView: View {
    @EnvironmentObject private var route: AppRouter
    var isFromHistory: Bool
    @StateObject private var viewModel: RecapViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isMuted: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var editingTitleText: String = ""
    @State private var selectedFilter: SlideWPMFilter = .all
    @State private var expandedSlides: Set<Int> = []

    init(isFromHistory: Bool, viewModel: RecapViewModel) {
        self.isFromHistory = isFromHistory
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            RecapHeaderView {}

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header.padding(.bottom, 20)
                    Divider().padding(.bottom, 24)
                    slidesHighlightsSection.padding(.bottom, 24)
                    replaySection.padding(.bottom, 24)
                    slideDetailsSection.padding(.bottom, 24)
                }
                .padding(24)
            }

            if !isFromHistory { footer }
        }
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden()
        .task {
            if !isFromHistory { viewModel.autoSave(context: modelContext) }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isFromHistory {
                Button {
                    route.replace(with: .history(.main))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())
                .padding(.bottom, 12)
            }

            if isEditingTitle {
                TextField("Session title", text: $editingTitleText)
                    .font(.largeTitle.bold())
                    .textFieldStyle(.plain)
                    .onSubmit { commitTitleEdit() }
            } else {
                HStack(spacing: 6) {
                    Text(viewModel.recapData.sesTitle)
                        .font(.largeTitle.bold())
                    Image(systemName: "pencil")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingTitleText = viewModel.recapData.sesTitle
                    isEditingTitle = true
                }
            }

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

    // MARK: - Slides Highlights

    private var slidesHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slides Highlights")
                .font(.title2.bold())

            HStack(alignment: .top, spacing: 12) {
                ForEach(viewModel.recapData.feedback, id: \.category) { feedback in
                    RecapCardView(feedback: feedback)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Replay your session

    private var replaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replay your session")
                .font(.title2.bold())

            audioPlayer
        }
    }

    private var audioPlayer: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.skipToPreviousSlide()
            } label: {
                Image(systemName: "backward.end.fill").font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

            Button {
                viewModel.skipToNextSlide()
            } label: {
                Image(systemName: "forward.end.fill").font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

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
                                    let p = min(max(value.location.x / geo.size.width, 0), 1)
                                    viewModel.seekByProgress(p)
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
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

            HStack(spacing: 4) {
                Text("\(viewModel.formattedCurrentTime) / \(viewModel.formattedTotalDuration)")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.secondary)

                Divider().frame(height: 12)

                Text("Slide \(viewModel.currentSlideNumber)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .opacity(viewModel.hasAudio ? 1 : 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task { viewModel.configureAudioPlayer() }
    }

    // MARK: - Slide Details

    private var slideDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Slide Details").font(.title2.bold())
            filterChips
            slideList
        }
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(SlideWPMFilter.allCases, id: \.self) { filter in
                filterChip(filter)
            }
        }
    }

    @ViewBuilder
    private func filterChip(_ filter: SlideWPMFilter) -> some View {
        if selectedFilter == filter {
            Button(filter.rawValue) { selectedFilter = filter; expandedSlides.removeAll() }
                .buttonStyle(.glassProminent)
                .tint(AppColor.controlAccent)
                .font(.subheadline)
        } else {
            Button(filter.rawValue) { selectedFilter = filter; expandedSlides.removeAll() }
                .buttonStyle(.glass)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var slideList: some View {
        let slides = viewModel.wpmSlides(for: selectedFilter)
        if slides.isEmpty {
            Text("No slides in this range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(slides.enumerated()), id: \.element.no) { idx, slide in
                    slideRowHeader(slide)
                    slideRowAttempts(slide)
                    if idx < slides.count - 1 {
                        Divider().padding(.leading, 34)
                    }
                }
            }
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func slideRowHeader(_ slide: Slide) -> some View {
        let isExpanded = expandedSlides.contains(slide.no)
        let hasAttempts = slide.attempts.count > 1
        return HStack(spacing: 10) {
            Circle()
                .fill(wpmColor(slide.value))
                .frame(width: 8, height: 8)
            Text("Slide \(slide.no)").font(.body.bold())
            Spacer()
            Text("\(slide.value) WPM").font(.subheadline).foregroundStyle(.secondary)
            Button { viewModel.seek(to: slide.timestamp) } label: {
                Image(systemName: "play.fill").font(.caption).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
                .opacity(hasAttempts ? 1 : 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            guard hasAttempts else { return }
            if isExpanded { expandedSlides.remove(slide.no) }
            else { expandedSlides.insert(slide.no) }
        }
    }

    @ViewBuilder
    private func slideRowAttempts(_ slide: Slide) -> some View {
        if expandedSlides.contains(slide.no) {
            ForEach(slide.attempts, id: \.attemptNo) { attempt in
                HStack(spacing: 10) {
                    Circle()
                        .fill(wpmColor(attempt.wpm))
                        .frame(width: 6, height: 6)
                        .padding(.leading, 22)
                    Text("Attempt \(attempt.attemptNo)").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(attempt.wpm) WPM").font(.subheadline).foregroundStyle(.secondary)
                    Button { viewModel.seek(to: attempt.startTimestamp) } label: {
                        Image(systemName: "play.fill").font(.caption2).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.secondary.opacity(0.04))
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        GlassEffectContainer {
            HStack {
                Spacer()
                Button {
                    route.popToRoot()
                } label: {
                    Label("Back to Home", systemImage: "house.fill")
                        .font(.system(size: 17))
                        .frame(height: 48)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(AppColor.controlAccent)
            }
        }
    }

    // MARK: - Helpers

    private func wpmColor(_ wpm: Int) -> Color {
        if wpm < 90 { return AppColor.wpmSlow }
        if wpm > 120 { return AppColor.wpmFast }
        return AppColor.wpmGood
    }

    private func commitTitleEdit() {
        let trimmed = editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { viewModel.updateTitleInHistory(trimmed, context: modelContext) }
        isEditingTitle = false
    }
}

#Preview {
    RecapView(isFromHistory: true, viewModel: RecapViewModel())
}
