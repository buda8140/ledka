import Foundation
import CoreBluetooth

struct DiscoveredDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let rssi: Int
    let name: String
}

class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var writeCharacteristic: CBCharacteristic?
    
    @Published var isConnected = false
    @Published var isPoweredOn = false
    @Published var connectionStatus = "Disconnected"
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning = false
    @Published var logs: [String] = []
    
    var connectedPeripheral: CBPeripheral?
    
    // UUIDs for BLEDDM / Lotus Lantern
    private let serviceUUIDs = [CBUUID(string: "FFF0"), CBUUID(string: "FFE0")]
    private let writeCharacteristics = [
        CBUUID(string: "FFF3"), 
        CBUUID(string: "FFF4"), 
        CBUUID(string: "FFE1")
    ]
    
    // Reconnection Logic
    private var reconnectAttempt = 0
    private var reconnectTimer: Timer?
    private let maxReconnectAttempts = 10
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        log("System initialized")
    }
    
    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let fullMessage = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.append(fullMessage)
            if self.logs.count > 100 { self.logs.removeFirst() }
            print(fullMessage) // Console backup
        }
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { 
            log("Scan failed: Bluetooth not powered on")
            return 
        }
        
        isScanning = true
        discoveredDevices.removeAll()
        log("Scanning started (ALL peripherals)")
        
        // Remove service filters to see EVERYTHING
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // Scan indefinitely or until stopped manually by UI
        // We removed the auto-stop timer to ensure the user can see their device
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        log("Scanning stopped")
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectionStatus = "Connecting..."
        log("Connecting to: \(peripheral.name ?? "Unknown") (\(peripheral.identifier.uuidString.prefix(8)))")
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            log("User requested disconnect from: \(peripheral.name ?? "Unknown")")
            centralManager.cancelPeripheralConnection(peripheral)
        }
        reconnectTimer?.invalidate()
        reconnectAttempt = 0
    }
    
    func togglePower() {
        let newState = !isPoweredOn
        send(LEDProtocol.power(newState))
        isPoweredOn = newState
        Haptics.play(.medium)
    }
    
    func setPower(on: Bool) {
        send(LEDProtocol.power(on))
        isPoweredOn = on
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        send(LEDProtocol.color(r: r, g: g, b: b))
    }
    
    func setBrightness(_ value: Int) {
        send(LEDProtocol.brightness(value))
    }
    
    func setEffectSpeed(_ value: Int) {
        send(LEDProtocol.speed(value))
    }
    
    func setMode(_ value: UInt8) {
        send(LEDProtocol.mode(value))
    }
    
    func sendRawHex(_ hex: String) {
        let cleaned = hex.replacingOccurrences(of: " ", with: "").uppercased()
        guard let data = cleaned.hexData() else {
            log("TX Error: Invalid HEX")
            return
        }
        send(Array(data))
    }
    
    private func send(_ bytes: [UInt8]) {
        guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else { 
            log("TX Skip: Not connected or no write char")
            return 
        }
        let data = Data(bytes)
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        
        let hexString = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
        log("TX: \(hexString)")
    }
    
    private func handleDisconnection() {
        isConnected = false
        writeCharacteristic = nil
        
        if reconnectAttempt < maxReconnectAttempts {
            reconnectAttempt += 1
            let delay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
            connectionStatus = "Retrying in \(Int(delay))s (#\(reconnectAttempt))"
            log("Connection lost. Retry #\(reconnectAttempt) in \(Int(delay))s")
            
            reconnectTimer?.invalidate()
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self = self, let p = self.connectedPeripheral else { return }
                self.log("Automatic reconnection attempt...")
                self.centralManager.connect(p, options: nil)
            }
        } else {
            connectionStatus = "Disconected"
            log("Max reconnection attempts reached")
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log("Bluetooth state: \(central.state == .poweredOn ? "ON" : "OFF (\(central.state.rawValue))")")
        if central.state == .poweredOn {
            startScanning()
        } else {
            connectionStatus = "Bluetooth Unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        
        // BROAD FILTER: Include BLEDDM, BLEDOM, ELK-, LED, or anything with name
        let lowerName = name.lowercased()
        let matches = lowerName.contains("led") || 
                     lowerName.contains("ble") || 
                     lowerName.contains("elk") || 
                     lowerName.contains("dm") ||
                     lowerName.contains("om")
        
        if matches || name != "Unknown" {
            DispatchQueue.main.async {
                if let index = self.discoveredDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                    self.discoveredDevices[index] = DiscoveredDevice(id: peripheral.identifier, peripheral: peripheral, rssi: rssi.intValue, name: name)
                } else {
                    self.log("Discovered: \(name) (\(rssi)dBm)")
                    self.discoveredDevices.append(DiscoveredDevice(id: peripheral.identifier, peripheral: peripheral, rssi: rssi.intValue, name: name))
                    self.discoveredDevices.sort { $0.rssi > $1.rssi }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatus = "Connected"
        reconnectAttempt = 0
        reconnectTimer?.invalidate()
        log("Connected to \(peripheral.name ?? "Device"). Discovering services...")
        peripheral.discoverServices(nil) // Discover all services for robustness
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Connect failed: \(error?.localizedDescription ?? "Unknown error")")
        handleDisconnection()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("Disconnected: \(error?.localizedDescription ?? "Clean disconnect")")
        handleDisconnection()
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { 
            log("No services found")
            return 
        }
        
        for service in services {
            log("Service found: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            log("  - Char: \(characteristic.uuid) [\(characteristic.properties.contains(.writeWithoutResponse) ? "W" : "")]")
            
            // Matches any of our target write UUIDs
            if writeCharacteristics.contains(characteristic.uuid) {
                if writeCharacteristic == nil {
                    writeCharacteristic = characteristic
                    log("Matched Write Characteristic: \(characteristic.uuid)")
                    // Initial ping
                    setPower(on: true)
                }
            }
        }
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
