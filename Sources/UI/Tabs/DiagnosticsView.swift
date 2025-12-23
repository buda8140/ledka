import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject var btManager: BluetoothManager
    @State private var rawHex = ""
    @State private var logs: [String] = []
   
    var body: some View {
        ZStack {
            Theme.background()
           
            VStack(spacing: 20) {
                HStack {
                    Text(NSLocalizedString("DIAGNOSTICS", comment: ""))
                        .premiumTitle()
                    Spacer()
                    Button(NSLocalizedString("RESET", comment: "")) {
                        logs.removeAll()
                    }
                    .font(.caption.bold())
                    .foregroundColor(Theme.secondaryNeon)
                }
                .padding(.horizontal, 25)
                .padding(.top, 40)
               
                // Real-time Logs
                GlassCard {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(btManager.logs.indices, id: \.self) { i in
                                    Text(btManager.logs[i])
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(btManager.logs[i].contains("TX") ? Theme.primaryNeon : btManager.logs[i].contains("ERROR") ? Theme.dangerNeon : .white)
                                        .id(i)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 300)
                        .onChange(of: btManager.logs.count) { _ in
                            withAnimation { proxy.scrollTo(btManager.logs.count - 1, anchor: .bottom) }
                        }
                    }
                }
                .padding(.horizontal)
               
                // Raw Sender
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RAW HEX SENDER")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.4))
                       
                        HStack {
                            TextField("7E 00 04 01 ...", text: $rawHex)
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                           
                            Button(action: sendRaw) {
                                Image(systemName: "paperplane.fill")
                                    .font(.title3)
                                    .foregroundColor(.black)
                                    .padding(12)
                                    .background(Theme.primaryNeon)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
               
                // Device Info
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Peripheral:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(btManager.connectedPeripheral?.name ?? "Not connected")
                                .foregroundColor(.white)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        HStack {
                            Text("Identifier:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(btManager.connectedPeripheral?.identifier.uuidString.prefix(12) ?? "N/A")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack {
                            Text("Status:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(btManager.connectionStatus)
                                .foregroundColor(btManager.isConnected ? .green : .red)
                                .bold()
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
               
                Spacer()
            }
        }
        .onAppear {
            btManager.log("Diagnostics View opened")
        }
    }
   
    private func sendRaw() {
        guard !rawHex.isEmpty else { return }
        btManager.sendRawHex(rawHex)
        rawHex = ""
        Haptics.play(.medium)
    }
}

extension String {
    func hexData() -> Data? {
        var data = Data(capacity: count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(location: 0, length: count)) { match, _, _ in
            if let match = match {
                let byteString = (self as NSString).substring(with: match.range)
                if let num = UInt8(byteString, radix: 16) {
                    data.append(num)
                }
            }
        }
        return data.count > 0 ? data : nil
    }
}
