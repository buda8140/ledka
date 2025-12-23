import Foundation

/// Unified Protocol for BLEDDM / BLEDOM / Lotus Lantern Controllers
/// All packets are standardized to 9 bytes: [7E] [00] [Type] [Data...] [EF]
struct LEDProtocol {
    
    enum CommandType: UInt8 {
        case power = 0x04
        case brightness = 0x01
        case speed = 0x02
        case color = 0x05
        case mode = 0x06
    }
    
    enum EffectMode: UInt8, CaseIterable {
        case rainbowSmooth = 0x25
        case rainbowPulse = 0x26
        case redPulse = 0x27
        case greenPulse = 0x28
        case bluePulse = 0x29
        case yellowPulse = 0x2A
        case cyanPulse = 0x2B
        case purplePulse = 0x2C
        case whitePulse = 0x2D
        case redGreenSmooth = 0x2E
        case redBlueSmooth = 0x2F
        case greenBlueSmooth = 0x30
        case rainbowStrobe = 0x31
        case redStrobe = 0x32
        case greenStrobe = 0x33
        case blueStrobe = 0x34
        case yellowStrobe = 0x35
        case cyanStrobe = 0x36
        case purpleStrobe = 0x37
        case whiteStrobe = 0x38
        case fire = 0x3C
    }
    
    static func power(_ on: Bool) -> [UInt8] {
        // [0x7E, 0x00, 0x04, state, 0x00, 0x00, 0x00, 0x00, 0xEF]
        return [0x7E, 0x00, 0x04, on ? 0x01 : 0x00, 0x00, 0x00, 0x00, 0x00, 0xEF]
    }
    
    static func color(r: Int, g: Int, b: Int) -> [UInt8] {
        // [0x7E, 0x00, 0x05, 0x03, R, G, B, 0x00, 0xEF]
        let r = UInt8(clamping: r)
        let g = UInt8(clamping: g)
        let b = UInt8(clamping: b)
        return [0x7E, 0x00, 0x05, 0x03, r, g, b, 0x00, 0xEF]
    }
    
    static func brightness(_ value: Int) -> [UInt8] {
        // [0x7E, 0x00, 0x01, brightness, 0x00, 0x00, 0x00, 0x00, 0xEF]
        let val = UInt8(clamping: value)
        return [0x7E, 0x00, 0x01, val, 0x00, 0x00, 0x00, 0x00, 0xEF]
    }
    
    static func speed(_ value: Int) -> [UInt8] {
        // [0x7E, 0x00, 0x02, speed, 0x00, 0x00, 0x00, 0x00, 0xEF]
        let val = UInt8(clamping: value)
        return [0x7E, 0x00, 0x02, val, 0x00, 0x00, 0x00, 0x00, 0xEF]
    }
    
    static func mode(_ value: UInt8) -> [UInt8] {
        // [0x7E, 0x00, 0x06, mode, 0x00, 0x00, 0x00, 0x00, 0xEF]
        return [0x7E, 0x00, 0x06, value, 0x00, 0x00, 0x00, 0x00, 0xEF]
    }
}
