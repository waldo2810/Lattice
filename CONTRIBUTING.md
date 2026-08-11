# Contributing to Lattice

Lattice is a small, early-stage macOS menu-bar app maintained by one
person. What that means in practice:

- **Issues are welcome.** Bug reports and feature ideas are useful even
  if nothing happens immediately. Use the
  [issue templates](.github/ISSUE_TEMPLATE/) — a window-manager bug
  without the macOS version, the target app, and the display setup
  usually cannot be reproduced.
- **Pull requests are taken case by case.** There is no roadmap
  commitment and no promised review time. Small, focused PRs (a bug fix,
  a doc correction) are the easiest to accept.
- **Anything non-trivial starts as a user story**, not as code. See
  [Writing a user story](#writing-a-user-story) below. This keeps
  design arguments in Markdown, where they are cheap, instead of in a
  large diff that took you a weekend.

If you are unsure whether a change is wanted, open an issue first and
say what you are trying to do.

## Building

Requirements:

- **Xcode 26.1 or newer** (verified with Xcode 26.1.1).
- **macOS 26.1 or newer** to run the build. That deployment target is
  currently Xcode's default rather than a deliberate floor; lowering it
  is tracked in
  [Run on More Than the Newest macOS](docs/user-stories/minimum-macos-version.md).

From the command line:

```sh
git clone https://github.com/waldo2810/Lattice.git
cd Lattice
xcodebuild -project Lattice.xcodeproj -scheme Lattice -configuration Debug build
```

Or open `Lattice.xcodeproj`, select the **Lattice** scheme and press
**⌘R**.

The Xcode scheme is not shared in the repository yet (it lives in
`xcuserdata`), so on a fresh clone `xcodebuild` auto-creates it from the
`Lattice` target. If your Xcode ever declines to do that, use
`-target Lattice` instead of `-scheme Lattice`. Sharing the scheme is
tracked in
[Clean repo and shared scheme](docs/user-stories/repo-hygiene-and-shared-scheme.md).

### Signing

The project uses `CODE_SIGN_STYLE = Automatic` with **no development
team set**, which resolves to *Sign to Run Locally* — an ad-hoc
signature. You do **not** need an Apple Developer account, a team, or a
certificate to build and run Lattice locally.

Do not commit a `DEVELOPMENT_TEAM` value into `project.pbxproj`. Signed
and notarized builds are a release concern, tracked in
[Signed, notarized release artifact](docs/user-stories/release-artifact-and-signing.md).

## The Accessibility permission caveat for local builds

Lattice moves other applications' windows through the Accessibility API,
so it needs the Accessibility permission
(**System Settings → Privacy & Security → Accessibility**). While
developing you will lose that grant repeatedly. This is expected, it is
not a bug in Lattice, and it is worth understanding before you spend an
hour debugging a hotkey that "stopped working".

**Why.** macOS records a TCC grant against the app's *code signing
identity*. A properly signed app is identified by a stable designated
requirement (bundle ID + Team ID), which survives updates. An ad-hoc
signed app has no team, so its designated requirement is the code
directory hash of that exact binary. Verified on this project:

```
$ codesign -dvvv --requirements - build/Build/Products/Debug/Lattice.app
Identifier=co.waasabi.Lattice
CodeDirectory v=20400 ... flags=0x2(adhoc)
Signature=adhoc
TeamIdentifier=not set
# designated => cdhash H"9953a4666a99ba51a26f76b9d16f130be59eb693"
```

Two clean builds of *identical, unmodified* sources produced two
different hashes (`9953a466…` and `d924adb0…`), because the compiled
output is not bit-for-bit reproducible. So any build that actually
re-links and re-signs the binary produces an app that macOS considers a
different program from the one you granted.

**What you will see.** The old grant does not disappear from the list.
**Lattice** stays in the Accessibility pane with its switch still on,
while the freshly built copy is not trusted: `AXIsProcessTrusted()`
returns false, the overlay opens but no window moves, and the log shows
`Could not capture window of … Trusted: false` from
`Lattice/Accesibility.swift`. The stale entry is the confusing part —
the UI says you granted it.

**What to do about it.**

- Toggle **Lattice** off and back on in
  **System Settings → Privacy & Security → Accessibility**, then
  relaunch. If that does not take, remove the entry with **−** and add
  the new build with **+**.
- Or reset the grant for the bundle and let the app re-prompt on next
  launch:

  ```sh
  tccutil reset Accessibility co.waasabi.Lattice
  ```

- Quit the old copy before launching the new one. Two builds with the
  same bundle ID running at once will fight over the global hotkey — the
  second `RegisterEventHotKey` fails and logs `Failed to register
  hotkey`.
- Incremental builds where nothing was recompiled or re-signed keep the
  grant. It is the rebuilds that cost you.
- Running from Xcode is grantable too, but the copy in DerivedData
  changes hash on every rebuild for the same reason. Some contributors
  find it less annoying to grant a `Release` build copied to
  `/Applications` and use it for manual verification, keeping Xcode runs
  for code paths that do not need Accessibility.

## Code style

There is no formatter or linter in the repo, and no CI style check.
Match what is already there:

- Standard Swift API Design Guidelines naming; 4-space indent; Xcode's
  default formatting (**Ctrl-I** on a selection).
- `final class` when a type is not meant to be subclassed
  (`HotKeyManager`, `FrontmostAppTracker`); `enum` with `static`
  members for pure namespaces (`Log`, `OverlayGeometry`).
- `struct` for value types and view models (`HotKey`, `GridCell`,
  `OverlaySettings`).
- **Never `print`.** All diagnostics go through `Log` in
  `Lattice/Log.swift`, which wraps `os.Logger` with subsystem
  `co.waasabi.Lattice`. Use `Log.info` / `Log.warn` / `Log.error`. (The
  one surviving `print` is the placeholder `Settings` menu action in
  `AppDelegate`; do not add more.)
- **Fail loudly in the log, quietly on screen.** Accessibility calls,
  hotkey registration and screen lookups all fail in normal use. Guard,
  log the error with the API's error code, and return — do not
  `fatalError`, do not force-unwrap C API results, do not show an alert.
- Comments explain *why*, not *what*. The existing ones are good models:
  they record non-obvious platform behaviour (why position is set before
  size, why the frontmost app is tracked separately, why row 0 is the
  top row while AppKit's y grows upward). Keep that.
- Coordinate spaces are the main source of bugs here. If a function
  takes or returns a rect, say which space it is in — AppKit screen
  coordinates (y up, origin bottom-left) or Accessibility coordinates
  (y down, origin top-left of the primary screen).
- Keep AppKit/SwiftUI glue at the edges. `OverlayGeometry` is pure math
  with no UI dependency, which is what makes it testable; add new
  geometry there rather than inside a view. (There is no test target
  yet:
  [Test target and coverage](docs/user-stories/test-target-and-coverage.md).)

## Writing a user story

Non-trivial features start as a story in
[`docs/user-stories/`](docs/user-stories/), one file per story, matching
the existing format:

```markdown
# User Story: <Title>

## Story

As <role>, I want <capability> — so that <outcome>.

## Context

What exists today, which files are involved, what makes this awkward.

## Acceptance Criteria

1. **Short name.** Testable statement of what must be true.
2. ...

## Out of Scope

- Things a reviewer might otherwise expect in this change.

## Open Questions

- Decisions the maintainer still has to make.
```

Then add it to the table in
[`docs/user-stories/README.md`](docs/user-stories/README.md). "Non-trivial"
roughly means: it changes user-visible behaviour, adds a dependency,
touches how the app is built or distributed, or you cannot describe it
in one line of a commit message. Bug fixes and typo corrections do not
need a story.

## Pull requests

- Branch off `main`; branch names follow `feat/`, `fix/`, `docs/`,
  `chore/`, `ci/`.
- [Conventional Commits](https://www.conventionalcommits.org/) for
  commit subjects (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`).
- Fill in the PR template, including **which macOS version you tested
  on and what you did manually**. There are no automated tests, so a PR
  that has not been run is a PR nobody can verify.
- If the change implements a story, link it and say which acceptance
  criteria it does and does not meet.

## Known non-issues

Things that look like bugs but are deliberate. Please do not open a PR
for these.

### The `Accesibility.swift` filename typo

[`Lattice/Accesibility.swift`](Lattice/Accesibility.swift) is spelled
with one `s`. **This is known and is intentionally being left alone.**

The type inside it is spelled correctly (`Accessibility`), so nothing in
the code reads wrong — only the filename. Renaming it would touch
`project.pbxproj`, break the file's history for a cosmetic gain, and
conflict with every in-flight branch that edits it. It may be renamed
some day as part of a change that already moves the file; until then,
please leave it.

The same decision is recorded in
[`docs/architecture.md`](docs/architecture.md).

## Project layout

See [`docs/architecture.md`](docs/architecture.md) for a map of the
source tree and how a hotkey press turns into a moved window.
