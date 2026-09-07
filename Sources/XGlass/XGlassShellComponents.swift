import SwiftUI

struct XGlassShellLayout {
    // Reserve the complete native traffic-light group plus a trailing inset.
    static let compactRailWidth: CGFloat = 80

    let isCompact: Bool
    let showsRouteLabels: Bool
    let outerPadding: CGFloat
    let gutter: CGFloat
    let railWidth: CGFloat

    init(windowWidth: CGFloat, compactPreference: Bool) {
        isCompact = windowWidth < 820
        showsRouteLabels = !compactPreference && windowWidth >= 1180
        outerPadding = windowWidth < 720 ? 8 : 12
        gutter = windowWidth < 720 ? 8 : 10
        railWidth = showsRouteLabels ? 178 : Self.compactRailWidth
    }
}

struct XGlassBrowserSurface: View {
    @ObservedObject var browser: XBrowserModel
    @ObservedObject var settings: XGlassSettingsStore
    let isCompact: Bool
    let showsToolbar: Bool

    var body: some View {
        VStack(spacing: 0) {
            if showsToolbar {
                XGlassBrowserToolbar(
                    browser: browser,
                    settings: settings,
                    isCompact: isCompact
                )

                Divider()
                    .overlay(settings.colors.stroke)
            }

            if browser.showsFindBar { XGlassFindBar(browser: browser) }

            XWebView()
                .background(settings.colors.content.opacity(0.94))
        }
        .background(settings.colors.content)
    }
}
