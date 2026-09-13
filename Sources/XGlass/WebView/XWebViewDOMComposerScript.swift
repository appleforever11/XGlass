import Foundation

enum XGlassDOMComposerScript {
    static let source = #"""
  function composerDescriptor(node) {
    return [
      node.getAttribute("data-testid"),
      node.getAttribute("aria-label"),
      node.getAttribute("placeholder"),
      node.getAttribute("data-placeholder")
    ].map(normalized).filter(Boolean).join(" ");
  }

  function isReplyComposerControl(node, articleRect) {
    if (!isComposerControl(node)) return false;

    const descriptor = composerDescriptor(node);
    if (/post\s+your\s+reply|reply\s+to|reply/.test(descriptor)) return true;
    if (!articleRect) return false;

    const rect = node.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && rect.top >= articleRect.bottom - 12;
  }

  function isReplyButton(node) {
    if (!node.matches('button, [role="button"]')) return false;

    const values = [
      node.getAttribute("data-testid"),
      node.getAttribute("aria-label"),
      node.getAttribute("title"),
      node.textContent
    ].map(normalized).filter(Boolean);

    return values.some((value) =>
      /tweetbutton/.test(value) || value === "reply" || /^reply\s/.test(value)
    );
  }

  function paintReplyComposer(primaryColumn, reset = false) {
    if (reset) {
      primaryColumn.querySelectorAll(`[${replyComposerAttribute}="true"]`).forEach((node) => {
        node.removeAttribute(replyComposerAttribute);
      });
      primaryColumn.querySelectorAll(`[${replySurfaceAttribute}="true"]`).forEach((node) => {
        node.removeAttribute(replySurfaceAttribute);
      });
      primaryColumn.querySelectorAll(`[${replyControlAttribute}="true"]`).forEach((node) => {
        node.removeAttribute(replyControlAttribute);
      });
      primaryColumn.querySelectorAll(`[${replyButtonAttribute}="true"]`).forEach((node) => {
        node.removeAttribute(replyButtonAttribute);
      });
    }
    const visibleDMContainer = Array.from(
      primaryColumn.querySelectorAll('[data-testid="dm-container"]')
    ).some(isVisible);
    if (visibleDMContainer) return;

    const columnRect = primaryColumn.getBoundingClientRect();
    if (!columnRect.width || !columnRect.height) return;

    const firstArticle = primaryColumn.querySelector("article[role=\"article\"], article");
    const firstArticleRect = firstArticle?.getBoundingClientRect();
    const visibleArticle = firstArticleRect && firstArticleRect.width > 0 && firstArticleRect.height > 0
      ? firstArticleRect
      : null;
    const articleRect = visibleArticle;

    const composerControls = Array.from(primaryColumn.querySelectorAll(
      '[data-testid*="tweetTextarea"], [contenteditable="true"], [role="textbox"], ' +
      'textarea, input'
    )).filter((node) => {
      const rect = node.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    });
    const composerControl = composerControls.find((node) =>
      isReplyComposerControl(node, articleRect)
    );
    if (!composerControl) return;

    let current = composerControl;
    let composer = null;
    let fallback = null;
    let fallbackArea = 0;
    let opaqueArea = 0;
    for (let depth = 0; current && current !== primaryColumn && depth < 16; depth += 1) {
      const rect = current.getBoundingClientRect();
      if (rect.width >= Math.max(280, columnRect.width * 0.68) &&
          rect.height >= 52 && rect.height <= 460 &&
          (!articleRect || rect.top >= articleRect.bottom - 24)) {
        const area = rect.width * rect.height;
        if (area > fallbackArea) {
          fallback = current;
          fallbackArea = area;
        }
        if (isOpaqueBlack(getComputedStyle(current).backgroundColor) && area > opaqueArea) {
          composer = current;
          opaqueArea = area;
        }
      }
      current = current.parentElement;
    }

    composer = composer || fallback;
    if (!composer) composer = composerControl.parentElement;
    if (!composer) return;
    markNode(composer, replyComposerAttribute);
    markNode(composer, replySurfaceAttribute);
    markNode(composerControl, replyControlAttribute);

    const controlRect = composerControl.getBoundingClientRect();
    const replyButton = Array.from(composer.querySelectorAll('button, [role="button"]'))
      .find(isReplyButton) ||
      Array.from(primaryColumn.querySelectorAll('button, [role="button"]'))
        .filter(isReplyButton)
        .filter((button) => {
          const rect = button.getBoundingClientRect();
          return rect.width > 0 && rect.height > 0 &&
            rect.top >= controlRect.top - 80 &&
            rect.bottom <= controlRect.bottom + 120 &&
            rect.left >= controlRect.left - 80;
        })
        .sort((left, right) => {
          const leftRect = left.getBoundingClientRect();
          const rightRect = right.getBoundingClientRect();
          return Math.abs(leftRect.top - controlRect.top) - Math.abs(rightRect.top - controlRect.top);
        })[0];
    if (replyButton) {
      markNode(replyButton, replyButtonAttribute);
    }
  }
"""#
}
