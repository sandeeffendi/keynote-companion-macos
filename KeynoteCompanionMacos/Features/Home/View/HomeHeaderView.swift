//
//  HomeHeaderView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import SwiftUI

struct HomeHeaderView: View {
    let onHeaderActionTapped: () -> Void

    var body: some View {
        WindowHeaderView(title: "Tiempo") {
            IconCircleButton(
                systemName: AppIcon.headerAction,
                action: onHeaderActionTapped
            )
        }
    }
}
