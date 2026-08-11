# User Story: README That Explains Install and Use

## Story

As someone who lands on the Lattice GitHub page, I want a README that
tells me what Lattice does, what macOS version it needs, how to
install it, how to grant the permission it requires, and which keys to
press — so that I can go from "found the repo" to "tiled a window"
without reading source code.

## Context

`README.md` is 4 lines: a title, one sentence, and a link to the GNOME
Tactile extension that inspired it. Nothing about the ⌃⌥Space hotkey,
the two-letter cell selection ([[cell-selection-window-placement]]),
the Accessibility permission requirement
(`Accesibility.swift:requestPermission`), the 3×4 default grid
(`Settings.swift`), or the fact that Lattice runs as a menu-bar-only
agent (`main.swift`, `.accessory` activation policy).

`MACOSX_DEPLOYMENT_TARGET = 26.1` in `project.pbxproj` means the
current build runs on a very narrow slice of macOS — whatever the
README claims must match whatever [[minimum-macos-version]] settles
on.

## Acceptance Criteria

1. **What it is, in one screenful.** Short description, a
   screenshot or GIF of the overlay grid over real windows, and the
   inspiration credit (keep the Tactile link).
2. **Requirements.** Stated macOS minimum and Apple Silicon /Intel
   support, matching the actual build settings.
3. **Install section.** Primary path = download the release
   ([[release-artifact-and-signing]]); secondary = Homebrew
   ([[homebrew-cask-distribution]]) if it exists; tertiary = build
   from source with the exact `xcodebuild` / Xcode-open steps.
4. **First-run section.** Explains the Accessibility prompt, the exact
   System Settings path (Privacy & Security → Accessibility), and that
   Lattice appears in the menu bar with no Dock icon or window.
5. **Usage section.** ⌃⌥Space opens the overlay; press two different
   cell letters for opposite corners; Escape cancels. Notes the
   3×4 default grid and that it is not yet user-configurable
   ([[settings-window]]).
6. **Troubleshooting section.** At minimum: "nothing happens when I
   press the hotkey" (permission not granted, or hotkey taken by
   Spotlight/another app), and how to read logs
   (`Log.swift` uses `os.Logger` subsystem `co.waasabi.Lattice` →
   Console.app).
7. **Status and license.** An honest maturity note (early / expect
   rough edges) and a link to the MIT `LICENSE`.
8. **Accuracy check.** Every keystroke and menu path in the README is
   verified against a real build, not against the source alone.

## Out of Scope

- A docs site or GitHub Pages.
- Contribution guidelines ([[contributor-onboarding]]).
- Localized READMEs.

## Open Questions

- Screenshot or animated GIF, and where hosted — committed under
  `docs/` (repo weight) or a GitHub-hosted asset URL (rots if the
  issue/release is deleted)?
- Does the project want a short name/tagline and a logo, or stay
  text-only for now?
- Should README document known limitations explicitly (primary
  screen only, per `OverlayManager.swift:17`), or track those as
  GitHub issues instead?
