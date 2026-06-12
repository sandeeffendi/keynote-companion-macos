# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

All `xcodebuild` commands must be prefixed with `rtk`.

```bash
# List targets, schemes, and configurations
rtk xcodebuild -list -project KeynoteCompanionMacos.xcodeproj

# Build
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj \
  -scheme KeynoteCompanionMacos \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData build

# Run all tests
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj \
  -scheme KeynoteCompanionMacos \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData test

# Run a single test method
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj \
  -scheme KeynoteCompanionMacos \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  -only-testing:KeynoteCompanionMacosTests/HomeViewModelTests/testInternalStatusMapsToVisibleStates test
```

## Architecture Overview

**TiempoMacOS** is a macOS SwiftUI app that monitors Keynote presentations and displays a floating overlay during active slideshows. The Xcode project is `KeynoteCompanionMacos.xcodeproj`; app source lives in `KeynoteCompanionMacos/` and tests in `KeynoteCompanionMacosTests/`.

### Routing

Navigation uses a custom `AppRouter` (`App/AppRouter.swift`) — an `ObservableObject` that owns a `[AppRoute]` path array backed by SwiftUI's `NavigationStack`. `AppRoute` is a top-level enum (`App/AppRoute.swift`) whose cases wrap per-feature route enums (e.g. `AppRoute.home(HomeRoute)`). Each feature exposes a `<Feature>RouteBuilder` factory with a static `build(_:)` method used inside `.navigationDestination`.

`RootView` controls window sizing reactively: it reads `router.activeRoute` and maps it to one of the `AppSize` constants, so the window resizes on every navigation push/pop.

### Feature Structure

Each feature under `Features/<Feature>/` follows a strict four-layer layout:

```
Features/<Feature>/
  Model/       — plain data types and domain enums
  View/        — SwiftUI views (composed from small sub-views)
  ViewModel/   — @MainActor ObservableObject, injected with protocol-typed services
  Router/      — <Feature>Route enum + <Feature>RouteBuilder factory
```

Current features: `Home`, `Settings`, `Recap`, `History`, `Onboarding`, `Help`, `LoadingScreen`.

### Core Layer

`Core/` holds everything shared:

- **DesignSystem** — `AppColor`, `AppFont`, `AppIcon`, `AppRadius`, `AppSpacing`, `AppSize`. All UI constants come from here; never use raw literals.
- **Components** — reusable SwiftUI views (`PillButton`, `IconCircleButton`, `WindowHeaderView`, `WindowTrafficLightControl*`).
- **Services/Keynote** — `KeynoteStatusService` (`actor`) polls Keynote state via AppleScript; `KeynoteSlideTrackingService` (`actor`) polls current slide number via AppleScript; `KeynoteAutomationPermissionService` checks/requests Apple Events permission; `KeynoteFileOpener` opens `.key` files via AppleScript. All are injected via protocols (`KeynoteStatusChecking`, `KeynoteSlideTracking`, `KeynoteAutomationPermissionChecking`, `KeynoteFileOpening`).
- **Services/Permissions** — `MicrophonePermissionService` wraps `AVCaptureDevice` authorization; `SpeechRecognitionPermissionService` wraps `SFSpeechRecognizer` authorization. Both injected via `*PermissionChecking` protocols.
- **Services/Audio** — `AudioCaptureService` (`actor`) owns the `AVAudioEngine` and an `AVAudioFile`. **Do not add `AVAudioRecorder`** — on macOS sandbox, `AVAudioRecorder` and `AVAudioEngine` cannot both consume the same input device reliably. The single tap callback fans out to both `SFSpeechAudioBufferRecognitionRequest.append(buffer)` (for live WPM streaming) and `AVAudioFile.write(from: buffer)` (for the recap audio file). `SpeechRecognitionService` (`actor`) owns the `SFSpeechRecognitionTask`.
- **Window** — `SlideshowOverlayWindowPresenter` is an `NSViewRepresentable` that creates an `NSPanel` at `.screenSaver` window level spanning the Keynote slideshow screen. When active, it hides the companion window and shows the overlay; `restore()` reverses this. `KeynoteSlideshowScreenResolver` picks the right screen by intersecting Keynote's `CGWindowListCopyWindowInfo` bounds with `NSScreen.screens`.

### Persistence

`HistoryModel` and `HistoryFeedback` are SwiftData `@Model` classes. The `modelContainer(for:)` is set up in `KeynoteCompanionMacosApp`. Per-slide data inside `HistoryFeedback` is stored as a JSON string (`perSlideJSON`) because SwiftData doesn't natively serialize arrays of `Codable` structs.

### Dependency Injection Pattern

View models have a `convenience init()` that wires concrete implementations, and a full `init(...)` that accepts protocol types. Tests provide mock implementations through the full initializer — never use real Keynote, microphone, or automation permissions in tests.

### Practice Feature Notes

The Practice feature lives at `Features/Practice/` and is the most fragile part of the app. A few conventions exist specifically to keep it working:

- **Keynote slide tracking AppleScript.** `KeynoteSlideTrackingService` reads `slide number of current slide of front document` (with a nested `on error` fallback to `document 1`). **Do not use `front slideshow` or `first slideshow`** — `slideshow` is not a valid object class in Keynote's scripting dictionary and the script fails with `Expected class name, etc. but found identifier.` `front document` works in both edit and playing modes, so no `playing` branching is needed.
- **Audio pipeline.** See the `Services/Audio` note above. The tap is installed using `inputNode.outputFormat(forBus: 0)`. The matching `AVAudioFile` is created with `format.settings` so the writer accepts the buffers as-is (typically 48 kHz Float32 `.caf`, playable via `AVAudioPlayer`).
- **Auto-stop on slideshow exit.** `HomeView` is the orchestration layer: it owns both `HomeViewModel` and `PracticeViewModel` as `@StateObject`. A single `.onChange(of: viewModel.state)` modifier calls `practiceViewModel.stop()` when `HomeViewModel.state` leaves `.keynoteSlideshowActive` while `practiceViewModel.isRecording` is `true`. **Do not couple the ViewModels to each other**; they remain isolated and only HomeView is the glue. The existing `onSessionFinished` closure handles the navigation to Recap automatically.
- **Cleanup safety net.** `PracticeViewModel.deinit` fires a `Task.detached` to `coordinator.stop()` so the audio engine and mic are always released if the view hierarchy tears down.
- **Observability.** Logger subsystem `com.tiempo.practice`, category `Coordinator`. Use it from any new diagnostic code in the Practice feature so logs aggregate. Stream live with `log stream --level debug --predicate 'subsystem == "com.tiempo.practice"'`.

## Testing Conventions

- Test files named after the unit: `HomeViewModelTests.swift`, `SettingsViewModelTests.swift`.
- Test methods use behavior statements: `testInternalStatusMapsToVisibleStates()`.
- Mark test classes `@MainActor` when the subject is `@MainActor`.

## Coding Style

- 4-space indentation, `UpperCamelCase` types, `lowerCamelCase` properties/methods.
- Protocol names describe capability: `KeynoteStatusChecking`, `KeynoteFileOpening`.
- Services that perform I/O are `actor`; view models are `@MainActor final class`.
- Prefer small, focused SwiftUI views composed from sub-views.

## Git & Branch Policy

- `main` and `development` are protected — no direct push, no force push.
- Feature work: branch `feature/<name>` from `development`; open a PR into `development`.
- Releases/hotfixes: `release/<version>` or `hotfix/<name>` → PR into `main`.
- Use squash merge; delete the branch after merge.
- Commit messages follow Conventional Commits with a scope: `feat(session): …`, `fix(recap): …`, `refactor(window): …`.
