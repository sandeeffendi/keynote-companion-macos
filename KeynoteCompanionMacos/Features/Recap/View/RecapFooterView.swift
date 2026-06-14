//
//  RecapFooterView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 12/06/26.
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import TipKit


struct RecapFooterView: View {
    var body: some View {
        VStack{
            Divider().padding(.vertical, 24)
            HStack{
                Spacer()
                Button{
                    
                }label:{
                    Label("Back to Home", systemImage: "house.fill").font(.title3).padding(7)
                }
            }
        }
    }
    
    
}

#Preview {
    RecapFooterView()
}
