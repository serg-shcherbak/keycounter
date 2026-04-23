import SwiftUI
import SwiftData

@main
struct KeyCountApp: App {
    // SwiftData container
    let container: ModelContainer
    
    // Stats manager (StateObject for lifecycle)
    @StateObject private var stats: StatsManager
    
    @AppStorage("showCountInMenubar") private var showCountInMenubar = true
    
    init() {
        do {
            container = try ModelContainer(for: KeyBucket.self)
            let statsManager = StatsManager(modelContainer: container)
            _stats = StateObject(wrappedValue: statsManager)
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        // Main Menu Bar Extra
        MenuBarExtra {
            PopoverView(stats: stats)
        } label: {
            if showCountInMenubar {
                Text(NumberFormatterUtils.formatXK(stats.todayCount))
                    .font(.system(.body, design: .monospaced))
            } else {
                Image(systemName: "keyboard")
            }
        }
        .menuBarExtraStyle(.window)
        
        // Settings Window
        Settings {
            SettingsView(stats: stats)
        }
    }
}
