//
//  SelfieView.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 04/06/26.
//

import Foundation
import SwiftUI

struct SelfieView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject var viewModel: SelfieViewModel
    
    var body: some View {
        Text("Selfie View")
        Button("Go to Setting") {
            router.push(.settings(.general))
        }
    }
}
