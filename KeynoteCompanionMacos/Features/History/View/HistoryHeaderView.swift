//
//  HistoryHeaderView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 15/06/26.
//

import Foundation
import SwiftUI

struct HistoryHeaderView: View {
    @EnvironmentObject private var router: AppRouter
    var body: some View {
        HStack{
            Button{
                backHome()
            }label:{
                Image(systemName: "chevron.left").foregroundStyle(AppColor.textPrimary).font(.title).padding(5)
            }.clipShape(Circle())
            
            HStack{
                Image(systemName: "magnifyingglass").padding(.leading, 10)
                TextField("Search...", text: .constant(""))
                    .textFieldStyle(.plain)
            }.padding(.vertical,10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
        }.padding(.top, 10)
    }
    
    private func backHome(){
        router.pop()
        router.push(.home(.main))
    }
}

#Preview {
    HistoryHeaderView()
}
