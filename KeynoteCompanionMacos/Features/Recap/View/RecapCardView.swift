//
//  RecapCardView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 08/06/26.
//

import SwiftUI

struct RecapCardView: View {

    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Text("Average Speaking Rate").font(.subheadline)
                Spacer()
                Button{
                    
                }label: {
                    Text("Detail")
                }
            }
            Text("150").font(.largeTitle).padding(.top,15)
            Text("Words per Minute").font(.title2)
            Divider().padding(.vertical,8)
            Text("Top 3 slides with highest WPM").font(.body)
            SlideRowView()
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: .bgFeedback)
                .fill(Color.white)
                .stroke(.black, lineWidth: 1).frame(maxWidth: .infinity,maxHeight: .infinity)
        )
    }
}

#Preview {
    RecapCardView().frame(width: 248, height: 389)
}
