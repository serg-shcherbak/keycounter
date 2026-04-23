import Foundation
import CoreGraphics
import AppKit

protocol KeystrokeDelegate: AnyObject {
    func didCaptureKey(event: CGEvent)
}

final class KeystrokeMonitor: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private var thread: Thread?
    
    private let stateLock = NSLock()
    
    weak var delegate: KeystrokeDelegate?
    
    private let _isListening = AtomicBool(false)
    private let _tapCreated = AtomicBool(false)
    private let _lastEventTime = AtomicDouble(0)
    
    var isListening: Bool { _isListening.value }
    var tapCreated: Bool { _tapCreated.value }
    var lastEventTime: Double { _lastEventTime.value }
    
    init() {}
    
    func start() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard !_isListening.value else { return }
        
        _tapCreated.set(false)
        let newThread = Thread { [weak self] in
            self?.run()
        }
        newThread.name = "org.keycount.monitor"
        self.thread = newThread
        newThread.start()
    }
    
    private func run() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, 
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeystrokeMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                if type == .keyDown {
                    monitor.recordEvent()
                    monitor.delegate?.didCaptureKey(event: event)
                }
                
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let tap = tap else {
            return
        }
        
        _tapCreated.set(true)
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source = source else { return }
        
        stateLock.lock()
        self.eventTap = tap
        self.runLoopSource = source
        self.runLoop = CFRunLoopGetCurrent()
        stateLock.unlock()
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        _isListening.set(true)
        CFRunLoopRun()
        
        _isListening.set(false)
    }
    
    func recordEvent() {
        _lastEventTime.set(Date().timeIntervalSince1970)
    }
    
    func stop() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, let rl = runLoop {
            CFRunLoopRemoveSource(rl, source, .commonModes)
        }
        if let rl = runLoop {
            CFRunLoopStop(rl)
        }
        eventTap = nil
        runLoopSource = nil
        runLoop = nil
        thread = nil
        _isListening.set(false)
    }
    
    func checkPermissionsSilent() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func requestPermissionsWithPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock(); private var v: Bool
    init(_ v: Bool) { self.v = v }
    var value: Bool { lock.lock(); defer { lock.unlock() }; return v }
    func set(_ nv: Bool) { lock.lock(); defer { lock.unlock() }; v = nv }
}

final class AtomicDouble: @unchecked Sendable {
    private let lock = NSLock(); private var v: Double
    init(_ v: Double) { self.v = v }
    var value: Double { lock.lock(); defer { lock.unlock() }; return v }
    func set(_ nv: Double) { lock.lock(); defer { lock.unlock() }; v = nv }
}
