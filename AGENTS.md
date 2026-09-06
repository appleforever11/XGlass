# XGlass project guidance

The active native SwiftPM/WebKit X client. The older restored XGlass directory is a separate reference copy.

## Working context

Inspect Git state before editing and preserve existing work. Use [PROJECT_STATUS.md](PROJECT_STATUS.md) for the latest handoff, and [SMOKE_CHECK.md](SMOKE_CHECK.md) when verifying runtime changes. Update status after a meaningful milestone or new blocker, not every trivial edit. Keep mutable versions and dependency facts in their existing manifests.

## Commands

- Compile: `swift build --product XGlass`.
- Tests: `./script/test.sh` (includes WebKit fixtures and Sparkle test staging).
- Stage only: `./script/build_and_run.sh build`.
- Stage/launch verification: `./script/build_and_run.sh --verify`; bundle: `dist/XGlass.app`.

## Project contracts

- Read [docs/RELIABILITY.md](docs/RELIABILITY.md) for loading, draft protection, recovery, scroll restoration, and unread state.
- Preserve the existing WebKit data store, cookies, account state, and preferences. Never clear them as a routine recovery shortcut.
- Keep health checks/reloads bounded. Automatic recovery needs evidence that no unfinished writing or file input exists; an unresponsive page does not establish that.
- Preserve throttled DOM scheduling and compatibility mode. A URL change alone does not prove destination content loaded.
- Keep draft content out of application persistence and diagnostics. Avoid publishing posts, liking, or sending messages during smoke checks.

## Completion

Match checks to the change. Documentation-only edits need link/command review; UI changes need inspection of the rebuilt app on the affected screen. Record the exact bundle and tested interactions. Check running instances before a launcher that may terminate an app by name. Keep Swift source under 500 lines where applicable; split by responsibility only when needed.

Stage explicit intended paths after reviewing the diff. A recovery snapshot records work as found and is not a declaration that it is complete. Make local milestone commits for completed work; push, release, installation replacement, and external account actions require the user's corresponding request.
