# ⌨️ KeyCount v1.0

KeyCount is a minimalist, native macOS menu bar application designed to track your keyboard activity while ensuring absolute privacy. It provides real-time statistics on your keystrokes without ever recording the content of what you type.

---

## 🚀 Getting Started

### 1. Installation
1.  **Download:** Get the `KeyCount-Build.zip` from the latest [GitHub Actions run](https://github.com/serg-shcherbak/keycounter/actions).
2.  **Move to Applications:** Unzip and drag `KeyCount.app` into your `/Applications` folder.
3.  **Bypass Gatekeeper:** Since the app is unsigned (Open Source), macOS will initially block it.
    *   Right-click `KeyCount.app` and select **Open**.
    *   If it says "damaged", open **Terminal** and run:
        ```bash
        xattr -cr /Applications/KeyCount.app
        ```

### 2. Granting Permissions (Crucial)
KeyCount requires **Accessibility** access to count keystrokes.
1.  Launch KeyCount. You will see a "Permission Required" banner.
2.  Click **Open System Settings**.
3.  Go to **Privacy & Security** > **Accessibility**.
4.  If KeyCount is not in the list:
    *   Click the **[+]** button.
    *   Navigate to your Applications folder and select **KeyCount**.
5.  Ensure the toggle next to KeyCount is **ON**.
6.  *Note: If it's already on but not working, toggle it OFF and back ON.*

---

## 🛠 Features

-   **Live Statistics:** Track counts for Today, Last Hour, and cumulative totals.
-   **Counting Modes:**
    -   **Smart (Default):** Counts alphanumeric keys and spaces. Subtracts 1 for Backspace. Ignores system shortcuts (Cmd/Opt/Ctrl).
    -   **All except Modifiers:** Counts everything except pure modifier keys (Shift, Cmd, etc.).
    -   **All Keystrokes:** Raw `keyDown` event count.
-   **Ultra Lightweight:** Written in Swift 6, using ~15MB RAM and <0.5% CPU.
-   **Launch at Login:** Option to start automatically when you boot your Mac.

---

## 🧠 Architectural Overview (For Geeks)

KeyCount is built with a focus on non-blocking performance and data integrity.

### Data Flow
1.  **Capture:** Uses `CGEventTap` (CoreGraphics) running on a dedicated background thread with a custom `CFRunLoop`. It operates in `listenOnly` mode, meaning it receives a copy of events without delaying the system's input stream.
2.  **Processing:** Events are filtered based on the selected `CountingMode`. Valid events are incremented in an **in-memory buffer** (using thread-safe atomic-like logic).
3.  **Persistence:** To minimize disk I/O, the in-memory buffer is flushed to a **SwiftData (SQLite)** store every 30 seconds.
4.  **Storage:** Data is stored in **Minute Buckets**. Each record represents a 60-second window: `(timestamp: Date, count: Int)`. This allows for efficient historical aggregation (e.g., calculating "Last Hour" is a simple sum of the last 60 records).

### Privacy Policy
- **Zero Content Recording:** The app only reads the *fact* of an event and the `keyCode` for special keys like Backspace/Enter. It **never** reads or stores the characters typed.
- **Local Only:** No data ever leaves your machine. There is no telemetry, no tracking, and no cloud sync.

---

## 🛠 Troubleshooting

-   **Counter is stuck at 0:** 
    1. Go to Settings > Advanced in the app.
    2. Check **Diagnostics**. If "Tap Active" is NO, try clicking **Restart Key Monitoring**.
    3. If "Trusted" is NO, reset permissions via Terminal:
       ```bash
       tccutil reset Accessibility org.keycount.app
       ```
-   **App won't open:** Ensure you are on macOS 15.0 (Sequoia) or newer.

---

## 🗺 Future Roadmap
- [ ] Visual charts and historical trends.
- [ ] Export data to CSV/JSON.
- [ ] Customizable goals (e.g., "Type 10k characters today").

*Developed with ❤️ as a native macOS utility.*
