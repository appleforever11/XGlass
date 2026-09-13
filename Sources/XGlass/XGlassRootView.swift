import SwiftUI

struct XGlassRootView: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore
    @EnvironmentObject private var workspace: XGlassWorkspaceState

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

                HStack(spacing: 0) {
                    if !workspace.isFocused {
                        XGlassNavigationRail(
                            browser: browser,
                            settings: settings,
                            showsLabels: layout.showsRouteLabels
                        )
                        .frame(width: layout.railWidth)
                        Divider().overlay(settings.colors.stroke.opacity(0.65))
                    }

                    XGlassBrowserSurface(
                        browser: browser,
                        settings: settings,
                        isCompact: layout.isCompact,
                        showsToolbar: settings.showBrowserToolbar || workspace.isFocused
                    )
                }

                XGlassStatusOverlay(browser: browser, colors: settings.colors)
                    .padding(.trailing, layout.outerPadding + 16)
                    .padding(.bottom, layout.outerPadding + 16)
            }
            .background(settings.colors.window)
        }
        .sheet(isPresented: $workspace.showsQuickSwitcher) {
            XGlassQuickSwitcher()
        }
    }
}
