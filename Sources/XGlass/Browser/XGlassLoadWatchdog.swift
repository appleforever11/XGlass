import WebKit

/// One delayed probe per navigation, with a deadline even if WebKit stops responding.
@MainActor
final class XGlassLoadWatchdog {
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private let probeDelay: Duration

    init(probeDelay: Duration = .seconds(15)) {
        self.probeDelay = probeDelay
    }

    static let readinessScript = #"""
    (() => {
      const visible = node => node && node.getClientRects().length > 0;
      if (visible(document.querySelector('input[type="password"], input[autocomplete="one-time-code"]'))) return true;
      const main = document.querySelector('[data-testid="primaryColumn"], main, [role="main"]');
      if (!main) return false;
      const statusID = location.pathname.match(/\/status\/(\d+)/)?.[1];
      if (statusID) return Array.from(main.querySelectorAll('article')).some(article =>
        visible(article) && article.querySelector(`a[href*="/status/${statusID}"]`));
      if (Array.from(main.querySelectorAll('article, [data-testid="tweet"]')).some(visible)) return true;
      if (Array.from(main.querySelectorAll('[role="progressbar"]')).some(visible)) return false;
      return visible(main) && main.innerText.trim().length > 40 &&
        Boolean(main.querySelector('button, a, [role="button"]'));

    })();
    """#

    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
    }

    func start(in webView: WKWebView, ready: @escaping @MainActor () -> Void = {}, stalled: @escaping @MainActor () -> Void) {
        cancel()
        let id = generation
        task = Task { @MainActor [weak self, weak webView] in
            guard let delay = self?.probeDelay else { return }
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, let webView, self.generation == id else { return }
            webView.evaluateJavaScript(Self.readinessScript) { [weak self] result, _ in
                guard let self, self.generation == id else { return }
                self.cancel()
                if result as? Bool == true { ready() } else { stalled() }
            }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, self.generation == id else { return }
            self.cancel()
            stalled()
        }
    }

    deinit { task?.cancel() }
}
