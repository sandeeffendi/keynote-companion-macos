//
//  HistoryView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject private var route: AppRouter
    @StateObject var viewModel = HistoryViewModel()
    @Query(sort: \HistoryModel.createdAt, order: .reverse) private var sessions: [HistoryModel]
    @State private var searchText: String = ""

    private var filtered: [HistoryModel] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter {
            $0.sesTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.sesKeynote.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecapHeaderView()
                .padding(.horizontal, AppSpacing.xl)

            navigationBar
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.md)

            ScrollView(.vertical, showsIndicators: false) {
                sessionList
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden()
    }

    // MARK: - Navigation bar

    private var navigationBar: some View {
        HStack(spacing: AppSpacing.md) {
            IconCircleButton(systemName: "chevron.left") {
                route.replace(with: .home(.main))
            }
            SearchField(text: $searchText)
        }
    }

    // MARK: - List

    @ViewBuilder
    private var sessionList: some View {
        let groups = viewModel.grouped(filtered)
        if groups.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(groups, id: \.date) { group in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(group.date)
                            .font(AppFont.recapSectionTitle)
                            .foregroundStyle(AppColor.textPrimary)

                        sessionCard(group.sessions)
                    }
                }
            }
        }
    }

    private func sessionCard(_ sessions: [HistoryModel]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sessions.enumerated()), id: \.element.persistentModelID) { index, session in
                SessionRow(session: session) {
                    route.replace(with: .recap(.fromHistory(session.toRecapModel())))
                }
                if index < sessions.count - 1 {
                    Divider().padding(.horizontal, AppSpacing.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }

    private var emptyState: some View {
        Text(searchText.isEmpty ? "No sessions yet." : "No results for \"\(searchText)\".")
            .font(AppFont.recapRow)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, AppSpacing.xxl)
    }
}

private struct SessionRow: View {
    let session: HistoryModel
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "text.document")
                    .font(AppFont.sizeIcon)
                    .foregroundStyle(AppColor.iconSecondary)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(session.sesTitle)
                        .font(AppFont.recapRow)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(SessionFormatting.sessionTime(session.createdAt))
                        .font(AppFont.recapMeta)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(AppFont.smallIcon)
                    .foregroundStyle(AppColor.iconSecondary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
        .environmentObject(AppRouter())
}
