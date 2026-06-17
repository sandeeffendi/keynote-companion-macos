//
//  DeleteConfirm.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 18/06/26.
//

import SwiftUI

enum DeleteConfirmAlert {
    static func show(sessionTitle: String, onDelete: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "Delete \"\(sessionTitle)\"?"
        alert.informativeText = "This session and its recording will be permanently deleted. This action cannot be undone."
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Cancel")       // ← pertama, jadi default (biru)
        let deleteButton = alert.addButton(withTitle: "Delete")  // ← kedua, bisa destructive
        deleteButton.hasDestructiveAction = true

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {   // ← Delete sekarang second button
            onDelete()
        }
    }
}
