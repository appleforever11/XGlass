import AppKit
import SwiftUI

struct XGlassSettingsGroup<Content: View>: View {
    @EnvironmentObject private var settings: XGlassSettingsStore

    let title: String
    let footer: String?
    let content: () -> Content

    init(title: String, footer: String?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Divider().overlay(settings.colors.stroke.opacity(0.6)) }

            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }
        }
    }
}

@MainActor
struct XGlassSettingsWindowConfigurator: NSViewRepresentable {
    let color: Color

    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

    func updateNSView(_ view: NSView, context: Context) {
        configure(window: view.window)
        DispatchQueue.main.async { [weak view] in
            configure(window: view?.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.title = "XGlass Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor.windowBackgroundColor
        window.hasShadow = true
        window.minSize = NSSize(width: 760, height: 600)
    }
}
