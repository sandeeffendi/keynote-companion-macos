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
    let onCanceltapped: () -> Void

    let viewState: HomeViewState
    private var isRecordPracticeActive: Bool {
        viewState == .keynoteSlideshowActive   // ganti dengan case yang sesuai
    }
    
    var body: some View {
        
        if isRecordPracticeActive {
            Button(action: onCanceltapped) {
                Text("Cancel")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.destructive)
                    .lineLimit(1)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: AppSize.footerHeight)
            
        }
        else{
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
}
