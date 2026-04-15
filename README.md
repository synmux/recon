# Recon

A tiny iOS app that converts and recons photos, saving the outputs to a "Recon" album in the user's Photos library. Built with SwiftUI on iOS 26.

## What it does

1. Pick one or more photos from your library.
2. Choose an output format: JPEG, WebP, AVIF, PNG, or TIFF.
3. For the lossy formats, pick a quality level.
4. Pick a recon mode:
   - **Keep original** — convert without resizing.
   - **Percentage** — scale each photo by a percent.
   - **Long edge** — cap the longest side to a pixel size.
   - **Short edge** — cap the shortest side to a pixel size.
5. Tap Process. Converted copies land in the **Recon** album in Photos with EXIF metadata preserved.

Free. Offline. No accounts, no analytics, no tracking.

## Requirements

- iOS 26.4+
- iPhone or iPad
- Photos access (read-write to resolve picker results to assets, add-only to write the outputs)

## Build

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

## Project docs

- [DESIGN.md](./DESIGN.md) — canonical visual design spec (tokens, typography, components, screens).
- [AGENTS.md](./AGENTS.md) — AI agent context / onboarding notes for anyone (human or AI) picking up the codebase.
