import XCTest
@testable import LEDControl

final class LEDProtocolTests: XCTestCase {

    func testPowerOnPacket() {
        let packet = LEDProtocol.power(true)
        let expected: [UInt8] = [0x7E, 0x04, 0x04, 0x01, 0x00, 0x00, 0xFF, 0x00, 0xEF]
        XCTAssertEqual(packet, expected)
    }

    func testPowerOffPacket() {
        let packet = LEDProtocol.power(false)
        let expected: [UInt8] = [0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]
        XCTAssertEqual(packet, expected)
    }

    func testColorPacket() {
        let packet = LEDProtocol.color(r: 255, g: 128, b: 0)
        let expected: [UInt8] = [0x7E, 0x07, 0x05, 0x03, 0xFF, 0x80, 0x00, 0x00, 0x00, 0xEF] 
        // Note: My protocol builder in previous turn had 9 bytes: [7E, 07, 05, 03, r, g, b, 00, EF]
        // Let's re-verify the count. 1(7E) + 1(07) + 1(05) + 1(03) + 1(R) + 1(G) + 1(B) + 1(00) + 1(EF) = 9 bytes. Correct.
        XCTAssertEqual(packet.count, 9)
        XCTAssertEqual(packet[4], 255)
        XCTAssertEqual(packet[5], 128)
        XCTAssertEqual(packet[6], 0)
    }

    func testBrightnessPacket() {
        let packet = LEDProtocol.brightness(50)
        XCTAssertEqual(packet[3], 50)
        XCTAssertEqual(packet.count, 9)
    }
    
    func testEffectPacket() {
        let packet = LEDProtocol.effect(.rainbowSmooth)
        XCTAssertEqual(packet[3], 0x25)
        XCTAssertEqual(packet.count, 9)
    }
}
