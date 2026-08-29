import SwiftUI

struct XGlassRootView: View {
    @EnvironmentObject private var browser: XBrowserModel

    var body: some View {
        GeometryReader { proxy in
            let metrics = layoutMetrics(for: proxy.size.width)

            ZStack {
                AngularGradient(
                    colors: [
                        Color(red: 0.09, green: 0.10, blue: 0.13),
                        Color(red: 0.00, green: 0.45, blue: 0.60),
                        Color(red: 0.72, green: 0.12, blue: 0.42),
                        Color(red: 0.09, green: 0.10, blue: 0.13)
                    ],
                    center: .topLeading
                )
                .ignoresSafeArea()

                contentPanel(metrics: metrics)

                HStack(spacing: 0) {
                    sidebar(width: metrics.sidebarWidth, isCompact: metrics.isCompact)
                        .padding(.vertical, 14)
                        .padding(.leading, metrics.outerPadding)

                    Spacer()
                }
            }
            .background(.black)
            .overlay(alignment: .bottomTrailing) {
                if let statusMessage = browser.statusMessage {
                    Text(statusMessage)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private func contentPanel(metrics: LayoutMetrics) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color(red: 0.10, green: 0.34, blue: 0.38).opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

            VStack(spacing: 10) {
                titleBar(isCompact: metrics.isCompact)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                XWebView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 24, x: 0, y: 16)
        .padding(.leading, metrics.contentLeading)
        .padding(.top, 10)
        .padding(.trailing, metrics.outerPadding)
        .padding(.bottom, metrics.outerPadding)
    }

    private func titleBar(isCompact: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                controlButton("Back", systemImage: "chevron.left", isEnabled: browser.canGoBack) {
                    browser.goBack()
                }

                controlButton("Forward", systemImage: "chevron.right", isEnabled: browser.canGoForward) {
                    browser.goForward()
                }

                controlButton(browser.isLoading ? "Stop" : "Reload", systemImage: browser.isLoading ? "xmark" : "arrow.clockwise") {
                    browser.isLoading ? browser.stopLoading() : browser.reload()
                }
            }

            Text(browser.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                if !isCompact {
                    Text(browser.currentURL.host() ?? "x.com")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                controlButton("Open in Browser", systemImage: "safari") {
                    browser.openCurrentPageInBrowser()
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 42)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.10, green: 0.34, blue: 0.38).opacity(0.28))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.66, green: 0.90, blue: 0.87).opacity(0.12), lineWidth: 1)
                }
        }
        .overlay(alignment: .bottomLeading) {
            if browser.isLoading {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.72))
                        .frame(width: max(22, proxy.size.width * browser.estimatedProgress), height: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
    }

    private func sidebar(width: CGFloat, isCompact: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark")
                .font(.system(size: isCompact ? 19 : 23, weight: .bold))
                .frame(width: isCompact ? 42 : 48, height: isCompact ? 42 : 48)
                .foregroundStyle(.primary)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("XGlass")

            Divider()
                .overlay(.white.opacity(0.2))
                .padding(.vertical, 4)

            ForEach(primaryRoutes) { route in
                routeButton(route)
            }

            Spacer(minLength: 10)

            VStack(spacing: 10) {
                routeButton(.profile)
                routeButton(.settings)
            }

            Button {
                browser.navigate(to: .compose)
            } label: {
                Image(systemName: XRoute.compose.systemImage)
                    .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                    .frame(width: isCompact ? 42 : 48, height: isCompact ? 42 : 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .help("New Post")
        }
        .padding(isCompact ? 8 : 10)
        .frame(width: width)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private func routeButton(_ route: XRoute) -> some View {
        Button {
            browser.navigate(to: route)
        } label: {
            Image(systemName: route.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(browser.activeRoute == route ? .black : .primary)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(browser.activeRoute == route ? .white.opacity(0.92) : .white.opacity(0.001))
        }
        .help(route.rawValue)
    }

    private var primaryRoutes: [XRoute] {
        [.home, .explore, .notifications, .messages, .bookmarks, .lists]
    }

    private func controlButton(
        _ label: String,
        systemImage: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.38)
        .help(label)
    }

    private func layoutMetrics(for width: CGFloat) -> LayoutMetrics {
        let isCompact = width < 960
        let outerPadding: CGFloat = isCompact ? 12 : 18
        let sidebarWidth: CGFloat = isCompact ? 64 : 76
        let contentLeading = outerPadding + sidebarWidth + 8
        return LayoutMetrics(
            isCompact: isCompact,
            outerPadding: outerPadding,
            sidebarWidth: sidebarWidth,
            contentLeading: contentLeading
        )
    }
}

private struct LayoutMetrics {
    let isCompact: Bool
    let outerPadding: CGFloat
    let sidebarWidth: CGFloat
    let contentLeading: CGFloat
}
