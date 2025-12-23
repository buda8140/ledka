import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @EnvironmentObject var btManager: BluetoothManager
    @State private var showingQRScanner = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background()
                
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Settings")
                                .premiumTitle()
                            Text("Manage devices and preferences")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        
                        Button(action: { 
                            showingQRScanner = true 
                            Haptics.play(.medium)
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title3)
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Theme.primaryNeon)
                                .clipShape(Circle())
                                .neonGlow()
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 60)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // Current Status
                            GlassCard(glow: btManager.isConnected) {
                                HStack(spacing: 20) {
                                    Circle()
                                        .fill(btManager.isConnected ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                        .neonGlow(color: btManager.isConnected ? .green : .red)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("SYSTEM STATUS")
                                            .font(.caption2.bold())
                                            .foregroundColor(.white.opacity(0.4))
                                        Text(btManager.connectionStatus)
                                            .font(.headline)
                                            .foregroundColor(btManager.isConnected ? .green : .white)
                                    }
                                    Spacer()
                                    
                                    if btManager.isConnected {
                                        Button("Disconnect") {
                                            btManager.disconnect()
                                            Haptics.play(.heavy)
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.dangerNeon)
                                    }
                                }
                            }
                            
                            // Discover Devices
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("DISCOVERED DEVICES")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white.opacity(0.4))
                                    Spacer()
                                    if btManager.isScanning {
                                        ProgressView().tint(Theme.primaryNeon)
                                    } else {
                                        Button(action: { btManager.startScanning() }) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.caption.bold())
                                                .foregroundColor(Theme.primaryNeon)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                
                                if btManager.discoveredDevices.isEmpty {
                                    GlassCard {
                                        Text("No devices found nearby.")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.3))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(btManager.discoveredDevices, id: \.identifier) { device in
                                            Button(action: { 
                                                btManager.connect(to: device) 
                                                Haptics.play(.medium)
                                            }) {
                                                HStack(spacing: 15) {
                                                    Image(systemName: "lightstrip.fill")
                                                        .foregroundColor(Theme.primaryNeon)
                                                        .frame(width: 40, height: 40)
                                                        .background(Circle().fill(Color.white.opacity(0.05)))
                                                    
                                                    VStack(alignment: .leading) {
                                                        Text(device.name ?? "LED Strip")
                                                            .font(.headline)
                                                        Text(device.identifier.uuidString.prefix(12))
                                                            .font(.caption2.monospaced())
                                                            .foregroundColor(.white.opacity(0.4))
                                                    }
                                                    Spacer()
                                                    if btManager.connectedPeripheral?.identifier == device.identifier {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(Theme.primaryNeon)
                                                    }
                                                }
                                                .padding()
                                                .background(Color.white.opacity(0.03))
                                                .cornerRadius(20)
                                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(btManager.connectedPeripheral?.identifier == device.identifier ? Theme.primaryNeon.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Debug Tools
                            VStack(alignment: .leading, spacing: 15) {
                                Text("DIAGNOSTICS")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.leading, 10)
                                
                                NavigationLink(destination: DiagnosticsView()) {
                                    GlassCard {
                                        HStack {
                                            Image(systemName: "terminal.fill")
                                                .foregroundColor(Theme.secondaryNeon)
                                            Text("BLE Protocol Debugger")
                                                .font(.subheadline.bold())
                                            Spacer()
                                            Image(systemName: "chevron.right")
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
            .foregroundColor(.white)
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView()
        }
        .onAppear {
            if !btManager.isConnected {
                btManager.startScanning()
            }
        }
    }
}

