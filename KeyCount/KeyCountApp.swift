import SwiftUI
import SwiftData

@main
struct KeyCountApp: App {
    let container: ModelContainer
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
        MenuBarExtra {
            PopoverView(stats: stats)
        } label: {
            if showCountInMenubar {
                // Только текст, без иконки
                Text(NumberFormatterUtils.formatXK(stats.todayCount))
                    .font(.system(.body, design: .monospaced))
            } else {
                // Если текст скрыт, показываем только иконку
                Image(systemName: "keyboard")
            }
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView(stats: stats)
        }
    }
}
