//
//  LightBoardApp.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import SwiftUI

@main
struct LightBoardApp: App {
    @StateObject private var breathingEngine = BreathingEngine()
    @StateObject private var permissionHelper = AccessibilityPermissionHelper()
    
    var body: some Scene {
        
        Window("LightBoard Settings", id: "settings") {
            ContentView(breathingEngine: breathingEngine, permissionHelper: permissionHelper)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
       
        Window("About Developer", id: "about") {
            AboutDevView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        
        MenuBarExtra {
            MenuBarView(breathingEngine: breathingEngine, permissionHelper: permissionHelper)
        } label: {
            if breathingEngine.musicSyncMode {
                Image(systemName: breathingEngine.isRunning ? "music.note" : "music.note")
                    .symbolEffect(.pulse, isActive: breathingEngine.isRunning)
            } else if breathingEngine.keyPressMode {
                Image(systemName: breathingEngine.isRunning ? "hand.tap.fill" : "hand.tap")
                    .symbolEffect(.pulse, isActive: breathingEngine.isRunning)
            } else {
                Image(systemName: breathingEngine.isRunning ? "keyboard.fill" : "keyboard")
                    .symbolEffect(.pulse, isActive: breathingEngine.isRunning)
            }
        }
    }
}


struct MenuBarView: View {
    @ObservedObject var breathingEngine: BreathingEngine
    @ObservedObject var permissionHelper: AccessibilityPermissionHelper
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Circle()
                    .fill(breathingEngine.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(breathingEngine.isRunning ? "Running" : "Stopped")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            
            Button(action: {
                if !permissionHelper.hasPermission {
                    permissionHelper.requestPermission()
                } else {
                    breathingEngine.toggle()
                }
            }) {
                HStack {
                    Image(systemName: breathingEngine.isRunning ? "stop.circle" : "play.circle")
                    Text(breathingEngine.isRunning ? "Stop Breathing" : "Start Breathing")
                }
            }
            .keyboardShortcut(breathingEngine.isRunning ? "s" : "b")
            
            Divider()
            
            
            Toggle(isOn: Binding(
                get: { breathingEngine.keyPressMode },
                set: { _ in breathingEngine.toggleMode() }
            )) {
                HStack {
                    Image(systemName: "hand.tap")
                        .symbolEffect(.pulse, isActive: breathingEngine.keyPressMode && breathingEngine.isRunning)
                    Text("Key Press Mode")
                }
            }
            .toggleStyle(.checkbox)
            
            Divider()
            
           
            Button(action: {
                openWindow(id: "settings")
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings...")
                }
            }
            .keyboardShortcut(",")
            
            Divider()
            
           
            Button(action: {
                openWindow(id: "about")
            }) {
                HStack {
                    Image(systemName: "person.circle")
                    Text("About Dev")
                }
            }
            
            Divider()
            
            
            if !permissionHelper.hasPermission {
                Button(action: {
                    permissionHelper.requestPermission()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Grant Permissions")
                    }
                }
                
                Divider()
            }
            
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit LightBoard")
                }
            }
            .keyboardShortcut("q")
        }
    }
}
