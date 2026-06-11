# Repository Guidelines

## Project Structure & Module Organization

This is a native macOS SwiftUI/AppKit project. The main Xcode project is `KeynoteCompanionMacos.xcodeproj`, with app source in `KeynoteCompanionMacos/` and tests in `KeynoteCompanionMacosTests/`.

Source is organized by responsibility:

- `App/`: app routing and root composition.
- `Core/`: shared components, design tokens, window utilities, and services.
- `Features/<Feature>/`: feature-local `Model`, `View`, `ViewModel`, and `Router` code.
- `Resources/`: asset catalogs and UI design references.

Keep feature code in the matching `Features/<Feature>/` folder. Put reusable UI, services, and design constants in `Core/`.

## Build, Test, and Development Commands

All shell commands in this repo should be prefixed with `rtk`.

```bash
rtk xcodebuild -list -project KeynoteCompanionMacos.xcodeproj
```

Lists targets, schemes, and build configurations.

```bash
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj -scheme KeynoteCompanionMacos -destination 'platform=macOS' -derivedDataPath .build/DerivedData build
```

Builds the app locally using a repo-local DerivedData directory.

```bash
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj -scheme KeynoteCompanionMacos -destination 'platform=macOS' -derivedDataPath .build/DerivedData test
```

Runs the XCTest target.

## Coding Style & Naming Conventions

Use Swift conventions: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and descriptive protocol names such as `KeynoteStatusChecking`. Prefer small SwiftUI views and `@MainActor` view models. Follow existing dependency-injection patterns so tests can provide mocks.

No formatter or linter configuration is currently checked in; match surrounding file style and keep imports, access control, and spacing tidy.

## Testing Guidelines

Tests use XCTest in `KeynoteCompanionMacosTests/`. Name test files after the unit under test, for example `HomeViewModelTests.swift`, and name methods as behavior statements such as `testMissingMicrophoneMapsToPermissionMissing()`.

Add tests for view-model logic, service state mapping, routing helpers, and window presenter behavior. Use mocks instead of real Keynote, microphone, or automation permissions where possible.

## Commit & Pull Request Guidelines

Git history mostly uses Conventional Commit style, for example `feat(session): implement session flow` and `fix(recap): fix recap routing on session flow`. Prefer `feat`, `fix`, `refactor`, or `test` with a concise scope.

Protected branches are `main` and `development`; do not push directly. Open PRs from `feature/*` or `bugfix/*` into `development`, and from `development`, `hotfix/*`, or `release/*` into `main`. PRs should include a short description, testing notes, linked issue when available, and screenshots or recordings for UI changes.

## Security & Configuration Tips

The app interacts with microphone permission, Apple Events automation, and Keynote availability. Do not hard-code local paths, personal provisioning details, or permission assumptions. Keep entitlements changes small and document why they are required.
