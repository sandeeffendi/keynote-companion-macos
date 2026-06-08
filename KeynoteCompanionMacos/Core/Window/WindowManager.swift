//
//  WindowManager.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniadi on 07/06/26.
//

import AppKit

final class WindowManager {

    static let shared = WindowManager()

    func configureSplashWindow(
        _ window: NSWindow
    ) {

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.standardWindowButton(
            .closeButton
        )?.isHidden = true

        window.standardWindowButton(
            .miniaturizeButton
        )?.isHidden = true

        window.standardWindowButton(
            .zoomButton
        )?.isHidden = true

        window.setContentSize(
            NSSize(
                width: AppSize.splashWindowWidth,
                height: AppSize.splashWindowHeight
            )
        )
    }

    func configureMainWindow(
        _ window: NSWindow
    ) {

        window.standardWindowButton(
            .closeButton
        )?.isHidden = false

        window.standardWindowButton(
            .miniaturizeButton
        )?.isHidden = false

        window.standardWindowButton(
            .zoomButton
        )?.isHidden = false

        window.setContentSize(
            NSSize(
                width: AppSize.homeWindowWidth,
                height: AppSize.homeWindowHeight
            )
        )
    }
}
