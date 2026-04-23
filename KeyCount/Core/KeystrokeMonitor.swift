import Foundation
import CoreGraphics
import AppKit

protocol KeystrokeDelegate: AnyObject {
    func didCaptureKey(event: CGEvent)
}

final class KeystrokeMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var thread: Thread?
    
    weak var delegate: KeystrokeDelegate?
    
    // Diagnostics
    private let _isListening = AtomicBool(false)
    private let _tapCreated = AtomicBool(false)
    private let _lastEventTime = AtomicDouble(0)
    
    var isListening: Bool { _isListening.value }
    var tapCreated: Bool { _tapCreated.value }
    var lastEventTime: Double { _lastEventTime.value }
    
    init() {}
    
    func start() {
        guard !_isListening.value else { return }
        
        _tapCreated.set(false)
        thread = Thread { [weak self] in
            self?.run()
        }
        thread?.name = "com.keycount.monitor"
        thread?.start()
    }
    
    private func run() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // Попробуем вернуться к .cgSessionEventTap, он более стандартный
        eventTap = CGEvent.tapCreate(
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
        
        guard let eventTap = eventTap else {
            print("KeystrokeMonitor: Failed to create tap")
            return
        }
        
        _tapCreated.set(true)
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let source = runLoopSource else { return }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        _isListening.set(true)
        CFRunLoopRun()
    }
    
    func recordEvent() {
        _lastEventTime.set(Date().timeIntervalSince1970)
    }
    
    func stop() {
        _isListening.set(false)
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
        }
        eventTap = nil
        runLoopSource = nil
        thread = nil
    }
    
    func checkPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
}

// Helpers
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
