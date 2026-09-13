import Foundation

enum XGlassDOMLayoutScript {
    static let source = #"""
(() => {
  const styleId = "xglass-layout-overrides";
  const hiddenAdAttribute = "data-xglass-ad-hidden";
  const topBandAttribute = "data-xglass-top-band";
  const topSurfaceAttribute = "data-xglass-top-surface";
  const topControlAttribute = "data-xglass-top-control";
  const addControlAttribute = "data-xglass-add-control";
  const addSurfaceAttribute = "data-xglass-add-surface";
  const composerSurfaceAttribute = "data-xglass-composer-surface";
  const searchOverlayAttribute = "data-xglass-search-overlay";
  const searchLayerAttribute = "data-xglass-search-layer";
  const searchHiddenAttribute = "data-xglass-search-hidden";
  const searchActiveAttribute = "data-xglass-search-active";
  const replyComposerAttribute = "data-xglass-reply-composer";
  const replySurfaceAttribute = "data-xglass-reply-surface";
  const replyControlAttribute = "data-xglass-reply-control";
  const replyButtonAttribute = "data-xglass-reply-button";
  const primaryColumnAttribute = "data-xglass-primary-column";
  window.__xglassPreferences = window.__xglassPreferences || {
    hidePromotedPosts: true,
    feedWidth: 760
  };
  const initialFeedWidth = Number(window.__xglassPreferences.feedWidth) || 760;
  document.documentElement.style.setProperty("--xglass-feed-width", `${initialFeedWidth}px`);
  const paintFull = 1;
  const paintAds = 2;
  const paintTop = 4;
  const restoreAds = 8;
  const minimumPaintInterval = 250;
  let pendingFrame = 0;
  let pendingTimer = 0;
  let pendingReasons = 0;
  let pendingMutationRoots = new Set();
  let lastPaintAt = 0;
  let cachedPrimaryColumn = null;
  let lastPrimaryColumn = null;
  let lastRouteKey = "";
  let lastAppliedThemeKey = "";

  const topMutationSelector =
    '[role="tablist"], [role="tab"], [data-testid="ScrollSnap-List"], ' +
    '[data-testid="toolBar"], [data-testid="floatingActionBar"], ' +
    '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"]';

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

  function hasAdMarker(article) {
    return Boolean(article.querySelector(
      '[data-testid="placementTracking"], [data-testid*="promot" i], ' +
      '[data-testid*="sponsor" i], [aria-label="ad" i], ' +
      '[aria-label="promoted" i], [aria-label="sponsored" i]'
    ));
  }

  function isPromotedArticle(article) {
    if (!article) return false;

    let current = article;
    for (let depth = 0; current && depth < 5; depth += 1) {
      if (hasPromotionMarker(current)) return true;
      current = current.parentElement;
    }

    return hasAdMarker(article);
  }

  function adTarget(node) {
    return node.closest('[data-testid="cellInnerDiv"]') ||
      node.closest("article") ||
      node;
  }

  function isPrimaryCandidate(node) {
    return Boolean(node && node.matches(
      '[data-testid="primaryColumn"], [data-xglass-primary-column="true"], ' +
      'main[role="main"] [role="region"], main[role="main"]'
    ));
  }

  function findPrimaryColumn() {
    if (cachedPrimaryColumn && document.documentElement.contains(cachedPrimaryColumn) &&
        isPrimaryCandidate(cachedPrimaryColumn)) {
      return cachedPrimaryColumn;
    }

    cachedPrimaryColumn = document.querySelector('[data-testid="primaryColumn"]') ||
      document.querySelector('[data-xglass-primary-column="true"]') ||
      document.querySelector('main[role="main"] [role="region"]') ||
      document.querySelector('main[role="main"]');
    return cachedPrimaryColumn;
  }

  function restoreHiddenPromotedContent(primaryColumn) {
    primaryColumn.querySelectorAll("[data-xglass-ad-hidden=\"true\"]").forEach((target) => {
      target.removeAttribute(hiddenAdAttribute);
      target.style.removeProperty("display");
      if (target.getAttribute("data-xglass-managed-aria") === "true") {
        target.removeAttribute("aria-hidden");
        target.removeAttribute("data-xglass-managed-aria");
      }
    });
  }

  function addArticlesFromRoot(root, articles) {
    if (!root || root.nodeType !== 1) return;
    if (root.matches("article")) articles.add(root);
    const containingArticle = root.closest("article");
    if (containingArticle) articles.add(containingArticle);
    root.querySelectorAll("article").forEach((article) => articles.add(article));
  }

  function hidePromotedContent(primaryColumn, roots, restore = false) {
    if (!primaryColumn) return;
    if (restore) restoreHiddenPromotedContent(primaryColumn);
    if (window.__xglassPreferences.hidePromotedPosts === false) return;

    const articles = new Set();
    if (!roots || roots.length === 0) {
      primaryColumn.querySelectorAll("article").forEach((article) => articles.add(article));
    } else {
      roots.forEach((root) => addArticlesFromRoot(root, articles));
    }

    const targets = new Set();
    articles.forEach((article) => {
      if (!isPromotedArticle(article)) return;
      targets.add(adTarget(article));
    });

    // Explore placements can be standalone modules instead of articles.
    const placementSelector = '[data-testid="placementTracking"], [data-testid*="promot" i], ' +
      '[data-testid*="sponsor" i], [aria-label="ad" i], [aria-label="promoted" i]';
    const scanRoots = roots && roots.length ? roots : [primaryColumn];
    scanRoots.forEach((root) => {
      if (!root || root.nodeType !== 1) return;
      if (root.matches(placementSelector)) targets.add(root.closest("article") || root);
      root.querySelectorAll(placementSelector).forEach((node) => {
        targets.add(node.closest("article") || node);
      });
      if (window.location.pathname.startsWith("/explore")) {
        const links = new Set(root.querySelectorAll('a, [role="link"]'));
        const containingLink = root.closest('a, [role="link"]');
        if (containingLink) links.add(containingLink);
        links.forEach((link) => {
          const label = normalized(link.textContent);
          if (label.length > 500 || !/\bpromoted by\b/.test(label)) return;
          const parent = link.parentElement;
          const isIsolatedPlacement = parent && parent !== primaryColumn &&
            parent.querySelectorAll('a, [role="link"]').length === 1 &&
            !parent.querySelector('article, input, [role="tablist"]');
          targets.add(isIsolatedPlacement ? parent : link);
        });
      }
    });

    targets.forEach((target) => {
      if (target.getAttribute(hiddenAdAttribute) !== "true") {
        target.setAttribute(hiddenAdAttribute, "true");
      }
      if (target.style.getPropertyValue("display") !== "none" ||
          target.style.getPropertyPriority("display") !== "important") {
        target.style.setProperty("display", "none", "important");
      }
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

  function isVisible(node) {
    if (!node) return false;
    const style = getComputedStyle(node);
    const rect = node.getBoundingClientRect();
    return style.display !== "none" && style.visibility !== "hidden" &&
      Number(style.opacity || 1) > 0 && rect.width > 0 && rect.height > 0;
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
        markNode(current, addSurfaceAttribute);
        return;
      }
      current = current.parentElement;
    }
  }

  function markNode(node, attribute) {
    if (node.getAttribute(attribute) !== "true") {
      node.setAttribute(attribute, "true");
    }
  }

  function setImportantStyle(node, property, value) {
    if (node.style.getPropertyValue(property) !== value ||
        node.style.getPropertyPriority(property) !== "important") {
      node.style.setProperty(property, value, "important");
    }
  }

  function isComposerControl(node) {
    return node.matches(
      '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"], textarea, input'
    );
  }



  function flattenTopBand(primaryColumn, columnRect, cutoff, topSection) {
    if (topSection) {
      markNode(topSection, topBandAttribute);
      markNode(topSection, composerSurfaceAttribute);
      if (topSection.hasAttribute(topSurfaceAttribute)) topSection.removeAttribute(topSurfaceAttribute);
      topSection.style.removeProperty("background");
      topSection.style.removeProperty("background-image");
      setImportantStyle(topSection, "border-color", "transparent");
      setImportantStyle(topSection, "box-shadow", "none");
    }

    const scanRoot = topSection || primaryColumn;
    const structuralNodes = scanRoot.querySelectorAll(
      'div, section, form, nav, li, button, a, textarea, input, span, p, label, ' +
      '[role="presentation"], [role="tablist"], [role="tab"], ' +
      '[role="group"], [role="button"], [role="textbox"]'
    );

    structuralNodes.forEach((node) => {
      if (node === topSection) return;

      if (node.matches('[role="list"], [role="listbox"]') &&
          node.closest('[role="combobox"][aria-expanded="true"]')) {
        return;
      }

      const rect = node.getBoundingClientRect();
      if (!isTopBandRect(rect, columnRect, cutoff)) return;

      const isPostButton = node.matches(
        'button[data-testid*="tweetButton"], [role="button"][data-testid*="tweetButton"]'
      );

      if (isPostButton) {
        setImportantStyle(node, "background", "rgba(232, 247, 246, 0.16)");
        setImportantStyle(node, "border", "1px solid rgba(232, 247, 246, 0.14)");
        setImportantStyle(node, "border-radius", "999px");
      } else {
        const hasBackgroundImage = getComputedStyle(node).backgroundImage.includes("url(");
        setImportantStyle(node, "background-color", "transparent");
        if (!hasBackgroundImage) {
          setImportantStyle(node, "background-image", "none");
        }
        setImportantStyle(node, "border-color", "transparent");
        setImportantStyle(node, "box-shadow", "none");
        setImportantStyle(node, "backdrop-filter", "none");
        setImportantStyle(node, "-webkit-backdrop-filter", "none");
      }
    });
  }

  function clearTopMarkers(primaryColumn) {
    const markerGroups = [
      [topBandAttribute],
      [topSurfaceAttribute],
      [composerSurfaceAttribute],
      [topControlAttribute, addControlAttribute],
      [addSurfaceAttribute]
    ];

    markerGroups.forEach((attributes) => {
      primaryColumn.querySelectorAll(
        attributes.map((attribute) => `[${attribute}="true"]`).join(", ")
      ).forEach((node) => {
        attributes.forEach((attribute) => {
          if (node.hasAttribute(attribute)) node.removeAttribute(attribute);
        });
      });
    });
  }

  function paintTopSurface(primaryColumn, reset = false) {
    if (!primaryColumn) return;
    if (reset) clearTopMarkers(primaryColumn);
    // Notification cells carry X's live unread background. They are not header
    // controls, even when there is no article delimiting the first 420 points.
    if (/^\/notifications(?:\/|$)/.test(window.location.pathname)) {
      paintStickyHeaders(primaryColumn);
      return;
    }
    paintReplyComposer(primaryColumn, reset);
    if (primaryColumn.querySelector('[data-testid="dm-container"]')) return;

    const columnRect = primaryColumn.getBoundingClientRect();
    if (!columnRect.width || !columnRect.height) return;

    const topSection = primaryColumn.querySelector(':scope > div > div:first-child');
    const scanRoot = topSection || primaryColumn;
    const firstArticle = primaryColumn.querySelector("article[role=\"article\"], article");
    const firstArticleRect = firstArticle?.getBoundingClientRect();
    const cutoff = firstArticleRect && firstArticleRect.width > 0 && firstArticleRect.height > 0
      ? firstArticleRect.top
      : columnRect.top + Math.min(columnRect.height, 420);

    scanRoot.querySelectorAll('button, a, [role="button"]').forEach((control) => {
      const rect = control.getBoundingClientRect();
      if (!isTopBandRect(rect, columnRect, cutoff)) return;
      markNode(control, topControlAttribute);
      if (isAddControl(control)) {
        markNode(control, addControlAttribute);
        markAddSurface(control, columnRect, cutoff);
      }
    });

    scanRoot.querySelectorAll(
      '[role="tablist"], [data-testid="ScrollSnap-List"], [data-testid="toolBar"], ' +
      '[data-testid="floatingActionBar"], [data-testid*="tweetTextarea"], ' +
      '[contenteditable="true"], [role="textbox"]'
    ).forEach((node) => {
      let current = node;
      for (let depth = 0; current && current !== primaryColumn && depth < 5; depth += 1) {
        const rect = current.getBoundingClientRect();
        if (isTopBandRect(rect, columnRect, cutoff)) {
          markNode(current, topSurfaceAttribute);
          break;
        }
        current = current.parentElement;
      }
    });

    flattenTopBand(primaryColumn, columnRect, cutoff, topSection);
    paintStickyHeaders(primaryColumn);
    paintSearchOverlay(primaryColumn);
  }

  function paintStickyHeaders(primaryColumn) {
    primaryColumn.querySelectorAll('[role="tablist"]').forEach((tabs) => {
      if (tabs.closest('article, [data-testid="toolBar"], [data-testid="floatingActionBar"]')) return;
      let current = tabs;
      for (let depth = 0; current && current !== primaryColumn && depth < 8; depth += 1) {
        const rect = current.getBoundingClientRect();
        if (rect.height > 180) break;
        // X uses both sticky and fixed wrappers; paint the complete tab row, including +.
        setImportantStyle(current, "background", "var(--xglass-surface)");
        setImportantStyle(current, "backdrop-filter", "none");
        setImportantStyle(current, "-webkit-backdrop-filter", "none");
        current = current.parentElement;
      }
    });
  }

  function currentRouteKey() {
    return window.location.pathname + window.location.search + window.location.hash;
  }

  function applyPrimaryLayout(primaryColumn) {
    const previousPrimaryColumns = document.querySelectorAll(`[${primaryColumnAttribute}="true"]`);
    previousPrimaryColumns.forEach((node) => {
      if (node !== primaryColumn) node.removeAttribute(primaryColumnAttribute);
    });

    if (!primaryColumn) return;
    markNode(primaryColumn, primaryColumnAttribute);

    const row = primaryColumn.parentElement;
    if (row) {
      setImportantStyle(row, "display", "flex");
      setImportantStyle(row, "justify-content", "center");
      setImportantStyle(row, "gap", "0px");
      setImportantStyle(row, "width", "100%");
      setImportantStyle(row, "background", "transparent");
    }

    const toolBar = primaryColumn.querySelector('[data-testid="toolBar"]');
    if (toolBar) {
      setImportantStyle(toolBar, "background", "transparent");
      setImportantStyle(toolBar, "box-shadow", "none");
    }
  }
"""#
}
