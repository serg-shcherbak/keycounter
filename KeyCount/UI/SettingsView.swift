import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var stats: StatsManager
    
    @AppStorage("showCountInMenubar") private var showCountInMenubar = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Показывать счётчик в меню-баре", isOn: $showCountInMenubar)
                
                Toggle("Запускать при входе в систему", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
            
            Divider()
            
            Section {
                Picker("Режим подсчёта", selection: $stats.countingMode) {
                    ForEach(CountingMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Считать Enter символом", isOn: $stats.countEnter)
                    .disabled(stats.countingMode != .smart)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Версия 1.0.0")
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
