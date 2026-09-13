# XGlass handoff

## 2026-09-07 — Preserve running development sessions

Build and packaging now preserve the active development instance instead of killing every XGlass process. Modes are validated before work; the packager checks again before replacing the bundle. A real build-only attempt was rejected while the running XGlass instance remained intact. Signed-process fixtures cover literal paths, arguments and symlink aliases. Existing source and status edits remain preserved.

Updated 2026-09-06 after the reload-stability pass.

Existing work covers WebKit loading/recovery, workspace restoration, unread indicators, settings, and theme components. The pre-existing diff is retained and separately checkpointed. The active source is this directory; `/Users/kevinhowe/Codex Projects Restored/XGlass` is the older reference copy.

## Validation record

Audit validation: 36 Swift tests passed using `swift test --build-system native --scratch-path /Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass`. The first default-build-engine run stalled and was stopped; this isolated fallback completed. This is a verified fallback for the current toolchain, not a permanent mandate to use the deprecated native engine. No new full live UI pass was performed by this setup task.

Latest stability milestone: `./script/test.sh` passed 36 tests, `./script/build_and_run.sh --verify` staged and launched `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app`, and live inspection showed rendered Home timeline content. Slow-load and web-process-termination paths now surface an explicit Retry state; they no longer reload automatically. Draft protection now treats a focused editor as active, including an empty comment field before the first character is entered.

See [SMOKE_CHECK.md](SMOKE_CHECK.md) for the repeatable workflow. Current audit logs and recovery references are recorded in `/Users/kevinhowe/Documents/ChatGPT/Audit skill.md files/followup/`. Build/tests and live UI observations must be reported separately. Update this section with subsequent results rather than treating a historical check as current.

## Unread badge clearing — 2026-09-06

Fixed false unread indications from retained Home prompts, accessibility-only controls, and stale aggregate page-title counts. Notification-link state is authoritative; only visible Home prompts can contribute the new-post dot. URL changes refresh the bridge. Regression fixtures cover clearing with a stale title, visually hidden controls and parents, SPA navigation, and preservation of genuine unread counts.

Validation: `./script/test.sh` passed 36 tests; signed `dist/XGlass.app` version 1.1.2 was rebuilt and launched from `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app`. Before the fix, live AX exposed “New posts available” on a post whose title had no unread count. After the fix, live Home and profile inspection showed no false unread badge. A controlled Notifications-screen read/unread cycle was not completed because active user navigation interrupted UI actions; fixtures cover that state transition without changing account read state. Git base was `ada81ef` plus the preserved dirty tree. The local badge milestone is scoped; other in-progress changes remain unstaged.

## 2026-09-07 — Image saving, page search, and late content readiness

- Image saving now streams to a temporary download file, validates image metadata before replacing the approved destination, and uses atomic sibling staging. Cookies are scoped by host/path/security/expiry and re-scoped on HTTPS redirects; sessions have bounded request/resource timeouts and no shared cookie store. X `format` query parameters select the suggested filename extension. The remembered image folder remains intact.
- Added Find in Page (Command-F), next/previous matches (Command-G/Shift-Command-G), no-match feedback, and Escape dismissal. The bar is accessible and fits the compact window.
- Readiness observation continues for at most 60 probes so late content clears a Slow warning without a reload. The toolbar now distinguishes waiting for rendered content from completed network loading.
- Packaging accepts `XGLASS_SWIFT_BUILD_SYSTEM` and `XGLASS_SWIFT_BUILD_PATH` for the existing isolated-cache fallback. Standard `./script/test.sh` encountered an invalid `.build/.../build.db`; native fallback passed all 41 tests, including cookie/filename/storage, WebKit find, and late-content fixtures.
- Staged bundle: `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app` (1.1.2), signature checked by staging script. Live compact-window inspection verified Command-F, a highlighted matching word, no-match feedback, and Escape. X currently displays its signed-out landing page; authenticated image saving and live unread clearing are not claimed as verified in this pass. No account data was cleared or sign-in attempted.
- Existing unrelated working-tree changes remain preserved. Test evidence covers the integrated working tree. Source/test backup: `/Users/kevinhowe/Library/Caches/XGlassImprovementBackup-20260907`. Reading offloaded Git pack files restored diff access; Git history was not rewritten.

## 2026-09-12 — Startup stall investigation and recovery hardening

Reproduced the user's splash-screen stall in the existing development instance. Normal Retry and compatibility-mode reload both remained on the splash. A fresh launch of the rebuilt app loaded the existing signed-in Home timeline; the intermittent stall's original cause is not conclusively isolated, and successful relaunch is not proof that X cannot stall again.

Implemented origin-revalidating Retry/Shift-Command-R, synchronous standard-appearance recovery, two-second JavaScript probe deadlines inside a 60-second monotonic observation window, exact post-ID/visibility readiness checks, explicit Stop state, and an untruncated recovery panel with direct browser and standard-appearance actions. Existing website data and preferences were retained. No automatic reloads were introduced.

Validation: 47 native SwiftPM tests passed using the existing isolated cache. Live signed `dist/XGlass.app` 1.1.2 loaded signed-in Home, opened a post with replies, returned via Back, reloaded normally, and reloaded from origin via Shift-Command-R. Focusing an empty reply editor and pressing Command-R showed the protection alert; Keep Editing preserved the document. The recovery panel was rendered and visually inspected at compact width (`/tmp/xglass-sep12-recovery-preview.png`). No posts, likes, or messages were sent. Longer sleep/wake, offline, and sustained-session behavior remain unverified in this pass. Existing unrelated edits remain preserved; validation covers the integrated working tree.

The standard test script remained in the default build engine with no further progress and was stopped; the isolated native fallback and signed launcher completed.

## 2026-09-12 — Six-area stability and usability pass

Implemented content-free startup telemetry and a readable Diagnostics event list, deferred heavy page customization, draft-protected web-view restart, old-view bridge rejection, route-safe delayed scroll saves, corrected post/sidebar selection, and persistent image-save feedback. Diagnostic copying now writes once. Session restart retains sign-in/current destination and resets the replaced view's back/forward history.

Validation: 53 native SwiftPM tests passed in the isolated cache, including 20 navigation cycles with a simulated offline failure/recovery, delayed-scroll route isolation, telemetry field filtering, deferred styling, and unread clearing/new arrivals across new documents and foreground events. A fixture initially remained hidden; explicitly simulating visibility resolved that test while retaining intentional background pausing.

Signed `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app` 1.1.2 rebuilt/launched. Live: Home loaded, a post kept Home selected rather than Profile, Restart Web Session returned to the same post with sign-in intact, Explore → Home worked, and the image picker recalled X photos. A live image save produced a valid 900×658 JPEG and showed ongoing saving feedback. Final Diagnostics UI was visually inspected: HTTP 200, document/DOM/load stages, zero reported resource/JS errors, and Ready. This is a single observed startup, not an aggregate speed claim.

Limits: real sleep/wake, weak-link network conditions, multi-hour endurance, and a controlled authenticated notification read cycle are not established by these fixtures. No posts/likes/messages were sent and notification read state was not changed for QA. Prior unrelated changes remain preserved; tests cover the integrated working tree.

## 2026-09-12 — Rendered-media loading recovery

Reproduced the intermittent warning with a visible signed-in X photo lightbox: the image had loaded, but the readiness probe required an article link and raised the Slow recovery banner. Photo/video lightboxes now count as ready when visible media has loaded; the exact-post check remains strict for ordinary status URLs, and the media fallback is limited to media paths. Home route watchers also accept a rendered Home surface when X keeps the same SPA URL. Main-frame WebKit failures are navigation-identity gated and receive one bounded content probe before XGlass reports a failure. Probe timeout tasks are cancelled after the first reply.

Validation: 57 native SwiftPM tests passed in `/Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass`, including dialog and no-dialog-role full-page media readiness, progress-indicator rejection, rendered-document failure recovery, genuine offline recovery, and the existing 20-cycle stability fixture. `XGLASS_SWIFT_BUILD_PATH=/Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass XGLASS_SWIFT_BUILD_SYSTEM=native ./script/build_and_run.sh --verify` rebuilt, staged, launched, and signed-verified `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app`. Live inspection opened an authenticated X photo lightbox and showed the image with no recovery banner; the Home timeline then remained rendered. OSLog loading events are now normalized and content-free.

Limits: this verifies the affected lightbox path and one signed launch, not multi-hour or weak-network endurance. No posts, likes, messages, or notification read state were changed. Existing unrelated working-tree edits remain preserved.

## 2026-09-13 — Deterministic startup window frame

The compact launch frame is now owned by `XGlassAppDelegate` and applies after `WindowGroup` creates the actual `NSWindow`. The controller ignores AppKit's saved window state, disables restoration on the main window, filters the hidden 500 × 500 `TUINSWindow` helper, and uses a bounded five-second scan plus 0.15/0.55-second correction checks. A restored full-screen or zoomed state is unwound only during startup; after the frame is applied, ordinary user resizing and full-screen remain available. The target is 600 × 1,059 points, positioned at the display's left edge with the existing 46-point titlebar offset in the window-server bounds; smaller displays are clamped by `XGlassStartupWindowFrame`.

Validation: 57 native SwiftPM tests passed in `/Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass`. `XGLASS_SWIFT_BUILD_PATH=/Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass XGLASS_SWIFT_BUILD_SYSTEM=native ./script/build_and_run.sh --verify` rebuilt, staged, launched, and signed-verified `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app`. Live CUA inspection showed the authenticated Home timeline in the compact window; CoreGraphics measured the XGlass window at `Width = 600`, `Height = 1059`, `X = 0`, `Y = 46`. Entering full screen, quitting, and relaunching returned to the normal compact frame with traffic-light controls.

No posts, likes, messages, notification read-state changes, or account-data resets were made. The current display and a full-screen persistence cycle are verified; multi-monitor placement, sleep/wake, weak-network endurance, and multi-hour sessions remain unverified. A local commit was not created because the existing Git object pack is truncated; all changes remain preserved in the working tree.

## 2026-09-13 — Release workflow compiler compatibility

The first `v1.2.0` GitHub Actions run validated the tag, release notes, signing secrets, certificate import, and dependency resolution, then stopped during `Run build checks` when Swift 6.3.3 crashed in batched SwiftUI IR generation for `XGlassAppearanceSettingsPage.swift` (`SmallVector` capacity overflow). No archive or GitHub release was published from that run. The test and release build scripts now pass `-Xswiftc -disable-batch-mode`, isolating primary-file compilation on that runner. A clean local SwiftPM build with the workaround passed; the standard file-provider checkout script was separately stopped after its known default-build planning stall.

The `v1.2.1` workflow confirmed that the runner still crashed while emitting `XGlassAppearanceSettingsPage.swift` even with isolated primary files. The Bool reabstraction thunk was traced to method-reference setters in that view; explicit setter closures now avoid the Swift 6.3.3 compiler path. No archive or GitHub release was published from `v1.2.1`.
