import AppKit
import SwiftUI

struct XGlassThemeCustomization: Codable, Equatable {
    struct RGBComponents: Equatable {
        let red: Int
        let green: Int
        let blue: Int
    }

    var accentHex: String?

    static let empty = XGlassThemeCustomization(accentHex: nil)

    var normalizedAccentHex: String? {
        guard let accentHex else { return nil }
        return Self.normalizeHex(accentHex)
    }

    var components: RGBComponents? {
        guard let normalized = normalizedAccentHex else { return nil }
        let value = String(normalized.dropFirst())
        guard let number = UInt64(value, radix: 16) else { return nil }
        return RGBComponents(
            red: Int((number >> 16) & 0xFF),
            green: Int((number >> 8) & 0xFF),
            blue: Int(number & 0xFF)
        )
    }

    var accentColor: Color? {
        guard let components else { return nil }
        return Color(
            red: Double(components.red) / 255,
            green: Double(components.green) / 255,
            blue: Double(components.blue) / 255
        )
    }

    static func normalizeHex(_ rawValue: String) -> String? {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        guard value.count == 6,
              value.allSatisfy({ $0.isHexDigit }) else { return nil }
        return "#" + value.uppercased()
    }

    static func hex(for color: Color) -> String? {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        let red = Int((srgb.redComponent * 255).rounded())
        let green = Int((srgb.greenComponent * 255).rounded())
        let blue = Int((srgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
