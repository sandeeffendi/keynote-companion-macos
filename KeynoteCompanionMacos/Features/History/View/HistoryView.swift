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
    @Query(sort: \HistoryModel.date, order: .reverse) var sessions: [HistoryModel]
    @State private var sessionDelete: HistoryModel? = nil
    @State private var historyToDetail: Bool = false

    private var header: some View {
        VStack{
            RecapHeaderView {}
            HStack {
                Button {
                    route.pop()
                    route.push(.home(.main))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                }
                .clipShape(Circle())

                HStack {
                    Button {} label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                    }
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 10)

                    TextField("Search", text: .constant(""))
                        .padding(.trailing, 10)
                        .textFieldStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8, opacity: 0.2))
                .cornerRadius(100)

                Spacer()
            }
        }
    }

    private var list: some View {
        let groups = viewModel.grouped(sessions)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(groups, id: \.date) { group in
                VStack(alignment: .leading) {
                    Text(group.date)
                        .font(.title2.bold())
                        .padding(.bottom, 4)

                    ForEach(group.sessions) { session in
                        SessionRow(session: session, historyToDetail: $historyToDetail)
                    }
                }
                .padding(16)
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
    @Binding var historyToDetail: Bool

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
                        route.pop()
                            route.push(.recap(.fromHistory))
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
