//
//  SessionStoreTests.swift
//  KeynoteCompanionMacosTests
//
//  Exercises SwiftDataSessionStore against a retained in-memory container, and the
//  RecapViewModel<->SessionStoring wiring through a mock. Methods are `async` so
//  XCTest runs them on the main actor (the store/context are main-actor bound).
//

import XCTest
import SwiftData
@testable import KeynoteCompanionMacos

@MainActor
final class SessionStoreTests: XCTestCase {

    /// Returns the container alongside the store so the caller keeps it alive — a
    /// `ModelContext` whose container is deallocated traps on use.
    private func makeStore() throws -> (SwiftDataSessionStore, ModelContainer) {
        let schema = Schema([HistoryModel.self, HistoryFeedback.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        return (SwiftDataSessionStore(context: container.mainContext), container)
    }

    private func recap(title: String = "Session") -> RecapModel {
        RecapModel(sesTitle: title, sesKeynote: "Deck.key", durationSeconds: 120, feedback: [])
    }

    private func allSessions(_ container: ModelContainer) throws -> [HistoryModel] {
        try container.mainContext.fetch(FetchDescriptor<HistoryModel>())
    }

    func testSavePersistsSession() async throws {
        let (store, container) = try makeStore()
        let recap = recap(title: "Saved")

        store.save(recap)

        let stored = try allSessions(container)
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.sesTitle, "Saved")
        XCTAssertEqual(stored.first?.sessionID, recap.id)
        XCTAssertEqual(stored.first?.durationSeconds, 120)
    }

    func testUpdateTitleChangesStoredRecord() async throws {
        let (store, container) = try makeStore()
        let recap = recap(title: "Old")
        store.save(recap)

        store.updateTitle(of: recap.id, to: "New Title")

        XCTAssertEqual(try allSessions(container).first?.sesTitle, "New Title")
    }

    func testUpdateTitleIgnoresBlankTitle() async throws {
        let (store, container) = try makeStore()
        let recap = recap(title: "Keep")
        store.save(recap)

        store.updateTitle(of: recap.id, to: "   ")

        XCTAssertEqual(try allSessions(container).first?.sesTitle, "Keep")
    }

    func testDeleteRemovesMatchingSession() async throws {
        let (store, container) = try makeStore()
        let recap = recap()
        store.save(recap)

        XCTAssertTrue(store.delete(sessionID: recap.id))
        XCTAssertTrue(try allSessions(container).isEmpty)
    }

    func testDeleteUnknownSessionReturnsFalse() async throws {
        let (store, container) = try makeStore()
        XCTAssertFalse(store.delete(sessionID: UUID()))
        XCTAssertTrue(try allSessions(container).isEmpty)
    }

    // MARK: - ViewModel wiring (mock store)

    func testAutoSaveSavesOnceThenNoOps() async {
        let mock = MockSessionStore()
        let vm = RecapViewModel(recapData: recap(title: "A"), store: mock)

        vm.autoSave()
        vm.autoSave()

        XCTAssertEqual(mock.saved.count, 1)
        XCTAssertEqual(mock.saved.first?.sesTitle, "A")
    }

    func testUpdateTitleUpdatesInMemoryAndPersists() async {
        let mock = MockSessionStore()
        let original = recap(title: "Before")
        let vm = RecapViewModel(recapData: original, store: mock)

        vm.updateTitle("After")

        XCTAssertEqual(vm.recapData.sesTitle, "After")
        XCTAssertEqual(mock.updatedTitles.first?.id, original.id)
        XCTAssertEqual(mock.updatedTitles.first?.title, "After")
    }

    func testDeleteSessionDelegatesToStore() async {
        let mock = MockSessionStore()
        mock.deleteResult = true
        let recap = recap()
        let vm = RecapViewModel(recapData: recap, store: mock)

        XCTAssertTrue(vm.deleteSession())
        XCTAssertEqual(mock.deleted, [recap.id])
    }
}

@MainActor
private final class MockSessionStore: SessionStoring {
    private(set) var saved: [RecapModel] = []
    private(set) var updatedTitles: [(id: UUID, title: String)] = []
    private(set) var deleted: [UUID] = []
    var deleteResult = true

    func save(_ recap: RecapModel) { saved.append(recap) }

    func updateTitle(of sessionID: UUID, to title: String) {
        updatedTitles.append((sessionID, title))
    }

    func delete(sessionID: UUID) -> Bool {
        deleted.append(sessionID)
        return deleteResult
    }
}
