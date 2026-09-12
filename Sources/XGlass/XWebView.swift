import AppKit
import SwiftUI
import WebKit

@MainActor
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var webView: XGlassWebView?

    init(webView: XGlassWebView) {
        self.webView = webView
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "xglassContextMenu" else { return }
        let imageURL = (message.body as? [String: Any])?["imageURL"] as? String
        webView?.recordContextImageURL(imageURL)
    }
}

@MainActor
final class XGlassWebView: WKWebView {
    var saveImageHandler: ((NSPoint) -> Void)?
    private var contextMenuLocation: NSPoint?
    private var observesMenus = false
    private(set) var contextImageURL: URL?
    var pauseMediaInBackground = true {
        didSet { if oldValue != pauseMediaInBackground { updateMediaSuspension() } }
    }
    private var mediaSuspended = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !observesMenus else { return }
        observesMenus = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuDidBeginTracking(_:)),
            name: NSMenu.didBeginTrackingNotification,
            object: nil
        )
        for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                     NSWindow.didDeminiaturizeNotification, NSApplication.didHideNotification,
                     NSApplication.didUnhideNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(windowVisibilityChanged(_:)), name: name, object: nil)
        }
        updateMediaSuspension()
    }

    @objc private func windowVisibilityChanged(_ notification: Notification) {
        if let changedWindow = notification.object as? NSWindow, changedWindow !== window { return }
        updateMediaSuspension()
    }

    private func updateMediaSuspension() {
        guard let window else { return }
        let suspended = pauseMediaInBackground &&
            (NSApp.isHidden || window.isMiniaturized || !window.occlusionState.contains(.visible))
        guard suspended != mediaSuspended else { return }
        mediaSuspended = suspended
        setAllMediaPlaybackSuspended(suspended, completionHandler: nil)
    }

    override func rightMouseDown(with event: NSEvent) {
        contextImageURL = nil
        contextMenuLocation = convert(event.locationInWindow, from: nil)
        super.rightMouseDown(with: event)
    }

    @objc private func menuDidBeginTracking(_ notification: Notification) {
        updateImageDownloadItem(in: notification.object as? NSMenu)
    }

    private func updateImageDownloadItem(in menu: NSMenu?) {
        guard let menu,
              let downloadItem = menu.items.first(where: {
                  $0.title.localizedCaseInsensitiveContains("download image")
              }) else {
            return
        }

        downloadItem.title = "Save Image..."
        downloadItem.target = self
        downloadItem.action = #selector(saveImageFromContextMenu(_:))
        if let contextMenuLocation {
            downloadItem.representedObject = NSValue(point: contextMenuLocation)
        }
    }

    func recordContextImageURL(_ imageURL: String?) {
        contextImageURL = imageURL.flatMap(URL.init(string:))
    }

    @objc private func saveImageFromContextMenu(_ sender: NSMenuItem) {
        guard let location = (sender.representedObject as? NSValue)?.pointValue else { return }
        saveImageHandler?(location)
    }
}

struct XWebView: NSViewRepresentable {
    @EnvironmentObject private var browser: XBrowserModel
    @EnvironmentObject private var settings: XGlassSettingsStore

    @MainActor
    final class Coordinator {
        private var lastCompatibilityMode: Bool?
        private var lastThemePayload: String?
        private var lastPreferencesPayload: String?

        func applySettings(
            to webView: WKWebView,
            themePayload: String,
            preferencesPayload: String,
            compatibilityMode: Bool
        ) {
            guard themePayload != lastThemePayload || preferencesPayload != lastPreferencesPayload || compatibilityMode != lastCompatibilityMode else {
                return
            }

            lastCompatibilityMode = compatibilityMode
            lastThemePayload = themePayload
            lastPreferencesPayload = preferencesPayload
            XGlassWebScriptInstaller.install(
                on: webView.configuration.userContentController,
                themePayload: themePayload,
                preferencesPayload: preferencesPayload, compatibilityMode: compatibilityMode
            )

            let script = """
            (() => {
              const theme = \(themePayload);
              const preferences = \(preferencesPayload);
              if (typeof window.__xglassSetTheme === 'function') window.__xglassSetTheme(theme);
              if (typeof window.__xglassSetPreferences === 'function') window.__xglassSetPreferences(preferences);
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        let webView = XGlassWebView(frame: .zero, configuration: configuration)
        configuration.userContentController.add(
            WeakScriptMessageHandler(webView: webView),
            name: "xglassContextMenu"
        )
        webView.underPageBackgroundColor = .clear
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        webView.setValue(false, forKey: "drawsBackground")
        configuration.userContentController.add(XGlassDraftMonitor(browser: browser), name: "xglassDraft")
        configuration.userContentController.add(XGlassUnreadMonitor(browser: browser), name: "xglassUnread")
        configuration.userContentController.add(XGlassLoadTelemetry(browser: browser), name: "xglassLoadTelemetry")
        browser.attach(webView)
        webView.pageZoom = settings.pageZoom
        webView.pauseMediaInBackground = settings.pauseMediaInBackground
        context.coordinator.applySettings(
            to: webView,
            themePayload: settings.javascriptThemePayload,
            preferencesPayload: settings.javascriptPreferencesPayload, compatibilityMode: browser.compatibilityMode
        )
        browser.loadInitialPageIfNeeded()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        browser.attach(nsView)
        if nsView.pageZoom != settings.pageZoom { nsView.pageZoom = settings.pageZoom }
        (nsView as? XGlassWebView)?.pauseMediaInBackground = settings.pauseMediaInBackground
        context.coordinator.applySettings(
            to: nsView,
            themePayload: settings.javascriptThemePayload,
            preferencesPayload: settings.javascriptPreferencesPayload, compatibilityMode: browser.compatibilityMode
        )
    }
}

private let minimumPaintInterval = 250
