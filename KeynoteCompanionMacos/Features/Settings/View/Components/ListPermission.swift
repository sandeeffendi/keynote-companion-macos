//
//  ListPermission.swift
//  KeynoteCompanionMacos
//
//  Created by Muhammad Arfian Praniza on 06/06/26.
//

import SwiftUI

struct ListPermission: View {
    var icon: String
    var title: String
    var description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                Image(systemName: icon)
            }
            .frame(width: 36, height: 56, alignment: .top)
            .font(AppFont.sizeIcon)
            
            Spacer()
                .frame(width: 16)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(AppFont.settingTitle)
                        .lineLimit(1)
                    Text(description)
                        .font(AppFont.settingDescription)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 396, height: 40, alignment: .leading)
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
            }
            
        }
        .padding(.top, AppSpacing.lg)
        .background(Color.clear)
    }
}
