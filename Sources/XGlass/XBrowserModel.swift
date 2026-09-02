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
    @Published var canRetry = false
    @Published var isRunningHealthCheck = false
    @Published var healthReport: XInterfaceHealthReport?

    weak var webView: WKWebView?
    private var observations: [NSKeyValueObservation] = []
    private var pendingNavigationID: UUID?
    var pendingNavigationRoute: XRoute?
    private var pendingNavigationTask: Task<Void, Never>?
    var lastRequestedRoute: XRoute?
    let imageSaver = XImageSaveCoordinator()

    override init() {
        super.init()
        imageSaver.statusHandler = { [weak self] message in
            self?.statusMessage = message
        }
    }

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
        if let xGlassWebView = webView as? XGlassWebView {
            imageSaver.attach(to: xGlassWebView)
        }

        observations = [
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self, self.canGoBack != webView.canGoBack else { return }
                    self.canGoBack = webView.canGoBack
                }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self, self.canGoForward != webView.canGoForward else { return }
                    self.canGoForward = webView.canGoForward
                }
            },
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self, self.isLoading != webView.isLoading else { return }
                    self.isLoading = webView.isLoading
                }
            },
            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self else { return }
                    let progress = webView.estimatedProgress
                    let isTerminalUpdate = progress <= 0.001 || progress >= 0.999
                    guard isTerminalUpdate || abs(progress - self.estimatedProgress) >= 0.02 else { return }
                    self.estimatedProgress = progress
                }
            },
            webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self else { return }
                    let title = webView.title ?? "X"
                    guard self.title != title else { return }
                    self.title = title
                }
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self, let url = webView.url else { return }
                    if self.currentURL != url {
                        self.currentURL = url
                    }
                    if let route = XRoute.match(url: url) {
                        if self.activeRoute != route {
                            self.activeRoute = route
                        }
                        if self.pendingNavigationRoute == route {
                            self.completeNavigation()
                        }
                    }
                }
            }
        ]
    }

    func loadInitialPageIfNeeded() {
        guard let webView, webView.url == nil else { return }
        lastRequestedRoute = .home
        webView.load(URLRequest(url: XRoute.home.url))
    }

    func navigate(to url: URL) {
        cancelPendingNavigation()
        lastRequestedRoute = XRoute.match(url: url)
        canRetry = false
        statusMessage = nil
        guard let webView else {
            statusMessage = "XGlass is still starting the X web session."
            canRetry = lastRequestedRoute != nil
            return
        }
        webView.load(URLRequest(url: url))
    }

    func navigate(to route: XRoute) {
        lastRequestedRoute = route
        canRetry = false
        guard let webView else {
            statusMessage = "XGlass is still starting the X web session."
            canRetry = true
            return
        }

        let navigationID = UUID()
        pendingNavigationID = navigationID
        pendingNavigationRoute = route
        pendingNavigationTask?.cancel()
        statusMessage = nil

        if route == .profile {
            navigateToOwnProfile(using: webView, navigationID: navigationID)
            return
        }

        let paths = route.navigationPaths
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
        canRetry = false
        webView?.goBack()
    }

    func goForward() {
        canRetry = false
        webView?.goForward()
    }

    func reload() {
        canRetry = false
        statusMessage = nil
        webView?.reload()
    }

    func stopLoading() {
        webView?.stopLoading()
    }

    func openCurrentPageInBrowser() {
        NSWorkspace.shared.open(currentURL)
    }

    func navigateToOwnProfile() {
        lastRequestedRoute = .profile
        canRetry = false
        guard let webView else {
            statusMessage = "XGlass is still starting the X web session."
            canRetry = true
            return
        }
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
            self.statusMessage = "X could not finish loading \(route.rawValue)."
            self.canRetry = true
        }
    }

    func retryLastNavigation() {
        guard let route = lastRequestedRoute else {
            reload()
            return
        }
        navigate(to: route)
    }


    private func completeNavigation() {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
        statusMessage = nil
        canRetry = false
    }

    func cancelPendingNavigation() {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
    }
}
