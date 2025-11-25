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
import AVFoundation

class AccessibilityPermissionHelper: ObservableObject {
    @Published var hasPermission: Bool = false
    @Published var hasMicrophonePermission: Bool = false
    
    init() {
        checkPermission()
    }
    
   
    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
        checkMicrophonePermission()
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
    
    // MARK: - Microphone Permissions
    
    func checkMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        hasMicrophonePermission = (status == .authorized)
    }
    
    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasMicrophonePermission = granted
                
                if !granted {
                    self?.showMicrophonePermissionAlert()
                }
            }
        }
    }
    
    private func showMicrophonePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Permission Required"
        alert.informativeText = "LightBoard needs microphone access to detect music beats for the Music Sync mode.\n\n1. Click 'Open System Settings'\n2. Go to Privacy & Security > Microphone\n3. Enable LightBoard\n4. Restart LightBoard"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openPrivacySettings()
        }
    }
    
    private func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func getMicrophonePermissionMessage() -> String {
        if hasMicrophonePermission {
            return "✓ Microphone access granted"
        } else {
            return "⚠️ Microphone access required for Music Sync"
        }
    }
}
