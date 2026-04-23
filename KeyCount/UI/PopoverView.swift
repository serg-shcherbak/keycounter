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
                
                // Троеточие - заменяем Menu на кнопку, которая открывает нативное меню
                Button {
                    showContextMenu()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Onboarding banner
            if !stats.isTrusted {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Permission Required")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    Text("1. Open System Settings\n2. Go to Privacy & Security\n3. Select **Input Monitoring**\n4. Enable **KeyCount**")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("Open System Settings") {
                        // Открываем конкретно Input Monitoring
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Text("Note: If already enabled, toggle it OFF and ON again.")
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
    
    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: Selector(("showSettingsWindow:")), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyCount", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let event = NSApp.currentEvent
        NSMenu.popUpContextMenu(menu, with: event ?? NSEvent(), for: NSApp.keyWindow?.contentView ?? NSView())
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
