import AppKit
import Combine
import WebKit
import Network


@MainActor
final class XBrowserModel: NSObject, ObservableObject {
    @Published var imageDownloadStatus: String?
    @Published var webViewID = UUID()
    @Published var showsFindBar = false
    @Published var findQuery = ""
    @Published var findMatch: Bool?
    var findGeneration = UUID()
    @Published var unreadState = XGlassUnreadState()
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
    let loadWatchdog = XGlassLoadWatchdog()
    @Published var loadState = "Starting"
    @Published var compatibilityMode = false
    var requestedURL: URL?
    var recoveryAttempts = 0
    var hasUnsavedDraft: Bool?
    var draftCheckID: UUID?
    var healthCheckID: UUID?
    var loadStartedAt = Date()
    @Published var diagnosticEvents: [String] = []
    let networkMonitor = NWPathMonitor()
    var networkAvailable = true
    var loadGeneration = UUID()
    var readinessTask: Task<Void, Never>?
    var lifecycleObservers: [NSObjectProtocol] = []
    var navigationFailureTask: Task<Void, Never>?
    var activeNavigationID: ObjectIdentifier?
    var ignoredNavigationIDs = Set<ObjectIdentifier>()

    override init() {
        super.init()
        imageSaver.progressHandler = { [weak self] in self?.imageDownloadStatus = $0 }
        imageSaver.statusHandler = { [weak self] message in
            self?.statusMessage = message
        }
    }

    deinit {
        pendingNavigationTask?.cancel()
        navigationFailureTask?.cancel()
    }

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }

        observations.removeAll()
        self.webView = webView
        activeNavigationID = nil
        ignoredNavigationIDs.removeAll()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        installLifecycleMonitoring()
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
                        webView.evaluateJavaScript("window.__xglassRefreshUnread?.()", completionHandler: nil)
                        self.requestedURL = url
                        self.recoveryAttempts = 0
                        self.monitorPageReadiness(in: webView)
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
        let destination = requestedURL ?? XRoute.home.url
        lastRequestedRoute = XRoute.match(url: destination)
        webView.load(URLRequest(url: destination))
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
        requestedURL = url
        webView.load(URLRequest(url: url))
    }

    func navigate(to route: XRoute) {
        loadWatchdog.cancel()
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

        monitorPageReadiness(in: webView)

        if route == .lists {
            navigateToOwnLists(using: webView, navigationID: navigationID)
            return
        }

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
                        webView: webView
                    )
                }
            }
        }

        watchNavigation(
            id: navigationID,
            route: route,
            webView: webView
        )
    }

    func goBack() {
        cancelPendingNavigation()
        statusMessage = nil
        canRetry = false
        webView?.goBack()
    }

    func goForward() {
        cancelPendingNavigation()
        statusMessage = nil
        canRetry = false
        webView?.goForward()
    }

    func reload() {
        cancelPendingNavigation()
        canRetry = false
        statusMessage = nil
        guard let webView else { return }
        protectDraft(in: webView) { [weak webView] in webView?.reload() }
    }

    func stopLoading() {
        cancelPendingNavigation()
        loadWatchdog.cancel()
        webView?.stopLoading()
        loadState = "Stopped"
        canRetry = true
        statusMessage = "Loading stopped. Retry when you’re ready."
    }

    func copyCurrentPageLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentURL.absoluteString, forType: .string)
        statusMessage = "Page link copied"
    }

    func openCurrentPageInBrowser() {
        NSWorkspace.shared.open(currentURL)
    }

    func navigateToOwnProfile() {
        loadWatchdog.cancel()
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
        monitorPageReadiness(in: webView)
        navigateToOwnProfile(using: webView, navigationID: navigationID)
    }

    private func navigateToOwnLists(using webView: WKWebView, navigationID: UUID) {
        let script = """
        (() => {
          const profile = document.querySelector('a[data-testid="AppTabBar_Profile_Link"]');
          if (!profile) return null;
          const url = new URL(profile.href, window.location.origin);
          url.pathname = url.pathname.replace(/\\/$/, '') + '/lists';
          url.search = '';
          url.hash = '';
          return url.href;
        })();
        """
        webView.evaluateJavaScript(script) { [weak self, webView] result, _ in
            Task { @MainActor in
                guard let self, self.webView === webView,
                      self.pendingNavigationID == navigationID else { return }
                guard let value = result as? String, let url = URL(string: value),
                      url.host == "x.com", XRoute.match(url: url) == .lists else {
                    self.cancelPendingNavigation()
                    self.statusMessage = "Your Lists link is not available. Open Home and try again."
                    self.canRetry = true
                    return
                }
                webView.load(URLRequest(url: url))
                self.watchNavigation(id: navigationID, route: .lists, webView: webView)
            }
        }
    }

    private func navigateToOwnProfile(using webView: WKWebView, navigationID: UUID) {

        watchNavigation(
            id: navigationID,
            route: .profile,
            webView: webView
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
        webView: WKWebView
    ) {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = Task { @MainActor [weak self, webView] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled, let self,
                  self.pendingNavigationID == id,
                  self.webView === webView else { return }

            if let url = webView.url, XRoute.match(url: url) == route {
                self.recordLoadEvent("Navigation \(route.rawValue) completed by URL")
                self.completeNavigation()
                return
            }

            // Home can remain on X's root URL while the SPA swaps the visible
            // timeline. A rendered primary column is enough to finish that
            // request; requiring a URL change here leaves a usable page with
            // a stale timeout banner. Keep the fallback scoped to Home so a
            // generic article cannot incorrectly satisfy Profile or Lists.
            let currentPath = webView.url?.path.lowercased() ?? ""
            let isHomeURL = currentPath == "/" || currentPath.hasPrefix("/home")
            if route == .home,
               isHomeURL,
               await XGlassPageProbe.readiness(in: webView) == true,
               !webView.isLoading,
               self.pendingNavigationID == id,
               self.webView === webView {
                self.recordLoadEvent("Navigation Home completed by content probe")
                self.completeNavigation()
                return
            }

            self.pendingNavigationTask?.cancel()
            self.pendingNavigationTask = nil
            self.pendingNavigationID = nil
            self.pendingNavigationRoute = nil
            self.statusMessage = "X could not finish loading \(route.rawValue). Retry when you are ready."
            self.canRetry = true
        }
    }

    private func completeNavigation() {
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        navigationFailureTask?.cancel()
        navigationFailureTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
        statusMessage = nil
        canRetry = false
    }

    func cancelPendingNavigation() {
        loadGeneration = UUID()
        readinessTask?.cancel()
        loadWatchdog.cancel()
        navigationFailureTask?.cancel()
        navigationFailureTask = nil
        pendingNavigationTask?.cancel()
        pendingNavigationTask = nil
        pendingNavigationID = nil
        pendingNavigationRoute = nil
        if let activeNavigationID {
            ignoredNavigationIDs.insert(activeNavigationID)
            if ignoredNavigationIDs.count > 32 { ignoredNavigationIDs.removeFirst() }
            self.activeNavigationID = nil
        }
    }
}
