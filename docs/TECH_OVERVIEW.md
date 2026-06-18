# Tiempo — Technical Overview

> **Last updated:** 2026-06-17  
> **Status:** Pre-production (heading to TestFlight)  
> **Target:** macOS 26.2+  
> **Bundle ID:** `com.kumpeni.Tiempo`

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Feature Map](#feature-map)
4. [Service Layer](#service-layer)
5. [Data Model](#data-model)
6. [Practice Pipeline](#practice-pipeline)
7. [Navigation System](#navigation-system)
8. [Design System](#design-system)
9. [Build & Test](#build--test)
10. [Known Issues & Bug History](#known-issues--bug-history)
11. [Development Changelog](#development-changelog)
12. [Next Milestones](#next-milestones)

---

## Project Overview

**Tiempo** is a native macOS public-speaking coach. It detects a live Keynote slideshow, overlays a floating panel with real-time words-per-minute (WPM) feedback, records the presenter's voice, and produces a per-slide recap session.

| Property | Value |
|---|---|
| Xcode project | `KeynoteCompanionMacos.xcodeproj` |
| Scheme | `KeynoteCompanionMacos` |
| App entry | `KeynoteCompanionMacosApp.swift` |
| Target | `Tiempo` |
| Deployment | macOS 26.2 |
| Language | Swift + SwiftUI + AppKit |
| Dependencies | None (zero third-party) |
| Persistence | SwiftData (local SQLite) |
| Observability | `os.Logger` subsystem `com.tiempo.practice` |

**Entitlements configured:** microphone, speech recognition, Keynote automation (Apple Events), network client, app sandbox, temporary-exception Apple Events for `com.apple.Keynote` and `com.apple.iWork.Keynote`.

---

## Architecture

### Layer diagram

```
KeynoteCompanionMacosApp
 └── AppRouter (ObservableObject)            ← single navigation owner
      └── RootView (NavigationStack)
           └── AppRouteBuilder → <Feature>RouteBuilder
                └── <Feature>View
                     ├── <Feature>ViewModel  (@MainActor, ObservableObject)
                     └── <Service>           (actor, protocol-typed)
```

### Four-layer feature structure (enforced)

Every feature under `Features/<Feature>/` must have:

```
Features/
  <Feature>/
    Model/      ← pure value types / SwiftData @Model classes
    View/       ← SwiftUI views (no business logic)
    ViewModel/  ← @MainActor final class ObservableObject
    Router/     ← <Feature>Route enum + <Feature>RouteBuilder struct
```

### ViewModel initializer pattern

Every ViewModel has **two initializers**:

```swift
// Production: wires concrete services
convenience init() {
    self.init(service: ConcreteService())
}

// Test injection: protocol-typed dependencies
init(service: SomeProtocol) { ... }
```

### Service pattern

I/O services are `actor` types behind protocols:

```swift
protocol AudioCapturing: Sendable {
    func start(speechRequest: SFSpeechAudioBufferRecognitionRequest) async throws
    // ...
}

actor AudioCaptureService: AudioCapturing { ... }
```

---

## Feature Map

| Feature | Status | Key files |
|---|---|---|
| **Onboarding** | Complete (simplified) | `Features/Onboarding/` |
| **Home** | Complete | `Features/Home/` |
| **Permissions Sheet** | Complete | `Features/Home/View/PermissionsSheetView.swift` |
| **Practice (live WPM)** | Complete — pending real-session verify | `Features/Practice/` |
| **Recap** | Complete (navigation fixed 2026-06-17) | `Features/Recap/` |
| **History** | Complete (sort fixed 2026-06-17) | `Features/History/` |
| **Settings** | Present in code, unreachable from UI | `Features/Settings/` |
| **Help** | Present in code | `Features/Help/` |
| **Filler Words detection** | Research phase only | — |
| **TestFlight / CI** | Not started | — |

### Home states

`HomeViewState` drives the entire Home screen UI:

```
permissionMissing      → PillButton: "Allow Access"     → opens PermissionsSheet
noKeynoteFileOpen      → PillButton: "Open Keynote File" → opens Keynote via AppleScript
noKeynoteSlideshowActive → PillButton: "Open Keynote"   → (window floats)
keynoteSlideshowActive → PillButton: "Record Practice"  → starts Practice session
```

Window floats above other apps for `noKeynoteFileOpen` and `noKeynoteSlideshowActive` states so Tiempo stays visible when Keynote is frontmost.

---

## Service Layer

### Permissions

| Service | Protocol | Notes |
|---|---|---|
| `MicrophonePermissionService` | `MicrophoneChecking` | AVAudioApplication |
| `SpeechPermissionService` | `SpeechChecking` | SFSpeechRecognizer |
| `KeynoteAutomationPermissionService` | `KeynoteAutomationChecking` | Apple Events TCC |
| `KeynoteAutomationStatusStore` | `KeynoteAutomationStatusStoring` | Caches last determinable result in UserDefaults (`keynote.automation.lastKnownStatus`) |

**Critical:** Keynote automation status is unknown when Keynote is not running. The status store caches the last *determinable* result and stays synced — `HomeViewModel` uses this cache to gate navigation correctly when Keynote is closed.

### Keynote integration

- `KeynoteStatusService` — polls via AppleScript, queries `front document` (NOT `slideshow` — that class doesn't exist in Keynote's dictionary).
- `KeynoteSlideTrackingService` — returns current slide number, polled every ~1s during practice.

**AppleScript pattern:**
```applescript
tell application "Keynote"
    try
        set d to front document
        -- work with d
    on error
        try
            set d to document 1
        on error
            -- no document open
        end try
    end try
end tell
```

### Audio

- `AudioCaptureService` — `AVAudioEngine` records to `.caf` file in app sandbox `Application Support`. Simultaneously taps audio buffers into the speech recognition request via a lock-protected `SpeechRequestBox`.
- **Do NOT** add an `AVAudioRecorder` — it contends with `AVAudioEngine` for the input device under sandbox.
- Audio file URL stored as `absoluteString`. Path is stable within one install; re-installs change the sandbox container path.

### Speech Recognition

- Service: `SpeechRecognitionService`, locale `id-ID` (Bahasa Indonesia).
- **Never** set `requiresOnDeviceRecognition = true` on macOS — `supportsOnDeviceRecognition` returns `true` even when the model is not installed, causing error 1101 with no results.
- Server recognition (network.client entitlement present) is reliable and used by default.

---

## Data Model

### SwiftData schema (V3, current)

```
HistoryModel                        HistoryFeedback
─────────────────────────────       ────────────────────────────
sesTitle: String                    title: String
sesKeynote: String                  overall: Int
date: String      (display only)    unit: String
time: String      (display only)    tips: String
duration: String  (display only)    subTitle: String
audioFileURL: String?               category: String
createdAt: Date   ← SORT KEY        perSlideJSON: String  (JSON-encoded [Slide])
sessionID: UUID?  ← edit linkage
feedbacks: [HistoryFeedback]  (cascade delete)
```

**Important:** Never sort by `date: String` — it's a locale display string. Always sort by `createdAt: Date`.

**Migration history:**

| Version | Change | Type |
|---|---|---|
| V1 → V2 | Added `audioFileURL: String?` | Lightweight |
| V2 → V3 | Added `createdAt: Date`, `sessionID: UUID?` | Lightweight |

**V2 is frozen** as inner classes in `HistorySchemaV2` (snapshot pattern). V3 references the live top-level `HistoryModel`.

### RecapModel (in-memory)

```swift
struct RecapModel: Hashable {
    let id: UUID           // ← same UUID stored as HistoryModel.sessionID
    let sesTitle: String
    let sesKeynote: String
    let date: String
    let time: String
    let duration: String
    let feedback: [Feedback]
    let audioFileURL: String?
    let createdAt: Date
}
```

`RecapModel.id` ↔ `HistoryModel.sessionID` is the link used to persist title edits.

---

## Practice Pipeline

**This pipeline is fragile — read `tiempo-practice` skill before editing.**

```
HomeView
  └── PracticeViewModel (@MainActor)
        └── PracticeRecordingCoordinator (actor)
              ├── AudioCaptureService (actor)
              │     └── AVAudioEngine → .caf file
              │               └── tap → SpeechRequestBox (lock)
              ├── SpeechRecognitionService (actor)
              │     └── SFSpeechRecognizer (id-ID, server)
              │           └── word counts → coordinator
              └── KeynoteSlideTrackingService (actor)
                    └── AppleScript poll (1s) → slide number
```

### Key invariants

1. **Single word-history array** is the source of truth. Feeds both live WPM and per-slide recap.
2. **`MediaClock`** is the only timeline. Freezes during pause so timestamps never count paused time.
3. **Monotonic high-water mark** (`maxCountCurrentTask`) prevents duplicate word ingest from recognizer partial-result revisions.
4. **Supervised recognition loop** (`runRecognitionSupervisor`) with watchdog — recognition can never permanently die while session is active.

### WPM calculation

- **Live:** gross WPM over sliding 10s window (`PracticeTuning.windowSeconds`). EMA smoothing α=0.45.
- **Recap:** per-slide = Σwords in slide interval / Σinterval duration × 60. Revisited slides merged.
- **Metric:** gross WPM (silence decays the live number; pauses included in denominator).
- **Thresholds:** 90–120 WPM ideal band, ±5 WPM hysteresis on status color transitions.

### Session flow

```
startSession() → coordinator.start() → arm recognition → start slide polling → emit .recording
     ↓
(live WPM ticks every 500ms via PracticeViewModel.startTimer)
     ↓
stop() → coordinator.stop() → PracticeResult { wordTimestamps, slideIntervals, duration, audioURL }
     ↓
HomeView.onSessionFinished → result.toRecapModel() → router.push(.recap(.main(recapModel)))
```

---

## Navigation System

### Router

`AppRouter` (`App/AppRouter.swift`) owns `path: [AppRoute]`. **Always** use:

```swift
router.push(.someRoute)         // add to stack
router.pop()                    // remove last
router.popToRoot()              // clear stack → root HomeView
router.replace(with: .route)    // pop + push atomically (no flicker)
```

**Never** use `route.pop(); route.push(...)` — use `replace(with:)` instead.

### Route hierarchy

```
AppRoute
  ├── .home(HomeRoute)
  │     └── .main
  ├── .settings(SettingsRoute)
  │     └── .main
  ├── .recap(RecapRoute)
  │     ├── .main(RecapModel)      ← from live Practice session
  │     └── .fromHistory(RecapModel) ← from History list
  ├── .history(HistoryRoute)
  │     └── .main
  └── .onboarding(OnboardingRoute)
        └── .main
```

### Screen flows

```
Onboarding → Home
Home → PermissionsSheet (sheet)
Home → Practice (overlay panel, same Home)
Practice end → Recap (.main)
Recap → History (save) → back to Recap (from history)
History → Recap (.fromHistory) → History
```

### Window sizing

`RootView` sets window size via `AppSize` constants based on `router.activeRoute`:
- Splash: 340×220
- Home: 340×480  
- Recap/History: 700×600

---

## Design System

All UI tokens are in `Core/DesignSystem/`:

| Token | File | Notes |
|---|---|---|
| Colors | `AppColor.swift` | Semantic Apple colors; `Color(light:dark:)` helper for custom |
| Fonts | `AppFont.swift` | |
| Icons | `AppIcon.swift` | SF Symbols only |
| Spacing | `AppSpacing.swift` | |
| Radius | `AppRadius.swift` | |
| Sizes | `AppSize.swift` | Window dimensions |

**Rules:**
- No asset-catalog `.colorset` — causes merge conflicts. Colors in code only.
- No raw `Color.black`/`.white` — use `AppColor` tokens (adaptive).
- Primary buttons: `.buttonStyle(.glassProminent).tint(AppColor.controlAccent)` (monochrome, NOT system blue).
- `AppColor.controlAccent = Color(light: .black, dark: .white)`.
- Multiple adjacent glass elements need `GlassEffectContainer`.

---

## Build & Test

```bash
# Build
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj -scheme KeynoteCompanionMacos \
  -destination 'platform=macOS' -derivedDataPath .build/DerivedData build

# All tests
rtk xcodebuild -project KeynoteCompanionMacos.xcodeproj -scheme KeynoteCompanionMacos \
  -destination 'platform=macOS' -derivedDataPath .build/DerivedData test

# Single test
rtk xcodebuild ... -only-testing:KeynoteCompanionMacosTests/<Class>/<method> test
```

**`rtk` prefix is mandatory** — project requirement.

### Test suites

| Suite | Coverage |
|---|---|
| `HomeViewModelTests` | All 4 HomeViewState transitions, permission gating, automation cache |
| `PermissionsSheetViewModelTests` | Permission rows, auto-dismiss, store sync |
| `WPMCalculatorTests` | Sliding window, EMA, pause/resume, warm-up |
| `PracticeRecordingCoordinatorTests` | Word ingest, monotonic max, pause/resume, recognition recovery |
| `PracticeResultTests` | Per-slide merge, word counting, recap WPM |
| `SettingsViewModelTests` | (basic) |
| `SlideshowOverlayWindowPresenterTests` | (basic) |

### Mock injection pattern

Tests inject mocks via the designated `init(...)` with protocol types. **Never** touch real Keynote/microphone/speech in tests.

```swift
// ✅ Correct
let vm = HomeViewModel(
    micChecker: MockMicrophoneChecker(),
    speechChecker: MockSpeechChecker(),
    automationChecker: MockKeynoteAutomationChecker(),
    automationStore: MockKeynoteAutomationStatusStore()
)

// ❌ Wrong
let vm = HomeViewModel()  // wires real system services
```

---

## Known Issues & Bug History

### Fixed (2026-06-17) — `feature/recap-history-fix`

| # | Category | Bug | Fix |
|---|---|---|---|
| N1 | Navigation | `pop() + push()` pattern causes window flicker + wrong stack state | Replaced with `replace(with:)` / `popToRoot()` in 4 call sites |
| N2 | Navigation | `RecapRoute.home` dead case created duplicate HomeView | Removed from `RecapRoute` + `RecapRouteBuilder` |
| N3 | Navigation | `HistoryRoute.home`, `.historyDetail` dead cases; `historyToDetail` unused binding | Removed all dead code |
| H1 | History | Sessions sorted lexicographically (String), not chronologically | Added `createdAt: Date` to HistoryModel (V3 migration); sort changed to `createdAt` |
| A1 | Audio | `fileExists(atPath: url.path)` failed silently for paths with special chars | Changed to `url.path(percentEncoded: false)` |
| A2 | Audio | Mute button showed `speaker.slash` in both muted and unmuted state | Changed to `speaker.wave.2.fill` for unmuted |
| A3 | Audio | `isPlaying` not reset when audio finishes naturally; no delegate | Added `AVAudioPlayerDelegate` via `AudioPlayerEndDelegate` helper class |
| S1 | Session | `sesTitle` always hardcoded `"Practice Recording"` | Auto-derived from `keynoteFileName` (strip extension, truncate 30 chars) |
| S2 | Session | No way to rename sessions | Inline editable TextField in RecapView; persists via `sessionID` lookup |
| SE1 | Search | Search field non-functional (`.constant("")`) | Wired to `@State var searchText`; client-side filter by title+keynote name |
| D1 | SwiftData | Migration fallback used `try!` — crashes if plain schema also mismatches | Replaced with layered fallback: migration → plain → in-memory |

### Known limitations (not bugs)

| # | Area | Description |
|---|---|---|
| L1 | Audio | `audioFileURL` stored as absolute path; breaks on app reinstall (silent, handled gracefully) |
| L2 | Speech | Server recognition only for `id-ID` — requires network; offline practice shows 0 WPM |
| L3 | WPM | Words timestamped at arrival (not segment timestamp) — up to ~2s mismatch at slide boundaries |
| L4 | History | Old sessions (migrated from V2) have `sessionID = nil`; title edits are in-memory only |
| L5 | Keynote | Automation revocation while Keynote is closed isn't detected until next Keynote run |

### Pending verification

| # | Description | How to verify |
|---|---|---|
| P1 | Live WPM supervised recognition | Run `log stream --predicate 'subsystem == "com.tiempo.practice"'`, start real practice in Bahasa Indonesia, confirm WPM rises ~2s after speaking, decays on silence, recovers. Reconnecting state shows on forced drop. |
| P2 | Audio playback from History | Save a session after practice, navigate to History, open it, confirm play/pause/scrub/mute work and `isPlaying` resets when audio ends. |

---

## Development Changelog

### 2026-06-17 — `feature/recap-history-fix`

- Fixed 12 bugs across navigation, audio, history date sort, session title, and search (see table above).
- Added `createdAt: Date` and `sessionID: UUID?` to `HistoryModel` (V3 migration).
- Froze `HistorySchemaV2` as inner-class snapshot (proper migration pattern going forward).
- Build: green. Tests (29 test cases): all passed.

### 2026-06-15 — `hotfix/permission` (merged to main as #41)

- Supervised recognition loop + watchdog (`PracticeRecordingCoordinator`) fixes "WPM stuck at 0".
- Permissions modal redesign — one "Allow" requests all 3 permissions in order.
- Fixed Keynote browser pop-up during automation permission request.
- Added `KeynoteAutomationStatusStore` — caches last determinable automation permission status.
- Adaptive theme (light/dark), removed forced `.aqua` appearance.

### 2026-06-13 — WPM redesign (in `feature/*`)

- Unified word-history architecture: single `[TimeInterval]` array feeds both live WPM and recap.
- `WPMCalculator` pure struct, `MediaClock` value type.
- Per-slide recap via `PracticeSlideInterval` tiling.
- Retake button removed.

### 2026-06-12 — WPM bug fix (v3)

- Root cause: `requiresOnDeviceRecognition = true` → error 1101 (model asset missing).
- Fix: `requiresOnDeviceRecognition = false`, locale `id-ID`, self-healing restart with `updateSpeechRequest(_:)`.
- Added `os.Logger` full instrumentation.

---

## Next Milestones

### Milestone 1: Usability Testing Ready

- [ ] Complete `feature/recap-history-fix` PR — merge to `development` → `main`
- [ ] Real-session verify: WPM supervised recognition (P1)
- [ ] Real-session verify: audio playback from History (P2)
- [ ] Tune `PracticeTuning.emaAlpha` and `windowSeconds` after real-session testing
- [ ] Clean up `development` branch (merge from `main` after hotfixes)

### Milestone 2: TestFlight

- [ ] Fastlane setup (Matchfile, Fastfile, Appfile)
- [ ] Code signing — certificates + provisioning profiles via `match`
- [ ] GitHub Actions workflow: build → test → archive → upload to TestFlight
- [ ] App version/build number automation
- [ ] App Store Connect app record

### Milestone 3: Filler Words

- [ ] Research complete (currently in research phase)
- [ ] Architecture decision: on-device vs server NLP
- [ ] Implementation

---

## Key Files Reference

| Area | File |
|---|---|
| App entry | `KeynoteCompanionMacosApp.swift` |
| Router | `App/AppRouter.swift`, `App/AppRoute.swift`, `App/AppRouteBuilder.swift` |
| Root view | `App/RootView.swift` |
| Home VM | `Features/Home/ViewModel/HomeViewModel.swift` |
| Permissions VM | `Features/Home/ViewModel/PermissionsSheetViewModel.swift` |
| Practice coordinator | `Features/Practice/Model/PracticeRecordingCoordinator.swift` |
| WPM calculator | `Features/Practice/Model/WPMCalculator.swift` |
| Media clock | `Features/Practice/Model/MediaClock.swift` |
| Practice VM | `Features/Practice/ViewModel/PracticeViewModel.swift` |
| Recap VM | `Features/Recap/ViewModel/RecapViewModel.swift` |
| History model | `Features/History/Model/HistoryModel.swift` |
| Migration plan | `Features/History/Model/HistoryMigrationPlan.swift` |
| Recap model | `Features/Recap/Model/RecapModel.swift` |
| Practice models | `Features/Practice/Model/PracticeModels.swift` |
| Audio service | `Core/Services/Audio/AudioCaptureService.swift` |
| Speech service | `Core/Services/Audio/SpeechRecognitionService.swift` |
| Keynote status | `Core/Services/Keynote/KeynoteStatusService.swift` |
| Keynote slide tracking | `Core/Services/Keynote/KeynoteSlideTrackingService.swift` |
| Automation store | `Core/Services/Permissions/KeynoteAutomationStatusStore.swift` |
| Overlay window | `Core/Window/SlideshowOverlayWindowPresenter.swift` |
| Design system | `Core/DesignSystem/AppColor.swift`, `AppFont.swift`, `AppIcon.swift` |
