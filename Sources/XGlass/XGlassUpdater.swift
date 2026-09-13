import AppKit
import Sparkle

/// Owns Sparkle for the process lifetime and exposes the menu action used by SwiftUI.
@MainActor
final class XGlassAppDelegate: NSObject, NSApplicationDelegate {
    private let updaterController: SPUStandardUpdaterController
    private let windowLaunchController = XGlassWindowLaunchController()

    override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowLaunchController.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        windowLaunchController.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowLaunchController.stop()
    }
}
