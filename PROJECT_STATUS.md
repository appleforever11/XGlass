# XGlass handoff

Updated 2026-09-05 by the Codex workspace audit.

Existing work covers WebKit loading/recovery, workspace restoration, unread indicators, settings, and theme components. The pre-existing diff is retained and separately checkpointed. The active source is this directory; `/Users/kevinhowe/Codex Projects Restored/XGlass` is the older reference copy.

## Validation record

Audit validation: 36 Swift tests passed using `swift test --build-system native --scratch-path /Users/kevinhowe/Library/Caches/CodexAuditBuild/XGlass`. The first default-build-engine run stalled and was stopped; this isolated fallback completed. This is a verified fallback for the current toolchain, not a permanent mandate to use the deprecated native engine. No new full live UI pass was performed by this setup task.

See [SMOKE_CHECK.md](SMOKE_CHECK.md) for the repeatable workflow. Current audit logs and recovery references are recorded in `/Users/kevinhowe/Documents/ChatGPT/Audit skill.md files/followup/`. Build/tests and live UI observations must be reported separately. Update this section with subsequent results rather than treating a historical check as current.

## Unread badge clearing — 2026-09-06

Fixed false unread indications from retained Home prompts, accessibility-only controls, and stale aggregate page-title counts. Notification-link state is authoritative; only visible Home prompts can contribute the new-post dot. URL changes refresh the bridge. Regression fixtures cover clearing with a stale title, visually hidden controls and parents, SPA navigation, and preservation of genuine unread counts.

Validation: `./script/test.sh` passed 36 tests; signed `dist/XGlass.app` version 1.1.2 was rebuilt and launched from `/Users/kevinhowe/Documents/ChatGPT/XGlass macOS App/dist/XGlass.app`. Before the fix, live AX exposed “New posts available” on a post whose title had no unread count. After the fix, live Home and profile inspection showed no false unread badge. A controlled Notifications-screen read/unread cycle was not completed because active user navigation interrupted UI actions; fixtures cover that state transition without changing account read state. Git base was `ada81ef` plus the preserved dirty tree. The local badge milestone is scoped; other in-progress changes remain unstaged.
