import SwiftUI

struct PopoverView: View {
    @ObservedObject var stats: StatsManager
    
    @State private var selectedTab: Int = 0 // 0: Stats, 1: Settings
    @State private var showingResetTodayAlert = false
    @State private var showingResetAllAlert = false
    
    @AppStorage("showCountInMenubar") private var showCountInMenubar = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showDiagnostics") private var showDiagnostics = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Switcher Header
            HStack(spacing: 0) {
                tabButton(title: "Statistics", index: 0)
                tabButton(title: "Settings", index: 1)
            }
            .padding(.top, 12)
            .padding(.horizontal)
            
            Divider().padding(.top, 8)
            
            if selectedTab == 0 {
                statsView
                    .transition(.opacity)
            } else {
                settingsView
                    .transition(.opacity)
            }
        }
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == index ? .bold : .medium))
                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                Rectangle()
                    .fill(selectedTab == index ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Stats View
    var statsView: some View {
        VStack(spacing: 0) {
            if !stats.isTrusted && !stats.monitorIsListening {
                permissionBanner
            }
            
            VStack(spacing: 14) {
                StatRow(label: "Today", value: stats.todayCount)
                StatRow(label: "Last Hour", value: stats.lastHourCount)
                
                Divider().padding(.vertical, 2)
                
                StatGroup(title: "Averages") {
                    StatRow(label: "Per Hour", value: stats.averagePerHour)
                    StatRow(label: "Per Day", value: stats.averagePerDay)
                }
                
                Divider().padding(.vertical, 2)
                
                StatRow(label: "Total Keystrokes", value: stats.totalCount)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: { showingResetTodayAlert = true }) {
                    Label("Reset Today", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { showingResetAllAlert = true }) {
                    Label("Full Reset", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 12)
        }
        .alert("Reset Today's Data?", isPresented: $showingResetTodayAlert) {
            Button("Reset Today", role: .destructive) { stats.resetToday() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all keystrokes recorded since midnight.")
        }
        .alert("Perform Full Reset?", isPresented: $showingResetAllAlert) {
            Button("Reset Everything", role: .destructive) { stats.resetAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all history and statistics. This action cannot be undone.")
        }
    }
    
    // MARK: - Settings View
    var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // General
                VStack(alignment: .leading, spacing: 10) {
                    Text("General").font(.caption).bold().foregroundColor(.secondary)
                    Toggle("Show counter in menu bar", isOn: $showCountInMenubar)
                    Toggle("Launch at login", isOn: $launchAtLogin)
                }
                
                Divider()
                
                // Counting
                VStack(alignment: .leading, spacing: 10) {
                    Text("Counting Strategy").font(.caption).bold().foregroundColor(.secondary)
                    Picker("Mode", selection: $stats.countingMode) {
                        ForEach(CountingMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if stats.countingMode == .smart {
                        Toggle("Count 'Enter' key", isOn: $stats.countEnter)
                            .font(.subheadline)
                    }
                }
                
                Divider()
                
                // Advanced
                VStack(alignment: .leading, spacing: 10) {
                    Text("Advanced").font(.caption).bold().foregroundColor(.secondary)
                    Toggle("Show Debug Info", isOn: $showDiagnostics)
                    
                    if showDiagnostics {
                        VStack(alignment: .leading, spacing: 6) {
                            DiagnosticRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                            DiagnosticRow(label: "Accessibility Trusted", value: stats.isTrusted ? "YES" : "NO")
                            DiagnosticRow(label: "Event Tap Created", value: stats.tapCreated ? "YES" : "NO")
                            DiagnosticRow(label: "Event Tap Active", value: stats.monitorIsListening ? "YES" : "NO")
                            
                            let cmd = "tccutil reset Accessibility \(Bundle.main.bundleIdentifier ?? "org.keycount.app")"
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(cmd, forType: .string)
                            }) {
                                Label("Copy TCC Reset Command", systemImage: "doc.on.doc")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.link)
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                    }
                    
                    Button("Restart Key Monitoring") {
                        stats.forceRestartMonitor()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Divider()
                
                // Quit
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "power")
                        Text("Quit KeyCount")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                
                Text("KeyCount v1.2 (Production Ready)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .frame(maxHeight: 450)
    }
    
    var permissionBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.orange)
                Text("Permissions Required")
                    .font(.subheadline).bold()
            }
            Text("1. Remove KeyCount using '-' in BOTH sections\n2. Click '+' to add it back and enable")
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button("Accessibility") {
                    stats.requestSystemPermissions()
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Input Monitoring") {
                    stats.requestSystemPermissions()
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
    }
}

struct StatGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
            content
        }
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

struct DiagnosticRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 9))
            Spacer()
            Text(value).font(.system(size: 9, weight: .bold))
        }
    }
}
