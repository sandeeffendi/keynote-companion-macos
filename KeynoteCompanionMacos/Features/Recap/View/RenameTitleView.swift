//
//  RenameTitleView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 18/06/26.
//

import SwiftUI
import AppKit

enum RenameAlert {
    static func show(currentTitle: String, onRename: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Rename Session"
        alert.informativeText = "Enter a new title for this session."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.stringValue = currentTitle
        textField.placeholderString = "New title"
        alert.accessoryView = textField

        alert.window.initialFirstResponder = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let newTitle = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newTitle.isEmpty {
                onRename(newTitle)
            }
        }
    }
}
