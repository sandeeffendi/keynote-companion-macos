//
//  RecapView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Foundation
import SwiftUI
import TipKit
import SwiftData

struct RecapView: View {
    @EnvironmentObject private var route: AppRouter
    @StateObject private var viewModel: RecapViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let saveTip = SaveSessionTip()
    let newTip = NewSessionTip()
    @State var saveToHistory: Bool = false
    
    init(viewModel: RecapViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var header: some View {        //header
            VStack(alignment: .leading,spacing: 4){
                Text(viewModel.recapData.sesTitle).font(.largeTitle.bold()) //title
                Text(viewModel.recapData.sesKeynote).font(.title3).padding(.top, 8) //file keynote
                HStack{
                    Label(viewModel.recapData.date, systemImage: "calendar")
                    Divider().frame(height: 14)
                    Label(viewModel.recapData.time, systemImage: "clock")
                    Divider().frame(height: 14)
                    Label(viewModel.recapData.duration, systemImage: "stopwatch")
                }.padding(.top, 16)
            }
    }
    //tip
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tip").font(.title2.bold())
            ForEach(viewModel.recapData.tips, id: \.self) { tip in
                Text("• \(tip)")
            }
        }
    }
    
    private var footer: some View {
        //footer
        HStack{
            Button{
                guard !saveToHistory else { return }
                viewModel.saveRecap(context: modelContext)
                saveToHistory = true
            } label: {
                Image(systemName: saveToHistory ? "bookmark.fill" : "bookmark" )
                    .font(.system(size: 24)).frame(width: 48, height: 48)
            }.background(.cBtnSecondary).clipShape(Circle()).popoverTip(saveTip) { action in
                
                guard action.id == "next" else {
                    return
                }

                SaveSessionTip.doneTip = true

                saveTip.invalidate(
                    reason: .actionPerformed
                )
            }
            Spacer()
            Button{
                route.pop()
                route.push(.home(.main))
            }label: {
                HStack{
                    Text("Record New Practice")
                }.font(.system(size: 17)).foregroundColor(.white).frame(width: 194, height: 48)
            }.background(.cBtnPrimary).cornerRadius(.btnNonCircle)
                .popoverTip(newTip)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            Divider().padding(.vertical, 24)
            VStack(alignment: .leading, spacing: 32) {
                RecapSection(title: "Speaking Pace", metric: viewModel.recapData.wpm)
                RecapSection(title: "Filler Words",  metric: viewModel.recapData.filler)
                tipSection
            }
            Spacer()
            Divider().padding(.vertical, 24)
            footer
        }
        .frame(maxWidth: 560, minHeight: 700, alignment: .leading)
        .padding(24)
        .cornerRadius(.bgFeedback)
        .navigationTitle("Tiempo")
        .navigationBarBackButtonHidden()
    }

}

#Preview {
    RecapView(
        viewModel: RecapViewModel()
    )
}

