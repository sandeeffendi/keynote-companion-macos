//
//  HistoryMigrationPlan.swift
//  KeynoteCompanionMacos
//

import Foundation
import SwiftData

enum HistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        HistorySchemaV1.self,
        HistorySchemaV2.self
    ]

    static var stages: [MigrationStage] = [migrateV1toV2]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: HistorySchemaV1.self,
        toVersion: HistorySchemaV2.self
    )
}

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

enum HistorySchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [
        HistoryModel.self,
        Feedback.self
    ]
}
