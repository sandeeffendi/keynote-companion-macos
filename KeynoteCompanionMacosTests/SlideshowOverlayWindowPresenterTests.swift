//
//  SlideshowOverlayWindowPresenterTests.swift
//  KeynoteCompanionMacosTests
//

import SwiftUI
import XCTest
@testable import KeynoteCompanionMacos

@MainActor
final class SlideshowOverlayWindowPresenterTests: XCTestCase {
    func testOverlayPanelConfigurationIsNonActivating() {
        let styleMask =
            SlideshowOverlayWindowPresenter<EmptyView>.overlayPanelStyleMask

        XCTAssertTrue(styleMask.contains(.nonactivatingPanel))
        XCTAssertTrue(styleMask.contains(.fullSizeContentView))
        XCTAssertTrue(styleMask.contains(.borderless))
    }

    func testOverlayPanelConfigurationKeepsSlideshowVisible() {
        let collectionBehavior =
            SlideshowOverlayWindowPresenter<EmptyView>
                .overlayPanelCollectionBehavior

        XCTAssertEqual(
            SlideshowOverlayWindowPresenter<EmptyView>.overlayPanelLevel,
            .screenSaver
        )
        XCTAssertTrue(collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(collectionBehavior.contains(.fullScreenAuxiliary))
        XCTAssertTrue(collectionBehavior.contains(.stationary))
    }
}
