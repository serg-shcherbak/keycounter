import SwiftUI
import SwiftData

@main
struct KeyCountApp: App {
    // Контейнер SwiftData
    let container: ModelContainer
    
    // Менеджер статистики (StateObject для жизненного цикла)
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
        // Основной элемент приложения - Menu Bar
        MenuBarExtra {
            PopoverView(stats: stats)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                
                if showCountInMenubar {
                    Text(NumberFormatterUtils.formatXK(stats.todayCount))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window) // Чтобы открывался Popover/Окно
        
        // Окно настроек
        Settings {
            SettingsView(stats: stats)
        }
    }
}
