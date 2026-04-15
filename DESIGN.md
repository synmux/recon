# Recon — Design & Implementation Spec

Handoff document for a fresh implementation session. Accompanies the Figma file at <https://www.figma.com/design/WJLUvDuAuHGgNoOBpXYPto>.

## Overview

Recon is a small iOS app that converts and recons photos from the library and writes them to a "Recon" album. Two themes (light and dark) with a lime accent. The app is called "Recon".

**Stack.** SwiftUI on the latest iOS (assumes iOS 18+ visual language). Native look and feel — system fonts, system-style blurred backgrounds, haptics on step transitions. No third-party UI libraries. Image I/O via `ImageIO` / `CoreImage`; encoding via `UTType` for JPEG/PNG/TIFF/HEIC, and via the `UTType.webP` / `UTType.avif` encoders available on the latest iOS.

**Scope.** Single user on their own device. No account, no payments, no analytics, no network access. Fully offline.

## Design tokens — Light mode

| Token | Hex |
|---|---|
| `bg` | `#F5F5F3` |
| `surface` | `#FFFFFF` |
| `surfaceAlt` | `#EFEFEC` |
| `border` | `#E4E4E1` |
| `text` | `#111111` |
| `textSecondary` | `#6B6B6B` |
| `accent` | `#4F7A0E` |
| `accentSoft` | `#E8F5C8` |
| `danger` | `#D0342C` |
| `onAccent` | `#FFFFFF` |

Accent in light mode is deliberately a deeper lime so it passes WCAG AA on white for body text and small UI. The vibrant lime is reserved for dark mode. **Do not use the dark-mode lime on light surfaces.**

## Design tokens — Dark mode

| Token | Hex |
|---|---|
| `bg` | `#0B0B0C` |
| `surface` | `#1A1A1C` |
| `surfaceAlt` | `#232326` |
| `border` | `#2A2A2D` |
| `text` | `#FAFAF8` |
| `textSecondary` | `#9A9A9A` |
| `accent` | `#C6FF3D` |
| `accentSoft` | `#2B3A10` |
| `danger` | `#FF5A4E` |
| `onAccent` | `#0B0B0C` |

Accent sits on a very dark near-black rather than pure black — softer on OLED and reduces the "glowing lime" effect. `onAccent` is near-black, not pure black, to match.

## Typography

Font: **SF Pro** (system). Weights used: Regular, Medium, Semi Bold, Bold.

```
Display / large title   34pt  Bold
Section title           28pt  Bold
Nav title               17pt  Semi Bold
Nav subtitle            12pt  Medium
Body                    15pt  Regular
List title              16pt  Semi Bold
List subtitle           13pt  Regular
Caption                 12pt  Regular
Value (quality)         72pt  Bold
Ring percent            54pt  Bold
```

## Spacing & radius

Spacing scale: `4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 40`.

- Screen horizontal padding: **20**
- Card inner padding: **18**
- Corner radius: cards **14**, CTAs **16**, hero card **24**, thumbnails **12**

## Screen flow

Linear `NavigationStack` with a 4-step progress indicator (Selected → Format → Quality → Recon). Processing and Done are terminal states, not steps. Back button on steps 2–5; Processing hides back; Done replaces it with "Recon More".

```
Home              → .sheet(PHPickerViewController)
Selected (1/4)    → tap Continue
Format   (2/4)    → tap Continue
Quality  (3/4)    → only shown if format is JPEG / WEBP / AVIF
Recon   (4/4)    → tap "Process N Photos"
Processing        → progress, cancellable
Done              → Open Photos / Recon More
```

Skip the Quality step automatically when format is PNG or TIFF (progress dots collapse from 4 to 3).

State lives in a single observable:

```swift
@Observable final class ReconSession {
    var assets: [PHAsset] = []
    var format: OutputFormat = .jpeg          // .jpeg .webp .avif .png .tiff
    var quality: Double = 0.85                // 0...1, only for jpeg/webp/avif
    var recon: ReconMode = .percentage(75)
    // ReconMode: .original, .percentage(Int), .longEdge(Int), .shortEdge(Int)
    var progress: Double = 0                  // 0...1
    var processedCount = 0
}
```

## Components

- **StepDots** — small pill progress indicator (active dot is a 22×6 pill, inactive 6×6). Accent fills completed + current dots.
- **OptionRow** — selectable card with title, subtitle, optional badge, radio on trailing edge. Selected state = accent border (2pt) + filled radio. Full-width tap target, 56pt minimum height.
- **PrimaryCTA** — 56pt tall, 16pt radius, full-width minus 20pt side insets, 40pt bottom inset. Accent fill with `onAccent` label. Secondary variant is surface fill with 1pt border.
- **QualitySlider** — 6pt track, accent fill, 22pt white knob with 3pt accent ring and drop shadow. Emits `.light` haptic on drag end.
- **ProgressRing** — 220pt diameter, 10pt stroke width, round caps. Arc starts at `-π/2`. Centre shows "N of M" above a large percent.
- **ThumbGrid** — 3-column lazy grid, 8pt gutter, 12pt radius. Selection pill is a 22pt accent circle with on-accent tick, top-right with 6pt inset.

## iOS implementation notes

### Photos library

Use `PHPicker` for selection (no full library permission needed). To write to the Recon album, request add-only `PHPhotoLibrary` access and create/find an album with `PHAssetCollectionChangeRequest`.

```swift
// Find-or-create album
func reconAlbum() async throws -> PHAssetCollection {
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", "Recon")
    let fetch = PHAssetCollection.fetchAssetCollections(
        with: .album, subtype: .albumRegular, options: fetchOptions)
    if let a = fetch.firstObject { return a }

    var placeholder: PHObjectPlaceholder?
    try await PHPhotoLibrary.shared().performChanges {
        let req = PHAssetCollectionChangeRequest
            .creationRequestForAssetCollection(withTitle: "Recon")
        placeholder = req.placeholderForCreatedAssetCollection
    }
    let id = placeholder!.localIdentifier
    return PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [id], options: nil).firstObject!
}
```

### Encoding

Use `CGImageDestination` with `UTType` for JPEG (`.jpeg`), PNG (`.png`), TIFF (`.tiff`), HEIC (`.heic`). For WebP and AVIF on iOS 17+, use `UTType.webP` and `UTType.avif` — ImageIO ships system encoders. Pass `kCGImageDestinationLossyCompressionQuality` for JPEG/WEBP/HEIC. AVIF quality via the same key is respected by the system encoder on recent iOS.

### Resizing

Prefer `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` for speed and low memory — it also applies EXIF orientation correctly. Compute the max pixel size from the chosen `ReconMode` using the original `pixelWidth`/`pixelHeight`.

### Concurrency

Process with a `TaskGroup` bounded to `ProcessInfo.processInfo.activeProcessorCount`. Keep a cancellation flag on the session. Update `progress` on the main actor only. Never decode full-size images on the main thread.

### Saving

Write each encoded file to a temp URL, then `PHAssetCreationRequest.forAsset().addResource(.photo, fileURL:…)` inside a `performChanges` block that also appends the placeholder to the Recon album via `PHAssetCollectionChangeRequest(for: album).addAssets([…])`.

### EXIF

Preserve source EXIF/metadata by reading properties from the source `CGImageSource` and passing them into the destination properties dictionary. Strip GPS on export if a privacy toggle is added later.

## Edge cases & UX details

- If format is PNG/TIFF the Quality step is skipped and the progress dots read 1·2·3 total.
- The Estimated size line on Quality updates live as the slider moves (debounced 80ms).
- If `Recon = Keep original` and `format = source format`, show a subtle notice on the Recon step ("This will create copies with identical settings") — still allow processing; the user may want a copy in the Recon album.
- Long-edge / short-edge inputs: numeric keypad; cap 1–20000 px; default = current image's matching edge rounded to nearest 100.
- Cancellation during Processing returns to the Recon step with previous settings intact. Already-written photos stay in the album (don't attempt rollback).
- On Done, tapping "Open Photos" uses the `photos-redirect://` URL scheme. Fall back gracefully if it fails.
- Haptics: `.selection` on step changes, `.success` on Done, `.warning` on error. No haptics during slider drag.
- Dark-mode accent is very bright — do NOT use it for large fills behind body text. Use `accentSoft` for tinted surfaces.

## Project layout

```
Recon/
├─ ReconApp.swift           // @main, WindowGroup, session injection
├─ Core/
│  ├─ ReconSession.swift    // Observable state
│  ├─ OutputFormat.swift
│  ├─ ReconMode.swift
│  └─ ImageProcessor.swift   // decode/recon/encode/save
├─ Photos/
│  ├─ PhotoLibrary.swift     // album find-or-create
│  └─ AssetLoader.swift
├─ UI/
│  ├─ HomeView.swift
│  ├─ SelectedView.swift
│  ├─ FormatView.swift
│  ├─ QualityView.swift
│  ├─ ReconOptionsView.swift
│  ├─ ProcessingView.swift
│  ├─ DoneView.swift
│  └─ Components/
│     ├─ StepDots.swift
│     ├─ OptionRow.swift
│     ├─ PrimaryCTA.swift
│     ├─ QualitySlider.swift
│     ├─ ProgressRing.swift
│     └─ ThumbGrid.swift
└─ Design/
   ├─ Theme.swift            // Color.accent, Color.surface, etc.
   └─ Typography.swift
```

`Theme.swift` exposes semantic colours that resolve via `Color("accent")` etc. in the Asset Catalog, with separate Any Appearance and Dark Appearance values matching the tokens above. Don't hardcode hex in views.

## Info.plist & capabilities

```
NSPhotoLibraryAddUsageDescription
    "Recon saves converted photos to your library."

NSPhotoLibraryUsageDescription
    "Recon reads the photos you pick to convert and recon them."

(optional) LSApplicationQueriesSchemes
    - photos-redirect
```

No background modes, no network entitlements.
