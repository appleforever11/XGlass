import SwiftUI

struct XGlassAppearanceSettingsPage: View {
    @EnvironmentObject private var settings: XGlassSettingsStore
    @Binding var themeQuery: String
    @Binding var themeCollection: XGlassThemeCollection

    private var colors: XGlassThemeColors { settings.colors }

    private var filteredThemes: [XGlassThemeFamily] {
        XGlassThemeFilter.matching(query: themeQuery, collection: themeCollection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            XGlassSettingsHeader(page: .appearance)

            currentThemeSummary

            XGlassSettingsGroup(
                title: "Theme Center",
                footer: "Choose an environment for the native shell and XGlass surfaces. Each preview shows the same environment in light and dark treatments."
            ) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Visual environments")
                            .font(.title3.weight(.bold))
                        Text("The live window updates as soon as you select a theme.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Text("\(filteredThemes.count) of \(XGlassThemeFamily.allCases.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 7) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(colors.accent)
                        Picker("Collection", selection: $themeCollection) {
                            ForEach(XGlassThemeCollection.allCases) { collection in
                                Text(collection.title).tag(collection)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    TextField("Search environments", text: $themeQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 270)
                        .accessibilityLabel("Search environments")

                    Spacer(minLength: 0)

                    Button {
                        let candidates = XGlassThemeFamily.allCases.filter { $0 != settings.theme }
                        settings.setTheme(candidates.randomElement() ?? .tahoeTide)
                    } label: {
                        Label("Surprise me", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                    .help("Apply a different environment")
                }

                if filteredThemes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(colors.accent)
                        Text("No environments found")
                            .font(.headline)
                        Text("Try a different name or collection.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .accessibilityElement(children: .combine)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 235, maximum: 360), spacing: 14)],
                        alignment: .leading,
                        spacing: 14
                    ) {
                        ForEach(filteredThemes) { theme in
                            XGlassThemeCard(
                                theme: theme,
                                isSelected: settings.theme == theme,
                                colors: theme.colors,
                                action: { settings.setTheme(theme) }
                            )
                        }
                    }
                }
            }

            XGlassSettingsGroup(
                title: "Glass controls",
                footer: "Lower intensity for a quieter window. Reduce motion also follows the system Reduce Motion accessibility setting."
            ) {
                HStack(alignment: .top, spacing: 26) {
                    XGlassSlider(
                        title: "Background glow",
                        systemImage: "sun.max",
                        value: Binding(
                            get: { settings.backgroundGlow },
                            set: { settings.setBackgroundGlow($0) }
                        ),
                        range: 0.35...1.0
                    )
                    XGlassSlider(
                        title: "Glass intensity",
                        systemImage: "circle.lefthalf.filled",
                        value: Binding(
                            get: { settings.glassIntensity },
                            set: { settings.setGlassIntensity($0) }
                        ),
                        range: 0.25...1.0
                    )
                }

                Divider()

                Toggle("Reduce ambient motion", isOn: Binding(
                    get: { settings.reduceMotion },
                    set: { settings.setReduceMotion($0) }
                ))
            }

            XGlassSettingsGroup(
                title: "Window layout",
                footer: "Feed width changes only the local page presentation. It does not modify your X account or timeline settings."
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feed width")
                        .font(.subheadline.weight(.semibold))
                    Picker("Feed width", selection: Binding(
                        get: { settings.feedWidth },
                        set: { settings.setFeedWidth($0) }
                    )) {
                        ForEach(XGlassFeedWidth.allCases) { width in
                            Label(width.title, systemImage: width.systemImage)
                                .tag(width)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Text(settings.feedWidth.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Toggle("Show browser toolbar", isOn: Binding(
                    get: { settings.showBrowserToolbar },
                    set: { settings.setShowBrowserToolbar($0) }
                ))
                Toggle("Use a compact navigation rail", isOn: Binding(
                    get: { settings.compactSidebar },
                    set: { settings.setCompactSidebar($0) }
                ))

                HStack {
                    Spacer()
                    Button("Restore appearance defaults") {
                        settings.resetAppearance()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var currentThemeSummary: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(systemName: settings.theme.systemImage, tint: colors.accent, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Current environment")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(settings.theme.title)
                    .font(.headline)
                Text(settings.theme.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Label("Live", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(colors.accent)
        }
        .padding(14)
        .background(colors.card.opacity(0.68), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(colors.stroke, lineWidth: 1)
        }
    }
}
