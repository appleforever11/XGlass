import SwiftUI

struct XGlassRootView: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    var body: some View {
        GeometryReader { proxy in
            let layout = XGlassShellLayout(
                windowWidth: proxy.size.width,
                compactPreference: settings.compactSidebar
            )

            ZStack(alignment: .bottomTrailing) {
                XGlassAmbientBackdrop(
                    colors: settings.colors,
                    intensity: settings.backgroundGlow,
                    reduceMotion: settings.reduceMotion
                )
                .ignoresSafeArea()

                HStack(spacing: layout.gutter) {
                    XGlassNavigationRail(
                        browser: browser,
                        settings: settings,
                        showsLabels: layout.showsRouteLabels
                    )
                    .frame(width: layout.railWidth)

                    XGlassBrowserSurface(
                        browser: browser,
                        settings: settings,
                        isCompact: layout.isCompact,
                        showsToolbar: settings.showBrowserToolbar
                    )
                }
                .padding(.horizontal, layout.outerPadding)
                .padding(.top, 10)
                .padding(.bottom, layout.outerPadding)

                XGlassStatusOverlay(browser: browser, colors: settings.colors)
                    .padding(.trailing, layout.outerPadding + 16)
                    .padding(.bottom, layout.outerPadding + 16)
            }
            .background(settings.colors.window)
            .background(XGlassWindowSizingView())
        }
    }
}
