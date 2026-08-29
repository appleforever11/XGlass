import AppKit
import Combine
import WebKit

@MainActor
final class XBrowserModel: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var estimatedProgress = 0.0
    @Published var title = "X"
    @Published var currentURL = XRoute.home.url
    @Published var activeRoute = XRoute.home
    @Published var statusMessage: String?

    private weak var webView: WKWebView?
    private var observations: [NSKeyValueObservation] = []
    private var pendingNavigationID: UUID?
    private var pendingNavigationRoute: XRoute?
    private var pendingNavigationTask: Task<Void, Never>?

    deinit {
        pendingNavigationTask?.cancel()
    }

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }

        observations.removeAll()
        self.webView = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true

        observations = [
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in self?.canGoBack = webView.canGoBack }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in self?.canGoForward = webView.canGoForward }
            },
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in self?.isLoading = webView.isLoading }
            },
            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in self?.estimatedProgress = webView.estimatedProgress }
            },
            webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in self?.title = webView.title ?? "X" }
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    if let url = webView.url {
                        self?.currentURL = url
                        if let route = XRoute.match(url: url) {
                            self?.activeRoute = route
                            if let self, self.pendingNavigationRoute == route {
                                self.completeNavigation()
                            }
                        }
                    }
                }
            }
        ]
    }

    func loadInitialPageIfNeeded() {
        guard let webView, webView.url == nil else { return }
        webView.load(URLRequest(url: XRoute.home.url))
    }

    func navigate(to url: URL) {
        cancelPendingNavigation()
        webView?.load(URLRequest(url: url))
    }

    func navigate(to route: XRoute) {
        guard let webView else { return }

        let navigationID = UUID()
        pendingNavigationID = navigationID
        pendingNavigationRoute = route
        pendingNavigationTask?.cancel()
        statusMessage = nil

        if route == .profile {
            navigateToOwnProfile(using: webView, navigationID: navigationID)
            return
        }

        let paths = route == .messages ? ["/i/chat", "/messages"] : [route.url.path]
        let pathsJSON = paths.map { String(reflecting: $0) }.joined(separator: ", ")
        let script = """
        (() => {
          const desiredPaths = [\(pathsJSON)];
          const links = Array.from(document.querySelectorAll('a[href]'));
          const link = links.find((candidate) => {
            try {
              return desiredPaths.includes(new URL(candidate.href, window.location.origin).pathname);
            } catch (_) {
              return false;
            }
          });
          if (!link) return false;
          link.click();
          return true;
        })();
        """

        webView.evaluateJavaScript(script) { [weak self, webView] result, _ in
            Task { @MainActor in
                guard let self,
                      self.webView === webView,
                      self.pendingNavigationID == navigationID else { return }

                if result as? Bool != true {
                    webView.load(URLRequest(url: route.url))
                    self.watchNavigation(
                        id: navigationID,
                        route: route,
                        webView: webView,
                        allowDirectRetry: false
                    )
                }
            }
        }

        watchNavigation(
            id: navigationID,
            route: route,
            webView: webView,
            allowDirectRetry: true
        )
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func stopLoading() {
        webView?.stopLoading()
    }

    func openCurrentPageInBrowser() {
        NSWorkspace.shared.open(currentURL)
    }

    func navigateToOwnProfile() {
        guard let webView else { return }
        let navigationID = UUID()
        pendingNavigationID = navigationID
        pendingNavigationRoute = .profile
        pendingNavigationTask?.cancel()
        statusMessage = nil
        navigateToOwnProfile(using: webView, navigationID: navigationID)
    }

    private func navigateToOwnProfile(using webView: WKWebView, navigationID: UUID) {

        watchNavigation(
            id: navigationID,
            route: .profile,
            webView: webView,
            allowDirectRetry: false
        )

        let script = """
        (() => {
          const selectors = [
            'a[data-testid="AppTabBar_Profile_Link"]',
            'a[href^="/"][role="link"][aria-label*="Profile"]',
            'a[href^="/"][role="link"][data-testid*="profile"]'
          ];
          for (const selector of selectors) {
            const node = document.querySelector(selector);
            const href = node?.getAttribute('href');
            if (href && href.startsWith('/')) {
              node.click();
              return true;
            }
          }
          return false;
        })();
        """

        webView.evaluateJavaScript(script) { [weak self, webView] result, _ in
            Task { @MainActor in
                guard let self,
                      self.webView === webView,
                      self.pendingNavigationID == navigationID else { return }

                if result as? Bool != true {
                    webView.load(URLRequest(url: XRoute.home.url))
                    self.statusMessage = "Your profile link was not available, so XGlass returned to Home."
                }

            }
        }
    }

    private func watchNavigation(
        id: UUID,
        route: XRoute,
        webView: WKWebView,
        allowDirectRetry: Bool
    ) {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = Task { @MainActor [weak self, webView] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled, let self,
                  self.pendingNavigationID == id,
                  self.webView === webView else { return }

            if allowDirectRetry {
                webView.load(URLRequest(url: route.url))
                self.watchNavigation(
                    id: id,
                    route: route,
                    webView: webView,
                    allowDirectRetry: false
                )
                return
            }

            self.pendingNavigationTask?.cancel()
            self.pendingNavigationTask = nil
            self.pendingNavigationID = nil
            self.pendingNavigationRoute = nil
            self.statusMessage = "X could not finish loading \(route.rawValue). Returned to Home."
            if route != .home {
                webView.load(URLRequest(url: XRoute.home.url))
            }
        }
    }

    private func completeNavigation() {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
        statusMessage = nil
    }

    private func cancelPendingNavigation() {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
    }
}

extension XBrowserModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cancelPendingNavigation()
        statusMessage = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        cancelPendingNavigation()
        statusMessage = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        statusMessage = nil
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

extension XBrowserModel: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
