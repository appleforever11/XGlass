import SwiftUI
import WebKit

struct XWebView: NSViewRepresentable {
    @EnvironmentObject private var browser: XBrowserModel

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: xGlassChromeSuppressionScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.underPageBackgroundColor = .clear
        webView.setValue(false, forKey: "drawsBackground")
        browser.attach(webView)
        browser.loadInitialPageIfNeeded()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        browser.attach(nsView)
    }

}

private let xGlassChromeSuppressionScript = #"""
(() => {
  const styleId = "xglass-layout-overrides";
  const hiddenAdAttribute = "data-xglass-ad-hidden";
  const topBandAttribute = "data-xglass-top-band";
  const topSurfaceAttribute = "data-xglass-top-surface";
  const topControlAttribute = "data-xglass-top-control";
  const addControlAttribute = "data-xglass-add-control";
  const addSurfaceAttribute = "data-xglass-add-surface";
  const composerSurfaceAttribute = "data-xglass-composer-surface";
  const replyComposerAttribute = "data-xglass-reply-composer";
  let pendingFrame = 0;

  function normalized(value) {
    return (value || "").replace(/\s+/g, " ").trim().toLowerCase();
  }

  function hasPromotionMarker(node) {
    const testId = normalized(node.getAttribute("data-testid"));
    const ariaLabel = normalized(node.getAttribute("aria-label"));

    return testId === "placementtracking" ||
      /promot|sponsor|advertis/.test(testId) ||
      /promot|sponsor|advertis/.test(ariaLabel) ||
      ariaLabel === "ad";
  }

  function hasAdBadge(article) {
    const badgeNodes = article.querySelectorAll("span, div, a, [aria-label]");
    return Array.from(badgeNodes).some((node) => {
      if (node.childElementCount > 0) return false;
      const value = normalized(node.textContent || node.getAttribute("aria-label"));
      return value === "ad" ||
        value === "promoted" ||
        value === "sponsored" ||
        value === "advertisement";
    });
  }

  function isPromotedArticle(article) {
    if (!article) return false;

    let current = article;
    for (let depth = 0; current && depth < 5; depth += 1) {
      if (hasPromotionMarker(current)) return true;
      current = current.parentElement;
    }

    return hasAdBadge(article);
  }

  function adTarget(node) {
    return node.closest('[data-testid="cellInnerDiv"]') ||
      node.closest("article") ||
      node;
  }

  function hidePromotedContent() {
    const primaryColumn = document.querySelector('[data-testid="primaryColumn"]');
    if (!primaryColumn) return;

    primaryColumn.querySelectorAll("[data-xglass-ad-hidden=\"true\"]").forEach((target) => {
      target.removeAttribute(hiddenAdAttribute);
      target.style.removeProperty("display");
      if (target.getAttribute("data-xglass-managed-aria") === "true") {
        target.removeAttribute("aria-hidden");
        target.removeAttribute("data-xglass-managed-aria");
      }
    });

    primaryColumn.querySelectorAll("article, [data-testid]").forEach((node) => {
      const article = node.matches("article") ? node : null;
      const marked = hasPromotionMarker(node) || isPromotedArticle(article);
      if (!marked) return;

      const target = adTarget(node);
      target.setAttribute(hiddenAdAttribute, "true");
      target.style.setProperty("display", "none", "important");
      if (!target.hasAttribute("aria-hidden")) {
        target.setAttribute("aria-hidden", "true");
        target.setAttribute("data-xglass-managed-aria", "true");
      }
    });
  }

  function isOpaqueBlack(color) {
    const values = color.match(/[\d.]+/g);
    if (!values || values.length < 3) return false;

    const alpha = values.length >= 4 ? Number(values[3]) : 1;
    return alpha > 0.72 &&
      Number(values[0]) < 42 &&
      Number(values[1]) < 48 &&
      Number(values[2]) < 58;
  }

  function isTopSurfaceRect(rect, columnRect, cutoff) {
    return rect.width >= columnRect.width * 0.62 &&
      rect.height >= 24 &&
      rect.top >= columnRect.top - 4 &&
      rect.bottom <= cutoff + 3;
  }

  function isTopBandRect(rect, columnRect, cutoff) {
    return rect.height >= 24 &&
      rect.top >= columnRect.top - 4 &&
      rect.bottom <= cutoff + 3;
  }

  function isAddControl(node) {
    const values = [
      node.getAttribute("data-testid"),
      node.getAttribute("aria-label"),
      node.getAttribute("title"),
      node.textContent
    ].map(normalized).filter(Boolean);

    return values.some((value) =>
      value === "+" ||
      /add\s*(a\s*)?(column|tab)/.test(value) ||
      /new\s*(a\s*)?(column|tab)/.test(value)
    );
  }

  function markAddSurface(control, columnRect, cutoff) {
    let current = control.parentElement;
    for (let depth = 0; current && depth < 5; depth += 1) {
      const rect = current.getBoundingClientRect();
      if (isTopBandRect(rect, columnRect, cutoff) &&
          rect.width >= Math.max(80, columnRect.width * 0.72)) {
        current.setAttribute(addSurfaceAttribute, "true");
        return;
      }
      current = current.parentElement;
    }
  }

  function isComposerControl(node) {
    return node.matches(
      '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"], textarea, input'
    );
  }

  function paintReplyComposer(primaryColumn) {
    primaryColumn.querySelectorAll(`[${replyComposerAttribute}="true"]`).forEach((node) => {
      node.removeAttribute(replyComposerAttribute);
    });
    if (primaryColumn.querySelector('[data-testid="dm-container"]')) return;

    const columnRect = primaryColumn.getBoundingClientRect();
    if (!columnRect.width || !columnRect.height) return;

    const composerControl = Array.from(primaryColumn.querySelectorAll(
      '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"], ' +
      'textarea, input'
    )).find(isComposerControl);
    if (!composerControl) return;

    let current = composerControl;
    let composer = null;
    let fallback = null;
    for (let depth = 0; current && current !== primaryColumn && depth < 10; depth += 1) {
      const rect = current.getBoundingClientRect();
      if (rect.width >= Math.max(280, columnRect.width * 0.68) &&
          rect.height >= 80 && rect.height <= 420) {
        fallback = current;
        if (isOpaqueBlack(getComputedStyle(current).backgroundColor)) {
          composer = current;
          break;
        }
      }
      current = current.parentElement;
    }

    composer = composer || fallback;
    if (!composer) return;
    composer.setAttribute(replyComposerAttribute, "true");
  }

  function flattenTopBand(primaryColumn, columnRect, cutoff, topSection) {
    if (topSection) {
      topSection.setAttribute(topBandAttribute, "true");
      topSection.setAttribute(composerSurfaceAttribute, "true");
      topSection.removeAttribute(topSurfaceAttribute);
      topSection.style.setProperty(
        "background",
        "linear-gradient(180deg, rgba(40, 111, 117, 0.46), rgba(24, 86, 95, 0.38))",
        "important"
      );
      topSection.style.setProperty("border-color", "transparent", "important");
      topSection.style.setProperty("box-shadow", "none", "important");
    }

    const structuralNodes = primaryColumn.querySelectorAll(
      'div, section, form, nav, li, button, a, textarea, input, span, p, label, ' +
      '[role="presentation"], [role="tablist"], [role="tab"], ' +
      '[role="group"], [role="button"], [role="textbox"]'
    );

    structuralNodes.forEach((node) => {
      if (node === topSection) return;

      const rect = node.getBoundingClientRect();
      if (!isTopBandRect(rect, columnRect, cutoff)) return;

      const isPostButton = node.matches(
        'button[data-testid*="tweetButton"], [role="button"][data-testid*="tweetButton"]'
      );

      if (isPostButton) {
        node.style.setProperty("background", "rgba(232, 247, 246, 0.16)", "important");
        node.style.setProperty("border", "1px solid rgba(232, 247, 246, 0.14)", "important");
        node.style.setProperty("border-radius", "999px", "important");
      } else {
        const hasBackgroundImage = getComputedStyle(node).backgroundImage.includes("url(");
        node.style.setProperty("background-color", "transparent", "important");
        if (!hasBackgroundImage) {
          node.style.setProperty("background-image", "none", "important");
        }
        node.style.setProperty("border-color", "transparent", "important");
        node.style.setProperty("box-shadow", "none", "important");
        node.style.setProperty("backdrop-filter", "none", "important");
        node.style.setProperty("-webkit-backdrop-filter", "none", "important");
      }
    });
  }

  function paintTopSurface() {
    const primaryColumn = document.querySelector('[data-testid="primaryColumn"]');
    if (!primaryColumn) return;
    paintReplyComposer(primaryColumn);
    if (primaryColumn.querySelector('[data-testid="dm-container"]')) return;

    primaryColumn.querySelectorAll("[data-xglass-top-band=\"true\"]").forEach((node) => {
      node.removeAttribute(topBandAttribute);
    });
    primaryColumn.querySelectorAll("[data-xglass-top-surface=\"true\"]").forEach((node) => {
      node.removeAttribute(topSurfaceAttribute);
    });
    primaryColumn.querySelectorAll("[data-xglass-composer-surface=\"true\"]").forEach((node) => {
      node.removeAttribute(composerSurfaceAttribute);
    });
    primaryColumn.querySelectorAll("[data-xglass-add-control=\"true\"]").forEach((node) => {
      node.removeAttribute(addControlAttribute);
    });
    primaryColumn.querySelectorAll("[data-xglass-add-surface=\"true\"]").forEach((node) => {
      node.removeAttribute(addSurfaceAttribute);
    });

    const columnRect = primaryColumn.getBoundingClientRect();
    if (!columnRect.width || !columnRect.height) return;

    const firstArticle = Array.from(
      primaryColumn.querySelectorAll("article[role=\"article\"], article")
    ).find((article) => {
      const rect = article.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    });
    const cutoff = firstArticle
      ? firstArticle.getBoundingClientRect().top
      : columnRect.top + Math.min(columnRect.height, 420);

    primaryColumn.querySelectorAll("[data-xglass-top-control=\"true\"]").forEach((node) => {
      node.removeAttribute(topControlAttribute);
    });

    primaryColumn.querySelectorAll('button, a, [role="button"]').forEach((control) => {
      const rect = control.getBoundingClientRect();
      if (isTopBandRect(rect, columnRect, cutoff)) {
        control.setAttribute(topControlAttribute, "true");
        if (isAddControl(control)) {
          control.setAttribute(addControlAttribute, "true");
          markAddSurface(control, columnRect, cutoff);
        }
      }
    });

    const semanticNodes = primaryColumn.querySelectorAll(
      '[role="tablist"], [data-testid="ScrollSnap-List"], [data-testid="toolBar"], ' +
      '[data-testid="floatingActionBar"], [data-testid*="tweetTextarea"], [contenteditable="true"]'
    );
    semanticNodes.forEach((node) => {
      let current = node;
      for (let depth = 0; current && current !== primaryColumn && depth < 5; depth += 1) {
        const rect = current.getBoundingClientRect();
        if (isTopBandRect(rect, columnRect, cutoff)) {
          current.setAttribute(topSurfaceAttribute, "true");
          break;
        }
        current = current.parentElement;
      }
    });

    const darkBlocks = Array.from(primaryColumn.querySelectorAll("div, section, form"))
      .filter((node) => {
        const rect = node.getBoundingClientRect();
        if (!isTopBandRect(rect, columnRect, cutoff) ||
            rect.width < columnRect.width * 0.04) return false;

        const computed = getComputedStyle(node);
        return isOpaqueBlack(computed.backgroundColor);
      });

    darkBlocks.forEach((node) => {
      const rect = node.getBoundingClientRect();
      const coveredByLargerBlock = darkBlocks.some((other) => {
        if (other === node || !other.contains(node)) return false;
        const otherRect = other.getBoundingClientRect();
        return otherRect.width >= rect.width * 0.95 &&
          otherRect.height >= rect.height * 1.05;
      });

      if (!coveredByLargerBlock) {
        node.setAttribute(topSurfaceAttribute, "true");
      }
    });

    const topSection = primaryColumn.querySelector(':scope > div > div:first-child');
    flattenTopBand(primaryColumn, columnRect, cutoff, topSection);
  }

  function applyOverrides() {
    if (!document.getElementById(styleId)) {
      const style = document.createElement("style");
      style.id = styleId;
      style.textContent = `
        html, body {
          background: transparent !important;
        }

        body {
          color: rgba(245, 248, 255, 0.96) !important;
        }

        #react-root,
        #react-root > div,
        main[role="main"],
        main[role="main"] > div,
        [data-testid="primaryColumn"],
        [data-testid="primaryColumn"] > div {
          background: transparent !important;
        }

        header[role="banner"] {
          display: none !important;
          width: 0 !important;
          min-width: 0 !important;
          max-width: 0 !important;
          flex: 0 0 0 !important;
          overflow: hidden !important;
          pointer-events: none !important;
        }

        main[role="main"] [data-testid="primaryColumn"] {
          width: min(100%, 760px) !important;
          max-width: 760px !important;
          margin-left: auto !important;
          margin-right: auto !important;
        }

        [data-testid="primaryColumn"] {
          background: transparent !important;
        }

        [data-testid="sidebarColumn"] {
          display: none !important;
        }

        [role="tablist"],
        [role="tablist"] > div,
        [role="tablist"] > div > div,
        [role="tablist"] [role="tab"],
        [role="tablist"] [role="presentation"],
        [data-testid="ScrollSnap-List"],
        [data-testid="ScrollSnap-List"] > div,
        [data-testid="ScrollSnap-List"] > div > div,
        [data-testid="primaryColumn"] > div > div:first-child,
        [data-testid="primaryColumn"] section > div:first-child,
        [data-testid="toolBar"],
        [data-testid="floatingActionBar"] {
          background: transparent !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
          box-shadow: none !important;
          border-color: transparent !important;
        }

        [role="tablist"] [role="tab"][aria-selected="true"] {
          background: transparent !important;
        }

        [data-testid="toolBar"] > div,
        [data-testid="toolBar"] > div > div,
        [data-testid="toolBar"] [role="group"],
        [data-testid="floatingActionBar"] > div,
        [data-testid="floatingActionBar"] > div > div {
          background: transparent !important;
          box-shadow: none !important;
          border-color: rgba(188, 221, 255, 0.06) !important;
        }

        [data-xglass-top-band="true"] {
          background: linear-gradient(180deg, rgba(40, 111, 117, 0.46), rgba(24, 86, 95, 0.38)) !important;
          background-image: linear-gradient(180deg, rgba(40, 111, 117, 0.46), rgba(24, 86, 95, 0.38)) !important;
          backdrop-filter: blur(22px) saturate(1.10) !important;
          -webkit-backdrop-filter: blur(22px) saturate(1.10) !important;
          border-color: transparent !important;
          border-radius: 18px 18px 0 0 !important;
          color: rgba(245, 252, 251, 0.96) !important;
          box-shadow: none !important;
        }

        [data-xglass-top-surface="true"] {
          background: transparent !important;
          background-image: none !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
          border-color: transparent !important;
          color: rgba(245, 252, 251, 0.96) !important;
          box-shadow: none !important;
        }

        [data-xglass-add-control="true"],
        [data-xglass-add-surface="true"] {
          background: transparent !important;
          background-image: none !important;
          border: 0 !important;
          border-color: transparent !important;
          border-radius: 999px !important;
          box-shadow: none !important;
          color: rgba(232, 247, 246, 0.92) !important;
        }

        [data-xglass-add-control="true"]:hover,
        [data-xglass-add-control="true"]:focus-visible {
          background: rgba(232, 247, 246, 0.10) !important;
        }

        [data-xglass-add-surface="true"] {
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
        }

        [data-xglass-top-band="true"] [data-xglass-top-surface="true"],
        [data-xglass-top-band="true"] [data-xglass-composer-surface="true"] {
          background: transparent !important;
          background-image: none !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
        }

        [data-xglass-top-band="true"] *,
        [data-xglass-add-surface="true"] *,
        [data-xglass-top-surface="true"] *,
        [data-xglass-composer-surface="true"] * {
          background-color: transparent !important;
          box-shadow: none !important;
        }

        [data-xglass-top-band="true"] *::before,
        [data-xglass-top-band="true"] *::after,
        [data-xglass-add-surface="true"] *::before,
        [data-xglass-add-surface="true"] *::after,
        [data-xglass-top-surface="true"] *::before,
        [data-xglass-top-surface="true"] *::after,
        [data-xglass-composer-surface="true"] *::before,
        [data-xglass-composer-surface="true"] *::after {
          background: transparent !important;
          box-shadow: none !important;
        }

        [data-xglass-top-band="true"] div,
        [data-xglass-top-band="true"] section,
        [data-xglass-top-band="true"] form,
        [data-xglass-top-band="true"] nav,
        [data-xglass-top-band="true"] li,
        [data-xglass-top-band="true"] [role="group"],
        [data-xglass-top-band="true"] [role="tab"],
        [data-xglass-top-band="true"] [role="button"],
        [data-xglass-top-band="true"] button,
        [data-xglass-top-band="true"] a,
        [data-xglass-top-surface="true"] div,
        [data-xglass-top-surface="true"] section,
        [data-xglass-top-surface="true"] form,
        [data-xglass-top-surface="true"] nav,
        [data-xglass-top-surface="true"] li,
        [data-xglass-top-surface="true"] [role="group"],
        [data-xglass-top-surface="true"] [role="tab"],
        [data-xglass-top-surface="true"] [role="button"],
        [data-xglass-top-surface="true"] button,
        [data-xglass-top-surface="true"] a,
        [data-xglass-top-control="true"] {
          background-color: transparent !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-xglass-top-surface="true"] [role="textbox"],
        [data-xglass-top-surface="true"] [contenteditable="true"],
        [data-xglass-top-surface="true"] [data-testid*="tweetTextarea"],
        [data-xglass-top-surface="true"] textarea,
        [data-xglass-top-surface="true"] input,
        [data-xglass-top-surface="true"] button {
          color: rgba(245, 252, 251, 0.96) !important;
          caret-color: rgba(245, 252, 251, 0.96) !important;
        }

        [data-xglass-top-surface="true"] [role="textbox"]::placeholder,
        [data-xglass-top-surface="true"] [contenteditable="true"]::placeholder,
        [data-xglass-top-surface="true"] [data-placeholder]::before,
        [data-xglass-top-surface="true"] [data-placeholder]::after,
        [data-xglass-top-surface="true"] [data-placeholder],
        [data-xglass-top-surface="true"] [data-testid*="tweetTextarea"],
        [data-xglass-top-surface="true"] textarea::placeholder,
        [data-xglass-top-surface="true"] input::placeholder {
          color: rgba(232, 247, 246, 0.72) !important;
          opacity: 1 !important;
        }

        [data-xglass-top-surface="true"] button *,
        [data-xglass-top-control="true"] * {
          color: inherit !important;
          fill: currentColor !important;
          stroke: currentColor !important;
        }

        [data-xglass-top-surface="true"] svg,
        [data-xglass-top-control="true"] svg {
          color: rgba(232, 247, 246, 0.90) !important;
        }

        [data-testid="primaryColumn"] [role="tablist"],
        [data-testid="primaryColumn"] [data-testid="ScrollSnap-List"] {
          background: transparent !important;
          background-image: none !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-testid="primaryColumn"] [data-testid="toolBar"],
        [data-testid="primaryColumn"] [data-testid="toolBar"] > div,
        [data-testid="primaryColumn"] [data-testid="floatingActionBar"],
        [data-testid="primaryColumn"] [data-testid="floatingActionBar"] > div {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-testid="primaryColumn"] [role="tablist"] [role="tab"],
        [data-testid="primaryColumn"] [data-testid="ScrollSnap-List"] [role="tab"],
        [data-xglass-top-surface="true"] [role="tab"] {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-xglass-reply-composer="true"] {
          background: linear-gradient(180deg, rgba(40, 111, 117, 0.38), rgba(24, 86, 95, 0.28)) !important;
          background-image: linear-gradient(180deg, rgba(40, 111, 117, 0.38), rgba(24, 86, 95, 0.28)) !important;
          border-top: 1px solid rgba(190, 235, 231, 0.12) !important;
          border-bottom: 1px solid rgba(190, 235, 231, 0.12) !important;
          border-radius: 0 !important;
          box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04), inset 0 -1px 0 rgba(6, 42, 50, 0.12) !important;
          color: rgba(245, 252, 251, 0.96) !important;
        }

        [data-xglass-reply-composer="true"] div,
        [data-xglass-reply-composer="true"] section,
        [data-xglass-reply-composer="true"] form,
        [data-xglass-reply-composer="true"] [role="group"],
        [data-xglass-reply-composer="true"] [role="textbox"],
        [data-xglass-reply-composer="true"] [contenteditable="true"],
        [data-xglass-reply-composer="true"] textarea,
        [data-xglass-reply-composer="true"] input {
          background: transparent !important;
          background-image: none !important;
          box-shadow: none !important;
        }

        [data-xglass-reply-composer="true"] [role="textbox"],
        [data-xglass-reply-composer="true"] [contenteditable="true"],
        [data-xglass-reply-composer="true"] [data-testid*="tweetTextarea"],
        [data-xglass-reply-composer="true"] textarea,
        [data-xglass-reply-composer="true"] input {
          color: rgba(248, 252, 255, 0.98) !important;
          caret-color: rgba(248, 252, 255, 0.98) !important;
        }

        [data-xglass-reply-composer="true"] [data-placeholder]::before,
        [data-xglass-reply-composer="true"] [data-placeholder]::after,
        [data-xglass-reply-composer="true"] [data-placeholder],
        [data-xglass-reply-composer="true"] textarea::placeholder,
        [data-xglass-reply-composer="true"] input::placeholder {
          color: rgba(232, 247, 246, 0.78) !important;
          opacity: 1 !important;
        }

        [data-xglass-reply-composer="true"] button *,
        [data-xglass-reply-composer="true"] [role="button"] * {
          color: inherit !important;
          fill: currentColor !important;
          stroke: currentColor !important;
        }

        [data-xglass-reply-composer="true"] button[data-testid*="tweetButton"],
        [data-xglass-reply-composer="true"] [role="button"][data-testid*="tweetButton"] {
          background: rgba(232, 247, 246, 0.16) !important;
          border: 1px solid rgba(232, 247, 246, 0.14) !important;
          border-radius: 999px !important;
        }

        [data-xglass-top-control="true"] {
          border-radius: 999px !important;
          background-color: transparent !important;
          box-shadow: none !important;
        }

        [data-xglass-top-control="true"]:hover,
        [data-xglass-top-control="true"]:focus-visible {
          background: rgba(232, 247, 246, 0.08) !important;
          border-color: rgba(232, 247, 246, 0.08) !important;
        }

        [data-xglass-top-surface="true"] button[data-testid*="tweetButton"],
        [data-xglass-top-control="true"][data-testid*="tweetButton"] {
          background: rgba(232, 247, 246, 0.16) !important;
          border: 1px solid rgba(232, 247, 246, 0.14) !important;
          border-radius: 999px !important;
        }

        [data-xglass-ad-hidden="true"] {
          display: none !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] {
          display: flex !important;
          flex-direction: column !important;
          width: fit-content !important;
          max-width: min(84%, 560px) !important;
          box-sizing: border-box !important;
          margin-top: 4px !important;
          margin-bottom: 4px !important;
          padding: 11px 14px !important;
          border: 1px solid rgba(224, 247, 245, 0.18) !important;
          border-radius: 18px !important;
          background: rgba(242, 250, 249, 0.11) !important;
          color: rgba(248, 252, 255, 0.96) !important;
          box-shadow: 0 5px 16px rgba(0, 16, 20, 0.12), inset 0 1px 0 rgba(255, 255, 255, 0.05) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"][class~="bg-gray-50"] {
          border-top-left-radius: 7px !important;
          background: linear-gradient(145deg, rgba(240, 249, 248, 0.18), rgba(180, 221, 220, 0.11)) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"][class~="bg-chat-accent"] {
          border-top-right-radius: 7px !important;
          border-color: rgba(115, 224, 220, 0.28) !important;
          background: linear-gradient(145deg, rgba(48, 156, 161, 0.50), rgba(22, 105, 116, 0.46)) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-"]:not([data-testid^="message-text-"])[class*="justify-start"] [data-testid^="message-text-"] {
          margin-right: auto !important;
          border-top-left-radius: 7px !important;
          background: linear-gradient(145deg, rgba(240, 249, 248, 0.14), rgba(180, 221, 220, 0.08)) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-"]:not([data-testid^="message-text-"])[class*="justify-end"] [data-testid^="message-text-"] {
          margin-left: auto !important;
          border-top-right-radius: 7px !important;
          border-color: rgba(115, 224, 220, 0.28) !important;
          background: linear-gradient(145deg, rgba(48, 156, 161, 0.50), rgba(22, 105, 116, 0.46)) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] p,
        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] span,
        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] div {
          color: inherit !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] a {
          color: rgba(151, 229, 255, 0.98) !important;
          text-decoration-color: rgba(151, 229, 255, 0.55) !important;
        }

        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] time,
        [data-testid="dm-message-scroller"] [data-testid^="message-text-"] [datetime] {
          color: rgba(230, 245, 245, 0.70) !important;
          font-size: 11px !important;
        }

        [data-testid="primaryColumn"] [role="textbox"],
        textarea,
        input {
          color: rgba(250, 252, 255, 0.98) !important;
          background: rgba(255, 255, 255, 0.04) !important;
        }

        [data-xglass-composer-surface="true"] [role="textbox"],
        [data-xglass-composer-surface="true"] [contenteditable="true"],
        [data-xglass-composer-surface="true"] [data-testid*="tweetTextarea"],
        [data-xglass-composer-surface="true"] textarea,
        [data-xglass-composer-surface="true"] input {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-testid="tweetText"],
        [data-testid="User-Name"],
        [data-testid="primaryColumn"] span,
        [data-testid="primaryColumn"] div[dir="ltr"] {
          color: inherit !important;
        }

        [data-xglass-top-surface="true"] [role="textbox"],
        [data-xglass-top-surface="true"] [contenteditable="true"],
        [data-xglass-top-surface="true"] [data-testid*="tweetTextarea"],
        [data-xglass-top-surface="true"] textarea,
        [data-xglass-top-surface="true"] input {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }
      `;
      document.head.appendChild(style);
    }

      const banner = document.querySelector('header[role="banner"]');
      if (banner) {
        banner.setAttribute("aria-hidden", "true");

        const parent = banner.parentElement;
        if (parent) {
          parent.style.setProperty("grid-template-columns", "minmax(0, 1fr)", "important");
          parent.style.setProperty("justify-content", "center", "important");
          parent.style.setProperty("column-gap", "0", "important");
          parent.style.setProperty("background", "transparent", "important");
        }
      }

      const primaryColumn = document.querySelector('[data-testid="primaryColumn"]');
      if (primaryColumn) {
        const row = primaryColumn.parentElement;
        if (row) {
          row.style.setProperty("display", "flex", "important");
          row.style.setProperty("justify-content", "center", "important");
          row.style.setProperty("gap", "0", "important");
          row.style.setProperty("width", "100%", "important");
          row.style.setProperty("background", "transparent", "important");
        }

        const toolBar = primaryColumn.querySelector('[data-testid="toolBar"]');
        if (toolBar) {
          toolBar.style.setProperty("background", "transparent", "important");
          toolBar.style.setProperty("box-shadow", "none", "important");
        }
      }

      hidePromotedContent();
      paintTopSurface();
  }

  function scheduleOverrides() {
    if (pendingFrame) return;
    pendingFrame = requestAnimationFrame(() => {
      pendingFrame = 0;
      applyOverrides();
    });
  }

  scheduleOverrides();
  new MutationObserver(scheduleOverrides).observe(document.documentElement, {
    childList: true,
    subtree: true
  });
})();
"""#;
