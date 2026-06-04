//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 03/06/26.
//

import SwiftUI

struct RecapView: View {
    
    @EnvironmentObject private var route: AppRouter
    @StateObject var viewModel: RecapViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            //navbar
            HStack{
                Button{
                    route.popToRoot()
                }label:{
                    Image(systemName: "chevron.backward").frame(maxHeight: 28)
                }
                .clipShape(Circle())
                Spacer()
                Button{
                    route.popToRoot()
                }label:{
                    Image(systemName: "trash.fill").frame(maxHeight: 50)
                }
                .clipShape(Circle())
                
            }
            //header
            VStack(alignment: .leading, spacing: 16){
                Text("Practice Recording 1").font(Font.title.bold())
                Text("Human Interface Guidelines Reading Materials")
                HStack{
                    Label("Monday, 17 August 2026", systemImage: "calendar")
                    Divider()
                    Label("10:00 AM", systemImage: "clock")
                    Divider()
                    Label("03:04:14", systemImage: "stopwatch")
                }
                Divider()
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            //content
            VStack(alignment: .leading, spacing:20){
                Text("WPM")
                HStack{
                    VStack(){
                        Text("Overall Speaking Rate")
                        Text("152 WPM")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 100).frame(minHeight:35) .background(.blue)
                    .cornerRadius(5)
                    Spacer()
                    VStack{
                        Text("Overall Speaking Rate")
                        Text("152 WPM")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 100).frame(minHeight:35) .background(.blue)
                    .cornerRadius(5)
                    Spacer()
                    VStack{
                        Text("Overall Speaking Rate")
                        Text("152 WPM")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 100).frame(minHeight:35) .background(.blue)
                    .cornerRadius(5)
                }
                HStack{
                    
                }
                Text("On slide 5, your speaking pace was quite fast at 190 WPM. Try slowing down a bit.")
            }
            //footer
            HStack{
                
            }
            
        }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Recap").navigationBarBackButtonHidden(true)
    }
}

#Preview {
    RecapView(
        viewModel: RecapViewModel()
    )
}
