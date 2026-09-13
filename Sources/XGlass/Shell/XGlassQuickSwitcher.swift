import SwiftUI

struct XGlassQuickSwitcher: View {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore
    @EnvironmentObject private var workspace: XGlassWorkspaceState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    private var actions: [XGlassQuickAction] { XGlassQuickAction.matching(query) }
    private var searchURL: URL? { XGlassQuickAction.searchURL(for: query) }
    private var resultCount: Int { actions.count + (searchURL == nil ? 0 : 1) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundStyle(settings.colors.accent)
                TextField("Search X or jump to...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($searchFocused)
                    .onSubmit { activateSelection() }
                    .accessibilityLabel("Quick switcher search")
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).help("Close quick switcher").accessibilityLabel("Close quick switcher")
            }
            .padding(20)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                            resultRow(title: action.title, symbol: action.symbol, index: index) {
                                perform(action)
                            }
                        }
                        if let searchURL {
                            resultRow(title: "Search X for \u{201c}\(query)\u{201d}", symbol: "magnifyingglass", index: actions.count) {
                                browser.navigate(to: searchURL)
                                dismiss()
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(height: min(CGFloat(resultCount) * 43 + 20, 390))
                .onChange(of: selectedIndex) { _, index in proxy.scrollTo(index) }
            }
        }
        .frame(width: 480)
        .background(settings.colors.window)
        .foregroundStyle(settings.colors.text)
        .onAppear { searchFocused = true }
        .onChange(of: query) { _, _ in selectedIndex = 0 }
        .onKeyPress(.downArrow) {
            selectedIndex = min(selectedIndex + 1, resultCount - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(selectedIndex - 1, 0)
            return .handled
        }
        .onExitCommand { dismiss() }
    }

    private func resultRow(title: String, symbol: String, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 22).foregroundStyle(settings.colors.accent)
                Text(title).lineLimit(1)
                Spacer(minLength: 8)
                if selectedIndex == index { Image(systemName: "return").foregroundStyle(.secondary) }
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(selectedIndex == index ? settings.colors.selected : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(index)
    }

    private func activateSelection() {
        if actions.indices.contains(selectedIndex) {
            perform(actions[selectedIndex])
        } else if let searchURL {
            browser.navigate(to: searchURL)
            dismiss()
        }
    }

    private func perform(_ action: XGlassQuickAction) {
        if let route = action.route {
            browser.navigate(to: route)
        } else {
            switch action {
            case .focus: workspace.isFocused.toggle()
            case .copyLink: browser.copyCurrentPageLink()
            case .reload: browser.reload()
            case .settings: openSettings()
            default: break
            }
        }
        dismiss()
    }
}
