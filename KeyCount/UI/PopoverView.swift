import SwiftUI

struct PopoverView: View {
    @ObservedObject var stats: StatsManager
    
    @State private var showingResetTodayAlert = false
    @State private var showingResetAllAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("KeyCount")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("Settings...") {
                        openSettings()
                    }
                    Divider()
                    Button("Quit KeyCount") {
                        NSApp.terminate(nil)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding()
            
            Divider()
            
            // Onboarding banner
            // Показываем только если доступа действительно нет И монитор не слушает
            if !stats.isTrusted && !stats.monitorIsListening {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Permission Required")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    Text("1. Open System Settings\n2. Go to Privacy & Security\n3. Select **Accessibility**\n4. Enable **KeyCount**")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("Open System Settings") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Text("Note: If enabled, toggle it OFF and ON again.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding()
                Divider()
            }
            
            // Stats
            VStack(spacing: 12) {
                StatRow(label: "Today", value: stats.todayCount)
                StatRow(label: "Last Hour", value: stats.lastHourCount)
                
                Divider().padding(.vertical, 4)
                
                StatRow(label: "Avg per Hour", value: stats.averagePerHour)
                StatRow(label: "Avg per Day", value: stats.averagePerDay())
                
                Divider().padding(.vertical, 4)
                
                StatRow(label: "Total", value: stats.totalCount)
            }
            .padding()
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 10) {
                Button("Reset Today") {
                    showingResetTodayAlert = true
                }
                .buttonStyle(.bordered)
                
                Button("Full Reset") {
                    showingResetAllAlert = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 280)
        .alert("Reset Today", isPresented: $showingResetTodayAlert) {
            Button("Reset Today", role: .destructive) { stats.resetToday() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Today's data will be deleted. Past history remains safe.")
        }
        .alert("Full Reset", isPresented: $showingResetAllAlert) {
            Button("Reset All", role: .destructive) { stats.resetAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All data will be permanently deleted: history, totals, and daily stats.")
        }
    }
    
    private func openSettings() {
        // Активируем приложение перед открытием настроек
        NSApp.activate(ignoringOtherApps: true)
        
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        
        // Хак: принудительно выводим окно настроек вперед
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for window in NSApp.windows {
                if window.title == "KeyCount Settings" || window.title == "Settings" || window.className.contains("Settings") {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(NumberFormatterUtils.formatFull(value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}
