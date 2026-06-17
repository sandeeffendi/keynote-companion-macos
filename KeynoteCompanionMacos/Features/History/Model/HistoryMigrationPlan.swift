//
//  HistoryMigrationPlan.swift
//  KeynoteCompanionMacos
//

import Foundation
import SwiftData

enum HistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        HistorySchemaV1.self,
        HistorySchemaV2.self,
        HistorySchemaV3.self
    ]

    static var stages: [MigrationStage] = [migrateV1toV2, migrateV2toV3]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: HistorySchemaV1.self,
        toVersion: HistorySchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: HistorySchemaV2.self,
        toVersion: HistorySchemaV3.self
    )
}

// MARK: - V1: original schema (no audioFileURL)

enum HistorySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        HistorySchemaV1.HistoryModel.self,
        HistorySchemaV1.HistoryFeedback.self
    ]

    @Model
    final class HistoryModel {
        var sesTitle: String = ""
        var sesKeynote: String = ""
        var date: String = ""
        var time: String = ""
        var duration: String = ""

        @Relationship(deleteRule: .cascade)
        var feedbacks: [HistorySchemaV1.HistoryFeedback] = []

        init() {}
    }

    @Model
    final class HistoryFeedback {
        var title: String = ""
        var overall: Int = 0
        var unit: String = ""
        var tips: String = ""
        var subTitle: String = ""
        var category: String = ""
        var perSlideJSON: String = "[]"

        init() {}
    }
}

// MARK: - V2: added audioFileURL

enum HistorySchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [
        HistorySchemaV2.HistoryModel.self,
        HistorySchemaV2.HistoryFeedback.self
    ]

    @Model
    final class HistoryModel {
        var sesTitle: String = ""
        var sesKeynote: String = ""
        var date: String = ""
        var time: String = ""
        var duration: String = ""
        var audioFileURL: String? = nil

        @Relationship(deleteRule: .cascade)
        var feedbacks: [HistorySchemaV2.HistoryFeedback] = []

        init() {}
    }

    @Model
    final class HistoryFeedback {
        var title: String = ""
        var overall: Int = 0
        var unit: String = ""
        var tips: String = ""
        var subTitle: String = ""
        var category: String = ""
        var perSlideJSON: String = "[]"

        init() {}
    }
}

// MARK: - V3: added createdAt + sessionID (lightweight — both have defaults)

enum HistorySchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] = [
        HistoryModel.self,
        HistoryFeedback.self
    ]
}
