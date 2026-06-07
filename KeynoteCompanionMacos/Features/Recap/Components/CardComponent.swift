//
//  card.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 06/06/26.
//

import SwiftUI

struct CardComponent: View {
    let label: String
    let value: String
    var detail: String? = nil //utk keterangan slide
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4){
            Text(label).font(Font.system(size: 12, design: .default))
            
            HStack(spacing: 8){
                Text(value).font(Font.system(size: 17, design: .default))
                if let detail {
                    Divider().frame(height:16)
                    Text(detail).font(.system(size: 17))
                }
            }
        }.padding(.vertical, 8, ).padding(.horizontal, 16).frame(width: 160, height: 55, alignment: .leading).background(.gray).cornerRadius(.card)
    }
}

#Preview {
    CardComponent(label: "ini label", value: "value")
}
