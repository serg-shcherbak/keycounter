import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var stats: StatsManager
    
    @AppStorage("showCountInMenubar") private var showCountInMenubar = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Show counter in menu bar", isOn: $showCountInMenubar)
                
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
            
            Divider()
            
            Section {
                Picker("Counting Mode", selection: $stats.countingMode) {
                    ForEach(CountingMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Count Enter as a key", isOn: $stats.countEnter)
                    .disabled(stats.countingMode != .smart)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 350)
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
