import WebKit

@MainActor
final class XGlassUnreadMonitor: NSObject, WKScriptMessageHandler {
    weak var browser: XBrowserModel?
    init(browser: XBrowserModel) { self.browser = browser }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame,
              let host = message.frameInfo.request.url?.host,
              host == "x.com" || host.hasSuffix(".x.com") || host == "twitter.com" || host.hasSuffix(".twitter.com"),
              let json = message.body as? String, let data = json.data(using: .utf8),
              var value = try? JSONDecoder().decode(XGlassUnreadState.self, from: data) else { return }
        value.count = max(0, min(value.count, 9999))
        if browser?.unreadState != value { browser?.unreadState = value }
    }

    static let source = #"""
    (() => {
      if (window.__xglassUnreadInstalled) return;
      window.__xglassUnreadInstalled = true;
      const navSelector = 'a[data-testid="AppTabBar_Notifications_Link"], a[href="/notifications"]';
      const bannerSelector = 'button[aria-label^="New posts"], [role="button"][aria-label^="New posts"]';
      let timer = 0, previous = '';
      let tracked = [];
      function publish() {
        timer = 0;
        const link = document.querySelector(navSelector);
        if (!link && !location.pathname.startsWith('/i/flow/login') && !document.querySelector('input[type="password"]')) return;
        const labels = link ? [link.getAttribute('aria-label') || '',
          ...Array.from(link.querySelectorAll('[aria-label]'), n => n.getAttribute('aria-label') || '')] : [];
        const text = labels.join(' ');
        const match = text.match(/(\d+)\+?\s+unread/i);
        const numericBadge = link ? Array.from(link.querySelectorAll('span'), n => n.textContent.trim())
          .find(value => /^\d+\+?$/.test(value)) : null;
        // The title may lag or count other surfaces. The bell link owns notification state.
        const count = Number(match?.[1] || numericBadge?.replace('+', '') || 0);
        const banners = Array.from(document.querySelectorAll(bannerSelector + ', main button, main [role="button"]'))
          .filter(n => n.matches(bannerSelector) || /^Show \d+ posts$/i.test(n.textContent.trim()));
        tracked = [link, ...banners].filter(Boolean);
        const newPosts = Boolean(link && location.pathname === '/home' && banners.some(isVisiblePrompt));
        const value = JSON.stringify({ count, unread: count > 0 || /unread/i.test(text) && !/\b(?:0|no)\s+unread/i.test(text), newPosts });
        if (value === previous) return;
        previous = value;
        window.webkit?.messageHandlers?.xglassUnread?.postMessage(value);
      }
      function isVisiblePrompt(node) {
        const rect = node.getBoundingClientRect();
        if (rect.width < 4 || rect.height < 4 || rect.bottom <= 0 || rect.right <= 0 ||
            rect.top >= innerHeight || rect.left >= innerWidth) return false;
        for (let current = node; current; current = current.parentElement) {
          const style = getComputedStyle(current);
          if (current.hidden || current.getAttribute('aria-hidden') === 'true' ||
              style.display === 'none' || style.visibility === 'hidden' || Number(style.opacity) === 0 ||
              /inset\(50%/.test(style.clipPath) || /rect\((?:1px[, ]+){3}1px\)/.test(style.clip)) return false;
        }
        return true;
      }
      const schedule = () => { if (!timer) timer = setTimeout(publish, 500); };
      window.__xglassRefreshUnread = schedule;
      const relevant = (node, descend = true) => {
        const e = node.nodeType === 1 ? node : node.parentElement;
        return e && (tracked.some(n => e === n || e.contains(n)) || e.closest('title') || e.closest(navSelector) || e.matches(bannerSelector) ||
          (e.matches('button, [role="button"]') && /^Show \d+ posts$/i.test(e.textContent.trim())) ||
          (descend && e.querySelector(navSelector + ', ' + bannerSelector)));
      };
      const observer = new MutationObserver(records => {
        if (records.some(r => relevant(r.target, false) || Array.from(r.addedNodes).some(n => relevant(n)) || Array.from(r.removedNodes).some(n => relevant(n)))) schedule();
      });
      observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true,
        attributes: true, attributeFilter: ['aria-label', 'aria-hidden', 'hidden', 'class', 'style'] });
      document.addEventListener('visibilitychange', schedule);
      window.addEventListener('pageshow', schedule);
      window.addEventListener('popstate', schedule);
      window.addEventListener('hashchange', schedule);
      document.addEventListener('DOMContentLoaded', schedule, { once: true });
      schedule();
    })();
    """#
}
