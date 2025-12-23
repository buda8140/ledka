import SwiftUI

struct MicrophoneView: View {
    @StateObject var micManager = MicrophoneManager()
    @EnvironmentObject var btManager: BluetoothManager
    @State private var isEnabled = false
    @State private var selectedMode: MicMode = .ambient
    
    enum MicMode: String, CaseIterable, Identifiable {
        case ambient = "Ambient"
        case strobe = "Strobe"
        case jump = "Beat Jump"
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .ambient: return "wave.3.forward"
            case .strobe: return "bolt.horizontal.fill"
            case .jump: return "arrow.up.and.down"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.background()
            
            VStack(spacing: 0) {
                Text("Microphone")
                    .premiumTitle()
                    .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 35) {
                        // Dynamic Level Indicator
                        ZStack {
                            Circle()
                                .stroke(Theme.primaryNeon.opacity(0.1), lineWidth: 15)
                                .frame(width: 200, height: 200)
                            
                            // Concentric Pulse
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(Theme.primaryNeon.opacity(0.3), lineWidth: 2)
                                    .frame(width: 200 + CGFloat(micManager.level * Double(i + 1) * 40))
                                    .opacity(isEnabled ? 1.0 - micManager.level : 0)
                            }
                            
                            // Core
                            ZStack {
                                Circle()
                                    .fill(isEnabled ? Theme.primaryNeon.opacity(0.2) : Color.white.opacity(0.05))
                                    .frame(width: 150)
                                    .neonGlow(color: isEnabled ? Theme.primaryNeon : .clear)
                                
                                Image(systemName: isEnabled ? "mic.fill" : "mic.slash.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(isEnabled ? Theme.primaryNeon : .white.opacity(0.2))
                            }
                        }
                        .padding(.vertical, 30)
                        
                        // Main Controls
                        GlassCard {
                            VStack(spacing: 30) {
                                Toggle(isOn: $isEnabled) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Sound Reactive Mode")
                                            .font(.headline)
                                        Text("LEDs sync to surrounding audio")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .tint(Theme.primaryNeon)
                                .onChange(of: isEnabled) { _, newValue in
                                    Haptics.notify(newValue ? .success : .warning)
                                    if newValue { micManager.startMonitoring() }
                                    else { micManager.stopMonitoring() }
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                // Sensitivity Control
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "slider.horizontal.3")
                                        Text("Sensitivity")
                                            .font(.caption.bold())
                                        Spacer()
                                        Text("\(Int(micManager.sensitivity * 100))%")
                                            .font(.caption2.monospaced())
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                    
                                    Slider(value: $micManager.sensitivity, in: 0.01...1.0)
                                        .accentColor(Theme.primaryNeon)
                                }
                            }
                        }
                        .padding(.horizontal, 25)
                        
                        // Mode Selection
                        VStack(alignment: .leading, spacing: 15) {
                            Text("REACTION STYLE")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 30)
                            
                            HStack(spacing: 15) {
                                ForEach(MicMode.allCases) { mode in
                                    Button(action: {
                                        selectedMode = mode
                                        Haptics.play(.medium)
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: mode.icon)
                                                .font(.headline)
                                            Text(mode.rawValue)
                                                .font(.caption2.bold())
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(selectedMode == mode ? Theme.primaryNeon.opacity(0.2) : Color.white.opacity(0.05))
                                        .foregroundColor(selectedMode == mode ? Theme.primaryNeon : .white.opacity(0.5))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedMode == mode ? Theme.primaryNeon.opacity(0.5) : Color.clear, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 25)
                        }
                        
                        Text("Place your device near the sound source for the best response.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.2))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            micManager.onSoundDetected = { level, r, g, b in
                guard isEnabled && btManager.isConnected else { return }
                
                switch selectedMode {
                case .ambient:
                    // Smooth flow based on volume
                    btManager.setBrightness(Int(level * 100))
                    // Subtle color shift
                    if level > 0.5 {
                        btManager.setColor(r: Int(r), g: Int(g), b: Int(b))
                    }
                    
                case .strobe:
                    // Flash on peaks
                    if level > 0.8 {
                        btManager.setPower(on: true)
                        btManager.setBrightness(100)
                        btManager.setColor(r: 255, g: 255, b: 255) // White flash
                    } else if level < 0.3 {
                        btManager.setBrightness(0)
                    }
                    
                case .jump:
                    // Change color on every "beat" (peak)
                    if level > 0.7 {
                        let colors: [[Int]] = [[255,0,255], [0,255,255], [255,255,0], [0,255,0]]
                        if let color = colors.randomElement() {
                            btManager.setColor(r: color[0], g: color[1], b: color[2])
                        }
                        btManager.setBrightness(100)
                    }
                }
            }
        }
    }
}

