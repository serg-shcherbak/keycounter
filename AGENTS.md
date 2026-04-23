# Instructions for AI Agents

Welcome to the KeyCount project. When modifying this codebase, please adhere to the following principles:

## 1. Zero-Trust Concurrency
- The app uses Swift 6 strict concurrency. Always use `@MainActor` for UI-related state in `StatsManager`.
- Keep the `KeystrokeMonitor` isolated on its background thread. Use thread-safe patterns (like `AtomicBool` or `Task { @MainActor in ... }`) for communication.

## 2. Privacy First
- Never add code that captures, logs, or stores actual characters or text content.
- All processing must happen locally. No network requests are allowed for analytics or telemetry.

## 3. Extending Statistics (Roadmap)
- When adding charts or history views, leverage the existing `KeyBucket` model.
- Avoid large SQL queries on the main thread. Use `SwiftData` background contexts if processing thousands of buckets.

## 4. UI Style
- Stick to native macOS aesthetics. Use SwiftUI's standard components (`Form`, `Toggle`, `Picker`, `GroupBox`).
- Avoid custom heavy animations that impact CPU usage.

## 5. Deployment
- The app is built via GitHub Actions (`build.yml`). 
- If adding new files, ensure they are included in the `Package.swift` targets.
