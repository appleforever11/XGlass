import SwiftUI

struct XGlassShellLayout {
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
        railWidth = showsRouteLabels ? 178 : (windowWidth < 720 ? 58 : 66)
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
                    colors: settings.colors,
                    glassIntensity: settings.glassIntensity,
                    isCompact: isCompact
                )

                Divider()
                    .overlay(settings.colors.stroke)
            }

            XWebView()
                .background(settings.colors.content.opacity(0.72))
        }
        .background(.ultraThinMaterial)
        .background(settings.colors.content.opacity(0.38 * settings.glassIntensity))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(settings.colors.stroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 12)
    }
}
