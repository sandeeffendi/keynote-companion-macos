//
//  SlideshowOverlayWindowPresenter.swift
//  KeynoteCompanionMacos
//

import AppKit
import CoreGraphics
import SwiftUI

struct SlideshowOverlayWindowPresenter<OverlayContent: View>:
    NSViewRepresentable {
    static var overlayPanelStyleMask: NSWindow.StyleMask {
        [
            .borderless,
            .fullSizeContentView,
            .nonactivatingPanel
        ]
    }

    static var overlayPanelLevel: NSWindow.Level {
        .screenSaver
    }

    static var overlayPanelCollectionBehavior:
        NSWindow.CollectionBehavior {
        [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
    }

    let isActive: Bool
    let size: CGSize
    private let overlayContent: OverlayContent

    init(
        isActive: Bool,
        size: CGSize,
        @ViewBuilder overlayContent: () -> OverlayContent
    ) {
        self.isActive = isActive
        self.size = size
        self.overlayContent = overlayContent()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(screenResolver: KeynoteSlideshowScreenResolver())
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            context.coordinator.update(
                parentWindow: view.window,
                isActive: isActive,
                size: size,
                overlayContent: overlayContent
            )
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.update(
                parentWindow: nsView.window,
                isActive: isActive,
                size: size,
                overlayContent: overlayContent
            )
        }
    }

    static func dismantleNSView(
        _ nsView: NSView,
        coordinator: Coordinator
    ) {
        coordinator.restore()
    }

    final class Coordinator {
        struct OriginalWindowState {
            let styleMask: NSWindow.StyleMask
            let level: NSWindow.Level
            let collectionBehavior: NSWindow.CollectionBehavior
            let wasVisible: Bool
        }

        private let screenResolver: KeynoteSlideshowScreenResolving
        private weak var parentWindow: NSWindow?
        private var originalWindowState: OriginalWindowState?
        private var hostingController: NSHostingController<OverlayContent>?
        private(set) var overlayPanel: NSPanel?

        init(screenResolver: KeynoteSlideshowScreenResolving) {
            self.screenResolver = screenResolver
        }

        func update(
            parentWindow: NSWindow?,
            isActive: Bool,
            size: CGSize,
            overlayContent: OverlayContent
        ) {
            guard let parentWindow else {
                if !isActive {
                    restore()
                }
                return
            }

            self.parentWindow = parentWindow

            if isActive {
                present(
                    parentWindow: parentWindow,
                    size: size,
                    overlayContent: overlayContent
                )
            } else {
                restore()
            }
        }

        func restore() {
            overlayPanel?.orderOut(nil)
            overlayPanel?.close()
            overlayPanel = nil
            hostingController = nil

            guard let parentWindow,
                  let originalWindowState else {
                return
            }

            parentWindow.level = originalWindowState.level
            parentWindow.styleMask = originalWindowState.styleMask
            parentWindow.collectionBehavior =
                originalWindowState.collectionBehavior

            if originalWindowState.wasVisible {
                parentWindow.orderFrontRegardless()
            }

            self.originalWindowState = nil
        }

        private func present(
            parentWindow: NSWindow,
            size: CGSize,
            overlayContent: OverlayContent
        ) {
            if originalWindowState == nil {
                originalWindowState = OriginalWindowState(
                    styleMask: parentWindow.styleMask,
                    level: parentWindow.level,
                    collectionBehavior: parentWindow.collectionBehavior,
                    wasVisible: parentWindow.isVisible
                )
            }

            let isNewPanel = overlayPanel == nil
            let panel = overlayPanel ?? makeOverlayPanel(size: size)
            let hostingController = hostingController
                ?? NSHostingController(rootView: overlayContent)
            hostingController.rootView = overlayContent
            hostingController.view.frame = NSRect(origin: .zero, size: size)

            if self.hostingController == nil {
                self.hostingController = hostingController
                panel.contentView = hostingController.view
            }

            overlayPanel = panel

            // Re-center when panel size changes (e.g. switching between recording
            // and idle states) so the resized panel lands in the right spot.
            let sizeChanged = !isNewPanel && panel.frame.size != size
            if sizeChanged {
                panel.setContentSize(size)
            }

            if isNewPanel {
                parentWindow.orderOut(nil)
            }

            if isNewPanel || sizeChanged {
                centerPanel(panel)
            }

            if isNewPanel {
                panel.orderFrontRegardless()
            }
        }

        // Resolves the Keynote slideshow screen and centers the panel on it.
        // CGRect is Sendable so extracting the frame inside assumeIsolated avoids
        // a Swift 6 Sendable violation from returning NSScreen directly.
        private func centerPanel(_ panel: NSPanel) {
            let screenFrame = MainActor.assumeIsolated {
                (screenResolver.slideshowScreen() ?? NSScreen.main)?.frame ?? .zero
            }
            let origin = NSPoint(
                x: screenFrame.midX - panel.frame.width / 2,
                y: screenFrame.midY - panel.frame.height / 2
            )
            panel.setFrameOrigin(origin)
        }

        private func makeOverlayPanel(size: CGSize) -> NSPanel {
            let panel = NonActivatingSlideshowPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask:
                    SlideshowOverlayWindowPresenter<OverlayContent>
                    .overlayPanelStyleMask,
                backing: .buffered,
                defer: false
            )
            panel.isReleasedWhenClosed = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level =
                SlideshowOverlayWindowPresenter<OverlayContent>
                .overlayPanelLevel
            panel.collectionBehavior =
                SlideshowOverlayWindowPresenter<OverlayContent>
                .overlayPanelCollectionBehavior
            panel.isMovableByWindowBackground = true
            panel.becomesKeyOnlyIfNeeded = true
            return panel
        }
    }
}

private final class NonActivatingSlideshowPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

@MainActor
protocol KeynoteSlideshowScreenResolving {
    func slideshowScreen() -> NSScreen?
}

@MainActor
private struct KeynoteSlideshowScreenResolver: KeynoteSlideshowScreenResolving {
    private let bundleIdentifiers = [
        "com.apple.Keynote",
        "com.apple.iWork.Keynote"
    ]

    func slideshowScreen() -> NSScreen? {
        guard let largestKeynoteWindowBounds else {
            return NSScreen.main
        }

        return NSScreen.screens.max { lhs, rhs in
            lhs.quartzFrame.intersectionArea(with: largestKeynoteWindowBounds)
                < rhs.quartzFrame.intersectionArea(
                    with: largestKeynoteWindowBounds
                )
        } ?? NSScreen.main
    }

    private var largestKeynoteWindowBounds: CGRect? {
        let keynoteProcessIdentifiers = Set(
            bundleIdentifiers
                .flatMap {
                    NSRunningApplication.runningApplications(
                        withBundleIdentifier: $0
                    )
                }
                .map(\.processIdentifier)
        )

        guard !keynoteProcessIdentifiers.isEmpty,
              let windowInfos = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
              ) as? [[String: Any]] else {
            return nil
        }

        return windowInfos
            .compactMap { windowInfo -> CGRect? in
                guard let ownerPID = windowInfo[
                    kCGWindowOwnerPID as String
                ] as? pid_t,
                      keynoteProcessIdentifiers.contains(ownerPID),
                      let boundsDictionary = windowInfo[
                        kCGWindowBounds as String
                      ] as? NSDictionary,
                      let bounds = CGRect(
                        dictionaryRepresentation: boundsDictionary
                            as CFDictionary
                      ),
                      bounds.width > 0,
                      bounds.height > 0 else {
                    return nil
                }

                return bounds
            }
            .max { lhs, rhs in
                lhs.area < rhs.area
            }
    }
}

private extension NSScreen {
    var quartzFrame: CGRect {
        guard let screenNumber = deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? NSNumber else {
            return frame
        }

        return CGDisplayBounds(CGDirectDisplayID(screenNumber.uint32Value))
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull else {
            return 0
        }

        return width * height
    }

    func intersectionArea(with rect: CGRect) -> CGFloat {
        intersection(rect).area
    }
}
