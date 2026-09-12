import AppKit
import WebKit

extension XBrowserModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hasUnsavedDraft = nil
        monitorPageReadiness(in: webView)
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
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        loadWatchdog.cancel()
        let requestedRoute = pendingNavigationRoute ?? lastRequestedRoute
        cancelPendingNavigation()
        statusMessage = requestedRoute.map { "X could not finish loading \($0.rawValue)." } ?? error.localizedDescription
        loadState = (error as NSError).code == NSURLErrorNotConnectedToInternet ? "Offline" : "Failed"
        recordLoadEvent(loadState)
        canRetry = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        loadWatchdog.cancel()
        let requestedRoute = pendingNavigationRoute ?? lastRequestedRoute
        cancelPendingNavigation()
        statusMessage = requestedRoute.map { "X could not finish loading \($0.rawValue)." } ?? error.localizedDescription
        loadState = (error as NSError).code == NSURLErrorNotConnectedToInternet ? "Offline" : "Failed"
        recordLoadEvent(loadState)
        canRetry = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
}
