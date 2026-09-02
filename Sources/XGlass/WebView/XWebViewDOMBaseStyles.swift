import Foundation

enum XGlassDOMBaseStyles {
    static let source = #"""
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
        [data-xglass-primary-column="true"],
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

        main[role="main"] [data-testid="primaryColumn"],
        main[role="main"] [data-xglass-primary-column="true"] {
          width: min(100%, var(--xglass-feed-width, 760px)) !important;
          max-width: var(--xglass-feed-width, 760px) !important;
          margin-left: auto !important;
          margin-right: auto !important;
        }

        [data-testid="primaryColumn"],
        [data-xglass-primary-column="true"] {
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
        [data-xglass-primary-column="true"] > div > div:first-child,
        [data-testid="primaryColumn"] section > div:first-child,
        [data-xglass-primary-column="true"] section > div:first-child,
        [data-testid="toolBar"],
        [data-testid="floatingActionBar"] {
          background: transparent !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
          box-shadow: none !important;
          border-color: transparent !important;
        }

        [role="tablist"] [role="tab"][aria-selected="true"] {
          background: var(--xglass-accent-soft, rgba(120, 228, 225, 0.10)) !important;
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
          background: linear-gradient(
            180deg,
            color-mix(in srgb, var(--xglass-band-top, rgba(40, 111, 117, 0.72)) 78%, rgba(7, 18, 24, 0.82)),
            color-mix(in srgb, var(--xglass-band-bottom, rgba(24, 86, 95, 0.68)) 82%, rgba(7, 18, 24, 0.86))
          ) !important;
          background-image: linear-gradient(
            180deg,
            color-mix(in srgb, var(--xglass-band-top, rgba(40, 111, 117, 0.72)) 78%, rgba(7, 18, 24, 0.82)),
            color-mix(in srgb, var(--xglass-band-bottom, rgba(24, 86, 95, 0.68)) 82%, rgba(7, 18, 24, 0.86))
          ) !important;
          backdrop-filter: blur(28px) saturate(1.18) !important;
          -webkit-backdrop-filter: blur(28px) saturate(1.18) !important;
          border-color: transparent !important;
          border-radius: 18px 18px 0 0 !important;
          color: rgba(245, 252, 251, 0.96) !important;
          box-shadow: inset 0 -1px 0 var(--xglass-border, rgba(190, 235, 231, 0.16)), 0 12px 28px rgba(0, 10, 15, 0.12) !important;
          isolation: isolate !important;
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
        [data-xglass-primary-column="true"] [role="tablist"],
        [data-testid="primaryColumn"] [data-testid="ScrollSnap-List"],
        [data-xglass-primary-column="true"] [data-testid="ScrollSnap-List"] {
          background: transparent !important;
          background-image: none !important;
          backdrop-filter: none !important;
          -webkit-backdrop-filter: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-testid="primaryColumn"] [data-testid="toolBar"],
        [data-xglass-primary-column="true"] [data-testid="toolBar"],
        [data-testid="primaryColumn"] [data-testid="toolBar"] > div,
        [data-xglass-primary-column="true"] [data-testid="toolBar"] > div,
        [data-testid="primaryColumn"] [data-testid="floatingActionBar"],
        [data-xglass-primary-column="true"] [data-testid="floatingActionBar"],
        [data-testid="primaryColumn"] [data-testid="floatingActionBar"] > div,
        [data-xglass-primary-column="true"] [data-testid="floatingActionBar"] > div {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
        }

        [data-testid="primaryColumn"] [role="tablist"] [role="tab"],
        [data-xglass-primary-column="true"] [role="tablist"] [role="tab"],
        [data-testid="primaryColumn"] [data-testid="ScrollSnap-List"] [role="tab"],
        [data-xglass-primary-column="true"] [data-testid="ScrollSnap-List"] [role="tab"],
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

        [data-xglass-reply-control="true"] {
          background: transparent !important;
          background-image: none !important;
          border-color: transparent !important;
          box-shadow: none !important;
          color: rgba(248, 252, 255, 0.98) !important;
          -webkit-text-fill-color: rgba(248, 252, 255, 0.98) !important;
          caret-color: rgba(232, 247, 246, 0.96) !important;
          opacity: 1 !important;
        }

        [data-xglass-reply-control="true"]::placeholder,
        [data-xglass-reply-control="true"][data-placeholder]::before,
        [data-xglass-reply-control="true"][data-placeholder]::after,
        [data-xglass-reply-control="true"][data-placeholder] {
          color: rgba(232, 247, 246, 0.90) !important;
          -webkit-text-fill-color: rgba(232, 247, 246, 0.90) !important;
          opacity: 1 !important;
        }

        [data-xglass-reply-button="true"] {
          min-width: 76px !important;
          min-height: 40px !important;
          padding: 0 16px !important;
          background: rgba(120, 228, 225, 0.88) !important;
          border: 1px solid rgba(232, 247, 246, 0.72) !important;
          border-radius: 999px !important;
          color: rgba(5, 28, 34, 0.96) !important;
          -webkit-text-fill-color: rgba(5, 28, 34, 0.96) !important;
          opacity: 0.82 !important;
          filter: none !important;
        }

        [data-xglass-reply-button="true"] *,
        [data-xglass-reply-button="true"] svg {
          color: inherit !important;
          fill: currentColor !important;
          stroke: currentColor !important;
          -webkit-text-fill-color: currentColor !important;
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
        [data-xglass-primary-column="true"] [role="textbox"],
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
        [data-xglass-primary-column="true"] span,
        [data-testid="primaryColumn"] div[dir="ltr"],
        [data-xglass-primary-column="true"] div[dir="ltr"] {
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
"""#
}
