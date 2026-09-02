import Foundation

enum XGlassDOMScripts {
    static let bootstrap = #"""
(() => {
  const host = document.head || document.documentElement;
  if (!host || document.getElementById("xglass-bootstrap-overrides")) return;
  const style = document.createElement("style");
  style.id = "xglass-bootstrap-overrides";
  style.textContent = `
    html,
    body,
    #react-root {
      background: transparent !important;
      background-color: transparent !important;
    }
  `;
  host.appendChild(style);
})();
"""#

    static let contextMenu = #"""
(() => {
  if (window.__xglassContextMenuInstalled) return;
  window.__xglassContextMenuInstalled = true;
  document.addEventListener('contextmenu', (event) => {
    const target = event.target instanceof Element ? event.target : null;
    const image = target?.closest('img') || target?.querySelector('img');
    const imageURL = image?.currentSrc || image?.src || null;
    window.webkit?.messageHandlers?.xglassContextMenu?.postMessage({ imageURL });
  }, true);
})();
"""#

    static func chromeSuppression(minimumPaintInterval: Int) -> String {
        let layout = XGlassDOMLayoutScript.source.replacingOccurrences(
            of: "const minimumPaintInterval = 250;",
            with: "const minimumPaintInterval = \(minimumPaintInterval);"
        )
        let runtime = XGlassDOMSchedulingScript.source(
            baseStyles: XGlassDOMBaseStyles.source,
            themeStyles: XGlassDOMThemeStyles.source
        )
        .replacingOccurrences(of: "__XGLASS_BASE_STYLES__", with: XGlassDOMBaseStyles.source)
        .replacingOccurrences(of: "__XGLASS_THEME_STYLES__", with: XGlassDOMThemeStyles.source)
        return [layout, runtime].joined(separator: "\n")
    }
}
