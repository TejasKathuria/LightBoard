//
//  ContentView.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var breathingEngine: BreathingEngine
    @ObservedObject var permissionHelper: AccessibilityPermissionHelper
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            VStack(spacing: 6) {
                Text("LightBoard")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Glowing Effect on Your Keyboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            
            Divider()
            
            // Glowing Visualization
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.yellow.opacity(0.8), .orange.opacity(0.3), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .opacity(breathingEngine.isRunning ? 0.3 + (breathingEngine.getCurrentBreathingLevel() * 0.7) : 0.3)
                    .animation(.linear(duration: 0.1), value: breathingEngine.currentPhase)
                
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                    .opacity(breathingEngine.isRunning ? 0.4 + (breathingEngine.getCurrentBreathingLevel() * 0.6) : 0.4)
                    .shadow(color: .yellow.opacity(breathingEngine.isRunning ? breathingEngine.getCurrentBreathingLevel() : 0), radius: 20)
                    .animation(.linear(duration: 0.1), value: breathingEngine.currentPhase)
            }
            .frame(height: 150)
            
            // Status
            HStack {
                Circle()
                    .fill(breathingEngine.isRunning ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                Text(breathingEngine.isRunning ? "Running" : "Stopped")
                    .font(.headline)
                    .foregroundColor(breathingEngine.isRunning ? .green : .secondary)
            }
            
            // Control Button
            Button(action: {
                if !permissionHelper.hasPermission {
                    permissionHelper.requestPermission()
                } else {
                    breathingEngine.toggle()
                }
            }) {
                HStack {
                    Image(systemName: breathingEngine.isRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(breathingEngine.isRunning ? "Stop Breathing" : "Start Breathing")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(breathingEngine.isRunning ? Color.red.gradient : Color.blue.gradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!permissionHelper.hasPermission && breathingEngine.isRunning)
            
            Divider()
            
            // Mode Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "switch.2")
                        .foregroundColor(.purple)
                    Text("Breathing Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Toggle(isOn: Binding(
                    get: { breathingEngine.keyPressMode },
                    set: { _ in breathingEngine.toggleMode() }
                )) {
                    HStack {
                        Image(systemName: breathingEngine.keyPressMode ? "hand.tap.fill" : "lungs.fill")
                            .foregroundColor(breathingEngine.keyPressMode ? .orange : .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(breathingEngine.keyPressMode ? "Key Press Mode" : "Continuous Breathing")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(breathingEngine.keyPressMode ? "Keys illuminate on press and fade out" : "Smooth rhythmic breathing effect")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Settings
            VStack(alignment: .leading, spacing: 20) {
                // Speed Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.blue)
                        Text("Speed: \(String(format: "%.1f", breathingEngine.speed))s per cycle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Slow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { breathingEngine.speed },
                            set: { breathingEngine.setSpeed($0) }
                        ), in: 1...10, step: 0.5)
                        
                        Text("Fast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Intensity Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "light.max")
                            .foregroundColor(.orange)
                        Text("Intensity: \(breathingEngine.intensity) steps")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Subtle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(breathingEngine.intensity) },
                            set: { breathingEngine.setIntensity(Int($0)) }
                        ), in: 1...10, step: 1)
                        
                        Text("Intense")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Permission Status
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: permissionHelper.hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(permissionHelper.hasPermission ? .green : .orange)
                    
                    Text(permissionHelper.getPermissionMessage())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !permissionHelper.hasPermission {
                    Button(action: {
                        permissionHelper.requestPermission()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Grant Permissions")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .frame(width: 400, height: 600)
        .padding()
        .onAppear {
            permissionHelper.checkPermission()
        }
    }
}

#Preview {
    ContentView(
        breathingEngine: BreathingEngine(),
        permissionHelper: AccessibilityPermissionHelper()
    )
}
