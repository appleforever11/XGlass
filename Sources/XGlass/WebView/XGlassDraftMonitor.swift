import WebKit

@MainActor
final class XGlassDraftMonitor: NSObject, WKScriptMessageHandler {
    weak var browser: XBrowserModel?
    init(browser: XBrowserModel) { self.browser = browser }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.webView === browser?.webView, let hasDraft = message.body as? Bool else { return }
        browser?.hasUnsavedDraft = hasDraft
    }
    static let source = #"""
    (() => {
      if (window.__xglassDraftInstalled) return;
      window.__xglassDraftInstalled = true;
      const update = () => {
        const draft = Array.from(document.querySelectorAll('[contenteditable="true"], textarea, input[type="file"]'))
          .some(n => n.isContentEditable ? n.innerText.trim().length > 0 :
            n.type === 'file' ? n.files.length > 0 : n.value.trim().length > 0);
        window.webkit?.messageHandlers?.xglassDraft?.postMessage(draft);
      };
      document.addEventListener('input', update, true);
      document.addEventListener('change', update, true);
      document.addEventListener('DOMContentLoaded', update, { once: true });
    })();
    """#
}
