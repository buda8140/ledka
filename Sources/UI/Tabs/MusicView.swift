import SwiftUI
import MediaPlayer

struct MusicView: View {
    @StateObject var audioManager = AudioManager()
    @EnvironmentObject var btManager: BluetoothManager
    @State private var showingPicker = false
    @State private var songTitle = "Select Track"
    @State private var artistName = "Media Library"
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Theme.background()
            
            VStack(spacing: 0) {
                Text("Music")
                    .premiumTitle()
                    .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Enhanced Vinyl Visualizer
                        ZStack {
                            // FFT Bar Visualizer (Circular Arrangement)
                            ForEach(0..<8) { i in
                                Capsule()
                                    .fill(Theme.primaryNeon.opacity(0.4))
                                    .frame(width: 4, height: 40 + CGFloat(audioManager.amplitudes[i] * 40))
                                    .offset(y: -130)
                                    .rotationEffect(.degrees(Double(i) * 45))
                            }
                            
                            // Central Disk
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 200, height: 200)
                                    .neonGlow(color: Theme.accentColor, radius: 20)
                                
                                // Art or Placeholder
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    .frame(width: 190, height: 190)
                                
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundColor(Theme.secondaryNeon)
                                    .rotationEffect(.degrees(rotation))
                                    .scaleEffect(1 + CGFloat(audioManager.currentBeat * 0.2))
                            }
                        }
                        .padding(.vertical, 30)
                        
                        // Track Info Card
                        VStack(spacing: 8) {
                            Text(songTitle)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text(artistName)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal)
                        
                        // FFT Bar Visualizer (Lower)
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(0..<8) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(colors: [Theme.primaryNeon, Theme.secondaryNeon], startPoint: .bottom, endPoint: .top))
                                    .frame(width: 20, height: 10 + CGFloat(audioManager.amplitudes[i] * 60))
                            }
                        }
                        .frame(height: 80)
                        
                        // Controls
                        GlassCard(glow: audioManager.isPlaying) {
                            HStack(spacing: 50) {
                                Button(action: { Haptics.play(.soft) }) {
                                    Image(systemName: "backward.fill").font(.title3)
                                }
                                
                                Button(action: {
                                    Haptics.play(.medium)
                                    if audioManager.isPlaying {
                                        audioManager.pause()
                                    } else {
                                        audioManager.resume()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.primaryNeon)
                                            .frame(width: 64, height: 64)
                                            .neonGlow()
                                        
                                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                Button(action: { Haptics.play(.soft) }) {
                                    Image(systemName: "forward.fill").font(.title3)
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: { 
                            Haptics.play(.light)
                            showingPicker = true 
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                Text("Open Media Library")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.secondaryNeon.opacity(0.2))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.secondaryNeon.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            audioManager.onBeat = { r, g, b in
                if btManager.isConnected && audioManager.isPlaying {
                    btManager.setColor(r: Int(r), g: Int(g), b: Int(b))
                    withAnimation(.linear(duration: 0.1)) {
                        rotation += 2
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            MediaPicker(songTitle: $songTitle, artistName: $artistName) { url in
                audioManager.playFile(url: url)
            }
        }
    }
}


struct MediaPicker: UIViewControllerRepresentable {
    @Binding var songTitle: String
    @Binding var artistName: String
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = context.coordinator
        picker.allowsPickingMultipleItems = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MediaPicker
        init(_ parent: MediaPicker) { self.parent = parent }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            if let item = mediaItemCollection.items.first, let url = item.assetURL {
                parent.songTitle = item.title ?? "Трек"
                parent.artistName = item.artist ?? "Исполнитель"
                parent.onPick(url)
            }
            mediaPicker.dismiss(animated: true)
        }
        
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}
