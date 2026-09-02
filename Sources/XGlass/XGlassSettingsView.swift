import SwiftUI

struct XGlassSettingsView: View {
    @EnvironmentObject private var settings: XGlassSettingsStore
    @EnvironmentObject private var browser: XBrowserModel

    @State private var sidebarVisible = true
    @State private var selection: XGlassSettingsPage? = .appearance
    @State private var themeQuery = ""
    @State private var themeCollection: XGlassThemeCollection = .all

    private var colors: XGlassThemeColors { settings.colors }

    var body: some View {
        ZStack {
            XGlassAmbientBackdrop(
                colors: colors,
                intensity: settings.backgroundGlow,
                reduceMotion: settings.reduceMotion
            )

            VStack(spacing: 0) {
                settingsChrome

                HStack(spacing: 0) {
                    if sidebarVisible {
                        settingsSidebar
                            .frame(minWidth: 230, idealWidth: 252, maxWidth: 290)
                        Divider().overlay(colors.stroke)
                    }

                    ScrollView {
                        settingsDetail
                            .frame(maxWidth: 900, alignment: .topLeading)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.horizontal, 30)
                            .padding(.top, 26)
                            .padding(.bottom, 42)
                    }
                    .scrollIndicators(.automatic)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(colors.content.opacity(0.82))
                }
            }
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(XGlassSettingsWindowConfigurator(color: colors.window))
    }

    private var settingsChrome: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    sidebarVisible.toggle()
                }
            } label: {
                Image(systemName: sidebarVisible ? "sidebar.leading" : "sidebar.trailing")
                    .frame(width: 26, height: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(sidebarVisible ? "Hide Settings Sidebar" : "Show Settings Sidebar")
            .accessibilityLabel(sidebarVisible ? "Hide Settings Sidebar" : "Show Settings Sidebar")

            XGlassBrandMark(foreground: colors.text, accent: colors.accent, size: 14)
                .frame(width: 24, height: 24)
                .background(colors.accent.opacity(0.16), in: Circle())

            Text("Settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text("XGlass")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().overlay(colors.stroke)
        }
    }

    private var settingsSidebar: some View {
        List(selection: $selection) {
            Section {
                HStack(spacing: 11) {
                    SettingsIconBadge(systemName: "xmark", tint: colors.accent, size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("XGlass")
                            .font(.headline)
                        Text("X for Mac")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 5)
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 8, trailing: 8))
                .listRowSeparator(.hidden)
            }

            Section("XGlass") {
                settingsRow(.appearance)
                settingsRow(.navigation)
            }

            Section("Safety") {
                settingsRow(.privacy)
                settingsRow(.diagnostics)
            }

            Section("Support") {
                settingsRow(.about)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(colors.sidebar.opacity(0.78))
    }

    private func settingsRow(_ page: XGlassSettingsPage) -> some View {
        HStack(spacing: 10) {
            SettingsIconBadge(systemName: page.systemImage, tint: page.tint, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(page.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .tag(page)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.title)
        .accessibilityHint(page.subtitle)
    }

    @ViewBuilder
    private var settingsDetail: some View {
        switch selection ?? .appearance {
        case .appearance:
            XGlassAppearanceSettingsPage(themeQuery: $themeQuery, themeCollection: $themeCollection)
        case .navigation:
            XGlassNavigationSettingsPage()
        case .privacy:
            XGlassPrivacySettingsPage()
        case .diagnostics:
            XGlassDiagnosticsSettingsPage()
        case .about:
            XGlassAboutSettingsPage()
        }
    }
}
