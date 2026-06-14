//
//  NewSessionTip.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 06/06/26.
//

import SwiftUI
import TipKit

struct NewSessionTip: Tip {
    
    var title: Text{
        Text("Back Home")
    }
    var message: Text? {
        Text("Go back to home then start new session")
       }

    var image: Image? {
       Image(systemName: "square.and.arrow.up")
    }
    
    var rules: [Rule] {
        #Rule(SaveSessionTip.$doneTip) {
            $0 == true
        }
    }
}
