//
//  SessionStoring.swift
//  KeynoteCompanionMacos
//
//  Persistence boundary for practice-session history. Keeping SwiftData behind a
//  protocol lets Recap/History talk in terms of `RecapModel` and lets tests inject
//  an in-memory or mock store instead of touching the on-disk container.
//

import Foundation

@MainActor
protocol SessionStoring {

    // persist a finished session. failures are logged by the implementation
    func save(_ recap: RecapModel)

    // update the stored title for the session created from 'sessionID'
    func updateTitle(of sessionID: UUID, to title: String)

    // Delete the session created from 'sessionID'. Returns 'true' when a record was found and removed
    @discardableResult
    func delete(sessionID: UUID) -> Bool
}
