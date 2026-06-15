//
//  HistoryHeaderView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 15/06/26.
//

import SwiftUI

struct HistoryHeaderView: View {
    var body: some View {
        HStack{
            Button{
                
            }label:{
                Image(systemName: "chevron.left.circle.fill").font(.largeTitle)
            }.buttonStyle(PlainButtonStyle())
            
            HStack{
                Image(systemName: "magnifyingglass").padding(.leading, 10)
                TextField("Search...", text: .constant(""))
                    .textFieldStyle(.plain)
            }.padding(.vertical,10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    HistoryHeaderView()
}
