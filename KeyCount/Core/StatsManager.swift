import Foundation
import SwiftData
import CoreGraphics
import AppKit

@MainActor
final class StatsManager: ObservableObject, KeystrokeDelegate {
    // Параметры для SwiftData
    private var modelContext: ModelContext
    
    // Текущие счетчики (In-memory для производительности)
    @Published private(set) var todayCount: Int = 0
    @Published private(set) var lastHourCount: Int = 0
    @Published private(set) var totalCount: Int = 0
    
    // Настройки
    @Published var countingMode: CountingMode = .smart
    @Published var countEnter: Bool = false
    @Published private(set) var isTrusted: Bool = false
    
    private var monitor: KeystrokeMonitor
    private var flushTimer: Timer?
    
    // Буфер для текущей минуты
    private var currentMinuteCount: Int = 0
    private var lastFlushTime: Date = Date()
    
    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
        self.monitor = KeystrokeMonitor()
        
        // Загрузка начальных данных
        loadInitialStats()
        
        self.monitor.delegate = self
        self.monitor.start()
        
        self.isTrusted = self.monitor.checkPermissions()
        
        self.flushTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                let nowTrusted = self?.monitor.checkPermissions() ?? false
                if nowTrusted && !(self?.isTrusted ?? true) {
                    self?.monitor.start() // Restart if permissions granted
                }
                self?.isTrusted = nowTrusted
                self?.flush()
            }
        }
    }
    
    // MARK: - KeystrokeDelegate
    
    // Делаем метод неизолированным для соответствия протоколу, 
    // но сразу перебрасываем выполнение на MainActor
    nonisolated func didCaptureKey(event: CGEvent) {
        let flags = event.flags
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        Task { @MainActor in
            self.processKeyEvent(flags: flags, keyCode: keyCode)
        }
    }
    
    private func processKeyEvent(flags: CGEventFlags, keyCode: Int) {
        var shouldCount = false
        let isBackspace = (keyCode == 51) // macOS backspace keycode
        
        switch countingMode {
        case .smart:
            let hasModifiers = flags.contains(.maskCommand) || 
                               flags.contains(.maskAlternate) || 
                               flags.contains(.maskControl)
            
            if !hasModifiers {
                if isBackspace {
                    shouldCount = true
                } else if keyCode == 36 { // Enter
                    shouldCount = countEnter
                } else {
                    shouldCount = true
                }
            }
            
        case .allExceptModifiers:
            let modifierKeyCodes = Set([54, 55, 56, 57, 58, 59, 60, 61, 62, 63])
            shouldCount = !modifierKeyCodes.contains(keyCode)
            
        case .allKeyDown:
            shouldCount = true
        }
        
        if shouldCount {
            if isBackspace && countingMode == .smart {
                decrement()
            } else {
                increment()
            }
        }
    }
    
    // MARK: - Logic
    
    private func increment() {
        currentMinuteCount += 1
        todayCount += 1
        totalCount += 1
        lastHourCount += 1
    }
    
    private func decrement() {
        if currentMinuteCount > 0 {
            currentMinuteCount -= 1
            todayCount = max(0, todayCount - 1)
            totalCount = max(0, totalCount - 1)
            lastHourCount = max(0, lastHourCount - 1)
        }
    }
    
    func flush() {
        guard currentMinuteCount != 0 else { return }
        
        let now = Date()
        let minuteTs = KeyBucket.normalizedTimestamp(now)
        
        let descriptor = FetchDescriptor<KeyBucket>(predicate: #Predicate { $0.timestamp == minuteTs })
        
        do {
            let existing = try modelContext.fetch(descriptor)
            if let bucket = existing.first {
                bucket.count += currentMinuteCount
            } else {
                let newBucket = KeyBucket(timestamp: minuteTs, count: currentMinuteCount)
                modelContext.insert(newBucket)
            }
            try modelContext.save()
            currentMinuteCount = 0
            refreshStats()
        } catch {
            print("Failed to save buckets: \(error)")
        }
    }
    
    func refreshStats() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now)
        todayCount = sum(from: midnight, to: now)
        
        let hourAgo = now.addingTimeInterval(-3600)
        lastHourCount = sum(from: hourAgo, to: now)
        
        totalCount = sum(from: .distantPast, to: .distantFuture)
    }
    
    private func sum(from: Date, to: Date) -> Int {
        let descriptor = FetchDescriptor<KeyBucket>(predicate: #Predicate { $0.timestamp >= from && $0.timestamp <= to })
        do {
            let buckets = try modelContext.fetch(descriptor)
            return buckets.reduce(0) { $0 + $1.count }
        } catch {
            return 0
        }
    }
    
    private func loadInitialStats() {
        refreshStats()
    }
    
    // MARK: - Reset Actions
    
    func resetToday() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now)
        
        let predicate = #Predicate<KeyBucket> { $0.timestamp >= midnight }
        do {
            try modelContext.delete(model: KeyBucket.self, where: predicate)
            try modelContext.save()
            currentMinuteCount = 0
            refreshStats()
        } catch {
            print("Failed to reset today: \(error)")
        }
    }
    
    func resetAll() {
        do {
            try modelContext.delete(model: KeyBucket.self)
            try modelContext.save()
            currentMinuteCount = 0
            refreshStats()
        } catch {
            print("Failed to reset all: \(error)")
        }
    }
    
    // MARK: - Computed Averages
    
    var averagePerHour: Int {
        let calendar = Calendar.current
        let now = Date()
        let hour = max(1, calendar.component(.hour, from: now) + 1)
        return todayCount / hour
    }
    
    func averagePerDay() -> Int {
        do {
            let buckets = try modelContext.fetch(FetchDescriptor<KeyBucket>())
            let days = Set(buckets.filter { $0.count > 0 }.map { Calendar.current.startOfDay(for: $0.timestamp) })
            return days.isEmpty ? todayCount : totalCount / days.count
        } catch {
            return 0
        }
    }
}
