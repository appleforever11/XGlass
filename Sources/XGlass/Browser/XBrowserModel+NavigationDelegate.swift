import AppKit
import WebKit

extension XBrowserModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hasUnsavedDraft = nil
        if let navigation {
            let identifier = ObjectIdentifier(navigation)
            ignoredNavigationIDs.remove(identifier)
            activeNavigationID = identifier
        }
        monitorPageReadiness(in: webView)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame, let response = navigationResponse.response as? HTTPURLResponse {
            recordLoadEvent("Document HTTP \(response.statusCode)")
        }
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        recordLoadEvent("Document committed")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadWatchdog.cancel()
        cancelPendingNavigation()
        recordLoadEvent("Web process terminated")
        loadState = "Failed"
        statusMessage = "The X web session stopped. Retry to reconnect. Unfinished writing in the stopped session may have been lost."
        canRetry = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(in: webView, navigation: navigation, error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationFailure(in: webView, navigation: navigation, error: error)
    }

    private func handleNavigationFailure(in webView: WKWebView, navigation: WKNavigation?, error: Error) {
        let errorCode = (error as NSError).code
        guard errorCode != NSURLErrorCancelled else { return }
        guard isCurrentNavigation(navigation) else {
            recordLoadEvent("Ignored stale navigation failure code \(errorCode)")
            return
        }

        loadWatchdog.cancel()
        let requestedRoute = pendingNavigationRoute ?? lastRequestedRoute
        let generation = loadGeneration
        navigationFailureTask?.cancel()
        navigationFailureTask = Task { @MainActor [weak self, weak webView] in
            guard let self, let webView else { return }
            let rendered = await XGlassPageProbe.readiness(in: webView)
            guard !Task.isCancelled,
                  self.webView === webView,
                  self.loadGeneration == generation,
                  self.isCurrentNavigation(navigation) else { return }

            self.navigationFailureTask = nil
            if rendered == true && !webView.isLoading {
                self.loadState = "Ready"
                self.statusMessage = nil
                self.canRetry = false
                self.recordLoadEvent("Navigation failure arrived after content rendered; keeping document")
                return
            }

            self.cancelPendingNavigation()
            self.statusMessage = requestedRoute.map { "X could not finish loading \($0.rawValue)." } ?? error.localizedDescription
            self.loadState = errorCode == NSURLErrorNotConnectedToInternet ? "Offline" : "Failed"
            self.recordLoadEvent("\(self.loadState): navigation error code \(errorCode)")
            self.canRetry = true
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recordLoadEvent("Document finished; awaiting rendered content")
        // Document completion does not imply that X has rendered the destination.
        // The existing content monitor owns completion and its original deadline.
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if navigationAction.targetFrame?.isMainFrame == true, isXWebURL(url) {
            requestedURL = url
        }
        if isXWebURL(url) || navigationAction.targetFrame?.isMainFrame != true {
            decisionHandler(.allow)
            return
        }

        NSWorkspace.shared.open(url)
        decisionHandler(.cancel)
    }

    private func isXWebURL(_ url: URL) -> Bool {
        guard let host = url.host(percentEncoded: false)?.lowercased() else { return false }
        return host == "x.com"
            || host.hasSuffix(".x.com")
            || host == "twitter.com"
            || host.hasSuffix(".twitter.com")
    }

    private func isCurrentNavigation(_ navigation: WKNavigation?) -> Bool {
        guard let navigation else { return true }
        let identifier = ObjectIdentifier(navigation)
        if ignoredNavigationIDs.contains(identifier) { return false }
        guard let activeNavigationID else { return true }
        return identifier == activeNavigationID
    }
}
