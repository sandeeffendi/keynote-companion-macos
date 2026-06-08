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
    func grouped(_ sessions: [HistoryModel]) -> [(date: String, sessions: [HistoryModel])] {
        let grouped = Dictionary(grouping: sessions, by: { $0.date })
        return grouped
            .map { (date: $0.key, sessions: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
