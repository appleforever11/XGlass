import AppKit
import WebKit

extension XBrowserModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let requestedRoute = pendingNavigationRoute ?? lastRequestedRoute
        cancelPendingNavigation()
        statusMessage = requestedRoute.map { "X could not finish loading \($0.rawValue)." } ?? error.localizedDescription
        canRetry = requestedRoute != nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let requestedRoute = pendingNavigationRoute ?? lastRequestedRoute
        cancelPendingNavigation()
        statusMessage = requestedRoute.map { "X could not finish loading \($0.rawValue)." } ?? error.localizedDescription
        canRetry = requestedRoute != nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        statusMessage = nil
        canRetry = false
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
