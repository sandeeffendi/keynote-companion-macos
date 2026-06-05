//
//  GlassPanelView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import Foundation
import SwiftUI

struct GlassPanelView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: AppSpacing.lg) {
            content
                .frame(
                    width: AppSize.homeWindowWidth,
                    height: AppSize.homeWindowHeight
                )
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.window,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.window,
                        style: .continuous
                    )
                    .stroke(AppColor.borderSubtle, lineWidth: 1)
                }
                .shadow(color: AppColor.shadow, radius: 28, x: 0, y: 18)
        }
    }
}
