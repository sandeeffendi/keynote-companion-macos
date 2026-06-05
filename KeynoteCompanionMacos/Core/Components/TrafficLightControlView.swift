//
//  GlassPanelView.swift
//  KeynoteCompanionMacos
//
//  Created by Sande Effendi on 05/06/26.
//

import AppKit
import SwiftUI

struct TrafficLightControlsView: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            trafficButton(color: AppColor.trafficClose) {
                NSApp.keyWindow?.close()
            }

            trafficButton(color: AppColor.trafficMinimize) {
                NSApp.keyWindow?.miniaturize(nil)
            }

            trafficButton(color: AppColor.trafficZoom) {
                NSApp.keyWindow?.zoom(nil)
            }
        }
    }

    private func trafficButton(
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(
                    width: AppSize.trafficLightSize,
                    height: AppSize.trafficLightSize
                )
        }
        .buttonStyle(.plain)
    }
}
