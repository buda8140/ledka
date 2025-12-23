import Foundation

/// Protocol definition for ELK-BLEDDM / ELK-BLEDOM / duoCo Strip controllers.
/// Based on byte-by-byte reverse engineering.
///
/// General Packet Structure:
/// [0x7E, length, type, data..., 0xEF]
/// Note: Some versions use a fixed 9-byte packet.
/// All commands are sent as Write Without Response.
///
/// Service UUID: 0000fff0-0000-1000-8000-00805f9b34fb
/// Characteristic UUID: 0000fff3-0000-1000-8000-00805f9b34fb
enum LEDProtocol {
    
    static let header: UInt8 = 0x7E
    static let footer: UInt8 = 0xEF
    
    // Commands Table
    // =========================================================================
    // Function     | Byte 1 | Byte 2 | Byte 3 | Byte 4 | Byte 5 | Byte 6 | Byte 7 | Byte 8 | Byte 9
    // -------------------------------------------------------------------------
    // Power ON     | 0x7E   | 0x04   | 0x04   | 0x01   | 0x00   | 0x00   | 0xFF   | 0x00   | 0xEF
    // Power OFF    | 0x7E   | 0x04   | 0x04   | 0x00   | 0x00   | 0x00   | 0xFF   | 0x00   | 0xEF
    // Set Bright   | 0x7E   | 0x04   | 0x01   | VALUE  | 0x00   | 0x00   | 0x00   | 0x00   | 0xEF (VALUE: 0-255)
    // Set Speed    | 0x7E   | 0x04   | 0x02   | VALUE  | 0x00   | 0x00   | 0x00   | 0x00   | 0xEF (VALUE: 1-100)
    // Static Color | 0x7E   | 0x07   | 0x05   | 0x03   | RED    | GREEN  | BLUE   | 0x00   | 0xEF
    // Set Mode     | 0x7E   | 0x05   | 0x03   | MODE   | 0x00   | 0x00   | 0x00   | 0x00   | 0xEF
    // =========================================================================
    
    enum CommandType {
        case power(isOn: Bool)
        case brightness(value: Int) // 0-100
        case speed(value: Int) // 0-100
        case color(r: Int, g: Int, b: Int)
        case mode(LEDMode)
    }
    
    enum LEDMode: UInt8, CaseIterable {
        case rainbowScale = 0x25
        case rainbowStrobe = 0x26
        case redStrobe = 0x27
        case greenStrobe = 0x28
        case blueStrobe = 0x29
        case yellowStrobe = 0x2A
        case cyanStrobe = 0x2B
        case purpleStrobe = 0x2C
        case whiteStrobe = 0x2D
        case redGreenTransition = 0x2E
        case redBlueTransition = 0x2F
        case greenBlueTransition = 0x30
        case rainbowSmooth = 0x31
        case redPulse = 0x32
        case greenPulse = 0x33
        case bluePulse = 0x34
        case yellowPulse = 0x35
        case cyanPulse = 0x36
        case purplePulse = 0x37
        case whitePulse = 0x38
        case fire = 0x3C
    }
    
    /// Builds a packet based on command type, handling protocol variations.
    static func buildPacket(for command: CommandType) -> [UInt8] {
        switch command {
        case .power(let isOn):
            // Default Power variant: [0x7E, 0x04, 0x04, (1=ON/0=OFF), 0x00, 0x00, 0xFF, 0x00, 0xEF]
            return [header, 0x04, 0x04, isOn ? 0x01 : 0x00, 0x00, 0x00, 0xFF, 0x00, footer]
            
        case .brightness(let value):
            let intensity = UInt8(clamping: Int(Double(value) * 2.55))
            return [header, 0x04, 0x01, intensity, 0x00, 0x00, 0x00, 0x00, footer]
            
        case .speed(let value):
            // Speed mapping: user 0-100 -> hardware 1-100 (often 1 is slowest or vice-versa)
            let speed = UInt8(clamping: value)
            return [header, 0x04, 0x02, speed, 0x00, 0x00, 0x00, 0x00, footer]
            
        case .color(let r, let g, let b):
            // Static RGB command: [0x7E, 0x07, 0x05, 0x03, R, G, B, 0x00, 0xEF]
            return [header, 0x07, 0x05, 0x03, UInt8(clamping: r), UInt8(clamping: g), UInt8(clamping: b), 0x00, footer]
            
        case .mode(let mode):
            return [header, 0x05, 0x03, mode.rawValue, 0x00, 0x00, 0x00, 0x00, footer]
        }
    }
    
    /// Protocol variations found in some ELK-BLEDDM hardware
    static func alternativePowerPacket(isOn: Bool) -> [UInt8] {
        // Variant B: [0x7E, 0x04, 0x01, (FF=ON/00=OFF), 0x00, 0x00, 0x00, 0x00, 0xEF]
        return [header, 0x04, 0x01, isOn ? 0xFF : 0x00, 0x00, 0x00, 0x00, 0x00, footer]
    }
}
