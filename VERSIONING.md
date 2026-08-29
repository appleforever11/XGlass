# XGlass Versioning and Release Path

XGlass uses Semantic Versioning and Git tags with a leading `v`.

## Release line

| Version shape | Meaning | Examples |
| --- | --- | --- |
| `1.0.0` | First stable GitHub release | `v1.0.0` |
| `1.0.x` | Patch, reliability, security, or compatibility release | `v1.0.1`, `v1.0.2` |
| `1.x.0` | Backward-compatible feature release | `v1.1.0` |
| `2.0.0` | Major product relaunch, migration, or new update channel | `v2.0.0` |

The prior internal `0.1.0` build is treated as a development predecessor. The
first public release from this repository is `1.0.0`.

## Every release

1. Update `CFBundleShortVersionString` and the numeric `CFBundleVersion` in `Sources/XGlass/Info.plist`.
2. Add `RELEASE_NOTES/<tag-version>.md` with end-user-facing notes.
3. Run `./script/test.sh`.
4. Run `./script/build_and_run.sh --verify` for a local launch check.
5. Run `./script/package_release.sh <version>` and `./script/package_dmg.sh`.
6. Create and push the matching tag: `git tag -a v<version> -m "XGlass <version>" && git push origin v<version>`.
7. Confirm the GitHub release contains the arm64 ZIP, DMG, appcast, and release notes.
8. Use **XGlass > Check for Updates...** to verify the next update path.

## Sparkle rules

- `SUPublicEDKey` is stable for the lifetime of the default update channel.
- `SUFeedURL` points to the latest GitHub release appcast.
- Update archives must be signed with Sparkle Ed25519 and Apple Developer ID code signing.
- Never commit the Ed25519 private key, Developer ID certificate, notarization key, OAuth secret, API key, or account token.
- The XGlass Sparkle private key belongs in the macOS Keychain or GitHub Actions secret `SPARKLE_PRIVATE_KEY`, never in this repository.
