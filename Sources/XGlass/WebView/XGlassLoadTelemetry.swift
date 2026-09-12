import WebKit

@MainActor
final class XGlassLoadTelemetry: NSObject, WKScriptMessageHandler {
    weak var browser: XBrowserModel?
    init(browser: XBrowserModel) { self.browser = browser }
    static func summary(_ value: [String: Any]) -> String? {
        guard let phase = value["phase"] as? String,
              ["document", "dom", "loaded", "errors", "visible"].contains(phase) else { return nil }
        func count(_ key: String) -> Int {
            guard let number = value[key] as? Double, number.isFinite else { return 0 }
            return Int(min(1_000_000, max(0, number)))
        }
        return "Web \(phase): \(count("ms"))ms; failed scripts \(count("scripts")), styles \(count("styles")), images \(count("images")), JS errors \(count("errors"))"
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.webView === browser?.webView,
              let value = message.body as? [String: Any], let summary = Self.summary(value) else { return }
        browser?.recordLoadEvent(summary)
    }
    static let source = #"""
    (() => {
      if (window.__xglassLoadTelemetry) return;
      window.__xglassLoadTelemetry = true;
      const counts = {scripts:0, styles:0, images:0, errors:0};
      let timer = 0;
      const send = phase => window.webkit?.messageHandlers?.xglassLoadTelemetry?.postMessage(
        {...counts, phase, ms:Math.round(performance.now())});
      const failure = key => {
        counts[key] = Math.min(10000, counts[key]+1);
        if (!timer && !document.hidden) timer = setTimeout(() => {timer=0; send('errors');}, 1000);
      };
      window.addEventListener('error', event => {
        const tag = event.target?.tagName;
        failure(tag === 'SCRIPT' ? 'scripts' : tag === 'LINK' ? 'styles' : tag === 'IMG' ? 'images' : 'errors');
      }, true);
      window.addEventListener('unhandledrejection', () => failure('errors'));
      document.addEventListener('DOMContentLoaded', () => send('dom'), {once:true});
      window.addEventListener('load', () => send('loaded'), {once:true});
      document.addEventListener('visibilitychange', () => {if (!document.hidden) send('visible');});
      send('document');
    })();
    """#
}
