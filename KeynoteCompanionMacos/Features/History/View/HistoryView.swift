//
//  HistoryView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import SwiftUI

struct HistoryView: View {
    private var header: some View {
        HStack{
            Button{
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24)).frame(width: 36, height: 36)
            }.clipShape(Circle())
            HStack{
                Button{
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                }.clipShape(Circle()).buttonStyle(PlainButtonStyle()).padding(.leading, 10)
                TextField("Search", text: .constant("")).padding(.trailing,10).textFieldStyle(.plain)
                
            }.frame(width: .infinity, height:42).background(Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8, opacity: 0.2))
                .cornerRadius(100)
            Spacer()
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading){
            Text("Monday, 17 August 2026").font(.title2).bold()
            HStack{
                VStack{
                    Image(systemName: "text.document").font(.system(size: 22)).padding(.trailing,20)
                    Spacer()
                }
                VStack{
                    HStack{
                        Text("Pratice Recording 1").font(.title2)
                        Spacer()
                        Text("13.00").font(.title2)
                        Button{
                            
                        }label:{
                            Image(systemName: "chevron.right").font(.system(size: 22))
                        }.cornerRadius(100).buttonStyle(.plain).padding(.leading,10)
                    
                    }.padding(.bottom,10)
                 Divider()
                    Spacer()
                }
            }.padding(.leading,30).padding(.vertical,16)
        }.padding(16)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
           header
           content
        Spacer()
        }.frame(maxWidth: 560, minHeight: 700, alignment: .leading)
            .padding(24)
            .cornerRadius(.bgFeedback)
            .navigationTitle("Tiempo")
            .navigationBarBackButtonHidden()}
    }

#Preview {
    HistoryView()
}
