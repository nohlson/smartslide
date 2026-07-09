# SmartSlides

A native macOS slideshow app with deterministic "human shuffle" playback, inspired by Classic Slideshow.

Instead of picking the next image at random during playback, SmartSlides generates one complete randomized timeline up front from a selected folder and a seed/hash, then plays that exact sequence start to finish (looping) until you regenerate the hash. Portrait and landscape images are automatically classified and can be shown solo or paired side by side.

Personal/friends-only distribution — no App Sandbox, ad-hoc signed, not on the App Store.

## Features

- **Folder-based scanning** — pick a folder (optionally including subfolders), scans supported images (jpg, jpeg, png, heic, tiff, gif), and classifies each as portrait or landscape by aspect ratio.
- **Deterministic timeline generation** — a seeded RNG (SplitMix64) shuffles the image pools and decides layouts, so the same folder + layout selection + seed always reproduces the same timeline. Every image appears once per timeline.
- **Four layouts** — 1 portrait, 1 landscape, 2 portraits side by side, 2 landscapes side by side — each independently enabled/disabled. Side-by-side pairs are sized from each image's real aspect ratio so they sit flush together with no gap and matching heights, never cropped.
- **Hash / reseed** — see the current seed and generate a new one at any time to reshuffle. Changing the folder, subfolders setting, or enabled layouts also generates a fresh hash automatically.
- **Fullscreen playback** — black background, crossfade transitions, aspect-fit images.
  - Keyboard: Space (pause/resume), Right/Left (next/previous), Escape (exit to settings).
  - Auto-hiding translucent overlay with live display/transition duration sliders and slide position.
- **Timeline filmstrip** — a scrollable strip of thumbnails at the bottom of the settings window shows every scene in the generated timeline and your current position, so you always know what's coming and what you've seen.
- **Stop and resume** — folder (via a security-scoped bookmark), layouts, seed, generated timeline, current slide index, and durations all persist across launches.

## Requirements

- macOS 14+
- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj` is generated from `project.yml`, not hand-maintained.

## Building

```bash
xcodegen generate   # regenerate SmartSlides.xcodeproj after editing project.yml or adding/removing files
open SmartSlides.xcodeproj
```

or from the command line:

```bash
xcodebuild -project SmartSlides.xcodeproj -scheme SmartSlides -configuration Debug build
```

## Project structure

```
SmartSlides/
  SmartSlidesApp.swift          Entry point
  ContentView.swift             Main settings window (3-column layout + timeline strip)
  Models/                       AppSettings, ImageAsset, SlideLayout, SlideScene
  Services/                     ImageScanner, TimelineGenerator, SeededRandomNumberGenerator,
                                 AppSettingsStore, ThumbnailStore
  ViewModels/                   SettingsViewModel, SlideshowPlayerViewModel
  Views/                        FolderSelectionView, TimingSettingsView, LayoutSelectionView,
                                 SlideshowView, SlideshowOverlayView, TimelineStripView
  Controllers/                  SlideshowWindowController (fullscreen AppKit window + key handling)
```

See `CLAUDE.md` for a deeper architecture walkthrough.

## Distribution

Direct `.app` or `.dmg` sharing. Since the app is ad-hoc signed (not notarized), friends will need to right-click → Open the first time to get past Gatekeeper.
