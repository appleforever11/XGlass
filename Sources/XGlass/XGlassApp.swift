import SwiftUI

@main
struct XGlassApp: App {
    @NSApplicationDelegateAdaptor(XGlassAppDelegate.self) private var appDelegate
    @StateObject private var browser = XBrowserModel()

    var body: some Scene {
        WindowGroup {
            XGlassRootView()
                .environmentObject(browser)
                .frame(minWidth: 600, minHeight: 480)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 820)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appDelegate.checkForUpdates()
                }
            }

            CommandGroup(replacing: .newItem) {
                Button("New Post") {
                    browser.navigate(to: XRoute.compose.url)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("Navigation") {
                Button("Back") {
                    browser.goBack()
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!browser.canGoBack)

                Button("Forward") {
                    browser.goForward()
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!browser.canGoForward)

                Button("Reload") {
                    browser.reload()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Home") {
                    browser.navigate(to: XRoute.home.url)
                }
                .keyboardShortcut("1", modifiers: .command)
            }
        }
    }
}
