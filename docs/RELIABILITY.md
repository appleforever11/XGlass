# Loading and appearance improvements

XGlass now checks rendered destination content instead of accepting a changed URL or search field as a successful load. Full page loads, in-page URL changes, sidebar navigation, and wake/reconnection start a bounded content check. A stalled page offers recovery after 15 seconds (up to five additional seconds if JavaScript does not respond). A slow page or terminated web process never triggers an automatic reload; recovery remains an explicit Retry action so typing and attachments cannot be interrupted.

Manual reload and retry check unfinished writing and ask before discarding it. If that check hangs, the confirmation still appears after three seconds. Cookies remain in the existing WebKit data store. Draft text is not copied into application storage. A slow page or terminated web process never triggers an automatic reload; recovery remains an explicit Retry action so typing and attachments cannot be interrupted. Content already lost in a terminated web process cannot be reconstructed.

Scroll restoration is bounded to ten seconds after full reloads and stops on user interaction. X continues to manage scrolling during in-page navigation and back/forward history. Feed virtualization can limit restoration after a reload.

Diagnostics includes loading state, bounded local timing history, a copyable report without URLs or account content, and optional compatibility mode. Compatibility mode disables injected page styling on the next reload. Layout work retains its 250 ms throttle, caps queued roots, pauses while hidden, and records pass count and maximum duration. Health checks time out after five seconds.

Appearance adds a macOS collection: Golden Gate, Big Sur, Mojave Dusk, and Sonoma Hills. Golden Gate uses the existing Codex Studio palette, including #17110D, #2A1D17, #E3A955, and #FFF7E9. These are color themes, not bundled wallpaper images.

### Deterministic startup frame

The main `WindowGroup` launch frame is applied by the AppKit app delegate after the real XGlass window exists, rather than by a view update that can run before window creation. `ApplePersistenceIgnoreState` and `NSQuitAlwaysKeepsWindows` prevent an old maximized or full-screen frame from becoming the next launch's starting state. During the bounded startup window, the controller exits a restored full-screen or zoomed state, applies a 600 × 1,059 point frame (clamped to a smaller display), and performs two delayed corrections to cover AppKit restoration races. It ignores hidden SwiftUI helper windows and stops correcting once the user begins resizing. Website data, cookies, preferences, drafts, and the current session are not cleared as part of this policy; users can still resize or enter full screen after launch.

## Verification

Run `./script/test.sh` for the build and WebKit fixtures, then `./script/build_and_run.sh --verify` for the signed app. Fixtures cover search plus spinner, authentication, requested-post identity, dialog and full-page photo lightbox readiness (including progress-indicator rejection), rendered-document recovery after a navigation callback, draft detection, stale watchdog cancellation, compatibility script selection, palette consistency, and bounded diagnostic history.

Live follow-up scenarios: repeat feed → post → back; rapidly switch destinations; reload a scrolled page; keep an unsent draft while attempting recovery; reconnect after an interrupted connection; wake after sleep; and scroll for an extended session while comparing layout metrics, CPU, and memory. Avoid changing the whole Mac's connection or terminating unrelated WebKit processes to test these scenarios.

## Live unread bell

The native notification bell mirrors unread counts exposed by X's notification navigation badge. Page-title counts are not used because they may lag or include other surfaces. Counts above 99 display as `99+`; visible new-post prompts on Home without a count display a red dot. Hidden accessibility prompts and retained Home controls on other routes do not contribute. The accessibility label distinguishes unread updates from new posts. Updates are coalesced to one scan per 500 ms and only changed values cross the native bridge. The bridge reads the existing signed-in page, remains enabled in compatibility mode, and does not fetch a private API or mark items read. Clearing follows X's own signals. This requires XGlass to be running with its web session active; it is not an operating-system push subscription.

### Late content and image downloads

Readiness observation has a 60-second monotonic window. Each JavaScript probe times out after two seconds; a final in-flight probe can finish just after that window. Late callbacks cannot resume a probe twice. Late success dismisses the Slow warning without replacing the document. The user remains in control of reloads.

Image saves use an ephemeral disk download, destination-scoped cookies (also on redirects), 30-second request / 120-second resource timeouts, image metadata validation, and atomic replacement of an approved existing file. Invalid responses leave the existing file intact. Successful saves retain the chosen directory. X image URLs with `format` query parameters use that format in the suggested filename.


## Startup recovery hardening (2026-09-12)

Retry and Navigation → Reload from Origin (Shift-Command-R) revalidate the current document from the origin. A different pending destination uses a bounded request that bypasses local cache. Neither action deletes cookies, website data, or preferences, and both retain the draft-protection check. The recovery panel offers Open in Browser and Retry with Standard Appearance; the latter synchronously removes optional presentation scripts before reloading so it does not race the next SwiftUI update.

Readiness rejects hidden content and requires an exact requested post ID. Photo and video lightboxes count as rendered content when their visible media or rendered controls have settled, even though X may render the modal outside the article link. A visible progress indicator still blocks the media fallback. A stale image cannot satisfy a normal status URL because the media fallback is limited to media paths. Username authentication and explicit empty-state surfaces count as rendered content. Stop Loading cancels probes and exposes a retry state. Main-frame failure callbacks are matched to the active WebKit navigation and get one bounded content probe before an error is shown, so a late callback cannot replace a document that already rendered. A terminated WebKit process is reported honestly: writing already lost in that process cannot be recovered by XGlass.

## Diagnostics, session restart, and interaction checks

Startup diagnostics now record main-document HTTP status, commit/completion stages, elapsed milliseconds, and aggregate script/stylesheet/image/JavaScript error counts. The bridge accepts only fixed phase names and bounded numbers; it does not copy URLs, stack traces, error messages, or account content. Events remain in the bounded in-memory history and are readable in Diagnostics. Copy Diagnostic Report writes the clipboard once.

Heavy presentation code waits for initial interface content, with at most 240 checks per visible episode at 250 ms spacing. It stops polling while hidden; the existing styling scheduler continues to coalesce DOM work. Compatibility mode still retains diagnostics, unread, and draft bridges.

Restart Web Session is an explicit, draft-protected action in Tools and Diagnostics. It replaces the web view while retaining the default website data store, current destination, and appearance preferences. Back/forward history belongs to the replaced web view and is reset. Messages from the retired view cannot update the native draft/unread/telemetry state.

Image saves show an ongoing toolbar status and percentage when the server provides a content length. Concurrent saves are summarized. Deferred scroll saves retain the route and position captured by their scroll event so SPA navigation cannot write that position under a different route. Post URLs no longer incorrectly select Profile.
