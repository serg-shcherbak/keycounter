import SwiftUI

struct PopoverView: View {
    @ObservedObject var stats: StatsManager
    @Environment(\.openWindow) var openWindow
    
    // Состояние для подтверждения сброса
    @State private var showingResetTodayAlert = false
    @State private var showingResetAllAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                Text("KeyCount")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Открыть настройки
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Onboarding баннер
            if !stats.isTrusted {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Нужен доступ к вводу")
                            .font(.headline)
                    }
                    Text("KeyCount считает нажатия клавиш, но не записывает текст. Откройте Системные настройки и разрешите доступ.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Открыть Системные настройки") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Divider()
            }
            
            // Статистика
            VStack(spacing: 12) {
                StatRow(label: "Сегодня", value: stats.todayCount)
                StatRow(label: "Последний час", value: stats.lastHourCount)
                
                Divider().padding(.vertical, 4)
                
                StatRow(label: "Среднее в час", value: stats.averagePerHour)
                StatRow(label: "Среднее в сутки", value: stats.averagePerDay())
                
                Divider().padding(.vertical, 4)
                
                StatRow(label: "Всего", value: stats.totalCount)
            }
            .padding()
            
            Divider()
            
            // Кнопки сброса
            HStack(spacing: 12) {
                Button("Сбросить сегодня") {
                    showingResetTodayAlert = true
                }
                .buttonStyle(.bordered)
                
                Button("Полный сброс") {
                    showingResetAllAlert = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 260)
        .alert("Сбросить сегодня", isPresented: $showingResetTodayAlert) {
            Button("Сбросить сегодня", role: .destructive) { stats.resetToday() }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Данные за сегодняшний день будут удалены. Статистика прошлых дней сохранится.")
        }
        .alert("Полный сброс", isPresented: $showingResetAllAlert) {
            Button("Сбросить всё", role: .destructive) { stats.resetAll() }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Все данные будут удалены: история, общий счётчик, статистика по дням.\nЭто действие необратимо.")
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
