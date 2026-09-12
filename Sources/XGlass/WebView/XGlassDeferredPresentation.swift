import Foundation

enum XGlassDeferredPresentation {
    static func wrap(_ source: String) -> String {
        """
        (() => {
          let attempts = 0, timer = 0, started = false;
          const start = () => { \(source) };
          const check = () => {
            timer = 0;
            if (started || document.hidden || ++attempts > 240) return;
            if (!document.hidden && document.querySelector('article, [data-testid="emptyState"], input[autocomplete="username"], input[type="password"], main [role="tablist"]')) {
              started = true; start(); return;
            }
            timer = setTimeout(check, 250);
          };
          document.addEventListener('visibilitychange', () => {
            if (timer) { clearTimeout(timer); timer = 0; }
            if (!document.hidden && !started) { attempts = 0; check(); }
          });
          check();
        })();
        """
    }
}
