import Foundation
import SwiftData
import CoreGraphics
import AppKit

@MainActor
final class StatsManager: ObservableObject, KeystrokeDelegate {
    private var modelContext: ModelContext
    
    @Published private(set) var todayCount: Int = 0
    @Published private(set) var lastHourCount: Int = 0
    @Published private(set) var totalCount: Int = 0
    
    @Published var countingMode: CountingMode = .smart
    @Published var countEnter: Bool = false
    @Published var isTrusted: Bool = false
    
    var monitorIsListening: Bool {
        monitor.isListening
    }
    
    private var monitor: KeystrokeMonitor
    private var flushTimer: Timer?
    
    private var currentMinuteCount: Int = 0
    
    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
        self.monitor = KeystrokeMonitor()
        
        loadInitialStats()
        
        self.monitor.delegate = self
        self.monitor.start()
        
        // Initial check
        self.isTrusted = self.monitor.checkPermissions()
        
        // Frequent check for permissions and flushing
        self.flushTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let nowTrusted = self.monitor.checkPermissions()
                
                // If permission state changed to true, restart monitor
                if nowTrusted && !self.isTrusted {
                    self.monitor.start()
                }
                
                // If monitor is actually listening, we are trusted
                self.isTrusted = nowTrusted || self.monitor.isListening
                self.flush()
            }
        }
    }
    
    nonisolated func didCaptureKey(event: CGEvent) {
        let flags = event.flags
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        Task { @MainActor in
            self.processKeyEvent(flags: flags, keyCode: keyCode)
        }
    }
    
    private func processKeyEvent(flags: CGEventFlags, keyCode: Int) {
        // If we received an event, we definitely have permission
        if !isTrusted { isTrusted = true }
        
        var shouldCount = false
        let isBackspace = (keyCode == 51)
        
        switch countingMode {
        case .smart:
            let hasModifiers = flags.contains(.maskCommand) || 
                               flags.contains(.maskAlternate) || 
                               flags.contains(.maskControl)
            
            if !hasModifiers {
                if isBackspace {
                    shouldCount = true
                } else if keyCode == 36 {
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
            print("Failed to save: \(error)")
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
            print("Reset error: \(error)")
        }
    }
    
    func resetAll() {
        do {
            try modelContext.delete(model: KeyBucket.self)
            try modelContext.save()
            currentMinuteCount = 0
            refreshStats()
        } catch {
            print("Reset error: \(error)")
        }
    }
    
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
