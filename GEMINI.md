# KeyCount Project Context

## Technical Stack
- **Language:** Swift 6 (Strict Concurrency)
- **Frameworks:** SwiftUI, SwiftData
- **Persistence:** SQLite (via SwiftData)
- **Event Capture:** `CGEventTap` (CoreGraphics)
- **Minimum OS:** macOS 15.0 (Sequoia)
- **Bundle ID:** `org.keycount.app`

## Key Implementation Details
- **Minute Buckets:** Data is stored in 1-minute intervals. This allows for flexible historical queries without data migration.
- **Background Threading:** `KeystrokeMonitor` runs on a dedicated `Thread` with its own `CFRunLoop` to avoid blocking the Main UI thread.
- **In-Memory Buffer:** Keystrokes are first counted in-memory and flushed to SwiftData every 30 seconds to save disk life and battery.
- **Smart Mode Logic:** Excludes keys with `Cmd`, `Opt`, or `Ctrl` modifiers. `Backspace` decrements the count within the current bucket (minimum 0).

## Data Schema
`KeyBucket` model:
- `timestamp: Date` (unique, normalized to start of minute)
- `count: Int`

## Permissions
The app uses `CGEventTap` which requires **Accessibility** (TCC) permissions. Due to the lack of code signing in development/CI builds, manual addition to the Accessibility list via the `+` button in System Settings is often required.

## 🚀 Backlog & Future Tasks
- [ ] **Silent Start:** Modify the permission check logic to completely avoid automatic system prompts on startup. The app should remain silent and only show the in-app "Permission Required" banner, allowing the user to trigger the prompt manually when ready. This prevents the "focus-stealing" loop on new installations.
- [ ] **Visual Charts:** Add historical trends and daily/weekly graphs using the minute-bucket data.
- [ ] **Export Feature:** Export statistics to CSV or JSON.
