//
//  SettingsModel.swift
//  KeynoteCompanionMacos
//

import Foundation

struct SettingsModel {
    var permissionItems: [PermissionItem]
}

struct PermissionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    var isEnabled: Bool = false
    var permissionType: PermissionType
}
