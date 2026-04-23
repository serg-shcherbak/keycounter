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
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        NSApp.activate(ignoringOtherApps: true)
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
            if !stats.isTrusted {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Input Access Required")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    Text("KeyCount needs Input Monitoring access to count keystrokes. It does not record text.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("Open System Settings") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
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
            HStack(spacing: 8) {
                Button("Reset Today") {
                    showingResetTodayAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Full Reset") {
                    showingResetAllAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(width: 280) // Slightly wider to fit text
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
