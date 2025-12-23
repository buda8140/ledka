import Foundation
import AVFoundation
import Accelerate

/// Enhanced Audio Manager with real-time FFT using vDSP.
class AudioManager: ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var playerNode: AVAudioPlayerNode!
    private var audioFile: AVAudioFile?
    
    @Published var isPlaying = false
    @Published var currentBeat: Float = 0.0
    @Published var amplitudes: [Float] = Array(repeating: 0, count: 8) // 8 bands
    
    var onBeat: ((Float, Float, Float) -> Void)? // R, G, B energies
    
    // FFT Properties
    private let fftSize = 1024
    private lazy var fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD)
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = audioEngine.mainMixerNode
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mixerNode, format: mixerNode.outputFormat(forBus: 0))
        
        // FFT Analysis Tap
        mixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: mixerNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            self?.processFFT(buffer: buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine Start Failure: \(error)")
        }
    }
    
    func playFile(url: URL) {
        do {
            audioFile = try AVAudioFile(forReading: url)
            guard let audioFile = audioFile else { return }
            
            playerNode.stop()
            playerNode.scheduleFile(audioFile, at: nil) {
                DispatchQueue.main.async { self.isPlaying = false }
            }
            playerNode.play()
            isPlaying = true
        } catch {
            print("Playback Error: \(error)")
        }
    }
    
    func pause() {
        playerNode.pause()
        isPlaying = false
    }
    
    func resume() {
        playerNode.play()
        isPlaying = true
    }
    
    private func processFFT(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let n = vDSP_Length(fftSize)
        
        // 1. Apply Hann Window to reduce spectral leakage
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, n, Int32(vDSP_HANN_NORM))
        var windowedSignals = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(channelData, 1, window, 1, &windowedSignals, 1, n)
        
        // 2. Perform FFT (Real to Complex)
        var realParts = windowedSignals
        var imagParts = [Float](repeating: 0, count: fftSize)
        var splitComplex = DSPSplitComplex(realp: &realParts, imagp: &imagParts)
        
        vDSP_DFT_Execute(fftSetup!, realParts, imagParts, &realParts, &imagParts)
        
        // 3. Calculate Magnitudes
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        // 4. Normalize and Group into Bands
        // Mapping bins to Bass, Mid, High
        let bassRange = 0..<10
        let midRange = 10..<100
        let highRange = 100..<512
        
        let bass = magnitudes[bassRange].reduce(0, +) / Float(bassRange.count)
        let mid = magnitudes[midRange].reduce(0, +) / Float(midRange.count)
        let high = magnitudes[highRange].reduce(0, +) / Float(highRange.count)
        
        // Visualizer bands (8 bars)
        var newAmplitudes: [Float] = []
        let binSize = (fftSize / 2) / 8
        for i in 0..<8 {
            let start = i * binSize
            let end = (i + 1) * binSize
            let avg = magnitudes[start..<end].reduce(0, +) / Float(binSize)
            newAmplitudes.append(sqrt(avg) * 5) // Boost for visibility
        }
        
        DispatchQueue.main.async {
            self.amplitudes = newAmplitudes
            self.currentBeat = bass * 10
            self.onBeat?(bass * 500, mid * 400, high * 300)
        }
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
}

