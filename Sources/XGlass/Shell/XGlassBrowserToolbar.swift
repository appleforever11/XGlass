import SwiftUI

struct XGlassBrowserToolbar: View {
    @ObservedObject var browser: XBrowserModel
    let colors: XGlassThemeColors
    let glassIntensity: Double
    let isCompact: Bool

    private var displayTitle: String {
        browser.title.replacingOccurrences(
            of: #"^\(\d+\)\s*"#,
            with: "",
            options: .regularExpression
        )
    }

    var body: some View {
        HStack(spacing: isCompact ? 6 : 10) {
            HStack(spacing: 2) {
                XGlassToolbarButton(
                    title: "Back",
                    systemImage: "chevron.left",
                    colors: colors,
                    isEnabled: browser.canGoBack,
                    action: browser.goBack
                )
                XGlassToolbarButton(
                    title: "Forward",
                    systemImage: "chevron.right",
                    colors: colors,
                    isEnabled: browser.canGoForward,
                    action: browser.goForward
                )
                XGlassToolbarButton(
                    title: browser.isLoading ? "Stop" : "Reload",
                    systemImage: browser.isLoading ? "xmark" : "arrow.clockwise",
                    colors: colors,
                    action: browser.isLoading ? browser.stopLoading : browser.reload
                )
            }

            Spacer(minLength: 4)

            HStack(spacing: 7) {
                Image(systemName: browser.activeRoute.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colors.accent)

                Text(displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(colors.text)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current page, \(displayTitle)")

            Spacer(minLength: 4)

            if !isCompact {
                Text(browser.currentURL.host() ?? "x.com")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.card.opacity(0.36), in: Capsule())
                    .overlay(Capsule().stroke(colors.stroke.opacity(0.72), lineWidth: 1))
            }

            XGlassToolbarButton(
                title: "Open in Browser",
                systemImage: "safari",
                colors: colors,
                action: browser.openCurrentPageInBrowser
            )
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .background(colors.card.opacity(0.24 * glassIntensity))
        .overlay(alignment: .bottomLeading) {
            if browser.isLoading {
                GeometryReader { proxy in
                    Capsule()
                        .fill(colors.accent)
                        .frame(
                            width: min(proxy.size.width, max(24, proxy.size.width * browser.estimatedProgress)),
                            height: 2
                        )
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                        .animation(.easeOut(duration: 0.15), value: browser.estimatedProgress)
                }
                .accessibilityHidden(true)
            }
        }
    }
}

struct XGlassToolbarButton: View {
    let title: String
    let systemImage: String
    let colors: XGlassThemeColors
    var isEnabled = true
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .foregroundStyle(isEnabled ? colors.text : colors.secondaryText.opacity(0.42))
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovering && isEnabled ? colors.accent.opacity(0.12) : .clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isHovering && isEnabled ? colors.stroke.opacity(0.85) : .clear, lineWidth: 1)
        }
        .onHover { isHovering = $0 }
        .help(title)
        .accessibilityLabel(title)
    }
}
