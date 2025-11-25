//
//  AccessibilityPermissionHelper.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import Foundation
import Combine
import ApplicationServices
import AppKit

class AccessibilityPermissionHelper: ObservableObject {
    @Published var hasPermission: Bool = false
    
    init() {
        checkPermission()
    }
    
   
    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }
    
    
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        hasPermission = trusted
        
        if !trusted {
            
            DispatchQueue.main.async {
                self.showPermissionAlert()
            }
        }
    }
    
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "LightBoard needs Accessibility permissions to control keyboard brightness.\n\n1. Click 'Open System Settings'\n2. Find 'LightBoard' in the list\n3. Enable the checkbox next to it\n4. Restart LightBoard"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemSettings()
        }
    }
    

    func getPermissionMessage() -> String {
        if hasPermission {
            return "✓ Accessibility permissions granted"
        } else {
            return "⚠️ Accessibility permissions required"
        }
    }
}
