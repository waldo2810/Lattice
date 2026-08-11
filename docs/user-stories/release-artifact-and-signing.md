# User Story: Downloadable, Signed, Notarized Release

## Story

As a macOS user who does not own Xcode, I want to download a Lattice
`.app` from the GitHub Releases page and open it by double-clicking —
without Gatekeeper telling me the app is damaged or from an
unidentified developer — so that I can use Lattice without building
it myself.

## Context

There are no releases and no build artifact today; the only way to run
Lattice is to open `Lattice.xcodeproj` in Xcode. `project.pbxproj` has
`CODE_SIGN_STYLE = Automatic` with no `DEVELOPMENT_TEAM`, no hardened
runtime setting, and `MARKETING_VERSION = 1.0` /
`CURRENT_PROJECT_VERSION = 1` never bumped.

Lattice is an Accessibility client
(`Accesibility.swift`). macOS ties Accessibility grants to the app's
code signature: an unsigned or ad-hoc-signed build loses its grant on
every rebuild, and re-prompts users. Signing is therefore a
functional requirement, not just a distribution nicety.

Depends on [[repo-hygiene-and-shared-scheme]] for a buildable scheme.

## Acceptance Criteria

1. **Hardened runtime + Developer ID.** Release builds are signed
   with a Developer ID Application certificate and hardened runtime
   enabled.
2. **Notarized and stapled.** The artifact is submitted to Apple's
   notary service and the ticket is stapled;
   `spctl -a -vvv Lattice.app` reports "accepted / Notarized
   Developer ID".
3. **Distributable container.** Release publishes a `.dmg` or
   `.zip` (one, consistently) plus a `SHA256` checksum, attached to a
   GitHub Release for a `vX.Y.Z` tag.
4. **Stable signing identity across versions.** Bundle ID stays
   `co.waasabi.Lattice` and the signing identity is stable, so an
   upgrade does not reset the user's Accessibility grant.
5. **Versioning.** `MARKETING_VERSION` matches the release tag, and
   `CURRENT_PROJECT_VERSION` increments per release.
6. **Release notes.** Each release lists user-visible changes and
   the minimum macOS version ([[minimum-macos-version]]).
7. **Verified on a clean machine.** Downloading and launching on a
   Mac that has never built Lattice produces a working menu-bar app
   with a single Accessibility prompt.

## Out of Scope

- Automating the above ([[ci-build-and-release-automation]]).
- Homebrew ([[homebrew-cask-distribution]]) and in-app updates
  ([[auto-update]]).
- Mac App Store distribution (Accessibility API use makes it a
  non-starter; noted here so nobody re-opens it).

## Open Questions

- Does the maintainer have a paid Apple Developer account ($99/yr)?
  If not, the fallback is unsigned + documented `xattr -dr
  com.apple.quarantine` instructions — much worse UX, and the
  Accessibility grant resets on each update. **This decision blocks
  the whole story.**
- `.dmg` (with drag-to-Applications background) or plain `.zip`?
- Should the app be sandboxed? (Accessibility control of other apps
  generally requires *not* sandboxing — confirm.)
- Universal binary (arm64 + x86_64) or arm64-only?
