import SwiftUI

struct SettingsIconBadge: View {
    let systemName: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        Group {
            if systemName == "xmark" {
                XGlassBrandMark(accent: tint, size: size * 0.50)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.40, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .background(tint, in: RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .shadow(color: tint.opacity(0.25), radius: 5, y: 2)
        .accessibilityHidden(true)
    }
}

struct XGlassSlider: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
            Slider(value: $value, in: range)
                .controlSize(.small)
                .accessibilityValue("\(Int(value * 100)) percent")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct XGlassThemeCard: View {
    let theme: XGlassThemeFamily
    let isSelected: Bool
    let colors: XGlassThemeColors
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    XGlassThemePreview(colors: colors, isDark: false)
                    XGlassThemePreview(colors: colors, isDark: true)
                }
                .frame(height: 88)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: theme.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colors.accent)
                        .frame(width: 24, height: 24)
                        .background(colors.accent.opacity(0.13), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(theme.title)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                            if let badge = theme.badgeTitle {
                                Text(badge)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(colors.secondary.opacity(0.20), in: Capsule())
                            }
                        }
                        Text(theme.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? colors.accent : Color.secondary.opacity(0.50))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(
                colors.card.opacity(isHovering ? 0.92 : 0.78),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? colors.accent.opacity(0.82) : colors.stroke.opacity(isHovering ? 0.90 : 0.58),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(
                color: isSelected ? colors.accent.opacity(0.16) : .black.opacity(isHovering ? 0.14 : 0.06),
                radius: isHovering ? 10 : 6,
                y: 3
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(theme.title), \(theme.subtitle)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

struct XGlassThemePreview: View {
    let colors: XGlassThemeColors
    let isDark: Bool

    var body: some View {
        GeometryReader { geometry in
            let base = isDark ? colors.window : Color(red: 0.94, green: 0.96, blue: 0.98)
            let foreground = isDark ? colors.text : Color.black.opacity(0.78)

            ZStack {
                base
                RadialGradient(
                    colors: [colors.primary.opacity(isDark ? 0.72 : 0.48), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.90
                )
                RadialGradient(
                    colors: [colors.secondary.opacity(isDark ? 0.62 : 0.38), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.82
                )

                HStack(spacing: 4) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(colors.accent)
                            .frame(width: 8, height: 8)
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(index == 0 ? colors.text.opacity(0.82) : colors.secondaryText.opacity(0.52))
                                .frame(width: 8, height: 6)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                    .frame(width: 17)
                    .background(colors.sidebar.opacity(isDark ? 0.82 : 0.54))

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(colors.card.opacity(isDark ? 0.84 : 0.62))
                            .frame(height: 10)

                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(index == 0 ? colors.selected : colors.card.opacity(0.46))
                            }
                        }
                        .frame(height: 9)

                        VStack(spacing: 3) {
                            ForEach(0..<2, id: \.self) { index in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(index == 0 ? colors.primary : colors.secondary)
                                        .frame(width: 9, height: 9)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Capsule()
                                            .fill(foreground.opacity(0.72))
                                            .frame(width: index == 0 ? 34 : 42, height: 2)
                                        Capsule()
                                            .fill(foreground.opacity(0.34))
                                            .frame(width: index == 0 ? 48 : 30, height: 2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(3)
                                .background(colors.content.opacity(isDark ? 0.74 : 0.28))
                            }
                        }
                    }
                    .padding(4)
                }
                .padding(6)
                .opacity(isDark ? 0.92 : 0.74)

                VStack {
                    HStack {
                        Spacer()
                        Text(isDark ? "DARK" : "LIGHT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(foreground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((isDark ? colors.card : .white).opacity(0.76), in: Capsule())
                    }
                    Spacer()
                }
                .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(colors.stroke, lineWidth: 1)
            }
        }
    }
}
