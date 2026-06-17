//
//  RecapHeaderView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import SwiftUI
import Combine

struct RecapHeaderView: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var viewModel: RecapViewModel
    let prev: RecapRoute
    
    var body: some View {
        if prev != .main {
            HStack{
                Button{
                    router.pop()
                    router.push(.history(.main))
                }label:{
                    Image(systemName: "chevron.left").foregroundStyle(AppColor.textPrimary).font(.title).padding(5)
                }.clipShape(Circle())
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        // delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        // rename
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title)
                        .padding(12)
                        .contentShape(Circle())
                }
                .clipShape(Circle())
                .buttonStyle(.plain)
                //.background(Circle().fill(.white.opacity(0.15)))
                
            }.frame(maxWidth: .infinity).padding(.bottom)
        }
        VStack(alignment: .leading) {
            Text("Practice Recording 1").font(Font.largeTitle.bold()).padding(.bottom, 4)
            Text("Human Interface Guidelines Reading Materials")
            HStack{
                Label("Monday, 17 August 2026", systemImage: "calendar").font(.body)
                Divider()
                Label("Monday, 17 August 2026", systemImage: "calendar")
                Divider()
                Label("Monday, 17 August 2026", systemImage: "calendar")
            }.fixedSize().padding(.top, 8)
            Divider().padding(.vertical, 24)
        }.frame(maxWidth: .infinity).padding(.horizontal,8)
    }
}

#Preview {
    RecapHeaderView(viewModel: RecapViewModel(), prev: .main).frame(maxWidth: .infinity)
}
