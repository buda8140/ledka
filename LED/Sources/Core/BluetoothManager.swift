import Foundation
import CoreBluetooth
import SwiftUI

/// Bluetooth Manager for controlling ELK-BLEDDM LED strips with robust connectivity.
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Published State
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isScanning = false
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var writeCharacteristic: CBCharacteristic?
    
    // Robust UUID Discovery
    private let targetServiceUUIDs = [
        CBUUID(string: "FFF0"), // Primary
        CBUUID(string: "FFE0"), // Fallback 1
        CBUUID(string: "FF12")  // Fallback 2 (observed in variants)
    ]
    
    private let targetCharacteristicUUIDs = [
        CBUUID(string: "FFF3"), // Primary Write
        CBUUID(string: "FFF4"), // Fallback Write
        CBUUID(string: "FFE1"), // Fallback Write (Alt Protocol)
        CBUUID(string: "FF02")  // Observed in BLE-LED variants
    ]
    
    // Persistence & Reconnection
    private let lastDeviceKey = "last_connected_device_uuid"
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 5
    private var reconnectWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    // MARK: - Public Methods
    
    func togglePower() {
        setPower(on: !isConnected) 
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        discoveredDevices.removeAll()
        // Scan for all if services not known, or specific ones for efficiency
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        connectionStatus = "Scanning..."
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectionStatus = "Connecting to \(peripheral.name ?? "Device")..."
        connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnConnectionKey: true
        ])
        
        // Save UUID for auto-connect
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastDeviceKey)
    }
    
    func disconnect() {
        reconnectWorkItem?.cancel()
        reconnectAttempt = 0
        UserDefaults.standard.removeObject(forKey: lastDeviceKey)
        
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth Ready"
            autoConnectLastDevice()
        case .poweredOff:
            connectionStatus = "Bluetooth Off"
            isConnected = false
        case .unauthorized:
            connectionStatus = "Permission Denied"
        default:
            connectionStatus = "Bluetooth Error"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        let isTarget = name.localizedCaseInsensitiveContains("ELK-") || 
                       name.localizedCaseInsensitiveContains("BLE-") || 
                       name.localizedCaseInsensitiveContains("LED")
        
        if isTarget {
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredDevices.append(peripheral)
                objectWillChange.send()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatus = "Connected"
        reconnectAttempt = 0
        peripheral.delegate = self
        
        // Discover all services to be safe, or filter by known ones
        peripheral.discoverServices(targetServiceUUIDs)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Failed to Connect: \(error?.localizedDescription ?? "Unknown Error")"
        handleReconnection()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        writeCharacteristic = nil
        
        if UserDefaults.standard.string(forKey: lastDeviceKey) != nil {
            connectionStatus = "Lost connection. Retrying..."
            handleReconnection()
        } else {
            connectionStatus = "Disconnected"
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(targetCharacteristicUUIDs, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // Priority matching
            if targetCharacteristicUUIDs.contains(characteristic.uuid) {
                if characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write) {
                    writeCharacteristic = characteristic
                    print("Identified Write Characteristic: \(characteristic.uuid)")
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func autoConnectLastDevice() {
        guard let uuidString = UserDefaults.standard.string(forKey: lastDeviceKey),
              let uuid = UUID(uuidString: uuidString) else {
            startScanning()
            return
        }
        
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if let lastPeripheral = peripherals.first {
            connect(to: lastPeripheral)
        } else {
            startScanning()
        }
    }
    
    private func handleReconnection() {
        guard reconnectAttempt < maxReconnectAttempts else {
            connectionStatus = "Connection lost. Please reconnect manually."
            return
        }
        
        reconnectAttempt += 1
        let delay = pow(2.0, Double(reconnectAttempt)) // Exponential backoff
        
        reconnectWorkItem?.cancel()
        reconnectWorkItem = DispatchWorkItem { [weak self] in
            self?.autoConnectLastDevice()
        }
        
        if let workItem = reconnectWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    // MARK: - LED Commands (via LEDProtocol)
    
    private func sendPacket(_ packet: [UInt8]) {
        guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else { return }
        let data = Data(packet)
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        peripheral.writeValue(data, for: characteristic, type: type)
        print("Sent Packet: \(packet.map { String(format: "%02X", $0) }.joined(separator: " "))")
    }
    
    func setPower(on: Bool) {
        sendPacket(LEDProtocol.buildPacket(for: .power(isOn: on)))
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        sendPacket(LEDProtocol.buildPacket(for: .color(r: r, g: g, b: b)))
    }
    
    func setBrightness(_ brightness: Int) {
        sendPacket(LEDProtocol.buildPacket(for: .brightness(value: brightness)))
    }
    
    func setEffectSpeed(_ speed: Int) {
        sendPacket(LEDProtocol.buildPacket(for: .speed(value: speed)))
    }
    
    func setMode(_ modeByte: UInt8) {
        if let mode = LEDProtocol.LEDMode(rawValue: modeByte) {
            sendPacket(LEDProtocol.buildPacket(for: .mode(mode)))
        }
    }
}

