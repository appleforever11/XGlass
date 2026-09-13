import Foundation

enum XGlassDOMSearchScript {
    static let source = #"""
  function searchOverlayLists(primaryColumn) {
    const listSelectors = '[role="list"], [role="listbox"], [role="menu"], ul';
    const candidates = new Set();
    const comboboxes = Array.from(document.querySelectorAll(
      '[role="combobox"][aria-expanded="true"], [data-testid*="typeahead" i]'
    )).filter(isVisible);

    comboboxes.forEach((combobox) => {
      combobox.querySelectorAll(listSelectors).forEach((list) => candidates.add(list));
      ["aria-controls", "aria-owns"].forEach((attribute) => {
        (combobox.getAttribute(attribute) || "").split(/\s+/).filter(Boolean).forEach((id) => {
          const list = document.getElementById(id);
          if (list) candidates.add(list);
        });
      });
    });

    document.querySelectorAll(listSelectors).forEach((list) => {
      if (!isVisible(list)) return;
      const label = normalized(list.textContent);
      if (/\brecent\b/.test(label) || /\bclear all\b/.test(label)) {
        candidates.add(list);
      }
    });

    return Array.from(candidates).filter((list) => {
      if (!isVisible(list)) return false;
      if (primaryColumn && primaryColumn.contains(list)) return true;
      return comboboxes.length > 0;
    });
  }

  function searchOverlayNodes(primaryColumn, lists) {
    const nodes = new Set(lists);
    const columnWidth = primaryColumn?.getBoundingClientRect().width || 0;
    const minimumWidth = Math.max(260, columnWidth * 0.55);

    lists.forEach((list) => {
      let current = list.parentElement;
      for (let depth = 0; current && depth < 7; depth += 1) {
        if (current === primaryColumn || current === document.body || current === document.documentElement) {
          break;
        }

        const rect = current.getBoundingClientRect();
        if (isVisible(current) && rect.width >= minimumWidth && rect.height >= 100) {
          nodes.add(current);
          break;
        }
        current = current.parentElement;
      }
    });

    return Array.from(nodes);
  }

  const searchOriginalStyles = new WeakMap();

  function setSearchStyle(node, property, value) {
    let originals = searchOriginalStyles.get(node);
    if (!originals) {
      originals = new Map();
      searchOriginalStyles.set(node, originals);
    }
    if (!originals.has(property)) {
      originals.set(property, [node.style.getPropertyValue(property), node.style.getPropertyPriority(property)]);
    }
    setImportantStyle(node, property, value);
  }

  function restoreSearchStyle(node) {
    const originals = searchOriginalStyles.get(node);
    if (!originals) return;
    originals.forEach(([value, priority], property) => {
      if (value) node.style.setProperty(property, value, priority);
      else node.style.removeProperty(property);
    });
    searchOriginalStyles.delete(node);
  }

  function clearSearchOverlay(primaryColumn) {
    document.querySelectorAll(`[${searchOverlayAttribute}="true"]`).forEach((node) => {
      node.removeAttribute(searchOverlayAttribute);
      restoreSearchStyle(node);
    });
    document.querySelectorAll(`[${searchLayerAttribute}="true"]`).forEach((node) => {
      node.removeAttribute(searchLayerAttribute);
      restoreSearchStyle(node);
    });
    document.querySelectorAll(`[${searchHiddenAttribute}="true"]`).forEach((node) => {
      node.removeAttribute(searchHiddenAttribute);
    });
    document.querySelectorAll(`[${searchActiveAttribute}="true"]`).forEach((node) => {
      node.removeAttribute(searchActiveAttribute);
      node.style.removeProperty("--xglass-search-cover-top");
    });
  }

  function paintSearchOverlay(primaryColumn) {
    clearSearchOverlay(primaryColumn);
    const expandedCombobox = Array.from(document.querySelectorAll(
      '[role="combobox"][aria-expanded="true"], [data-testid*="typeahead" i]'
    )).find(isVisible);
    if (!expandedCombobox || !primaryColumn) return;

    const columnRect = primaryColumn.getBoundingClientRect();
    const comboboxRect = expandedCombobox.getBoundingClientRect();
    if (columnRect.width > 0 && columnRect.height > 0 && comboboxRect.height > 0) {
      markNode(primaryColumn, searchActiveAttribute);
      setSearchStyle(
        primaryColumn,
        "--xglass-search-cover-top",
        `${Math.max(0, comboboxRect.bottom - columnRect.top + 8)}px`
      );
    }

    const overlayLists = searchOverlayLists(primaryColumn);
    const overlayNodes = searchOverlayNodes(primaryColumn, overlayLists);
    const topSection = primaryColumn?.querySelector(':scope > div > div:first-child');
    if (topSection && overlayNodes.some((node) => topSection.contains(node))) {
      markNode(topSection, searchLayerAttribute);
      if (getComputedStyle(topSection).position === "static") {
        setSearchStyle(topSection, "position", "relative");
      }
      setSearchStyle(topSection, "z-index", "1001");
    }

    const protectedNodes = new Set();
    const protectedSubtrees = new Set();
    const protectSubtree = (node) => {
      if (!node || !primaryColumn || !primaryColumn.contains(node)) return;
      let current = node;
      while (current && current !== primaryColumn) {
        protectedNodes.add(current);
        current = current.parentElement;
      }
      protectedSubtrees.add(node);
    };
    protectSubtree(expandedCombobox);
    overlayLists.forEach(protectSubtree);

    // Hide complete branches and stop descending once hidden; long feeds cost no extra scans.
    const coverTop = comboboxRect.bottom + 4;
    const pending = Array.from(primaryColumn.children);
    while (pending.length) {
      const node = pending.pop();
      if (protectedSubtrees.has(node)) continue;
      if (!protectedNodes.has(node)) {
        const rect = node.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0 && rect.top >= coverTop) {
          markNode(node, searchHiddenAttribute);
          continue;
        }
      }
      pending.push(...node.children);
    }

    overlayNodes.forEach((list) => {
      markNode(list, searchOverlayAttribute);
      setSearchStyle(
        list,
        "background",
        "linear-gradient(180deg, color-mix(in srgb, var(--xglass-band-top, rgba(40, 111, 117, 0.72)) 48%, rgba(8, 20, 26, 0.98)), color-mix(in srgb, var(--xglass-band-bottom, rgba(24, 86, 95, 0.68)) 52%, rgba(8, 20, 26, 0.99)))"
      );
      setSearchStyle(list, "background-color", "rgba(11, 35, 41, 0.98)");
      setSearchStyle(list, "border", "1px solid var(--xglass-border, rgba(190, 235, 231, 0.16))");
      setSearchStyle(list, "border-radius", "16px");
      setSearchStyle(list, "box-shadow", "0 14px 34px rgba(0, 10, 15, 0.24), inset 0 1px 0 rgba(255, 255, 255, 0.06)");
      setSearchStyle(list, "isolation", "isolate");
      setSearchStyle(list, "overflow", "hidden");
      setSearchStyle(list, "opacity", "1");
      setSearchStyle(list, "filter", "none");
      if (getComputedStyle(list).position === "static") {
        setSearchStyle(list, "position", "relative");
      }
      setSearchStyle(list, "z-index", "1000");

      let current = list.parentElement;
      for (let depth = 0; current && current !== primaryColumn && depth < 8; depth += 1) {
        const computed = getComputedStyle(current);
        const createsStackingContext =
          current.hasAttribute(topBandAttribute) ||
          computed.isolation === "isolate" ||
          computed.position !== "static" ||
          computed.transform !== "none" ||
          computed.filter !== "none" ||
          computed.opacity !== "1";
        if (createsStackingContext) {
          markNode(current, searchLayerAttribute);
          if (computed.position === "static") {
            setSearchStyle(current, "position", "relative");
          }
          setSearchStyle(current, "z-index", "1001");
          break;
        }
        current = current.parentElement;
      }
    });
  }
"""#
}
