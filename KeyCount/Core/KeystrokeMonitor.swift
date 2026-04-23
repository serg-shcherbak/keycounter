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
    
    // Using a thread-safe boolean
    private let _isListening = AtomicBool(false)
    var isListening: Bool { _isListening.value }
    
    init() {}
    
    func start() {
        guard !_isListening.value else { return }
        
        // Start the monitor in a dedicated background thread
        thread = Thread { [weak self] in
            self?.run()
        }
        thread?.name = "com.keycount.keystroke-monitor"
        thread?.start()
    }
    
    private func run() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // We use .cghidEventTap for better reliability in background apps on macOS 15+
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap, 
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeystrokeMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                if type == .keyDown {
                    // Send to delegate
                    monitor.delegate?.didCaptureKey(event: event)
                }
                
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            print("KeystrokeMonitor: Failed to create event tap.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let source = runLoopSource else { return }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        _isListening.set(true)
        
        // Keep the thread alive
        CFRunLoopRun()
    }
    
    func stop() {
        guard _isListening.value else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        // Stop the RunLoop in the background thread
        if let thread = thread {
            // We need to stop the runloop from within the thread itself 
            // but for simplicity we'll just invalidate the source
            if let source = runLoopSource {
                // This doesn't stop the loop immediately but invalidates the source
                CFRunLoopSourceInvalidate(source)
            }
        }
        
        eventTap = nil
        runLoopSource = nil
        thread = nil
        _isListening.set(false)
    }
    
    func checkPermissions() -> Bool {
        // AXIsProcessTrusted is the most reliable "soft" check
        return AXIsProcessTrusted()
    }
}

// Simple Atomic helper
final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool
    
    init(_ value: Bool) {
        self._value = value
    }
    
    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
    
    func set(_ newValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _value = newValue
    }
}
