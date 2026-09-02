import SwiftUI

struct XGlassStatusOverlay: View {
    @ObservedObject var browser: XBrowserModel
    let colors: XGlassThemeColors

    var body: some View {
        if let message = browser.statusMessage {
            HStack(spacing: 9) {
                Image(systemName: browser.canRetry ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .foregroundStyle(browser.canRetry ? .orange : colors.accent)

                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)

                if browser.canRetry {
                    Button("Retry", action: browser.retryLastNavigation)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Button("Home") { browser.navigate(to: .home) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
        }
    }
}
