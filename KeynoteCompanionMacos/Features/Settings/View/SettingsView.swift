//
//  SettingsView.swift
//  KeynoteCompanionMacos
//

import SwiftUI

// Feature ini masih belum ada PICnya

struct SettingsView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .center) {
            
            VStack(alignment: .leading) {
                Button {
                    router.popToRoot()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.nativeCircle)
                
                Text("Settings")
                    .font(AppFont.settingHead)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)

            List {
                ForEach($viewModel.settingsData.permissionItems) { $permissionItems in
                    ListPermission(
                        icon: permissionItems.icon,
                        title: permissionItems.title,
                        description: permissionItems.description,
                        isOn: $permissionItems.isEnabled
                    )
                }
            }

        }
        .frame(
            maxWidth: AppSize.homeWindowWidth,
               maxHeight: AppSize.homeWindowHeight
        )
        .background(Color.clear)
        .padding(AppSpacing.xl)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
