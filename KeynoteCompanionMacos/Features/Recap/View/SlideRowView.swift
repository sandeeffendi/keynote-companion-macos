//
//  SlideRowView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 14/06/26.
//

import SwiftUI

struct SlideRowView: View {
    @EnvironmentObject private var router: AppRouter
    struct Ocean: Identifiable {
        let name: String
        let id = UUID()
    }
    
    private var oceans = [
        Ocean(name: "Pacific"),
        Ocean(name: "Atlantic"),
        Ocean(name: "Indian")
    ]
    
    
    @State var oceanID: String? = nil
    
    var body: some View {
        List(oceans){ ocean in
            VStack{
                Button{
                    withAnimation(.easeInOut(duration:0.2)){
                        oceanID = oceanID == ocean.name ? nil : ocean.name
                    }
                }label:{
                    HStack {
                        Text(ocean.name).font(.body)
                        Spacer()
                        Text("170 WPM").font(.body)
                            Image(systemName: "play.fill").font(.title2)
                        Image(systemName: oceanID == ocean.name ? "chevron.down" : "chevron.right").font(.title2)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
                
                if oceanID == ocean.name {
                    AttemptRowView()
                }
            }
        }.listStyle(.plain).scrollContentBackground(.hidden)
    }
}

#Preview {
    SlideRowView().frame(maxWidth: .infinity).padding()
}
