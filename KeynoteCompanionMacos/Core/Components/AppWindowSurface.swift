//
//  AppWindowSurface.swift
//  KeynoteCompanionMacos
//

import SwiftUI

struct AppWindowSurface<Content: View>: View {
    private let width: CGFloat
    private let height: CGFloat
    private let content: Content

    private var windowShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: AppRadius.window,
            style: .continuous
        )
    }

    init(
        width: CGFloat,
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            content
                .frame(
                    width: width,
                    height: height
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
            width: width,
            height: height
        )
        .background(AppWindowConfigurator())
        .containerBackground(.clear, for: .window)
    }
}
