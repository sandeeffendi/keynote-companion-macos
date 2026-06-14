//
//  SlideRowView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 14/06/26.
//

import SwiftUI

struct SlideRowView: View {
    struct Ocean: Identifiable {
        let name: String
        let id = UUID()
    }
    
    private var oceans = [
        Ocean(name: "Pacific"),
        Ocean(name: "Atlantic"),
        Ocean(name: "Indian")
    ]
    
    var body: some View {
        List(oceans){ ocean in
            Button{
                
            }label:{
                HStack {
                    Text(ocean.name).font(.body)
                    Spacer()
                    Text("170 WPM").font(.body)
                    Image(systemName: "play.fill").font(.title2)
                }.padding(.vertical, 8).frame(maxWidth: .infinity)
            }.buttonStyle(.plain)
        }.listStyle(.plain).scrollContentBackground(.hidden)
    }
}

#Preview {
    SlideRowView().frame(maxWidth: .infinity).padding()
}
