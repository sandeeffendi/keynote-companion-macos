//
//  RecapViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 04/06/26.
//

import Combine
import Foundation
import SwiftUI

final class RecapViewModel: ObservableObject {
    @Published var recapData: RecapModel

    init(
        recapData: RecapModel = RecapModel(
            title: "Ini adalah recap screen",
            subTitle: "PIC: Dina"
        )
    ) {
        self.recapData = recapData
    }

    func loadRecapData() {
        // ini adalha function placeholder untuk viewmodel recap data
    }

}
