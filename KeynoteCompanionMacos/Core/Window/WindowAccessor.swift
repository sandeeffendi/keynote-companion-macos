//
//  WindowAccessor.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 07/06/26.
//

import SwiftUI

struct WindowAccessor:
NSViewRepresentable {

    let callback: (NSWindow?) -> Void

    func makeNSView(
        context: Context
    ) -> NSView {

        let view = NSView()

        DispatchQueue.main.async {
            callback(view.window)
        }

        return view
    }

    func updateNSView(
        _ nsView: NSView,
        context: Context
    ) {}
}
