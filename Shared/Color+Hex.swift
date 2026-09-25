import SwiftUI

extension Color {
    init(pickupHex: String) {
        let value = UInt32(pickupHex, radix: 16) ?? 0xB5F36C
        self.init(.sRGB, red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255, opacity: 1)
    }
}
