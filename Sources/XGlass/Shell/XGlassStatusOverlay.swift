import SwiftUI

struct XGlassStatusOverlay: View {
    @ObservedObject var browser: XBrowserModel
    let colors: XGlassThemeColors

    var body: some View {
        if let message = browser.statusMessage {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: browser.canRetry ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(browser.canRetry ? .orange : colors.accent)
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { browser.statusMessage = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain)
                        .help("Dismiss notification")
                        .accessibilityLabel("Dismiss notification")
                }
                if browser.canRetry {
                    HStack {
                        Button("Retry", action: browser.retryLastNavigation)
                            .buttonStyle(.borderedProminent)
                        Button("Open in Browser", action: browser.openCurrentPageInBrowser)
                            .buttonStyle(.bordered)
                    }.controlSize(.small)
                    Button("Restart Web Session", action: browser.restartWebSession)
                        .controlSize(.small)
                    if !browser.compatibilityMode {
                        Button("Retry with Standard Appearance", action: browser.retryWithStandardAppearance)
                            .controlSize(.small)
                            .help("Reload without XGlass page styling, keeping your sign-in and preferences")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(colors.stroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            .frame(maxWidth: 400)
            .task(id: message) {
                guard !browser.canRetry else { return }
                try? await Task.sleep(for: .seconds(4))
                if !Task.isCancelled && browser.statusMessage == message { browser.statusMessage = nil }
            }
        }
    }
}
