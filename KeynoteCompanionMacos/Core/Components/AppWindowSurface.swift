//
//  AppWindowSurface.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct AppWindowSurface<Content: View>: View {
    private let content: Content

    private var windowShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: AppRadius.window,
            style: .continuous
        )
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            content
                .frame(
                    width: AppSize.homeWindowWidth,
                    height: AppSize.homeWindowHeight
                )
                .background(Color.clear)
                .glassEffect(.regular, in: windowShape)
                .clipShape(windowShape)
                .overlay {
                    windowShape
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                }
                .shadow(color: AppColor.shadow, radius: 28, x: 0, y: 18)
        }
        .frame(
            width: AppSize.homeWindowWidth,
            height: AppSize.homeWindowHeight
        )
        .background(AppWindowConfigurator())
        .containerBackground(.clear, for: .window)
    }
}
