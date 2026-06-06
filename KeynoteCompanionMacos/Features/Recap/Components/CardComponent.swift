//
//  card.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 06/06/26.
//

import SwiftUI

struct CardComponent: View {
    var body: some View {
        VStack(alignment: .leading){
            Text("Overall").font(Font.system(size: 12, design: .default))
            Text("152 WPM").font(Font.system(size: 17, design: .default))
        }.padding(.vertical, 8, ).padding(.horizontal, 16).frame(width: 160, height: 55, alignment: .leading).background(.gray).cornerRadius(.card)
    }
}

#Preview {
    CardComponent()
}
