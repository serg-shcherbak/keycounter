import SwiftUI

struct PopoverView: View {
    @ObservedObject var stats: StatsManager
    
    @State private var selectedTab: Int = 0 // 0: Stats, 1: Settings
    @State private var showingResetTodayAlert = false
    @State private var showingResetAllAlert = false
    
    @AppStorage("showCountInMenubar") private var showCountInMenubar = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Switcher Header
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: 4) {
                        Text("Stats")
                            .fontWeight(selectedTab == 0 ? .bold : .regular)
                            .foregroundColor(selectedTab == 0 ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == 0 ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: 4) {
                        Text("Settings")
                            .fontWeight(selectedTab == 1 ? .bold : .regular)
                            .foregroundColor(selectedTab == 1 ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == 1 ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 12)
            .padding(.horizontal)
            
            Divider().padding(.top, 8)
            
            if selectedTab == 0 {
                statsView
            } else {
                settingsView
            }
        }
        .frame(width: 280)
    }
    
    // MARK: - Stats View
    var statsView: some View {
        VStack(spacing: 0) {
            if !stats.isTrusted && !stats.monitorIsListening {
                permissionBanner
            }
            
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
            
            HStack(spacing: 10) {
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
        .alert("Reset Today", isPresented: $showingResetTodayAlert) {
            Button("Reset Today", role: .destructive) { stats.resetToday() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Today's data will be deleted.")
        }
        .alert("Full Reset", isPresented: $showingResetAllAlert) {
            Button("Reset All", role: .destructive) { stats.resetAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All history will be permanently deleted.")
        }
    }
    
    // MARK: - Settings View
    var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show counter in menu bar", isOn: $showCountInMenubar)
                    Toggle("Launch at login", isOn: $launchAtLogin)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Counting Mode").font(.subheadline).foregroundColor(.secondary)
                    Picker("", selection: $stats.countingMode) {
                        ForEach(CountingMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    
                    Toggle("Count Enter as a key", isOn: $stats.countEnter)
                        .disabled(stats.countingMode != .smart)
                }
                
                Divider()
                
                // Troubleshoot
                VStack(alignment: .leading, spacing: 8) {
                    Text("Troubleshooting").font(.subheadline).foregroundColor(.secondary)
                    Button("Restart Tracking") {
                        stats.forceRestartMonitor()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Open System Settings") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .font(.caption)
                }
                
                Divider()
                
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    HStack {
                        Spacer()
                        Text("Quit KeyCount")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                
                Text("Version 1.0.4")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .frame(maxHeight: 400)
    }
    
    var permissionBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Permission Required")
                    .font(.subheadline).bold()
            }
            Text("Enable KeyCount in System Settings -> Accessibility. If already enabled, toggle it OFF and ON.")
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(NumberFormatterUtils.formatFull(value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}
