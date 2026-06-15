//
//  SettingsModel.swift
//  KeynoteCompanionMacos
//

import Foundation

struct SettingsModel: Sendable {
    var permissionItems: [PermissionItem]
}

struct PermissionItem: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    var isEnabled: Bool = false
    var status: PermissionStatus = .notDetermined
    var permissionType: PermissionType
}
