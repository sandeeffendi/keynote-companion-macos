//
//  SettingsViewModelTests.swift
//  KeynoteCompanionMacosTests
//

import XCTest
@testable import KeynoteCompanionMacos

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testProjectUsesProductionBundleIdentifiers() throws {
        let projectFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("KeynoteCompanionMacos.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let project = try String(contentsOf: projectFile, encoding: .utf8)

        XCTAssertTrue(
            project.contains("PRODUCT_BUNDLE_IDENTIFIER = com.kumpeni.Tiempo;")
        )
        XCTAssertTrue(
            project.contains("PRODUCT_BUNDLE_IDENTIFIER = com.kumpeni.TiempoTests;")
        )
        XCTAssertTrue(project.contains("PRODUCT_NAME = Tiempo;"))
        XCTAssertTrue(
            project.contains("PRODUCT_MODULE_NAME = KeynoteCompanionMacos;")
        )
        XCTAssertTrue(
            project.contains("TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/Tiempo.app/Contents/MacOS/Tiempo\";")
        )
    }

    func testAutomationRefreshUsesLatestRequestWhenPreviousRefreshCompletesLate() async {
        let service = ControllableAutomationPermissionService()
        let viewModel = SettingsViewModel(
            settingsData: SettingsModel(
                permissionItems: [
                    .microphone,
                    .keynoteAutomation,
                    .wpmDetector
                ]
            ),
            automationPermissionService: service
        )

        await service.waitForPendingRequestCount(1)
        viewModel.refreshAllPermissionStatuses()
        await service.waitForPendingRequestCount(2)

        await service.resumeOldest(with: .denied)
        await service.resumeOldest(with: .authorized)
        await waitUntil {
            viewModel.currentStatus(for: .keynoteAutomation) == .authorized
        }

        XCTAssertTrue(viewModel.isPermissionEnabled(.keynoteAutomation))
    }

    func testAutomationToggleRequestsPromptWhenStatusIsNotDetermined() async {
        let service = RecordingAutomationPermissionService(
            statuses: [.notDetermined, .authorized]
        )
        let viewModel = SettingsViewModel(
            settingsData: SettingsModel(
                permissionItems: [
                    .microphone,
                    .keynoteAutomation,
                    .wpmDetector
                ]
            ),
            automationPermissionService: service
        )

        await waitUntil {
            viewModel.currentStatus(for: .keynoteAutomation) == .notDetermined
        }

        viewModel.togglePermission(for: .keynoteAutomation, newValue: true)
        await waitUntil {
            viewModel.currentStatus(for: .keynoteAutomation) == .authorized
        }

        let prompts = await service.promptRequests()
        XCTAssertEqual(prompts, [false, true])
        XCTAssertTrue(viewModel.isPermissionEnabled(.keynoteAutomation))
    }
}

private actor ControllableAutomationPermissionService:
    KeynoteAutomationPermissionChecking {

    private var continuations:
        [CheckedContinuation<KeynoteAutomationPermissionState, Never>] = []

    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func waitForPendingRequestCount(_ count: Int) async {
        while continuations.count < count {
            await Task.yield()
        }
    }

    func resumeOldest(with status: KeynoteAutomationPermissionState) {
        continuations.removeFirst().resume(returning: status)
    }
}

private actor RecordingAutomationPermissionService:
    KeynoteAutomationPermissionChecking {

    private var statuses: [KeynoteAutomationPermissionState]
    private var prompts: [Bool] = []

    init(statuses: [KeynoteAutomationPermissionState]) {
        self.statuses = statuses
    }

    func authorizationStatus(
        promptIfNeeded: Bool
    ) async -> KeynoteAutomationPermissionState {
        prompts.append(promptIfNeeded)

        if statuses.isEmpty {
            return .denied
        }

        return statuses.removeFirst()
    }

    func promptRequests() -> [Bool] {
        prompts
    }
}

@MainActor
private func waitUntil(
    _ condition: @escaping @MainActor () -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<100 {
        if condition() {
            return
        }

        await Task.yield()
    }

    XCTFail("Condition was not met", file: file, line: line)
}
