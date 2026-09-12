import SwiftUI

struct XGlassBrowserToolbar: View {
    @ObservedObject var browser: XBrowserModel
    @ObservedObject var settings: XGlassSettingsStore
    @EnvironmentObject private var workspace: XGlassWorkspaceState
    let isCompact: Bool

    private var colors: XGlassThemeColors { settings.colors }
    private var displayTitle: String {
        browser.title.replacingOccurrences(of: #"^\(\d+\)\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: " / X", with: "")
    }

    var body: some View {
        HStack(spacing: 4) {
            XGlassToolbarButton(title: "Back", systemImage: "chevron.left", colors: colors, isEnabled: browser.canGoBack, action: browser.goBack)
            XGlassToolbarButton(title: "Forward", systemImage: "chevron.right", colors: colors, isEnabled: browser.canGoForward, action: browser.goForward)
            XGlassToolbarButton(title: browser.isLoading ? "Stop" : "Reload", systemImage: browser.isLoading ? "xmark" : "arrow.clockwise", colors: colors, action: browser.isLoading ? browser.stopLoading : browser.reload)
            Text(displayTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colors.text)
                .lineLimit(1)
                .padding(.leading, 8)
                .accessibilityLabel("Current page, \(displayTitle)")
            if browser.loadState == "Loading" && !browser.isLoading {
                ProgressView().controlSize(.small)
                    .help("Waiting for X to show page content")
                    .accessibilityLabel("Loading page content")
            }
            if let progress = browser.imageDownloadStatus {
                Text(progress).font(.caption).lineLimit(1).accessibilityLabel(progress)
            }
            Spacer(minLength: 8)
            if workspace.isFocused {
                XGlassToolbarButton(title: "Exit Focus Mode", systemImage: "sidebar.leading", colors: colors) {
                    workspace.isFocused = false
                }
            }
            XGlassToolbarButton(title: "Quick Switcher", systemImage: "magnifyingglass", colors: colors) {
                workspace.showsQuickSwitcher = true
            }
            if !isCompact {
                XGlassToolbarButton(title: "Copy Page Link", systemImage: "link", colors: colors, action: browser.copyCurrentPageLink)
            }
            Menu {
                Button("Open in Browser", systemImage: "safari", action: browser.openCurrentPageInBrowser)
                Button("Find in Page", systemImage: "doc.text.magnifyingglass") { browser.showsFindBar = true }
                Button("Copy Page Link", systemImage: "link", action: browser.copyCurrentPageLink)
                Divider()
                Toggle("Focus Mode", isOn: $workspace.isFocused)
                Menu("Feed Width") {
                    Picker("Feed Width", selection: Binding(get: { settings.feedWidth }, set: settings.setFeedWidth)) {
                        ForEach(XGlassFeedWidth.allCases) { Text($0.title).tag($0) }
                    }
                }
                Menu("Page Size") {
                    ForEach([80, 90, 100, 110, 120, 130, 140], id: \.self) { value in
                        Button("\(value)%", systemImage: Int((settings.pageZoom * 100).rounded()) == value ? "checkmark" : "textformat.size") {
                            settings.setPageZoom(Double(value) / 100)
                        }
                    }
                }
                Divider()
                SettingsLink { Label("XGlass Settings...", systemImage: "gearshape") }
                Button("X Account Settings", systemImage: "person.crop.circle") { browser.navigate(to: .settings) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 30, height: 30)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Page Options")
            .accessibilityLabel("Page Options")
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(colors.window.opacity(0.44))
        .overlay(alignment: .bottomLeading) {
            if browser.isLoading {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(colors.accent)
                        .frame(width: max(24, proxy.size.width * browser.estimatedProgress), height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
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
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .foregroundStyle(isEnabled ? colors.text : colors.secondaryText.opacity(0.42))
        .background(isHovering && isEnabled ? colors.selected.opacity(0.65) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering = $0 }
        .help(title)
        .accessibilityLabel(title)
    }
}
