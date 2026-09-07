# Loading and appearance improvements

XGlass now checks rendered destination content instead of accepting a changed URL or search field as a successful load. Full page loads, in-page URL changes, sidebar navigation, and wake/reconnection start a bounded content check. A stalled page offers recovery after 15 seconds (up to five additional seconds if JavaScript does not respond). A slow page or terminated web process never triggers an automatic reload; recovery remains an explicit Retry action so typing and attachments cannot be interrupted.

Manual reload and retry check unfinished writing and ask before discarding it. If that check hangs, the confirmation still appears after three seconds. Cookies remain in the existing WebKit data store. Draft text is not copied into application storage. A slow page or terminated web process never triggers an automatic reload; recovery remains an explicit Retry action so typing and attachments cannot be interrupted. Content already lost in a terminated web process cannot be reconstructed.

Scroll restoration is bounded to ten seconds after full reloads and stops on user interaction. X continues to manage scrolling during in-page navigation and back/forward history. Feed virtualization can limit restoration after a reload.

Diagnostics includes loading state, bounded local timing history, a copyable report without URLs or account content, and optional compatibility mode. Compatibility mode disables injected page styling on the next reload. Layout work retains its 250 ms throttle, caps queued roots, pauses while hidden, and records pass count and maximum duration. Health checks time out after five seconds.

Appearance adds a macOS collection: Golden Gate, Big Sur, Mojave Dusk, and Sonoma Hills. Golden Gate uses the existing Codex Studio palette, including #17110D, #2A1D17, #E3A955, and #FFF7E9. These are color themes, not bundled wallpaper images.

## Verification

Run `./script/test.sh` for the build and WebKit fixtures, then `./script/build_and_run.sh --verify` for the signed app. Fixtures cover search plus spinner, authentication, requested-post identity, draft detection, stale watchdog cancellation, compatibility script selection, palette consistency, and bounded diagnostic history.

Live follow-up scenarios: repeat feed → post → back; rapidly switch destinations; reload a scrolled page; keep an unsent draft while attempting recovery; reconnect after an interrupted connection; wake after sleep; and scroll for an extended session while comparing layout metrics, CPU, and memory. Avoid changing the whole Mac's connection or terminating unrelated WebKit processes to test these scenarios.

## Live unread bell

The native notification bell mirrors unread counts exposed by X's notification navigation badge. Page-title counts are not used because they may lag or include other surfaces. Counts above 99 display as `99+`; visible new-post prompts on Home without a count display a red dot. Hidden accessibility prompts and retained Home controls on other routes do not contribute. The accessibility label distinguishes unread updates from new posts. Updates are coalesced to one scan per 500 ms and only changed values cross the native bridge. The bridge reads the existing signed-in page, remains enabled in compatibility mode, and does not fetch a private API or mark items read. Clearing follows X's own signals. This requires XGlass to be running with its web session active; it is not an operating-system push subscription.
