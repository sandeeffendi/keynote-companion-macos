//
//  WindowTrafficLightControlsView.swift
//  KeynoteCompanionMacos
//

import AppKit
import SwiftUI

struct WindowTrafficLightControlsView: View {
    @State private var isHoveringControls = false
    @State private var hostingWindow: NSWindow?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(WindowTrafficLightControl.allCases) { control in
                WindowTrafficLightButton(
                    color: control.color,
                    systemName: control.systemName,
                    showsSymbol: isHoveringControls,
                    accessibilityLabel: control.accessibilityLabel
                ) {
                    control.perform(on: targetWindow)
                }
            }
        }
        .background(WindowResolver { hostingWindow = $0 })
        .contentShape(Rectangle())
        .onHover { isHoveringControls = $0 }
    }

    private var targetWindow: NSWindow? {
        hostingWindow ?? NSApp.keyWindow ?? NSApp.mainWindow
    }
}

private struct WindowResolver: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}
