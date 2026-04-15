# Recon

**Re**size and **Con**vert. A tiny iOS app that resizes and converts photos, saving the outputs to a "Recon" album in your Photos library. Built with SwiftUI for iOS 26.

Free. Offline. On-device. No accounts, no analytics, no tracking, no network access at all.

## Why this exists

I wanted a small, fast utility to resize and convert photos on my phone. Every other option I tried was tangled in adverts, cluttered with features I didn't need, or quietly uploading the originals somewhere. Recon does one job, on-device, and then gets out of the way.

> _Draft from Claude based on the note in TODO.md — Dave, rewrite this in your own voice when you get a moment._

## What it does

1. Pick one or more photos from your library.
2. Choose an output format — JPEG, WebP, AVIF, PNG, or TIFF.
3. For the lossy formats, pick a quality level.
4. Pick a resize mode:
   - **Keep original** — convert without resizing.
   - **Percentage** — scale each photo by a percent.
   - **Long edge** — cap the longest side to a pixel size.
   - **Short edge** — cap the shortest side to a pixel size.
5. Tap Process. Converted copies land in the **Recon** album in Photos with EXIF metadata preserved (camera model, capture time, GPS, and so on).

## Features

- Five output formats via the system ImageIO stack — no third-party libraries, nothing to update.
- Four resize modes: keep original, percentage, cap long edge, cap short edge.
- Preserves EXIF metadata; rewrites orientation so every output renders the right way up regardless of how the source was tagged.
- Processes batches in parallel, bounded to the device's active CPU count.
- Cancel mid-batch — any photos already saved stay in the album (no rollback, because the files are yours).
- Light and dark themes with a lime accent.
- iPhone and iPad in every useful orientation.
- Haptics on step changes, slider release, completion, and errors.

## Privacy

Recon never makes a network request. No analytics SDK, no telemetry, no crash reporter, no accounts. Photos access is requested twice:

- **Read-write** so it can resolve the images you pick into the underlying asset records needed for processing.
- **Add-only** so it can write the converted copies back into the Recon album.

Both are standard iOS system prompts. Converted files only leave the app through the Photos library.

## Requirements

- iOS 26.4 or later.
- iPhone or iPad.

## Build from source

Open `Recon.xcodeproj` in Xcode 16 or later, or build from the command line:

```sh
xcodebuild -project Recon.xcodeproj -scheme Recon \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -configuration Debug build
```

## Test

```sh
xcodebuild -project Recon.xcodeproj -scheme Recon \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' test
```

## How it works (short version)

Each photo is loaded from PhotoKit, downsized with `CGImageSourceCreateThumbnailAtIndex` (which also bakes the EXIF rotation into the pixels in a single pass), re-encoded with `CGImageDestination` at the chosen format and quality, and written to the Recon album in a single atomic PhotoKit transaction. Batches fan out across a `TaskGroup` capped at the device's CPU count. Everything happens on-device.

## Project docs

- [DESIGN.md](./DESIGN.md) — visual design spec: tokens, typography, component sizes, screen flow.
- [AGENTS.md](./AGENTS.md) — onboarding notes for anyone (human or AI) picking up the codebase.
- [TODO.md](./TODO.md) — what's on the wish list.

## Licence

[MIT](./LICENSE) © 2026 Dave Williams.
