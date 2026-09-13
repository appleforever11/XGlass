import SwiftUI

struct XGlassAppearanceSettingsPage: View {
    @EnvironmentObject private var settings: XGlassSettingsStore
    @Binding var themeQuery: String
    @Binding var themeCollection: XGlassThemeCollection
    @State private var favoritesOnly = false

    private var filteredThemes: [XGlassThemeFamily] {
        XGlassThemeFilter.matching(query: themeQuery, collection: themeCollection)
            .filter { !favoritesOnly || settings.favoriteThemes.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .appearance)
            HStack(alignment: .center, spacing: 20) {
                XGlassThemePreview(colors: settings.colors, isDark: true)
                    .frame(width: 184, height: 112)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 7) {
                    Text(settings.theme.title).font(.system(size: 18, weight: .semibold))
                    Text(settings.theme.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle().fill([settings.colors.accent, settings.colors.secondary, settings.colors.tertiary][index])
                                .frame(width: 12, height: 12)
                        }
                        Text(settings.themeCustomization.normalizedAccentHex ?? "Default accent")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            XGlassSettingsGroup(title: "Themes", footer: nil) {
                HStack(spacing: 10) {
                    TextField("Search themes", text: $themeQuery)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Search themes")
                    Picker("Collection", selection: $themeCollection) {
                        ForEach(XGlassThemeCollection.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden().fixedSize()
                    Toggle(isOn: $favoritesOnly) {
                        Image(systemName: favoritesOnly ? "star.fill" : "star")
                    }
                    .toggleStyle(.button)
                    .help("Favorite themes").accessibilityLabel("Favorite themes")
                }
                if filteredThemes.isEmpty {
                    ContentUnavailableView(
                        favoritesOnly ? "No favorite themes" : "No matching themes",
                        systemImage: favoritesOnly ? "star" : "magnifyingglass"
                    ).frame(height: 150)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 208), spacing: 12)], spacing: 12) {
                        ForEach(filteredThemes) { theme in
                            XGlassThemeCard(
                                theme: theme, isSelected: settings.theme == theme,
                                colors: settings.theme == theme ? settings.colors : theme.colors,
                                isFavorite: settings.favoriteThemes.contains(theme),
                                toggleFavorite: { settings.toggleFavorite(theme) },
                                action: { settings.setTheme(theme) }
                            )
                        }
                    }
                }
            }

            DisclosureGroup("Custom accent") { XGlassAccentEditor().padding(.top, 12) }
                .font(.system(size: 13, weight: .semibold))

            XGlassSettingsGroup(title: "Glass & Motion", footer: nil) {
                HStack(alignment: .top, spacing: 24) {
                    XGlassSlider(title: "Background glow", systemImage: "sun.max", value: Binding(
                        get: { settings.backgroundGlow }, set: settings.setBackgroundGlow
                    ), range: 0.35...1.0)
                    XGlassSlider(title: "Glass intensity", systemImage: "circle.lefthalf.filled", value: Binding(
                        get: { settings.glassIntensity }, set: settings.setGlassIntensity
                    ), range: 0.25...1.0)
                }
                Toggle("Reduce ambient motion", isOn: Binding(
                    get: { settings.reduceMotion }, set: settings.setReduceMotion
                ))
            }
            HStack {
                Spacer()
                Button("Restore Appearance Defaults", systemImage: "arrow.counterclockwise", action: settings.resetAppearance)
                    .controlSize(.small)
            }
        }
    }
}
