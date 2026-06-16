//
//  HomeFooterView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation
import SwiftUI

struct HomeFooterView: View {
    let onActivitiesTapped: () -> Void

    var body: some View {
        Button(action: onActivitiesTapped) {
            Text("Activities")
                .font(AppFont.button)
                .foregroundStyle(AppColor.controlTextPrimary)
                .lineLimit(1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: AppSize.footerHeight)
    }
}
