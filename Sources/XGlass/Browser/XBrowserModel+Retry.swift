import WebKit

@MainActor
extension XBrowserModel {
    func retryLastNavigation() { retryPage(usingStandardAppearance: false) }
    func retryWithStandardAppearance() { retryPage(usingStandardAppearance: true) }

    private func retryPage(usingStandardAppearance: Bool) {
        guard let webView else { return }
        protectDraft(in: webView) { [weak self, weak webView] in
            guard let self, let webView else { return }
            self.cancelPendingNavigation()
            if usingStandardAppearance {
                self.compatibilityMode = true
                // Install synchronously before loading; SwiftUI's next update is too late.
                let controller = webView.configuration.userContentController
                let scripts = controller.userScripts.filter {
                    !$0.source.contains("xglass-bootstrap-overrides") &&
                    !$0.source.contains("function applyOverrides(")
                }
                controller.removeAllUserScripts()
                scripts.forEach(controller.addUserScript)
            }
            self.recoveryAttempts += 1
            self.recordLoadEvent(usingStandardAppearance ? "Retry with standard appearance" : "Retry from origin")
            self.statusMessage = nil
            self.canRetry = false
            self.monitorPageReadiness(in: webView)
            let target = self.requestedURL ?? self.currentURL
            if webView.url == target {
                webView.reloadFromOrigin()
            } else {
                webView.load(Self.recoveryRequest(for: target))
            }
        }
    }

    func restartWebSession() {
        guard let webView else { return }
        protectDraft(in: webView) { [weak self, weak webView] in
            guard let self else { return }
            self.cancelPendingNavigation()
            self.requestedURL = self.requestedURL ?? self.currentURL
            webView?.stopLoading()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
            self.webView = nil
            self.unreadState = XGlassUnreadState()
            self.findMatch = nil
            self.recordLoadEvent("User restarted web view; existing data store retained")
            self.webViewID = UUID()
        }
    }

    static func recoveryRequest(for url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
    }
}
