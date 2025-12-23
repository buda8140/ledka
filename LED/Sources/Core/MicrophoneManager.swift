import Foundation
import AVFoundation
import Accelerate

/// Enhanced Microphone Manager using AVAudioEngine for real-time spectrum analysis.
class MicrophoneManager: ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    @Published var level: Double = 0.0
    @Published var sensitivity: Double = 0.5
    @Published var isRunning = false
    
    var onSoundDetected: ((Double, Float, Float, Float) -> Void)? // Level, R, G, B energies
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }
    
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            
            let format = inputNode.inputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
                self?.analyzeAudio(buffer: buffer)
            }
            
            try audioEngine.start()
            DispatchQueue.main.async { self.isRunning = true }
        } catch {
            print("Microphone Start Error: \(error)")
        }
    }
    
    func stopMonitoring() {
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
    }
    
    private func analyzeAudio(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = vDSP_Length(buffer.frameLength)
        
        // Calculate RMS Level
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, frameCount)
        
        let normalizedLevel = Double(rms) / (sensitivity > 0 ? sensitivity : 0.01)
        
        DispatchQueue.main.async {
            self.level = min(1.0, normalizedLevel)
            if self.level > 0.05 {
                self.onSoundDetected?(self.level, rms * 500, rms * 300, rms * 200)
            }
        }
    }
}

