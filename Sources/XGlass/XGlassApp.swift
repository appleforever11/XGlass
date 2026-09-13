import SwiftUI

@main
struct XGlassApp: App {
    @NSApplicationDelegateAdaptor(XGlassAppDelegate.self) private var appDelegate
    @StateObject private var browser = XBrowserModel()
    @StateObject private var settings = XGlassSettingsStore()
    @StateObject private var workspace = XGlassWorkspaceState()

    var body: some Scene {
        WindowGroup {
            XGlassRootView()
                .environmentObject(browser)
                .environmentObject(settings)
                .environmentObject(workspace)
                .frame(minWidth: 600, minHeight: 480)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: XGlassStartupWindowFrame.preferredWidth, height: XGlassStartupWindowFrame.preferredHeight)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appSettings) {
                Divider()
                Button("Check for Updates...") { appDelegate.checkForUpdates() }
            }
            XGlassCommands(browser: browser, settings: settings, workspace: workspace)
        }

        Settings {
            XGlassSettingsView()
                .environmentObject(browser)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1000, height: 740)
        .windowResizability(.contentMinSize)
    }
}
