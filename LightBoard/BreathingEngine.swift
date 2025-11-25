//
//  BreathingEngine.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import Foundation
import Combine

class BreathingEngine: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var currentPhase: Double = 0.0 // 0.0 to 1.0, represents position in breathing cycle
    @Published var speed: Double = 4.0 // Duration of one complete breath cycle in seconds
    @Published var intensity: Int = 5 // Number of brightness steps (1-10)
    @Published var keyPressMode: Bool = false // Toggle between continuous breathing and key press mode
    
    private var timer: AnyCancellable?
    private let brightnessController = KeyboardBrightnessController()
    private var startTime: Date?
    private var currentBrightnessLevel: Int = 0
    private let maxBrightnessLevel: Int = 16 // macOS keyboard brightness has 16 levels
    private var fadeOutTimer: AnyCancellable?
    private let keyPressMonitor = KeyPressMonitor()
    
    /// Start the breathing effect
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        if keyPressMode {
            // Key press mode: monitor keyboard and pulse on key press
            currentBrightnessLevel = 0
            keyPressMonitor.startMonitoring { [weak self] in
                self?.handleKeyPress()
            }
        } else {
            // Continuous breathing mode
            startTime = Date()
            currentBrightnessLevel = 0 // Start from minimum
            
            // Create a timer that fires every 100ms for smooth transitions
            timer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateBreathing()
                }
        }
    }
    
    /// Stop the breathing effect
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        
        // Stop key press monitoring
        keyPressMonitor.stopMonitoring()
        
        // Stop continuous breathing timer
        timer?.cancel()
        timer = nil
        startTime = nil
        currentPhase = 0.0
        
        // Stop fade out timer
        fadeOutTimer?.cancel()
        fadeOutTimer = nil
        
        // Reset brightness to minimum
        if currentBrightnessLevel > 0 {
            brightnessController.decreaseBrightness(steps: currentBrightnessLevel)
            currentBrightnessLevel = 0
        }
    }
    
    /// Toggle breathing effect on/off
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    /// Toggle between continuous breathing and key press mode
    func toggleMode() {
        keyPressMode.toggle()
        
        // Restart if currently running to apply new mode
        if isRunning {
            stop()
            start()
        }
    }
    
    /// Update breathing effect based on elapsed time
    private func updateBreathing() {
        guard let startTime = startTime else { return }
        
        // Calculate elapsed time
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Calculate phase (0.0 to 1.0) based on speed
        let cycleProgress = (elapsed.truncatingRemainder(dividingBy: speed)) / speed
        currentPhase = cycleProgress
        
        // Use sine wave for smooth breathing pattern
        // sin(2π * phase) gives values from -1 to 1
        // We transform it to 0 to 1 range: (sin(2π * phase) + 1) / 2
        let sineValue = (sin(2 * .pi * cycleProgress) + 1) / 2
        
        // Calculate target brightness level based on intensity
        // Scale the sine wave to the intensity range
        let targetLevel = Int(round(sineValue * Double(intensity)))
        
        // Only adjust if target level is different from current
        if targetLevel != currentBrightnessLevel {
            let difference = targetLevel - currentBrightnessLevel
            
            if difference > 0 {
                brightnessController.increaseBrightness(steps: difference)
            } else if difference < 0 {
                brightnessController.decreaseBrightness(steps: abs(difference))
            }
            
            currentBrightnessLevel = targetLevel
        }
    }
    
    /// Update speed (duration of one breath cycle)
    func setSpeed(_ newSpeed: Double) {
        speed = max(1.0, min(10.0, newSpeed)) // Clamp between 1-10 seconds
        
        // Reset start time to avoid jumps when changing speed
        if isRunning {
            startTime = Date()
        }
    }
    
    /// Update intensity (number of brightness steps)
    func setIntensity(_ newIntensity: Int) {
        intensity = max(1, min(10, newIntensity)) // Clamp between 1-10 steps
    }
    
    /// Get current breathing level as a percentage (0.0 to 1.0) for UI visualization
    func getCurrentBreathingLevel() -> Double {
        return (sin(2 * .pi * currentPhase) + 1) / 2
    }
    
    /// Handle key press event - illuminate and fade out
    private func handleKeyPress() {
        // Cancel any existing fade out timer
        fadeOutTimer?.cancel()
        
        // Immediately set to maximum brightness based on intensity
        let targetLevel = intensity
        let difference = targetLevel - currentBrightnessLevel
        
        if difference > 0 {
            brightnessController.increaseBrightness(steps: difference)
        } else if difference < 0 {
            brightnessController.decreaseBrightness(steps: abs(difference))
        }
        
        currentBrightnessLevel = targetLevel
        
        // Start fade out after a short delay
        fadeOutTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fadeOut()
            }
    }
    
    /// Gradually fade out the keyboard brightness
    private func fadeOut() {
        guard currentBrightnessLevel > 0 else {
            fadeOutTimer?.cancel()
            fadeOutTimer = nil
            return
        }
        
        // Decrease by 1 step
        brightnessController.decreaseBrightness(steps: 1)
        currentBrightnessLevel -= 1
        
        // Update phase for visualization
        currentPhase = Double(currentBrightnessLevel) / Double(intensity)
    }
}
