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
    @Query(sort: \HistoryModel.createdAt, order: .reverse) var sessions: [HistoryModel]
    @State private var searchText: String = ""

    private var filtered: [HistoryModel] {
        guard !searchText.isEmpty else { return Array(sessions) }
        return sessions.filter {
            $0.sesTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.sesKeynote.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var header: some View {
        VStack {
            RecapHeaderView {}
            HStack {
                Button {
                    route.replace(with: .home(.main))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
                .clipShape(Circle())

                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 10)

                    TextField("Search", text: $searchText)
                        .padding(.trailing, 10)
                        .textFieldStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Color(nsColor: .quaternaryLabelColor))
                .cornerRadius(100)

                Spacer()
            }
        }
    }

    private var list: some View {
        let groups = viewModel.grouped(filtered)
        return VStack(alignment: .leading, spacing: 0) {
            if groups.isEmpty {
                Text(searchText.isEmpty ? "No sessions yet." : "No results for \"\(searchText)\".")
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(groups, id: \.date) { group in
                    VStack(alignment: .leading) {
                        Text(group.date)
                            .font(.title2.bold())
                            .padding(.bottom, 4)

                        ForEach(group.sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            header
            ScrollView {
                list
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden()
    }
}

struct SessionRow: View {
    @EnvironmentObject private var route: AppRouter
    let session: HistoryModel

    var body: some View {
        HStack {
            VStack {
                Image(systemName: "text.document")
                    .font(.system(size: 22))
                    .padding(.trailing, 26)
                    .padding(.bottom, 13)
            }

            VStack {
                HStack {
                    Text(session.sesTitle)
                        .font(.title2)
                    Spacer()
                    Text(session.time)
                        .font(.title2)
                    Button {
                        route.replace(with: .recap(.fromHistory(session.toRecapModel())))
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22))
                    }
                    .cornerRadius(100)
                    .buttonStyle(.plain)
                    .padding(.leading, 10)
                }
                .padding(.bottom, 10)

                Divider()
            }
        }
        .padding(.leading, 30)
        .padding(.top, 16)
    }
}

#Preview {
    HistoryView(viewModel: HistoryViewModel())
}
