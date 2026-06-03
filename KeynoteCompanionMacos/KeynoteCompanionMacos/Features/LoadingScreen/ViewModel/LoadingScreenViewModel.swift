//
//  LoadingScreenViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 03/06/26.
//

import Combine
import Foundation

final class LoadingScreenViewModel: ObservableObject {
    @Published var title = "Ini adalah Loading Screen"
    
    func loadData() {
        // placeholder
    }
}
