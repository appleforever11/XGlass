import Foundation

enum XGlassScrollRestoration {
    // Only restore full reloads. X retains ownership of its SPA and back/forward positions.
    static let source = #"""
    (() => {
      if (window.__xglassScrollInstalled) return;
      window.__xglassScrollInstalled = true;
      const key = () => 'xglass-scroll:' + location.pathname + location.search;
      let timer = 0;
      const save = (destination = key(), y = window.scrollY) => {
        try { sessionStorage.setItem(destination, String(y)); } catch (_) {}
      };
      window.addEventListener('scroll', () => {
        if (timer) return;
        const destination = key(), y = window.scrollY;
        timer = setTimeout(() => { timer = 0; save(destination, y); }, 400);
      }, { passive: true });
      window.addEventListener('pagehide', () => { if (timer) clearTimeout(timer); save(); });
      if (performance.getEntriesByType('navigation')[0]?.type !== 'reload') return;
      let y = 0;
      try { y = Number(sessionStorage.getItem(key())) || 0; } catch (_) {}
      if (y <= 0) return;
      let cancelled = false;
      const cancel = () => { cancelled = true; };
      window.addEventListener('wheel', cancel, { once: true, passive: true });
      window.addEventListener('pointerdown', cancel, { once: true, passive: true });
      window.addEventListener('keydown', cancel, { once: true });
      const destination = location.href;
      let attempts = 0;
      const restore = () => {
        if (cancelled || location.href !== destination || ++attempts > 20) return;
        if (document.documentElement.scrollHeight >= y + innerHeight) { scrollTo(0, y); return; }
        setTimeout(restore, 500);
      };
      restore();
    })();
    """#
}
