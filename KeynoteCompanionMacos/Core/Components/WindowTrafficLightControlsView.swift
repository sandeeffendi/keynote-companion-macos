//
//  WindowTrafficLightControlsView.swift
//  KeynoteCompanionMacos
//

import AppKit
import SwiftUI

struct WindowTrafficLightControlsView: View {
    @State private var isHoveringControls = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(WindowTrafficLightControl.allCases) { control in
                WindowTrafficLightButton(
                    color: control.color,
                    systemName: control.systemName,
                    showsSymbol: isHoveringControls,
                    accessibilityLabel: control.accessibilityLabel
                ) {
                    control.perform(on: activeWindow)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { isHoveringControls = $0 }
    }

    private var activeWindow: NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow
    }
}
