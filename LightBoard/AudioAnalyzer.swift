//
//  AudioAnalyzer.swift
//  LightBoard
//
//  Created by Tejas Kathuria on 25/11/25.
//

import Foundation
import AVFoundation
import Combine
import Accelerate

class AudioAnalyzer: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var beatDetected: Bool = false
    @Published var sensitivity: Double = 0.5 // 0.0 to 1.0
    @Published var currentVolume: Float = 0.0
    
    // Beat detection callback
    var onBeatDetected: (() -> Void)?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let bufferSize: AVAudioFrameCount = 1024
    
    // Beat detection parameters
    private var energyHistory: [Float] = []
    private let historySize = 43 // ~1 second at 44.1kHz with 1024 buffer
    private var lastBeatTime: Date = Date.distantPast
    private let minimumBeatInterval: TimeInterval = 0.15 // Minimum 150ms between beats (400 BPM max)
    
    // FFT setup
    private var fftSetup: FFTSetup?
    private let log2n = vDSP_Length(10) // 2^10 = 1024
    
    init() {
        setupFFT()
    }
    
    deinit {
        stop()
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupFFT() {
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    /// Start audio analysis
    func start() {
        guard !isAnalyzing else { return }
        
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startAudioEngine()
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    /// Stop audio analysis
    func stop() {
        guard isAnalyzing else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        
        DispatchQueue.main.async {
            self.isAnalyzing = false
            self.beatDetected = false
            self.currentVolume = 0.0
        }
        
        energyHistory.removeAll()
    }
    
    /// Toggle audio analysis
    func toggle() {
        if isAnalyzing {
            stop()
        } else {
            start()
        }
    }
    
    private func startAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        
        guard let inputNode = inputNode else { return }
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on the input node
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isAnalyzing = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Calculate energy in the low frequency range (bass)
        let energy = calculateLowFrequencyEnergy(samples: samples)
        
        // Update volume for visualization
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        DispatchQueue.main.async {
            self.currentVolume = rms
        }
        
        // Detect beat
        detectBeat(energy: energy)
    }
    
    private func calculateLowFrequencyEnergy(samples: [Float]) -> Float {
        guard samples.count >= Int(bufferSize) else { return 0 }
        
        // Use only the first 1024 samples for FFT
        var input = Array(samples.prefix(Int(bufferSize)))
        
        // Prepare for FFT
        var realParts = [Float](repeating: 0, count: Int(bufferSize / 2))
        var imagParts = [Float](repeating: 0, count: Int(bufferSize / 2))
        
        // Convert to split complex format
        var splitComplex = DSPSplitComplex(realp: &realParts, imagp: &imagParts)
        
        input.withUnsafeMutableBufferPointer { inputPtr in
            inputPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: Int(bufferSize / 2)) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
            }
        }
        
        // Perform FFT
        guard let fftSetup = fftSetup else { return 0 }
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        // Calculate magnitude for low frequencies (bass range: ~20-250 Hz)
        // At 44.1kHz sample rate with 1024 samples, each bin is ~43 Hz
        // So bins 0-6 cover roughly 0-258 Hz
        let lowFreqBins = 6
        var magnitudes = [Float](repeating: 0, count: lowFreqBins)
        
        for i in 0..<lowFreqBins {
            let real = realParts[i]
            let imag = imagParts[i]
            magnitudes[i] = sqrt(real * real + imag * imag)
        }
        
        // Return average magnitude of low frequency bins
        return magnitudes.reduce(0, +) / Float(lowFreqBins)
    }
    
    private func detectBeat(energy: Float) {
        // Add to history
        energyHistory.append(energy)
        if energyHistory.count > historySize {
            energyHistory.removeFirst()
        }
        
        // Need enough history to detect beats
        guard energyHistory.count >= historySize else { return }
        
        // Calculate average energy
        let averageEnergy = energyHistory.reduce(0, +) / Float(energyHistory.count)
        
        // Calculate variance
        let variance = energyHistory.map { pow($0 - averageEnergy, 2) }.reduce(0, +) / Float(energyHistory.count)
        let threshold = averageEnergy + Float(sensitivity) * sqrt(variance) * 2.0
        
        // Check if current energy exceeds threshold
        let now = Date()
        let timeSinceLastBeat = now.timeIntervalSince(lastBeatTime)
        
        if energy > threshold && timeSinceLastBeat > minimumBeatInterval {
            lastBeatTime = now
            
            DispatchQueue.main.async {
                self.beatDetected = true
                self.onBeatDetected?()
                
                // Reset beat indicator after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.beatDetected = false
                }
            }
        }
    }
    
    /// Update sensitivity (0.0 to 1.0)
    func setSensitivity(_ newSensitivity: Double) {
        sensitivity = max(0.0, min(1.0, newSensitivity))
    }
    
    /// Check if microphone permission is granted
    static func checkMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    /// Request microphone permission
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
    }
}
