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
    @Published private(set) var activeDays: Int = 1
    
    @Published var countingMode: CountingMode = .smart
    @Published var countEnter: Bool = false
    @Published var isTrusted: Bool = false
    @Published var tapCreated: Bool = false
    @Published var lastEventTime: Double = 0
    
    var monitorIsListening: Bool {
        monitor.isListening
    }
    
    private var monitor: KeystrokeMonitor
    private var flushTimer: Timer?
    private var uiTimer: Timer?
    
    private var currentMinuteCount: Int = 0
    private var lastKnownDay: Date = Date.distantPast
    
    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
        self.monitor = KeystrokeMonitor()
        
        loadInitialStats()
        
        self.monitor.delegate = self
        self.monitor.start()
        
        self.isTrusted = self.monitor.checkPermissionsSilent()
        self.tapCreated = self.monitor.tapCreated
        
        // Timer for flushing to DB (every 30s)
        self.flushTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flush()
            }
        }
        
        // Timer for UI updates and permission checks (every 3s)
        self.uiTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Only check permissions if we don't have them yet or aren't listening
                if !self.isTrusted || !self.monitor.isListening {
                    let nowTrusted = self.monitor.checkPermissionsSilent()
                    if nowTrusted && !self.monitor.isListening {
                        self.monitor.start()
                    }
                    self.isTrusted = nowTrusted || self.monitor.isListening
                }
                
                self.tapCreated = self.monitor.tapCreated
                self.lastEventTime = self.monitor.lastEventTime
                
                // Check midnight crossing
                let currentDay = Calendar.current.startOfDay(for: Date())
                if currentDay != self.lastKnownDay {
                    self.flush() // flush remaining for old day
                    self.lastKnownDay = currentDay
                    self.todayCount = 0
                    self.activeDays += 1
                }
                
                self.updateMovingAverages()
            }
        }
    }
    
    func requestSystemPermissions() {
        monitor.requestPermissionsWithPrompt()
    }
    
    nonisolated func didCaptureKey(event: CGEvent) {
        let flags = event.flags
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        Task { @MainActor in
            self.processKeyEvent(flags: flags, keyCode: keyCode)
        }
    }
    
    private func processKeyEvent(flags: CGEventFlags, keyCode: Int) {
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
    }
    
    private func decrement() {
        if currentMinuteCount > 0 {
            currentMinuteCount -= 1
            todayCount = max(0, todayCount - 1)
            totalCount = max(0, totalCount - 1)
        } else {
            // Need to decrement from DB
            let now = Date()
            let midnight = Calendar.current.startOfDay(for: now)
            let descriptor = FetchDescriptor<KeyBucket>(
                predicate: #Predicate { $0.timestamp >= midnight && $0.count > 0 },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            do {
                if let lastBucket = try modelContext.fetch(descriptor).first {
                    lastBucket.count -= 1
                    try modelContext.save()
                    todayCount = max(0, todayCount - 1)
                    totalCount = max(0, totalCount - 1)
                }
            } catch {
                print("Failed to decrement from DB: \(error)")
            }
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
            updateMovingAverages()
        } catch {
            print("Save error: \(error)")
        }
    }
    
    private func updateMovingAverages() {
        let hourAgo = Date().addingTimeInterval(-3600)
        let sumLastHour = sum(from: hourAgo, to: Date())
        lastHourCount = sumLastHour + currentMinuteCount
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
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now)
        self.lastKnownDay = midnight
        
        todayCount = sum(from: midnight, to: now)
        
        // Calculate Total
        totalCount = sum(from: .distantPast, to: .distantFuture)
        
        // Calculate Active Days
        do {
            let descriptor = FetchDescriptor<KeyBucket>(predicate: #Predicate { $0.count > 0 })
            let buckets = try modelContext.fetch(descriptor)
            let days = Set(buckets.map { Calendar.current.startOfDay(for: $0.timestamp) })
            activeDays = max(1, days.count)
        } catch {
            activeDays = 1
        }
        
        updateMovingAverages()
    }
    
    func resetToday() {
        let now = Date()
        let midnight = Calendar.current.startOfDay(for: now)
        let predicate = #Predicate<KeyBucket> { $0.timestamp >= midnight }
        do {
            try modelContext.delete(model: KeyBucket.self, where: predicate)
            try modelContext.save()
            currentMinuteCount = 0
            todayCount = 0
            totalCount = sum(from: .distantPast, to: .distantFuture)
            updateMovingAverages()
        } catch {
            print("Reset error: \(error)")
        }
    }
    
    func resetAll() {
        do {
            try modelContext.delete(model: KeyBucket.self)
            try modelContext.save()
            currentMinuteCount = 0
            todayCount = 0
            totalCount = 0
            activeDays = 1
            updateMovingAverages()
        } catch {
            print("Reset error: \(error)")
        }
    }
    
    func forceRestartMonitor() {
        monitor.stop()
        monitor = KeystrokeMonitor()
        monitor.delegate = self
        monitor.start()
        isTrusted = monitor.checkPermissionsSilent()
    }
    
    var averagePerHour: Int {
        let calendar = Calendar.current
        let now = Date()
        let hour = max(1, calendar.component(.hour, from: now) + 1)
        return todayCount / hour
    }
    
    var averagePerDay: Int {
        return totalCount / max(1, activeDays)
    }
}
