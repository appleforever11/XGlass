import SwiftUI

@main
struct XGlassApp: App {
    @NSApplicationDelegateAdaptor(XGlassAppDelegate.self) private var appDelegate
    @StateObject private var browser = XBrowserModel()
    @StateObject private var settings = XGlassSettingsStore()

    var body: some Scene {
        WindowGroup {
            XGlassRootView()
                .environmentObject(browser)
                .environmentObject(settings)
                .frame(minWidth: 600, minHeight: 480)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(
            width: XGlassStartupWindowFrame.preferredWidth,
            height: XGlassStartupWindowFrame.preferredHeight
        )
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appSettings) {
                Divider()

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

                Button("Explore") {
                    browser.navigate(to: .explore)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Notifications") {
                    browser.navigate(to: .notifications)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Messages") {
                    browser.navigate(to: .messages)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Bookmarks") {
                    browser.navigate(to: .bookmarks)
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("Lists") {
                    browser.navigate(to: .lists)
                }
                .keyboardShortcut("6", modifiers: .command)

                Button("Your Profile") {
                    browser.navigateToOwnProfile()
                }
                .keyboardShortcut("7", modifiers: .command)

                Button("Retry Last Navigation") {
                    browser.retryLastNavigation()
                }
                .disabled(!browser.canRetry)

                Divider()

                Button("Run Interface Health Check") {
                    browser.runInterfaceHealthCheck()
                }

                Divider()

                Toggle("Show Browser Toolbar", isOn: Binding(
                    get: { settings.showBrowserToolbar },
                    set: { settings.setShowBrowserToolbar($0) }
                ))
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            CommandMenu("XGlass") {
                Button("Run Interface Health Check") {
                    browser.runInterfaceHealthCheck()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])

                Button("Retry Last Navigation") {
                    browser.retryLastNavigation()
                }
                .disabled(!browser.canRetry)
            }
        }

        Settings {
            XGlassSettingsView()
                .environmentObject(browser)
                .environmentObject(settings)
        }
        .defaultSize(width: 1040, height: 720)
        .windowResizability(.contentMinSize)
    }
}
