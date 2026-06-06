//
//  WindowTrafficLightControl.swift
//  KeynoteCompanionMacos
//

import AppKit
import SwiftUI

enum WindowTrafficLightControl: CaseIterable, Identifiable {
    case close
    case minimize
    case zoom

    var id: Self { self }

    var color: Color {
        switch self {
        case .close:
            AppColor.trafficClose
        case .minimize:
            AppColor.trafficMinimize
        case .zoom:
            AppColor.trafficZoom
        }
    }

    var systemName: String {
        switch self {
        case .close:
            "xmark"
        case .minimize:
            "minus"
        case .zoom:
            "arrow.up.left.and.arrow.down.right"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .close:
            "Close"
        case .minimize:
            "Minimize"
        case .zoom:
            "Zoom"
        }
    }

    func perform(on window: NSWindow?) {
        switch self {
        case .close:
            window?.close()
        case .minimize:
            window?.miniaturize(nil)
        case .zoom:
            window?.zoom(nil)
        }
    }
}
