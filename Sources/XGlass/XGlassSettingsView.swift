import SwiftUI

struct XGlassSettingsView: View {
    @EnvironmentObject private var settings: XGlassSettingsStore
    @State private var selection: XGlassSettingsPage? = .appearance
    @State private var themeQuery = ""
    @State private var themeCollection: XGlassThemeCollection = .all

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .accessibilityHidden(true)
                    Text("XGlass")
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .accessibilityElement(children: .combine)

                List(selection: $selection) {
                    Section("Personalize") {
                        settingsRow(.appearance)
                        settingsRow(.navigation)
                    }
                    Section("Application") {
                        settingsRow(.privacy)
                        settingsRow(.diagnostics)
                        settingsRow(.about)
                    }
                }
                .listStyle(.sidebar)
            }
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ScrollView {
                Group {
                    switch selection ?? .appearance {
                    case .appearance: XGlassAppearanceSettingsPage(themeQuery: $themeQuery, themeCollection: $themeCollection)
                    case .navigation: XGlassNavigationSettingsPage()
                    case .privacy: XGlassPrivacySettingsPage()
                    case .diagnostics: XGlassDiagnosticsSettingsPage()
                    case .about: XGlassAboutSettingsPage()
                    }
                }
                .frame(maxWidth: 860, alignment: .leading)
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .id(selection)
            .background(settings.colors.window)
            .navigationTitle((selection ?? .appearance).title)
        }
        .tint(settings.colors.accent)
        .frame(minWidth: 760, minHeight: 600)
        .background(XGlassSettingsWindowConfigurator(color: settings.colors.window))
    }

    private func settingsRow(_ page: XGlassSettingsPage) -> some View {
        Label {
            Text(page.title).font(.system(size: 13, weight: .medium))
        } icon: {
            Image(systemName: page.systemImage).foregroundStyle(page.tint)
        }
        .padding(.vertical, 6)
        .tag(page)
    }
}
