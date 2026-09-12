import SwiftUI

struct XGlassCommands: Commands {
    @ObservedObject var browser: XBrowserModel
    @ObservedObject var settings: XGlassSettingsStore
    @ObservedObject var workspace: XGlassWorkspaceState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Post") { browser.navigate(to: .compose) }
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        CommandGroup(after: .toolbar) {
            Button("Quick Switcher") { workspace.showsQuickSwitcher = true }
                .keyboardShortcut("k", modifiers: .command)
            Toggle("Focus Mode", isOn: $workspace.isFocused)
                .keyboardShortcut("f", modifiers: [.command, .shift])
            Toggle("Show Browser Toolbar", isOn: Binding(
                get: { settings.showBrowserToolbar }, set: settings.setShowBrowserToolbar
            ))
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Divider()
            Button("Zoom In") { settings.setPageZoom(settings.pageZoom + 0.1) }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(settings.pageZoom >= XGlassReadingScale.range.upperBound)
            Button("Zoom Out") { settings.setPageZoom(settings.pageZoom - 0.1) }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(settings.pageZoom <= XGlassReadingScale.range.lowerBound)
            Button("Actual Size") { settings.setPageZoom(1) }
                .keyboardShortcut("0", modifiers: .command)
        }
        CommandGroup(after: .textEditing) {
            Button("Find in Page") { browser.showsFindBar = true }
                .keyboardShortcut("f", modifiers: .command)
            Button("Find Next") { browser.findInPage() }
                .keyboardShortcut("g", modifiers: .command).disabled(browser.findQuery.isEmpty)
            Button("Find Previous") { browser.findInPage(backwards: true) }
                .keyboardShortcut("g", modifiers: [.command, .shift]).disabled(browser.findQuery.isEmpty)
        }
        CommandMenu("Navigation") {
            Button("Back", action: browser.goBack)
                .keyboardShortcut("[", modifiers: .command).disabled(!browser.canGoBack)
            Button("Forward", action: browser.goForward)
                .keyboardShortcut("]", modifiers: .command).disabled(!browser.canGoForward)
            Button("Reload", action: browser.reload).keyboardShortcut("r", modifiers: .command)
            Button("Reload from Origin", action: browser.retryLastNavigation)
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
            ForEach(Array([XRoute.home, .explore, .notifications, .messages, .bookmarks, .lists, .profile].enumerated()), id: \.element.id) { index, route in
                Button(route == .profile ? "Your Profile" : route.rawValue) { browser.navigate(to: route) }
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
            }
            Divider()
            Button("Copy Page Link", action: browser.copyCurrentPageLink)
                .keyboardShortcut("c", modifiers: [.command, .shift])
            Button("Open in Browser", action: browser.openCurrentPageInBrowser)
            Button("X Account Settings") { browser.navigate(to: .settings) }
        }
        CommandMenu("Tools") {
            Button("Restart Web Session", action: browser.restartWebSession)
            Button("Run Interface Health Check", action: browser.runInterfaceHealthCheck)
                .keyboardShortcut("i", modifiers: [.command, .option])
            Button("Retry Last Navigation", action: browser.retryLastNavigation).disabled(!browser.canRetry)
        }
    }
}
