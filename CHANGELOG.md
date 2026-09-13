# Changelog

## 1.2.3

- Removed remaining SwiftUI settings binding method references so Swift 6.3.3 release runners compile the shell without the IRGen reabstraction crash.
- Kept release and test builds on independent primary-file compilation for reliable CI packaging.

## 1.2.2

- Avoided the Swift 6.3.3 SwiftUI IRGen crash in the appearance settings view by using compiler-compatible explicit setter closures alongside isolated primary-file builds.

## 1.2.1

- Made SwiftPM test and release builds use independent Swift primary-file compilation so Swift 6.3.3 runners avoid the batch IRGen crash encountered in the settings module.

## 1.2.0

- Hardened startup and recovery with rendered-content readiness checks, bounded retries, draft protection, session restart, compatibility recovery, and content-free Diagnostics telemetry.
- Added a deterministic 600 × 1,059 point compact launch frame that ignores restored full-screen and maximized state while preserving normal user resizing.
- Added live notification unread badges, new-post highlights, reliable badge clearing, native image saves with remembered folders, Find in Page, and the Command-K quick switcher.
- Added Golden Gate, Big Sur, Mojave Dusk, Sonoma Hills, Tahoe Tide, Violet Bloom, and additional macOS-inspired themes with accent customization and responsive layout.
- Tightened WebKit presentation scheduling, scroll restoration, media readiness, traffic-light layout, logo placement, and signed bundle verification.

## 1.1.2

- Published the complete 1.1 refresh with portable release checks for both native SwiftPM and Xcode-backed macOS runners.

## 1.1.1

- Published the complete 1.1 refresh with a release test path compatible with standard GitHub macOS runners.

## 1.1.0

- Rebuilt the native shell with responsive Liquid Glass navigation, browser controls, feed sizing, and deterministic startup placement.
- Added a complete XGlass Settings experience with searchable theme previews, appearance controls, and release-safe defaults.
- Split the WebKit presentation layer into focused, tested modules with bounded DOM scheduling and reduced redundant updates.
- Improved navigation recovery, interface health reporting, direct-message readability, composer contrast, and promoted-post suppression.
- Added native image save panels with collision-resistant filenames and hardened app-bundle packaging verification.

## 1.0.0

- Initial public XGlass release.
- Added Sparkle 2.9.5 update support with a signed GitHub appcast.
- Added the native SwiftUI shell, custom navigation, feed presentation, profile, settings, direct messages, and compose routes.
