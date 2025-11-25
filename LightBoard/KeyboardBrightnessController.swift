//
//  KeyboardBrightnessController.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import Foundation
import CoreGraphics
import AppKit

class KeyboardBrightnessController {
   
    private let NX_KEYTYPE_ILLUMINATION_UP: Int32 = 21
    private let NX_KEYTYPE_ILLUMINATION_DOWN: Int32 = 22
    

    func increaseBrightness() {
        postKeyboardIlluminationEvent(keyType: NX_KEYTYPE_ILLUMINATION_UP)
    }
    
  
    func decreaseBrightness() {
        postKeyboardIlluminationEvent(keyType: NX_KEYTYPE_ILLUMINATION_DOWN)
    }
    
    
    func increaseBrightness(steps: Int) {
        for _ in 0..<steps {
            increaseBrightness()
            
            usleep(50000)
        }
    }
    
   
    func decreaseBrightness(steps: Int) {
        for _ in 0..<steps {
            decreaseBrightness()
            
            usleep(50000) // 50ms delay
        }
    }
    

    private func postKeyboardIlluminationEvent(keyType: Int32) {
       
        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // NX_SUBTYPE_AUX_CONTROL_BUTTONS
            data1: Int((keyType << 16) | ((0xa) << 8)),
            data2: -1
        ) else {
            print("Failed to create keyboard illumination event for key type: \(keyType)")
            return
        }
        
        
        event.cgEvent?.post(tap: .cghidEventTap)
        
        // Small delay
        usleep(10000) // 10ms
        
        // Create key up event
        guard let eventUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // NX_SUBTYPE_AUX_CONTROL_BUTTONS
            data1: Int((keyType << 16) | ((0xb) << 8)),
            data2: -1
        ) else {
            print("Failed to create keyboard illumination up event for key type: \(keyType)")
            return
        }
        
        eventUp.cgEvent?.post(tap: .cghidEventTap)
    }
    

    func setBrightness(targetLevel: Int, currentLevel: Int) {
        let difference = targetLevel - currentLevel
        
        if difference > 0 {
            increaseBrightness(steps: difference)
        } else if difference < 0 {
            decreaseBrightness(steps: abs(difference))
        }

    }
}
