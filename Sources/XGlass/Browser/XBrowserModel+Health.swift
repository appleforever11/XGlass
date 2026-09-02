import Foundation
import WebKit

private let xGlassHealthScript = """
(() => {
  const visible = (node) => {
    if (!node) return false;
    const style = getComputedStyle(node);
    const rect = node.getBoundingClientRect();
    return style.display !== 'none' && style.visibility !== 'hidden' &&
      Number(style.opacity || 1) > 0 && rect.width > 0 && rect.height > 0;
  };
  const primary = document.querySelector('[data-testid="primaryColumn"]') ||
    document.querySelector('[data-xglass-primary-column="true"]');
  const composer = primary?.querySelector(
    '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"], textarea, input'
  );
  return JSON.stringify({
    pagePath: window.location.pathname,
    primaryColumn: Boolean(primary),
    customStyles: Boolean(document.getElementById('xglass-layout-overrides')),
    nativeSidebarSuppressed: !visible(document.querySelector('header[role="banner"]')),
    themeBridge: typeof window.__xglassSetTheme === 'function',
    preferenceBridge: typeof window.__xglassSetPreferences === 'function',
    interactiveControls: Boolean(primary?.querySelector('button, a, [role="button"]')),
    composerSurface: Boolean(composer?.closest('[data-xglass-top-surface="true"], [data-xglass-composer-surface="true"], [data-xglass-reply-composer="true"]')),
    adFilterEnabled: window.__xglassPreferences?.hidePromotedPosts !== false
  });
})();
"""

@MainActor
extension XBrowserModel {
    func runInterfaceHealthCheck() {
        guard let webView else {
            healthReport = XInterfaceHealthReportBuilder.unavailable(checkedAt: Date())
            statusMessage = "The X web session is still starting. Try the health check again shortly."
            return
        }

        isRunningHealthCheck = true

        webView.evaluateJavaScript(xGlassHealthScript) { [weak self, webView] result, error in
            Task { @MainActor in
                guard let self else { return }
                self.isRunningHealthCheck = false

                guard error == nil,
                      let json = result as? String,
                      let payload = try? XInterfaceHealthPayload.decode(json: json) else {
                    self.healthReport = XInterfaceHealthReport(
                        pagePath: webView.url?.path ?? "Unknown",
                        checkedAt: Date(),
                        checks: [XInterfaceHealthCheck(
                            id: "webView",
                            title: "Web view responded",
                            detail: error?.localizedDescription ?? "No response",
                            passed: false
                        )]
                    )
                    return
                }

                self.healthReport = XInterfaceHealthReportBuilder.make(
                    payload: payload,
                    currentURL: webView.url ?? self.currentURL,
                    checkedAt: Date()
                )
            }
        }
    }
}
