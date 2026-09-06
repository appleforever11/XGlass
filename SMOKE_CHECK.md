# XGlass smoke check

Run the relevant automated commands in [AGENTS.md](AGENTS.md), then exercise the affected scenarios below when runtime verification is required. Use the project's staged app rather than a bare GUI executable. Preserve user data and existing installations.

1. Record the staged `dist/XGlass.app` path and version; launch through the project script after checking existing app sessions.
2. Inspect feed, a post, back navigation, Settings, and a narrow window. Confirm content loads rather than just the URL changing.
3. Exercise a harmless search and rapid destination switching; check the final destination and bounded loading state.
4. For recovery changes, test unsent writing with a disposable draft and confirm reload protection; do not send it. Preserve any pre-existing draft.
5. For unread changes, compare the native badge with X's exposed signals without marking messages read merely to produce a test result.
6. Record what was tested live separately from fixture results. Sleep/reconnection and long-duration performance checks remain explicit scenarios.

Record date, Git revision plus any dirty state, bundle path/version, relevant test result, interactions actually observed, and any blocker. Use sanitized screenshots where useful. A process/signature check alone is not UI proof.
