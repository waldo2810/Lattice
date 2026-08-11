# User Story: Install via Homebrew

## Story

As a Mac developer who installs everything through Homebrew, I want
`brew install --cask lattice` to work, so that installing and updating
Lattice fits the tooling I already use.

## Context

Homebrew is the default install path for this app's likely audience
(developers who miss a GNOME tiling extension). A cask depends on a
stable, versioned download URL and checksum from
[[release-artifact-and-signing]], and ideally an automated version
bump from [[ci-build-and-release-automation]].

Note the name collision risk: `lattice` is a generic word and may
already be taken in homebrew-cask.

## Acceptance Criteria

1. **Cask formula exists** with `version`, `sha256`, `url` pointing
   at the GitHub Release asset, `name`, `desc`, `homepage`,
   `depends_on macos:` matching [[minimum-macos-version]], and an
   `app "Lattice.app"` stanza.
2. **Installs to `/Applications`** so the Accessibility grant and
   [[launch-at-login]] behave.
3. **`zap` stanza** removes preferences (`co.waasabi.Lattice`
   defaults domain) and any Application Support files on
   `brew uninstall --zap`.
4. **Upgrade path works.** `brew upgrade --cask lattice` replaces the
   app without the user having to re-grant Accessibility (holds only
   if the signing identity is stable — see
   [[release-artifact-and-signing]] AC 4).
5. **Version bump is not manual drudgery.** Either the release
   workflow opens the bump PR, or `brew bump-cask-pr` steps are
   documented in a release checklist.
6. **README documents the command** ([[readme-and-install-docs]]).

## Out of Scope

- MacPorts, Nix, or other package managers.
- `brew install` (formula) — this is a GUI app, so cask only.

## Open Questions

- Submit to `homebrew/cask` (needs the project to meet their
  notability requirements — typically a real user base and a signed,
  notarized artifact) or start with a personal tap
  (`waldo2810/homebrew-tap`)? Personal tap is the realistic v1.
- Is the cask token `lattice` available upstream, and does the app
  need a more distinctive name if not?
- Does homebrew-cask accept an unsigned app? (It generally requires
  signed/notarized — another dependency on the Apple Developer
  account question.)
