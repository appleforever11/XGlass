import SwiftUI

/// The geometric X mark used by XGlass branding.
struct XGlassBrandMark: View {
    let foreground: Color
    let accent: Color
    let size: CGFloat

    init(colors: XGlassThemeColors, size: CGFloat) {
        self.foreground = colors.text
        self.accent = colors.accent
        self.size = size
    }

    init(foreground: Color = .white, accent: Color, size: CGFloat) {
        self.foreground = foreground
        self.accent = accent
        self.size = size
    }

    var body: some View {
        XBrandShape()
            .fill(
                LinearGradient(
                    colors: [foreground, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: FillStyle(eoFill: true)
            )
            .overlay {
                XBrandShape()
                    .stroke(foreground.opacity(0.68), lineWidth: max(0.5, size * 0.018))
            }
            .shadow(color: accent.opacity(0.24), radius: max(2, size * 0.16), y: 1)
            .frame(width: size, height: size)
            .accessibilityLabel("X")
    }
}

private struct XBrandShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        var path = Path()

        // X's official 24-point geometry, kept as vector data for crisp scaling.
        path.move(to: point(18.244, 2.25))
        path.addLine(to: point(21.552, 2.25))
        path.addLine(to: point(14.325, 10.51))
        path.addLine(to: point(22.827, 21.75))
        path.addLine(to: point(16.17, 21.75))
        path.addLine(to: point(10.956, 14.933))
        path.addLine(to: point(4.989, 21.75))
        path.addLine(to: point(1.68, 21.75))
        path.addLine(to: point(9.41, 12.915))
        path.addLine(to: point(1.254, 2.25))
        path.addLine(to: point(8.08, 2.25))
        path.addLine(to: point(12.793, 8.481))
        path.addLine(to: point(18.244, 2.25))
        path.closeSubpath()

        path.move(to: point(17.083, 19.77))
        path.addLine(to: point(18.916, 19.77))
        path.addLine(to: point(7.084, 4.126))
        path.addLine(to: point(5.117, 4.126))
        path.closeSubpath()

        return path
    }
}
