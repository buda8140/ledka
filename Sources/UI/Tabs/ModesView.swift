import SwiftUI

struct ModePreset: Identifiable {
    let id = UUID()
    let name: String
    let value: UInt8
    let color: Color
}

struct ModesView: View {
    @EnvironmentObject var btManager: BluetoothManager
    @StateObject var presetService = PresetService()
    
    @State private var selectedColor = Color.cyan
    @State private var speed: Double = 50
    @State private var brightness: Double = 100
    @State private var activeMode: UInt8?
    @State private var showingSavePreset = false
    @State private var newPresetName = ""
    
    // Complete Lotus Lantern / ELK-BLEDDM effect codes
    let presets = [
        ModePreset(name: NSLocalizedString("Smooth Rainbow", comment: ""), value: 0x25, color: .orange),
        ModePreset(name: NSLocalizedString("7 Color Pulse", comment: ""), value: 0x26, color: .purple),
        ModePreset(name: "Red Pulse", value: 0x27, color: .red),
        ModePreset(name: "Green Pulse", value: 0x28, color: .green),
        ModePreset(name: "Blue Pulse", value: 0x29, color: .blue),
        ModePreset(name: "Yellow Pulse", value: 0x2A, color: .yellow),
        ModePreset(name: "Cyan Pulse", value: 0x2B, color: .cyan),
        ModePreset(name: "Purple Pulse", value: 0x2C, color: .indigo),
        ModePreset(name: "White Pulse", value: 0x2D, color: .white),
        ModePreset(name: "Red-Green Flow", value: 0x2E, color: .yellow),
        ModePreset(name: "Red-Blue Flow", value: 0x2F, color: .pink),
        ModePreset(name: "Green-Blue Flow", value: 0x30, color: .teal),
        ModePreset(name: "7 Color Strobe", value: 0x31, color: .white),
        ModePreset(name: "Red Strobe", value: 0x32, color: .red),
        ModePreset(name: "Green Strobe", value: 0x33, color: .green),
        ModePreset(name: "Blue Strobe", value: 0x34, color: .blue),
        ModePreset(name: "Yellow Strobe", value: 0x35, color: .yellow),
        ModePreset(name: "Cyan Strobe", value: 0x36, color: .cyan),
        ModePreset(name: "Purple Strobe", value: 0x37, color: .indigo),
        ModePreset(name: "White Strobe", value: 0x38, color: .white),
        ModePreset(name: "Fire", value: 0x3C, color: .orange)
    ]
    
    var body: some View {
        ZStack {
            Theme.background()
            
            VStack(spacing: 0) {
                HStack {
                    Text(NSLocalizedString("MODES", comment: ""))
                        .premiumTitle()
                    Spacer()
                    PowerButton()
                }
                .padding(.horizontal, 25)
                .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Color & Controls
                        GlassCard {
                            VStack(spacing: 25) {
                                HStack {
                                    ColorPickerView(selectedColor: $selectedColor) {
                                        activeMode = nil
                                        updateColor()
                                    }
                                    
                                    Button(action: { showingSavePreset = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Theme.primaryNeon)
                                    }
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                VStack(spacing: 20) {
                                    ControlSlider(title: NSLocalizedString("BRIGHTNESS", comment: ""), value: $brightness, icon: "sun.max.fill") { val in
                                        btManager.setBrightness(Int(val))
                                    }
                                    
                                    ControlSlider(title: NSLocalizedString("SPEED", comment: ""), value: $speed, icon: "bolt.fill") { val in
                                        btManager.setEffectSpeed(Int(val))
                                    }
                                }
                            }
                        }
                        
                        // Favorites
                        if !presetService.favorites.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(NSLocalizedString("FAVORITES", comment: ""))
                                    .font(.caption2.bold())
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.leading, 5)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(presetService.favorites) { fav in
                                            FavoriteButton(preset: fav) {
                                                applyPreset(fav)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Effects Grid
                        VStack(alignment: .leading, spacing: 15) {
                            Text(NSLocalizedString("DYNAMIC_EFFECTS", comment: ""))
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 5)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(presets) { preset in
                                    EffectButton(preset: preset, isActive: activeMode == preset.value) {
                                        activeMode = preset.value
                                        btManager.setMode(preset.value)
                                        Haptics.play(.medium)
                                    }
                                }
                            }
                        }
                    }
                    .padding(25)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert(NSLocalizedString("SAVE_PRESET", comment: ""), isPresented: $showingSavePreset) {
            TextField(NSLocalizedString("NAME", comment: ""), text: $newPresetName)
            Button(NSLocalizedString("SAVE", comment: "")) {
                saveCurrentAsPreset()
            }
            Button(NSLocalizedString("CANCEL", comment: ""), role: .cancel) {}
        }
    }
    
    private func updateColor() {
        let uiColor = UIColor(selectedColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        btManager.setColor(r: Int(r * 255), g: Int(g * 255), b: Int(b * 255))
    }
    
    private func saveCurrentAsPreset() {
        let uiColor = UIColor(selectedColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        presetService.save(
            name: newPresetName,
            r: Int(r * 255),
            g: Int(g * 255),
            b: Int(b * 255),
            brightness: Int(brightness),
            mode: activeMode
        )
        newPresetName = ""
        Haptics.notify(.success)
    }
    
    private func applyPreset(_ preset: Preset) {
        selectedColor = Color(red: Double(preset.r)/255, green: Double(preset.g)/255, blue: Double(preset.b)/255)
        brightness = Double(preset.brightness)
        activeMode = preset.mode
        
        if let mode = preset.mode {
            btManager.setMode(mode)
        } else {
            btManager.setColor(r: preset.r, g: preset.g, b: preset.b)
        }
        btManager.setBrightness(preset.brightness)
        Haptics.play(.heavy)
    }
}

struct FavoriteButton: View {
    let preset: Preset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(red: Double(preset.r)/255, green: Double(preset.g)/255, blue: Double(preset.b)/255))
                    .frame(width: 44, height: 44)
                    .neonGlow(color: Color(red: Double(preset.r)/255, green: Double(preset.g)/255, blue: Double(preset.b)/255), radius: 5)
                
                Text(preset.name)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
    }
}


// MARK: - Subviews

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    var onChange: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Static Color")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Tap to refine")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .scaleEffect(1.5)
                .onChange(of: selectedColor) { _, _ in
                    onChange()
                }
        }
    }
}

struct PowerButton: View {
    @EnvironmentObject var btManager: BluetoothManager
    
    var body: some View {
        Button(action: {
            btManager.togglePower()
            Haptics.play(.light)
        }) {
            Image(systemName: "power")
                .font(.title2.bold())
                .foregroundColor(btManager.isConnected ? Theme.primaryNeon : .white.opacity(0.3))
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .neonGlow(color: btManager.isConnected ? Theme.primaryNeon : .clear)
        }
    }
}

struct ControlSlider: View {
    let title: String
    @Binding var value: Double
    let icon: String
    var onChange: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(Int(value))%")
                    .font(.caption2.monospaced())
            }
            .foregroundColor(.white.opacity(0.6))
            
            Slider(value: $value, in: 0...100, step: 1)
                .accentColor(Theme.primaryNeon)
                .onChange(of: value) { _, newValue in
                    onChange(newValue)
                }
        }
    }
}

struct EffectButton: View {
    let preset: ModePreset
    let isActive: Bool
    let action: () -> Void
    
    @State private var animate = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Animated Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(preset.color.opacity(0.1))
                    
                    if isActive {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animate ? 4 : 1)
                            .opacity(animate ? 0 : 0.6)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                    animate = true
                                }
                            }
                    }
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(preset.color.opacity(0.8))
                }
                .frame(height: 60)
                
                Text(preset.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.6))
            }
            .padding(12)
            .background(isActive ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isActive ? preset.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
            )
        }
    }
}

