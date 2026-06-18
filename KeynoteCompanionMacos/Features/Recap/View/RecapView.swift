//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import AVFoundation
import Foundation
import SwiftUI
import AppKit

struct RecapView: View {
    @EnvironmentObject private var route: AppRouter
    var isFromHistory: Bool
    @StateObject private var viewModel: RecapViewModel

    @State private var isEditingTitle: Bool = false
    @State private var editingTitleText: String = ""
    @State private var isHoveringTitle: Bool = false
    @State private var selectedFilter: SlideWPMFilter = .ascending
    @State private var deleteAlert: Bool = false

    init(isFromHistory: Bool, viewModel: RecapViewModel) {
        self.isFromHistory = isFromHistory
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header shares the same horizontal inset as the content below so the
            // custom traffic-light controls align with the 24pt margin (matching
            // Home/Settings/History) instead of sitting flush against the window edge.
            RecapHeaderView()
                .padding(.horizontal, AppSpacing.xl)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    highlightSection
                    replaySection
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }

            if !isFromHistory { footer }
        }
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden()
        .task {
            if !isFromHistory { viewModel.autoSave() }
        }
        .confirmationDialog(
            "Delete Session?",
            isPresented: $deleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if isFromHistory {
                HStack{
                    IconCircleButton(systemName: "chevron.left") {
                        route.replace(with: .history(.main))
                    }
                    .padding(.bottom, AppSpacing.md)
                    Spacer()
                    IconCircleButton(systemName: "trash") {
                        deleteAlert = true
                    }
                }
            }

            titleView

            Text(viewModel.recapData.sesKeynote)
                .font(AppFont.recapSubtitle)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, AppSpacing.sm)

            metadataRow
                .padding(.top, AppSpacing.md)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if isEditingTitle {
            TextField("Session title", text: $editingTitleText)
                .font(AppFont.recapTitle)
                .textFieldStyle(.plain)
                .onSubmit { commitTitleEdit() }
        } else {
            HStack(spacing: AppSpacing.sm) {
                Text(viewModel.recapData.sesTitle)
                    .font(AppFont.recapTitle)
                Image(systemName: "pencil")
                    .font(.callout)
                    .foregroundStyle(AppColor.textTertiary)
                    .opacity(isHoveringTitle ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onHover { isHoveringTitle = $0
                if isHoveringTitle {
                    NSCursor.iBeam.push()
                }else{
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                editingTitleText = viewModel.recapData.sesTitle
                isEditingTitle = true
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(SessionFormatting.sessionDate(viewModel.recapData.createdAt))
            Divider().frame(height: AppSize.footerSeparatorHeight)
            Text(SessionFormatting.sessionTime(viewModel.recapData.createdAt))
            Divider().frame(height: AppSize.footerSeparatorHeight)
            Text(SessionFormatting.duration(viewModel.recapData.durationSeconds))
        }
        .font(AppFont.recapMeta)
        .foregroundStyle(AppColor.textSecondary)
    }

    // MARK: - Highlight

    private var highlightSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Highlight")
                    .font(AppFont.recapSectionTitle)
                Spacer()
                filterMenu
            }
            highlightCard
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(SlideWPMFilter.allCases) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    if selectedFilter == filter {
                        Label(filter.rawValue, systemImage: "checkmark")
                    } else {
                        Text(filter.rawValue)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(AppFont.smallIcon)
                .foregroundStyle(AppColor.iconSecondary)
                .frame(
                    width: AppSize.headerIconButtonSize,
                    height: AppSize.headerIconButtonSize
                )
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .fixedSize()
    }

    private var highlightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("This is your speaking rate")
                    .font(AppFont.recapCardTitle)
                Text("Tips: keep your speaking rate between \(RecapViewModel.wpmLowerBand) to \(RecapViewModel.wpmUpperBand) WPM (Words per Minute).")
                    .font(AppFont.recapCardTip)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.lg)

            slideList
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }

    @ViewBuilder
    private var slideList: some View {
        let slides = viewModel.wpmSlides(for: selectedFilter)
        if slides.isEmpty {
            Text("No slides in this range.")
                .font(AppFont.recapRow)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(slides.enumerated()), id: \.element.no) { idx, slide in
                    slideRow(slide)
                    if idx < slides.count - 1 {
                        Divider().padding(.horizontal, AppSpacing.lg)
                    }
                }
            }
            .padding(.bottom, AppSpacing.sm)
        }
    }

    private func slideRow(_ slide: Slide) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text("Slide \(slide.no)")
                .font(AppFont.recapRow)
            Spacer()
            if let label = viewModel.status(for: slide.value).label {
                Text(label)
                    .font(AppFont.recapRowStatus)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Text("\(slide.value) WPM")
                .font(AppFont.recapRowValue)
                .foregroundStyle(AppColor.textSecondary)
            Button {
                viewModel.playSlideSegment(slide)
            } label: {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(AppColor.iconSecondary)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Session player

    private var replaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Listen to your entire practice session:")
                .font(AppFont.recapCardTitle)
                .foregroundStyle(AppColor.textSecondary)
            audioPlayer
        }
    }

    private var audioPlayer: some View {
        HStack(spacing: AppSpacing.md) {
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

            scrubber

            Button {
                viewModel.setMuted(!viewModel.isMuted)
            } label: {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundStyle(AppColor.iconSecondary)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasAudio)

            HStack(spacing: AppSpacing.xs) {
                Text("\(viewModel.formattedCurrentTime) / \(viewModel.formattedTotalDuration)")
                    .font(AppFont.recapPlayerTime)
                    .foregroundStyle(AppColor.textSecondary)

                Divider().frame(height: AppSize.footerSeparatorHeight - 4)

                Text("Slide \(viewModel.currentSlideNumber)")
                    .font(AppFont.recapPlayerTime.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .opacity(viewModel.hasAudio ? 1 : 0.4)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .task { viewModel.configureAudioPlayer() }
    }

    private var scrubber: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.separator)
                    .frame(height: 4)
                Capsule()
                    .fill(viewModel.hasAudio ? AppColor.textPrimary : AppColor.separator)
                    .frame(width: geo.size.width * viewModel.playbackProgress, height: 4)
                Circle()
                    .fill(viewModel.hasAudio ? AppColor.textPrimary : AppColor.separator)
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
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            PillButton(
                title: "Back to Home",
                systemImage: "house.fill",
                role: .primary
            ) {
                route.popToRoot()
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Helpers

    private func commitTitleEdit() {
        let trimmed = editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { viewModel.updateTitle(trimmed) }
        isEditingTitle = false
    }
    
    private func performDelete() {
        if viewModel.deleteSession() {
            route.replace(with: .history(.main))
        }
    }
}

#if DEBUG
#Preview {
    RecapView(isFromHistory: true, viewModel: RecapViewModel(recapData: .preview))
}
#endif
