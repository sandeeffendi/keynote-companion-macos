//
//  PersistenceController.swift
//  KeynoteCompanionMacos
//

import Foundation
import SwiftData
import os

nonisolated final class PersistenceController: Sendable {
    static let shared = PersistenceController()

    let container: ModelContainer

    private static let log = Logger(
        subsystem: "com.tiempo.persistence",
        category: "Store"
    )

    init(inMemory: Bool = false) {
        let schema = Schema([HistoryModel.self, HistoryFeedback.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        container = PersistenceController.makeContainer(
            schema: schema,
            configuration: configuration
        )
    }

    private static func makeContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            // Incompatible on disk store from an earlier schema (pre-production reset
            // is accepted). Discard the store files and rebuild from scratch.
            log.error(
                "Store open failed, resetting store: \(error.localizedDescription)"
            )
            destroyStore(at: configuration.url)
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: configuration
                )
            } catch {
                log.fault(
                    "Store rebuild failed, falling back to in-memory: \(error.localizedDescription)"
                )
                let memory = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                return try! ModelContainer(for: schema, configurations: memory)
            }
        }
    }

    private static func destroyStore(at url: URL) {
        let fileManager = FileManager.default
        // SwiftData/SQLite keeps the main store plus -shm/-wal sidecar files.
        for suffix in ["", "-shm", "-wal"] {
            let file = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: file)
        }
    }
}
