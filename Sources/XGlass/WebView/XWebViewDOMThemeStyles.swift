import Foundation

enum XGlassDOMThemeStyles {
    static let source = #"""
      :root {
        --xglass-band-top: ${theme.bandTop || "rgba(40, 111, 117, 0.46)"};
        --xglass-band-bottom: ${theme.bandBottom || "rgba(24, 86, 95, 0.38)"};
        --xglass-accent: ${theme.accent || "rgb(120, 228, 225)"};
        --xglass-accent-soft: ${theme.accentSoft || "rgba(120, 228, 225, 0.15)"};
        --xglass-text: ${theme.text || "rgba(245, 252, 251, 0.96)"};
        --xglass-muted: ${theme.muted || "rgba(232, 247, 246, 0.76)"};
        --xglass-border: ${theme.border || "rgba(190, 235, 231, 0.16)"};
        --xglass-incoming-bubble: ${theme.incomingBubble || "rgba(240, 249, 248, 0.16)"};
        --xglass-outgoing-bubble: ${theme.outgoingBubble || "rgba(48, 156, 161, 0.50)"};
      }

      html {
        scrollbar-color: var(--xglass-accent-soft) transparent;
      }

      ::selection {
        background: var(--xglass-accent-soft) !important;
        color: var(--xglass-text) !important;
      }

      [data-xglass-primary-column="true"] :is(button, a, [role="button"], [role="tab"], [role="textbox"]):focus-visible {
        outline: 2px solid var(--xglass-accent) !important;
        outline-offset: -2px !important;
      }

      [data-xglass-top-band="true"] {
        background: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 78%, rgba(7, 18, 24, 0.82)),
          color-mix(in srgb, var(--xglass-band-bottom) 82%, rgba(7, 18, 24, 0.86))
        ) !important;
        background-image: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 78%, rgba(7, 18, 24, 0.82)),
          color-mix(in srgb, var(--xglass-band-bottom) 82%, rgba(7, 18, 24, 0.86))
        ) !important;
        color: var(--xglass-text) !important;
      }

      [data-xglass-primary-column="true"] [data-testid="cellInnerDiv"] {
        border-color: var(--xglass-border) !important;
      }

      [data-xglass-primary-column="true"] article :is(img, video) {
        transition: filter 140ms ease-out !important;
      }

      [data-xglass-primary-column="true"] article :is(img, video):hover {
        filter: brightness(1.025) saturate(1.02) !important;
      }

      [data-xglass-top-band="true"] [role="tab"][aria-selected="true"]::after {
        background: var(--xglass-accent) !important;
      }

      [data-xglass-top-control="true"],
      [data-xglass-add-control="true"] {
        color: var(--xglass-text) !important;
      }

      [data-xglass-top-control="true"]:hover,
      [data-xglass-top-control="true"]:focus-visible,
      [data-xglass-add-control="true"]:hover,
      [data-xglass-add-control="true"]:focus-visible {
        background: var(--xglass-accent-soft) !important;
        border-color: var(--xglass-border) !important;
      }

      [data-xglass-top-surface="true"] button[data-testid*="tweetButton"],
      [data-xglass-top-control="true"][data-testid*="tweetButton"],
      [data-xglass-reply-composer="true"] button[data-testid*="tweetButton"] {
        background: var(--xglass-accent-soft) !important;
        border-color: var(--xglass-border) !important;
        color: var(--xglass-text) !important;
      }

      [data-xglass-reply-composer="true"] {
        background: linear-gradient(180deg, var(--xglass-band-top), var(--xglass-band-bottom)) !important;
        border-color: var(--xglass-border) !important;
        color: var(--xglass-text) !important;
      }

      [data-xglass-reply-composer="true"] [role="textbox"],
      [data-xglass-reply-composer="true"] [contenteditable="true"],
      [data-xglass-reply-composer="true"] textarea,
      [data-xglass-reply-composer="true"] input {
        color: var(--xglass-text) !important;
        caret-color: var(--xglass-accent) !important;
      }

      [data-xglass-reply-composer="true"] [data-placeholder]::before,
      [data-xglass-reply-composer="true"] textarea::placeholder,
      [data-xglass-reply-composer="true"] input::placeholder {
        color: var(--xglass-muted) !important;
      }

      [data-testid="dm-message-scroller"] [data-testid^="message-text-"] {
        border-color: var(--xglass-border) !important;
        color: var(--xglass-text) !important;
        background: var(--xglass-incoming-bubble) !important;
      }

      [data-testid="dm-message-scroller"] [data-testid^="message-text-"][class~="bg-chat-accent"],
      [data-testid="dm-message-scroller"] [data-testid^="message-"][class*="justify-end"] [data-testid^="message-text-"] {
        border-color: var(--xglass-accent) !important;
        background: var(--xglass-outgoing-bubble) !important;
      }

      [data-testid="dm-message-scroller"] [data-testid^="message-text-"] a {
        color: var(--xglass-accent) !important;
      }

      [data-xglass-reply-composer="true"] {
        background: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%),
          color-mix(in srgb, var(--xglass-band-bottom) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%)
        ) !important;
        background-image: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%),
          color-mix(in srgb, var(--xglass-band-bottom) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%)
        ) !important;
        border-top-color: var(--xglass-border) !important;
        border-bottom-color: var(--xglass-border) !important;
        color: var(--xglass-text) !important;
        opacity: 1 !important;
      }

      [data-xglass-reply-surface="true"] {
        background: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%),
          color-mix(in srgb, var(--xglass-band-bottom) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%)
        ) !important;
        background-image: linear-gradient(
          180deg,
          color-mix(in srgb, var(--xglass-band-top) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%),
          color-mix(in srgb, var(--xglass-band-bottom) 62%, var(--xglass-accent) 23%, var(--xglass-text) 15%)
        ) !important;
        border-top-color: var(--xglass-border) !important;
        border-bottom-color: var(--xglass-border) !important;
        color: var(--xglass-text) !important;
        opacity: 1 !important;
      }

      [data-xglass-reply-surface="true"] div,
      [data-xglass-reply-surface="true"] section,
      [data-xglass-reply-surface="true"] form,
      [data-xglass-reply-surface="true"] [role="group"],
      [data-xglass-reply-surface="true"] [role="textbox"],
      [data-xglass-reply-surface="true"] [contenteditable="true"],
      [data-xglass-reply-surface="true"] textarea,
      [data-xglass-reply-surface="true"] input {
        background: transparent !important;
        background-image: none !important;
        border-color: transparent !important;
        box-shadow: none !important;
      }

      [data-xglass-reply-surface="true"] [role="textbox"],
      [data-xglass-reply-surface="true"] [contenteditable="true"],
      [data-xglass-reply-surface="true"] textarea,
      [data-xglass-reply-surface="true"] input {
        color: var(--xglass-text) !important;
        -webkit-text-fill-color: var(--xglass-text) !important;
        caret-color: var(--xglass-accent) !important;
        opacity: 1 !important;
      }

      [data-xglass-reply-surface="true"] [data-placeholder]::before,
      [data-xglass-reply-surface="true"] [data-placeholder]::after,
      [data-xglass-reply-surface="true"] textarea::placeholder,
      [data-xglass-reply-surface="true"] input::placeholder {
        color: var(--xglass-muted) !important;
        -webkit-text-fill-color: var(--xglass-muted) !important;
        opacity: 1 !important;
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
        border-color: transparent !important;
        box-shadow: none !important;
      }

      [data-xglass-reply-composer="true"] [role="textbox"],
      [data-xglass-reply-composer="true"] [contenteditable="true"],
      [data-xglass-reply-composer="true"] textarea,
      [data-xglass-reply-composer="true"] input,
      [data-xglass-reply-control="true"] {
        color: var(--xglass-text) !important;
        -webkit-text-fill-color: var(--xglass-text) !important;
        caret-color: var(--xglass-accent) !important;
        opacity: 1 !important;
      }

      [data-xglass-reply-composer="true"] [data-placeholder]::before,
      [data-xglass-reply-composer="true"] [data-placeholder]::after,
      [data-xglass-reply-composer="true"] textarea::placeholder,
      [data-xglass-reply-composer="true"] input::placeholder,
      [data-xglass-reply-control="true"]::placeholder,
      [data-xglass-reply-control="true"][data-placeholder]::before,
      [data-xglass-reply-control="true"][data-placeholder]::after {
        color: var(--xglass-muted) !important;
        -webkit-text-fill-color: var(--xglass-muted) !important;
        opacity: 1 !important;
      }

      [data-xglass-reply-button="true"] {
        min-width: 76px !important;
        min-height: 40px !important;
        padding: 0 16px !important;
        background: var(--xglass-accent) !important;
        background-image: none !important;
        border: 1px solid var(--xglass-accent) !important;
        border-radius: 999px !important;
        color: rgba(5, 28, 34, 0.96) !important;
        -webkit-text-fill-color: rgba(5, 28, 34, 0.96) !important;
        opacity: 1 !important;
        filter: none !important;
        box-shadow: 0 3px 10px rgba(0, 16, 20, 0.16), inset 0 1px 0 rgba(255, 255, 255, 0.24) !important;
      }

      [data-xglass-reply-button="true"] *,
      [data-xglass-reply-button="true"] svg {
        color: inherit !important;
        fill: currentColor !important;
        stroke: currentColor !important;
        -webkit-text-fill-color: currentColor !important;
      }

      [data-xglass-reply-surface="true"] button[data-testid*="tweetButton"],
      [data-xglass-reply-surface="true"] [role="button"][data-testid*="tweetButton"],
      [data-xglass-reply-surface="true"] button[aria-label*="Reply" i],
      [data-xglass-reply-surface="true"] [role="button"][aria-label*="Reply" i] {
        min-width: 76px !important;
        min-height: 40px !important;
        padding: 0 16px !important;
        background: var(--xglass-accent) !important;
        background-image: none !important;
        border: 1px solid var(--xglass-accent) !important;
        border-radius: 999px !important;
        color: rgba(5, 28, 34, 0.96) !important;
        -webkit-text-fill-color: rgba(5, 28, 34, 0.96) !important;
        opacity: 1 !important;
        filter: none !important;
        box-shadow: 0 3px 10px rgba(0, 16, 20, 0.16), inset 0 1px 0 rgba(255, 255, 255, 0.24) !important;
      }

      [data-xglass-reply-surface="true"] button[data-testid*="tweetButton"] *,
      [data-xglass-reply-surface="true"] [role="button"][data-testid*="tweetButton"] *,
      [data-xglass-reply-surface="true"] button[aria-label*="Reply" i] *,
      [data-xglass-reply-surface="true"] [role="button"][aria-label*="Reply" i] * {
        color: inherit !important;
        fill: currentColor !important;
        stroke: currentColor !important;
        -webkit-text-fill-color: currentColor !important;
      }

      [data-xglass-reply-button="true"]:hover,
      [data-xglass-reply-button="true"]:focus-visible {
        opacity: 1 !important;
        filter: brightness(1.06) !important;
      }
"""#
}
