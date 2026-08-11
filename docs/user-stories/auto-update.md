# User Story: In-App Updates

## Story

As a Lattice user who installed the `.app` directly, I want to be
notified when a new version exists and update from inside the app, so
that I am not silently stuck on the version I downloaded once.

## Context

Lattice is a menu-bar agent with no visible window — a user has no
natural moment to notice a new release, and there is no update
mechanism at all today. Homebrew users get updates via
`brew upgrade` ([[homebrew-cask-distribution]]), but direct
downloaders do not.

Sparkle is the standard macOS answer: it requires an EdDSA signing
key, an appcast XML feed hosted somewhere stable (GitHub Pages or the
release assets), and the SPM dependency added to the project.
Sparkle updates also replace the app bundle, which interacts with the
Accessibility grant — this must be verified, not assumed.

## Acceptance Criteria

1. **Update check exists.** Sparkle (or an equivalent) is integrated;
   "Check for Updates…" appears in the status menu.
2. **Appcast published.** Each release
   ([[release-artifact-and-signing]]) publishes/updates a signed
   appcast entry with version, release notes, minimum macOS version,
   and EdDSA signature.
3. **Automatic checks are opt-in** and asked about once, not enabled
   silently.
4. **Update preserves permission.** After an in-app update, Lattice
   still has its Accessibility grant and its login item
   ([[launch-at-login]]) — verified on a real update, since a changed
   signature would break both.
5. **Keys handled safely.** The EdDSA private key lives in CI secrets
   only ([[ci-build-and-release-automation]]); the public key is in
   `Info.plist`.
6. **No update UI for Homebrew installs**, or at least behavior that
   does not fight `brew upgrade`.

## Out of Scope

- Delta updates.
- Beta/nightly channels.

## Open Questions

- Is auto-update worth the dependency at this stage, or is
  "Homebrew + a GitHub watch" enough until there are actual users?
  This story may be deferred deliberately.
- Where does the appcast live — GitHub Pages, or a raw file in the
  repo (raw.githubusercontent caching is a known annoyance)?
- Adding Sparkle via SPM to a bare `.xcodeproj` — clean, or does it
  push us toward a workspace
  ([[repo-hygiene-and-shared-scheme]] open question)?
- How do we detect a Homebrew-managed install at runtime to suppress
  the update UI?
