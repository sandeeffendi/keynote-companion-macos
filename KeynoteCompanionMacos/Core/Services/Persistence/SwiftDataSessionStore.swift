//
//  SwiftDataSessionStore.swift
//  KeynoteCompanionMacos
//
//  SwiftData-backed `SessionStoring`. Not an actor: `ModelContext` is bound to the
//  main actor and is not Sendable, so the store is `@MainActor`. Save/fetch errors
//  are logged via os.Logger rather than silently swallowed.
//

import Foundation
import SwiftData
import os

@MainActor
final class SwiftDataSessionStore: SessionStoring {
    private let context: ModelContext

    private static let log = Logger(subsystem: "com.tiempo.persistence", category: "SessionStore")

    init(context: ModelContext) {
        self.context = context
    }

    /// Production wiring: shares the app's single container context with the
    /// History `@Query`.
    convenience init() {
        self.init(context: PersistenceController.shared.container.mainContext)
    }

    func save(_ recap: RecapModel) {
        context.insert(HistoryModel.make(from: recap))
        commit("save")
    }

    func updateTitle(of sessionID: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let record = record(for: sessionID) else { return }
        record.sesTitle = trimmed
        commit("updateTitle")
    }

    @discardableResult
    func delete(sessionID: UUID) -> Bool {
        guard let record = record(for: sessionID) else { return false }
        context.delete(record)
        return commit("delete")
    }

    // MARK: - Private

    private func record(for sessionID: UUID) -> HistoryModel? {
        let descriptor = FetchDescriptor<HistoryModel>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        do {
            return try context.fetch(descriptor).first
        } catch {
            Self.log.error("Fetch failed for session \(sessionID.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    @discardableResult
    private func commit(_ operation: StaticString) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            Self.log.error("\(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
