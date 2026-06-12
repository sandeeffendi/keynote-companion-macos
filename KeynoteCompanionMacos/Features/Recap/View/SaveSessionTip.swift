//
//  FeedbackTip.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 06/06/26.
//

import SwiftUI
import TipKit

struct SaveSessionTip: Tip {
    @Parameter
    static var doneTip: Bool = false
    
    var title: Text{
        Text("Save your recap")
    }
    var message: Text? {
        Text("Save your recap to history if you want to review it later")
    }
    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }
    
    var actions: [Action] {
        Action(
            id: "next",
            title: "Next"
        )
    }
}
