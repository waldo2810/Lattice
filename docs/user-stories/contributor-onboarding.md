# User Story: Contributor and Issue Onboarding

## Story

As someone who wants to report a Lattice bug or send a pull request, I
want issue templates, contribution guidelines, and a clear picture of
how the code is organized — so that I can file something useful
without guessing, and the maintainer does not have to ask the same
five questions on every report.

## Context

The repo has a `LICENSE` (MIT) and one design doc
(`docs/user-stories/cell-selection-window-placement.md`), which is
already a good convention worth stating out loud. There is no
`CONTRIBUTING.md`, no `.github/ISSUE_TEMPLATE`, no PR template, and no
code-of-conduct.

Bug reports for a window manager are near-useless without macOS
version, display arrangement, and the target app's name — most
placement failures are app-specific (some apps refuse
`kAXSizeAttribute`, some clamp it) or display-specific
([[multi-monitor-support]]).

## Acceptance Criteria

1. **`CONTRIBUTING.md`** covering: how to build (Xcode version,
   scheme, signing for local dev), the Accessibility permission
   caveat for debug builds, code style, and the expectation that
   non-trivial features start as a user story in
   `docs/user-stories/` matching the existing format.
2. **Bug report template** requiring macOS version, Lattice version,
   Mac model/architecture, display setup, the app whose window
   failed, and relevant Console output (subsystem
   `co.waasabi.Lattice`, per `Log.swift`).
3. **Feature request template** that asks what the user is trying to
   do, not just what control they want.
4. **PR template** with a "tested on macOS __ / verified manually
   how" checklist — important while there are no automated tests
   ([[test-target-and-coverage]]).
5. **Architecture note.** A short section (README or
   `docs/architecture.md`) mapping the pieces: `main.swift` +
   `AppDelegate` (agent lifecycle, menu bar), `HotKey/` (Carbon
   global hotkey), `Overlay/` (grid window, geometry, key handling),
   `Accesibility.swift` (AX window capture and placement),
   `Settings.swift`, `FrontmostAppTracker.swift`, `Log.swift`.
6. **Typo decision recorded.** `Lattice/Accesibility.swift` is
   misspelled (one `s`); either rename it or note it, so contributors
   do not each open the same PR.
7. **Discoverability.** README links to CONTRIBUTING and to the
   user-stories directory.

## Out of Scope

- A governance model or maintainer team.
- Translations.
- Funding / sponsorship setup.

## Open Questions

- Does the maintainer want outside contributions at this stage, or
  should the repo be explicitly "source-available, issues welcome,
  PRs case-by-case"? This changes the tone of everything above.
- Adopt a Code of Conduct (Contributor Covenant), or skip until
  there is a community?
- GitHub Discussions on or off?
- Rename `Accesibility.swift` → `Accessibility.swift` now (small,
  churns history) or leave it?
