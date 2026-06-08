//
//  LoadingScreenView.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 07/06/26.
//

import SwiftUI

struct LoadingScreenView: View {

    let onFinished: @MainActor () -> Void

    var body: some View {

        ZStack {

            Text("TIEMPO.")
                .font(
                    .system(
                        size: 25,
                        weight: .semibold
                    )
                )
                .foregroundStyle(AppColor.textPrimary)
                .tracking(6)
                .accessibilityLabel("Tiempo")

            ProgressView()
                .controlSize(.small)
                .scaleEffect(1.5)
                .offset(y: AppSize.splashWindowHeight * 0.25)
                .accessibilityLabel("Loading Tiempo")
        }
        .frame(
            width: AppSize.splashWindowWidth,
            height: AppSize.splashWindowHeight
        )
        .task {
            do {
                try await Task.sleep(
                    for: .seconds(3)
                )

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    onFinished()
                }
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView(
            onFinished: {}
        )
    }
}
