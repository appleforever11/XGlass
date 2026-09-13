import SwiftUI

struct XGlassNavigationRail: View {
    @ObservedObject var browser: XBrowserModel
    @ObservedObject var settings: XGlassSettingsStore
    let showsLabels: Bool

    private let primaryRoutes: [XRoute] = [.home, .explore, .notifications, .messages, .bookmarks, .lists]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                XGlassBrandMark(colors: settings.colors, size: 24).frame(width: 34, height: 34)
                if showsLabels {
                    Text("XGlass").font(.system(size: 16, weight: .bold))
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("XGlass")

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(primaryRoutes) { route in
                        XGlassNavigationButton(
                            route: route, isSelected: browser.activeRoute == route,
                            showsLabel: showsLabels, colors: settings.colors,
                            unreadState: route == .notifications ? browser.unreadState : XGlassUnreadState(),
                            action: { browser.navigate(to: route) }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity)

            XGlassNavigationButton(
                route: .profile, isSelected: browser.activeRoute == .profile,
                showsLabel: showsLabels, colors: settings.colors,
                action: browser.navigateToOwnProfile
            )

            Menu {
                SettingsLink { Label("XGlass Settings...", systemImage: "paintpalette") }
                Button("X Account Settings", systemImage: "person.crop.circle") { browser.navigate(to: .settings) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape").frame(width: 28, height: 28)
                    if showsLabels { Text("Settings"); Spacer(minLength: 0) }
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, showsLabels ? 8 : 6)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .help("Settings")
            .accessibilityLabel("Settings")

            Button { browser.navigate(to: .compose) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                    if showsLabels { Text("New Post") }
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(settings.colors.accentForeground)
                .background(settings.colors.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("New Post")
            .accessibilityLabel("New Post")
            .padding(.top, 4)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
        .foregroundStyle(settings.colors.secondaryText)
        .background(settings.colors.sidebar.opacity(0.20 + 0.30 * settings.glassIntensity))
    }
}

struct XGlassNavigationButton: View {
    let route: XRoute
    var label: String? = nil
    let isSelected: Bool
    let showsLabel: Bool
    let colors: XGlassThemeColors
    var unreadState = XGlassUnreadState()
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: route.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .overlay(alignment: .topTrailing) {
                        if unreadState.isVisible {
                            Group {
                                if let text = unreadState.badgeText {
                                    Text(text).font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4).frame(minWidth: 15, minHeight: 15)
                                } else {
                                    Circle().frame(width: 9, height: 9)
                                }
                            }
                            .foregroundStyle(unreadState.badgeText == nil ? Color(red: 0.78, green: 0.08, blue: 0.14) : Color.white)
                            .background(Color(red: 0.78, green: 0.08, blue: 0.14), in: Capsule())
                            .overlay(Capsule().stroke(colors.content, lineWidth: 1.5))
                            .offset(x: 6, y: -3)
                            .accessibilityHidden(true)
                        }
                    }

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
        .accessibilityValue([isSelected ? "Current page" : "", unreadState.accessibilityDescription].filter { !$0.isEmpty }.joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
