import SwiftUI

extension XGlassThemeFamily {
    static func landscape(background: String, panel: String, card: String, accent: String,
                          secondary: String, highlight: String, text: String, muted: String) -> XGlassThemeColors {
        func color(_ hex: String) -> Color {
            let value = UInt32(hex, radix: 16) ?? 0
            return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                         green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
        }
        return XGlassThemeColors(
            window: color(background), sidebar: color(panel), content: color(background),
            card: color(card), selected: color(accent).opacity(0.25), stroke: color(highlight).opacity(0.24),
            text: color(text), secondaryText: color(muted), primary: color(accent),
            secondary: color(secondary), tertiary: color(highlight), accent: color(accent),
            web: .init(bandTop: "#\(panel)", bandBottom: "#\(background)", accent: "#\(accent)",
                       accentSoft: "#\(card)", text: "#\(text)", muted: "#\(muted)", border: "#\(card)",
                       incomingBubble: "#\(card)", outgoingBubble: "#\(secondary)")
        )
    }
}
