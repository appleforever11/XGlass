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
        .background(tint, in: RoundedRectangle(cornerRadius: 8))
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
            HStack {
                Label(title, systemImage: systemImage).font(.subheadline)
                Spacer(minLength: 4)
                Text("\(Int(value * 100))%").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
                .controlSize(.small)
                .accessibilityLabel(title)
                .accessibilityValue("\(Int(value * 100)) percent")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct XGlassThemeCard: View {
    let theme: XGlassThemeFamily
    let isSelected: Bool
    let colors: XGlassThemeColors
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                XGlassThemePreview(colors: colors, isDark: true)
                    .frame(height: 106)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Apply \(theme.title) theme")
            .accessibilityValue(isSelected ? "Selected" : "")
            HStack(spacing: 8) {
                Button(action: action) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(colors.accent)
                        }
                        Text(theme.title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? colors.accent : colors.secondaryText)
                        .frame(width: 24, height: 26)
                }
                .buttonStyle(.plain)
                .help(isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityLabel("\(isFavorite ? "Unfavorite" : "Favorite") \(theme.title)")
            }
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .foregroundStyle(colors.text)
        .background(colors.window, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? colors.accent : colors.stroke, lineWidth: isSelected ? 2 : 1)
                .allowsHitTesting(false)
        }
    }
}

struct XGlassThemePreview: View {
    let colors: XGlassThemeColors
    let isDark: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 9) {
                XGlassBrandMark(colors: colors, size: 13)
                ForEach(["house.fill", "magnifyingglass", "bell", "envelope"], id: \.self) { symbol in
                    Image(systemName: symbol).font(.system(size: 8)).foregroundStyle(colors.text.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .frame(width: 30)
            .background(colors.sidebar.opacity(0.65))

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Circle().fill(colors.accent).frame(width: 4, height: 4)
                    Capsule().fill(colors.text.opacity(0.8)).frame(width: 25, height: 3)
                    Spacer()
                    Image(systemName: "magnifyingglass").font(.system(size: 7))
                }
                .padding(8)
                .background(colors.window.opacity(0.7))
                ForEach(0..<2) { index in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(index == 0 ? colors.accent : colors.secondary)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 5) {
                            Capsule().fill(colors.text.opacity(0.8)).frame(width: index == 0 ? 44 : 35, height: 3)
                            Capsule().fill(colors.text.opacity(0.3)).frame(height: 3)
                            Capsule().fill(colors.text.opacity(0.3)).frame(width: index == 0 ? 66 : 52, height: 3)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if index == 0 { Rectangle().fill(colors.stroke).frame(height: 0.5) }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(colors.text)
            .background(colors.content)
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .accessibilityHidden(true)
    }
}
