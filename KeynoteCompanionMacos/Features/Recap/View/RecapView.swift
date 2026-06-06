//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation
import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var route: AppRouter
    @StateObject private var viewModel: RecapViewModel

    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading) {
            //header
            VStack(alignment: .leading,spacing: 4){
                Text("Ini judul").font(.largeTitle.bold()) //title
                Text("Human Interface Guidelines Reading Materials").font(.title3).padding(.top, 8) //file keynote
                HStack{
                    HStack{
                        Image(systemName: "calendar")
                        Text("Monday, 17 August 2026")
                    }.frame(alignment: .leading)
                    Divider().frame(height: 14)
                    HStack{
                        Image(systemName: "clock")
                        Text("10:00").frame(alignment: .leading)
                    }
                    Divider().frame(height: 14)
                    HStack{
                        Image(systemName: "stopwatch")
                        Text("00:05:00").frame(alignment: .leading)
                    }
                }.padding(.top, 16)
            }
            Divider().padding(.vertical, 24)
            //content
            VStack(alignment: .leading){
                VStack(alignment: .leading, spacing: 10){
                    Text("Speaking Pace").font(.title2).bold()
                    HStack(spacing:30){
                        CardComponent()
                        CardComponent()
                        CardComponent()
                    }.frame(maxWidth: .infinity)
                    Text("• ini rekomendasi wpm")
                }.padding(.bottom, 32)
                VStack(alignment: .leading){
                    Text("Filler Words").font(.title2).bold()
                    HStack(spacing:30){
                        CardComponent()
                        CardComponent()
                        CardComponent()
                    }.frame(maxWidth: .infinity)
                    Text("• ini rekomendasi wpm")
                }.padding(.bottom, 32)
                VStack(alignment: .leading, spacing: 8){
                    Text("Tip").font(.title2).bold()
                    Text("• Latihan teratur setiap hari")
                }
            }
            Spacer()
            Divider().padding(.vertical, 24)
            //footer
            HStack{
                Button{
                } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 24)).frame(width: 48, height: 48)
                }.background(.cBtnSecondary).clipShape(Circle())
                Spacer()
                Button{
                }label: {
                    HStack{
                        Text("Record New Practice")
                    }.font(.system(size: 17)).foregroundColor(.white).frame(width: 194, height: 48)
                }.background(.cBtnPrimary).cornerRadius(.btnNonCircle)
            }
        }.frame(maxWidth: 560, minHeight: 700, alignment: .leading).navigationTitle("Tiempo").padding(24).cornerRadius(.bgFeedback).navigationBarBackButtonHidden()
    }
}

#Preview {
    RecapView(
        viewModel: RecapViewModel()
    )
}

