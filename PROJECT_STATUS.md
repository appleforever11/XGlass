# XGlass handoff

## 2026-09-07 — Preserve running development sessions

Build and packaging now preserve the active development instance instead of killing every XGlass process. Modes are validated before work; the packager checks again before replacing the bundle. A real build-only attempt was rejected while the running XGlass instance remained intact. Signed-process fixtures cover literal paths, arguments and symlink aliases. Existing source and status edits remain preserved.

Updated 2026-09-05 by the Codex workspace audit.

Existing work covers WebKit loading/recovery, workspace restoration, unread indicators, settings, and theme components. The pre-existing diff is retained and separately checkpointed. The active source is this directory; `/Users/kevinhowe/Codex Projects Restored/XGlass` is the older reference copy.

## Validation record

Audit validation: 36 Swift tests passed using `swift test --build-system native --scratch-path /Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass`. The first default-build-engine run stalled and was stopped; this isolated fallback completed. This is a verified fallback for the current toolchain, not a permanent mandate to use the deprecated native engine. No new full live UI pass was performed by this setup task.

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
