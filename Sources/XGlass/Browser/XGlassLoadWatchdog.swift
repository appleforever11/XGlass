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
      const visible = node => {
        if (!node || !node.getClientRects().length) return false;
        for (let parent = node; parent; parent = parent.parentElement) {
          const style = getComputedStyle(parent);
          if (parent.hidden || style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;
        }
        return true;
      };
      const loadedMedia = node => {
        if (!node || !visible(node)) return false;
        const tag = node.tagName?.toLowerCase();
        if (tag === 'img') return node.complete && node.naturalWidth > 0;
        return true;
      };
      if (visible(document.querySelector('input[type="password"], input[autocomplete="one-time-code"], input[autocomplete="username"]'))) return true;
      const main = document.querySelector('[data-testid="primaryColumn"], main, [role="main"]');
      const statusID = location.pathname.match(/\/status\/(\d+)/)?.[1];
      if (statusID) {
        const exactPost = main && Array.from(main.querySelectorAll('article')).some(article =>
          visible(article) && Array.from(article.querySelectorAll('a[href]')).some(link => {
            try { return new URL(link.href, location.href).pathname.match(/\/status\/(\d+)(?:\/|$)/)?.[1] === statusID; }
            catch (_) { return false; }
          }));
        if (exactPost) return true;

        // X renders photo/video lightboxes outside the primary article. The
        // URL is already on the requested status, so a visible loaded media
        // surface is a valid terminal state even when the modal has no post
        // link in its accessibility tree.
        const modal = document.querySelector('[role="dialog"], [aria-modal="true"], [data-testid*="photoModal"], [data-testid*="mediaModal"]');
        if (modal && visible(modal)) {
          if (Array.from(modal.querySelectorAll('[role="progressbar"]')).some(visible)) return false;
          if (Array.from(modal.querySelectorAll('img, video, canvas, [role="img"]')).some(loadedMedia)) return true;
          if (modal.innerText.trim().length > 20 && Array.from(modal.querySelectorAll('button, a, [role="button"]')).some(visible)) return true;
        }

        // Some X builds use a full-page media surface without a dialog role.
        // Limit this fallback to media URLs so a stale image from a previous
        // page cannot satisfy an exact post request.
        const mediaPath = /\/(?:photo|video|media)(?:\/|$)/.test(location.pathname);
        if (mediaPath) {
          const visibleMedia = Array.from(document.querySelectorAll('img, video, canvas, [role="img"]')).some(loadedMedia);
          const renderedStatusSurface = document.body.innerText.trim().length > 20 &&
            Array.from(document.querySelectorAll('button, a, [role="button"]')).some(visible);
          const visibleProgress = Array.from(document.querySelectorAll('[role="progressbar"]')).some(visible);
          const visibleFailure = Array.from(document.querySelectorAll('[role="alert"], [data-testid*="error"]')).some(visible);
          if (!visibleFailure && !visibleProgress && (visibleMedia || renderedStatusSurface)) return true;
        }
        return false;
      }
      if (!main) return false;
      if (Array.from(main.querySelectorAll('article, [data-testid="tweet"], [data-testid="emptyState"]')).some(visible)) return true;
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
