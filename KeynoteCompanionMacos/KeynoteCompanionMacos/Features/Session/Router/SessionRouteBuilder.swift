//
//  SessionRoute.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 03/06/26.
//

import Foundation
import SwiftUI

struct SessionRouteBuilder {
    @ViewBuilder

    static func build(_ route: SessionRoute) -> some View {
        switch route {
        case .main:
            SessionView(
                viewModel: SessionViewModel()
            )
        }
    }
}
