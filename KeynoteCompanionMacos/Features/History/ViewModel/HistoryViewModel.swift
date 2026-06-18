//
//  HistoryViewModel.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 07/06/26.
//

import Foundation
import Combine
import SwiftData

final class HistoryViewModel: ObservableObject {
    /// Groups sessions by their display date string, with sessions and groups
    /// ordered most-recent-first using the `createdAt` Date (chronologically correct).
    func grouped(_ sessions: [HistoryModel]) -> [(date: String, sessions: [HistoryModel])] {
        let grouped = Dictionary(grouping: sessions, by: { SessionFormatting.sessionDate($0.createdAt) })
        return grouped
            .map { (date: $0.key, sessions: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted {
                let maxA = $0.sessions.map(\.createdAt).max() ?? .distantPast
                let maxB = $1.sessions.map(\.createdAt).max() ?? .distantPast
                return maxA > maxB
            }
    }
}
