import SwiftUI

struct XGlassNavigationRail: View {
    @ObservedObject var browser: XBrowserModel
    @ObservedObject var settings: XGlassSettingsStore
    let showsLabels: Bool

    @State private var isComposeHovering = false

    private let primaryRoutes: [XRoute] = [
        .home, .explore, .notifications, .messages, .bookmarks, .lists
    ]

    var body: some View {
        VStack(spacing: 8) {
            brand

            Divider()
                .overlay(settings.colors.stroke)
                .padding(.vertical, 4)

            ForEach(primaryRoutes) { route in
                XGlassNavigationButton(
                    route: route,
                    isSelected: browser.activeRoute == route,
                    showsLabel: showsLabels,
                    colors: settings.colors,
                    action: { browser.navigate(to: route) }
                )
            }

            Spacer(minLength: 10)

            XGlassNavigationButton(
                route: .profile,
                isSelected: browser.activeRoute == .profile,
                showsLabel: showsLabels,
                colors: settings.colors,
                action: browser.navigateToOwnProfile
            )

            XGlassNavigationButton(
                route: .settings,
                label: "X Settings",
                isSelected: browser.activeRoute == .settings,
                showsLabel: showsLabels,
                colors: settings.colors,
                action: { browser.navigate(to: .settings) }
            )

            Button {
                browser.navigate(to: .compose)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: XRoute.compose.systemImage)
                    if showsLabels {
                        Text("New Post")
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.black.opacity(0.86))
            .background(settings.colors.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(settings.colors.text.opacity(isComposeHovering ? 0.38 : 0.18), lineWidth: 1)
            }
            .shadow(
                color: settings.colors.accent.opacity(isComposeHovering ? 0.32 : 0.18),
                radius: isComposeHovering ? 9 : 5,
                y: 3
            )
            .onHover { isComposeHovering = $0 }
            .help("New Post")
            .accessibilityLabel("New Post")
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .background(settings.colors.sidebar.opacity(0.34 * settings.glassIntensity))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(settings.colors.stroke, lineWidth: 1)
        }
    }

    private var brand: some View {
        HStack(spacing: 9) {
            XGlassBrandMark(colors: settings.colors, size: 24)
                .frame(width: 34, height: 34)
            if showsLabels {
                VStack(alignment: .leading, spacing: 0) {
                    Text("XGlass")
                        .font(.system(size: 14, weight: .bold))
                    Text("X for Mac")
                        .font(.caption2)
                        .foregroundStyle(settings.colors.secondaryText)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("XGlass")
    }
}

struct XGlassNavigationButton: View {
    let route: XRoute
    var label: String? = nil
    let isSelected: Bool
    let showsLabel: Bool
    let colors: XGlassThemeColors
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: route.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)

                if showsLabel {
                    Text(label ?? route.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, showsLabel ? 8 : 6)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? colors.text : colors.secondaryText)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? colors.selected : (isHovering ? colors.card.opacity(0.34) : .clear))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isSelected ? colors.accent.opacity(0.30) : .clear, lineWidth: 1)
        }
        .overlay(alignment: .trailing) {
            if isSelected {
                Capsule()
                    .fill(colors.accent)
                    .frame(width: 3, height: 20)
                    .padding(.trailing, 2)
            }
        }
        .onHover { isHovering = $0 }
        .help(label ?? route.rawValue)
        .accessibilityLabel(label ?? route.rawValue)
        .accessibilityValue(isSelected ? "Current page" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
