import Foundation

enum XGlassDOMSchedulingScript {
    static func source(baseStyles: String, themeStyles: String) -> String {
        return #"""
  function applyOverrides(reasons = paintFull, roots = []) {
    if (!document.getElementById(styleId)) {
      const style = document.createElement("style");
      style.id = styleId;
      style.textContent = `__XGLASS_BASE_STYLES__`;
      document.head.appendChild(style);
    }

    const primaryColumn = findPrimaryColumn();
    const routeKey = currentRouteKey();
    const fullLayout = (reasons & paintFull) !== 0 ||
      primaryColumn !== lastPrimaryColumn || routeKey !== lastRouteKey;

    if (fullLayout) {
      if (lastPrimaryColumn && lastPrimaryColumn !== primaryColumn &&
          document.documentElement.contains(lastPrimaryColumn)) {
        clearTopMarkers(lastPrimaryColumn);
        restoreHiddenPromotedContent(lastPrimaryColumn);
      }

      const banner = document.querySelector('header[role="banner"]');
      if (banner) {
        if (banner.getAttribute("aria-hidden") !== "true") {
          banner.setAttribute("aria-hidden", "true");
        }

        const parent = banner.parentElement;
        if (parent) {
          setImportantStyle(parent, "grid-template-columns", "minmax(0, 1fr)");
          setImportantStyle(parent, "justify-content", "center");
          setImportantStyle(parent, "column-gap", "0px");
          setImportantStyle(parent, "background", "transparent");
        }
      }

      applyPrimaryLayout(primaryColumn);
      if (primaryColumn) {
        clearTopMarkers(primaryColumn);
        hidePromotedContent(primaryColumn, [], true);
        paintTopSurface(primaryColumn, true);
      }
      lastPrimaryColumn = primaryColumn;
      lastRouteKey = routeKey;
      return;
    }

    if (!primaryColumn) return;
    if ((reasons & paintAds) !== 0) {
      hidePromotedContent(primaryColumn, roots, (reasons & restoreAds) !== 0);
    }
    if ((reasons & paintTop) !== 0) {
      paintTopSurface(primaryColumn, false);
    }
  }
  function applyTheme(theme) {
    if (!theme || !document.head) return;

    const themeKey = JSON.stringify(theme);
    let style = document.getElementById("xglass-theme-overrides");
    if (style && themeKey === lastAppliedThemeKey) return;
    if (!style) {
      style = document.createElement("style");
      style.id = "xglass-theme-overrides";
      document.head.appendChild(style);
    }

    lastAppliedThemeKey = themeKey;
    window.__xglassTheme = theme;

    style.textContent = `__XGLASS_THEME_STYLES__`;
  }

  window.__xglassSetTheme = applyTheme;
  window.__xglassSetPreferences = function(preferences) {
    const nextPreferences = Object.assign(
      { hidePromotedPosts: true, feedWidth: 760 },
      preferences || {}
    );
    const previousHidePromotedPosts = window.__xglassPreferences.hidePromotedPosts !== false;
    const nextHidePromotedPosts = nextPreferences.hidePromotedPosts !== false;
    const previousFeedWidth = Number(window.__xglassPreferences.feedWidth) || 760;
    const nextFeedWidth = Math.min(960, Math.max(620, Number(nextPreferences.feedWidth) || 760));
    nextPreferences.feedWidth = nextFeedWidth;
    window.__xglassPreferences = nextPreferences;
    document.documentElement.style.setProperty("--xglass-feed-width", `${nextFeedWidth}px`);

    let reasons = 0;
    if (previousHidePromotedPosts !== nextHidePromotedPosts) reasons |= paintAds | restoreAds;
    if (previousFeedWidth !== nextFeedWidth) reasons |= paintFull;
    if (reasons) scheduleOverrides(reasons);
  };

  function mutationElement(node) {
    if (!node) return null;
    if (node.nodeType === 1) return node;
    return node.parentElement || null;
  }

  function nodeContainsSelector(node, selector) {
    if (!node || node.nodeType !== 1) return false;
    return node.matches(selector) || Boolean(node.querySelector(selector));
  }

  function mutationMayChangePrimary(record) {
    const target = mutationElement(record.target);
    if (!target || target === document.documentElement || target === document.body) return true;

    const primarySelector =
      'main[role="main"], [data-testid="primaryColumn"], ' +
      '[data-xglass-primary-column="true"]';
    return Array.from(record.addedNodes || []).some((node) =>
      nodeContainsSelector(mutationElement(node), primarySelector)
    ) || Array.from(record.removedNodes || []).some((node) =>
      nodeContainsSelector(mutationElement(node), primarySelector)
    );
  }

  function mutationTouchesTop(record) {
    const target = mutationElement(record.target);
    if (target && (target.matches(topMutationSelector) || target.closest(topMutationSelector))) {
      return true;
    }

    return Array.from(record.addedNodes || []).some((node) =>
      nodeContainsSelector(mutationElement(node), topMutationSelector)
    );
  }

  function mutationRoots(record, primaryColumn) {
    const roots = [];
    const target = mutationElement(record.target);
    const targetRoot = target && (
      target.closest("article") ||
      target.closest('[data-testid="cellInnerDiv"]')
    );
    if (targetRoot) roots.push(targetRoot);

    Array.from(record.addedNodes || []).forEach((node) => {
      const element = mutationElement(node);
      if (!element || (primaryColumn && !primaryColumn.contains(element))) return;
      roots.push(
        element.closest("article") ||
        element.closest('[data-testid="cellInnerDiv"]') ||
        element
      );
    });
    return roots;
  }

  function scheduleFrame() {
    if (pendingFrame || document.hidden) return;
    pendingFrame = requestAnimationFrame(() => {
      pendingFrame = 0;
      const reasons = pendingReasons || paintFull;
      pendingReasons = 0;
      const roots = Array.from(pendingMutationRoots);
      pendingMutationRoots.clear();
      lastPaintAt = performance.now();
      applyOverrides(reasons, roots);
    });
  }

  function scheduleOverrides(reasons = paintFull, roots = []) {
    pendingReasons |= reasons;

    if (document.hidden) {
      pendingReasons = paintFull;
      pendingMutationRoots.clear();
      return;
    }

    roots.forEach((root) => {
      if (root) pendingMutationRoots.add(root);
    });

    const elapsed = performance.now() - lastPaintAt;
    const delay = Math.max(0, minimumPaintInterval - elapsed);
    if (delay > 0) {
      if (!pendingTimer) {
        pendingTimer = setTimeout(() => {
          pendingTimer = 0;
          scheduleFrame();
        }, delay);
      }
      return;
    }

    scheduleFrame();
  }

  if (window.__xglassTheme) applyTheme(window.__xglassTheme);

  const observer = new MutationObserver((records) => {
    let reasons = 0;
    const roots = [];
    const primaryColumn = findPrimaryColumn();

    records.forEach((record) => {
      if (record.type !== "childList") return;
      if (mutationMayChangePrimary(record)) {
        reasons |= paintFull;
        return;
      }
      if (!primaryColumn) {
        reasons |= paintFull;
        return;
      }

      const target = mutationElement(record.target);
      if (!target || (target !== primaryColumn && !primaryColumn.contains(target))) return;

      reasons |= paintAds;
      if (mutationTouchesTop(record)) reasons |= paintTop;
      roots.push(...mutationRoots(record, primaryColumn));
    });

    if (reasons) scheduleOverrides(reasons, roots);
  });
  const observerOptions = {
    childList: true,
    subtree: true
  };
  if (!document.hidden) observer.observe(document.documentElement, observerOptions);

  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      if (pendingFrame) {
        cancelAnimationFrame(pendingFrame);
        pendingFrame = 0;
      }
      if (pendingTimer) {
        clearTimeout(pendingTimer);
        pendingTimer = 0;
      }
      pendingReasons = paintFull;
      pendingMutationRoots.clear();
      observer.disconnect();
      return;
    }

    observer.observe(document.documentElement, observerOptions);
    scheduleOverrides(paintFull);
  });

  scheduleOverrides(paintFull);
})();
"""#
    }
}
