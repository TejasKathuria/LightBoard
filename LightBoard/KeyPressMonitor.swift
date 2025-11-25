//
//  KeyPressMonitor.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import Foundation
import Combine
import ApplicationServices

class KeyPressMonitor: ObservableObject {
    @Published var isMonitoring: Bool = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var onKeyPress: (() -> Void)?
    
    /// Start monitoring keyboard events
    func startMonitoring(onKeyPress: @escaping () -> Void) {
        guard !isMonitoring else { return }
        
        self.onKeyPress = onKeyPress
        
      
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        guard AXIsProcessTrusted() else {
            print("⚠️ Accessibility permissions not granted")
            return
        }
        
        // Create event tap for key down events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Call the key press handler
                if type == .keyDown {
                    let monitor = Unmanaged<KeyPressMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                    DispatchQueue.main.async {
                        monitor.onKeyPress?()
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isMonitoring = true
        print("✅ Key press monitoring started")
    }
    
  
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            eventTap = nil
            runLoopSource = nil
        }
        
        isMonitoring = false
        onKeyPress = nil
        print("🛑 Key press monitoring stopped")
    }
    
    deinit {
        stopMonitoring()
    }
}
