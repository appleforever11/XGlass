import SwiftUI
import WebKit

@MainActor
extension XBrowserModel {
    func findInPage(backwards: Bool = false) {
        guard let webView else { return }
        findGeneration = UUID()
        let generation = findGeneration
        let configuration = WKFindConfiguration()
        configuration.backwards = backwards
        configuration.wraps = true
        webView.find(findQuery, configuration: configuration) { [weak self] result in
            guard let self, self.findGeneration == generation else { return }
            self.findMatch = self.findQuery.isEmpty ? nil : result.matchFound
        }
    }

    func closeFindBar() {
        findQuery = ""
        findInPage()
        showsFindBar = false
        if let webView { webView.window?.makeFirstResponder(webView) }
    }
}

struct XGlassFindBar: View {
    @ObservedObject var browser: XBrowserModel
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").accessibilityHidden(true)
            TextField("Find in page", text: $browser.findQuery)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { browser.findInPage() }
            if browser.findMatch == false && !browser.findQuery.isEmpty {
                Text("No matches").font(.caption).foregroundStyle(.secondary)
            }
            Button { browser.findInPage(backwards: true) } label: {
                Image(systemName: "chevron.up")
            }.help("Previous match (⇧⌘G)").accessibilityLabel("Previous match")
            Button { browser.findInPage() } label: {
                Image(systemName: "chevron.down")
            }.help("Next match (⌘G)").accessibilityLabel("Next match")
            Button("Done", action: browser.closeFindBar)
        }
        .padding(8)
        .background(.bar)
        .onAppear { focused = true }
        .onExitCommand(perform: browser.closeFindBar)
        .task(id: browser.findQuery) {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            browser.findInPage()
        }
    }
}
