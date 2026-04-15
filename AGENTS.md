# Recon — AI agent context

A small SwiftUI iOS app that resizes and converts photos and writes the outputs to a user album called "Recon" (the name is a portmanteau of **Re**size + **Con**vert). Single-user, fully offline, no analytics, no accounts, no payments.

## Stack

- Swift 5 language mode with `SWIFT_APPROACHABLE_CONCURRENCY = YES` + `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — Swift-6-style main-actor-default without the Swift 6 strictness. `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` is also on.
- SwiftUI on iOS 26.4 — `@Observable`, `NavigationStack`, `@Environment(_:)` for typed environment
- `PhotosUI` / `Photos` / `ImageIO` / `CoreGraphics` — no third-party libraries
- Swift Testing (`@Test` / `#expect`) for unit tests; XCTest for a minimal UI smoke test
- File System Synchronized project (Xcode 16+): drop new `.swift` files into `Recon/`, `ReconTests/`, or `ReconUITests/` and the build picks them up — no `project.pbxproj` edits needed.

## Layout

```
Recon/
├─ ReconApp.swift           # @main, owns @State ReconSession + ReconRouter
├─ Core/                     # Models + pipeline (no UI)
│  ├─ OutputFormat.swift     # enum: jpeg|webp|avif|png|tiff + UTType/MIME/quality flag
│  ├─ ReconMode.swift       # enum: original|percentage|longEdge|shortEdge + targetMaxPixelSize(for:source:)
│  ├─ ReconSession.swift    # @Observable: assets, format, quality, recon, progress, failures
│  └─ ImageProcessor.swift   # nonisolated static decode/recon/encode pipeline
├─ Photos/
│  ├─ PhotoPicker.swift      # UIViewControllerRepresentable around PHPickerViewController
│  ├─ AssetLoader.swift      # Resolves [PHPickerResult] -> [PHAsset] preserving order
│  └─ PhotoLibrary.swift     # Access requests, album find-or-create, append
├─ Design/
│  └─ Typography.swift       # AppFont.* semantic font tokens
└─ UI/
   ├─ Router.swift           # @Observable path container + Step enum
   ├─ HomeView.swift         # Root, owns NavigationStack
   ├─ SelectedView.swift     # 1/4 Review picks
   ├─ FormatView.swift       # 2/4 Pick output format
   ├─ QualityView.swift      # 3/4 Quality slider (skipped for PNG/TIFF)
   ├─ ReconOptionsView.swift# 4/4 Recon mode + inline pixel field
   ├─ ProcessingView.swift   # Bounded TaskGroup + ProgressRing + Cancel
   ├─ DoneView.swift         # Summary + Open Photos + Recon More + Retry
   └─ Components/
      ├─ StepDots.swift
      ├─ OptionRow.swift
      ├─ PrimaryCTA.swift
      ├─ QualitySlider.swift
      ├─ ProgressRing.swift
      └─ ThumbGrid.swift
```

`DESIGN.md` is the canonical visual spec — tokens, typography, spacing, component specs, screen flow. Views should reference its tables rather than re-deriving measurements.

## Architecture at a glance

- **State.** `ReconSession` (`@Observable`) holds the whole pipeline: `assets, format, quality, recon, progress, processedCount, isCancelled, failures`. `reset()` and `beginProcessing()` are the lifecycle hooks; `DoneView` reads `failures` to show partial-success summaries.
- **Navigation.** `ReconRouter.path: [Step]` drives `NavigationStack(path:)` in `HomeView`. Cases: `selected → format → quality? → options → processing → done`. The resize-options step is `.options` (not `.recon`) — the screen title is "Recon" but the enum case isn't. `QualityView` is skipped for PNG/TIFF via `session.showsQualityStep`.
- **Pipeline.** `ImageProcessor.process(...)` is `nonisolated static async` and runs entirely off-main: load PHAsset bytes → `CGImageSourceCreateThumbnailAtIndex` (applies EXIF orientation + downsamples in one pass) → `sanitize` forces orientation=1 → `CGImageDestination` encode to a temp URL → `PhotoLibrary.append` consumes that file (`shouldMoveFile = true`) inside a single `performChanges` transaction that also links the new asset into the album.
- **Concurrency.** `ProcessingView.run()` is a bounded producer/consumer `TaskGroup`: seed `ProcessInfo.activeProcessorCount` tasks, refill one-for-one as each completes. `session.isCancelled` is checked between completions and triggers `group.cancelAll()` — already-saved outputs stay in the album (no rollback).
- **Asset order.** `PHAsset.fetchAssets(withLocalIdentifiers:)` returns in unspecified order. `AssetLoader.resolveAssets` projects back through the original identifier array to preserve pick order — don't refactor that away.

## Build & test

```sh
# Build the app for iPhone 17 Simulator (iOS 26.4)
xcodebuild -project Recon.xcodeproj -scheme Recon \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -configuration Debug build

# Run the full test suite (Swift Testing + XCUITest)
xcodebuild -project Recon.xcodeproj -scheme Recon \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' test

# Run just one test (or one suite) — much faster iteration than the full run
xcodebuild -project Recon.xcodeproj -scheme Recon \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:ReconTests/ImageProcessorTests/outputOrientationAlwaysUp test

# If 'iPhone 17' / iOS 26.4 isn't installed locally, list what's available:
xcrun simctl list devices available iOS
```

The unit suite covers:
- `ReconMode.targetMaxPixelSize` math across every mode + aspect ratio
- `OutputFormat` UTType/MIME/extension/supportsQuality truth table
- `ImageProcessor` round-trips each of the 5 formats on an in-memory fixture
- Orientation-1 regression (`outputOrientationAlwaysUp`) guarding the double-rotation class of bugs

## Manual smoke test (run on a physical device for the most realistic PhotoKit behaviour)

1. Fresh install. Launch → Home screen shows "Recon" / "Resize and convert photos in a tap." (with the "Re" and "con" tinted in the lime accent) / hero card / "Choose Photos" CTA.
2. Tap **Choose Photos**. Grant **read-write** Photos access when prompted.
3. Pick three varied photos: one HEIC portrait, one JPEG with GPS, one landscape > 4000 px.
4. **Selected** (1/4): 3-column thumbnail grid. Tap **Continue**.
5. **Format** (2/4): pick **JPEG**. Dots show 1·2·3·4. Tap Continue.
6. **Quality** (3/4): value reads `0.85`. Drag to `0.80`; single `.light` haptic on release. Continue.
7. **Recon** (4/4): pick **Long edge**, type `2000`. Tap **Process 3 Photos**.
8. **Processing**: ring animates 0 → 100 %. Don't tap Cancel.
9. **Done**: "3 photos saved to Recon." Tap **Open Photos**.
10. In Photos → Albums → "Recon" verify:
    - 3 JPEGs present
    - Long edge of each is 2000 px
    - EXIF (camera model, capture time, GPS on the tagged one) preserved
    - The portrait HEIC renders the right way up (no double rotation)
11. Return to Recon → **Recon More** pops to Home with session reset.
12. Repeat with format = **PNG**: dots should collapse to 1·2·3 (no quality step).
13. Repeat with **Keep original** + format = PNG on a JPEG source: verify a pure-convert copy lands in the album.
14. Mid-processing on a larger batch, tap **Cancel**: returns to Recon step; already-saved outputs stay in the album (no rollback).

## App icon

`scripts/generate_icon.swift` regenerates the three 1024×1024 variants (default/dark/tinted) into `Recon/Assets.xcassets/AppIcon.appiconset/`. Edit `IconView` inside that script and rerun `swift scripts/generate_icon.swift` to update all three at once.

## Conventions

- Asset tokens: colour names match `DESIGN.md`'s tables. `Color.accent`, `Color.bg`, etc. auto-generate via `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`.
- Fonts: use `AppFont.<name>` not raw `.system(size:)`. New tokens go in `Design/Typography.swift`.
- Pipeline code (anything that runs off main) is `nonisolated`. Views and session state default to `@MainActor` via the project build setting.
- `EXIF` / orientation: `ImageProcessor.sanitize(properties:)` forces orientation = 1 on every output — the single regression guard for the double-rotation class of bugs. Don't remove it.
- `PHPicker` returns `PHPickerResult`s with `assetIdentifier`. Resolving those to `PHAsset` requires **read-write** (not just add-only) Photos access. Both usage-description keys are therefore required.
- `Info.plist` at the repo root only carries `LSApplicationQueriesSchemes = [photos-redirect]` (for the "Open Photos" deep-link on `DoneView`). The two Photos usage strings live in the Xcode target's build settings as `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` and `INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription` — don't look for them in the plist file itself.
