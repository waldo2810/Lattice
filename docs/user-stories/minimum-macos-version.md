# User Story: Run on More Than the Newest macOS

## Story

As a Mac user who is not running the very latest macOS, I want Lattice
to install and run on my system, so that the release is usable by more
than a handful of early adopters.

## Context

`project.pbxproj` sets `MACOSX_DEPLOYMENT_TARGET = 26.1` — the
default Xcode picked, not a deliberate choice. Any user below that
version gets "requires a newer version of macOS" on launch, which is
most of the potential audience.

Nothing in the current code obviously needs 26.x: the app uses
`NSStatusItem`, Carbon hotkeys (`HotKey/`), the Accessibility API,
`os.Logger`, and SwiftUI in the overlay views. The `@Observable`
macro on `Settings.swift` requires macOS 14+. SwiftUI's `.onKeyPress`
(`OverlayView.swift:26`) requires macOS 14+. So 14.0 is a plausible
floor, but must be verified by compiling.

## Acceptance Criteria

1. **Target lowered to the real floor.** `MACOSX_DEPLOYMENT_TARGET`
   is set to the lowest version the code actually compiles and runs
   against, with each API that forces the floor documented in a
   comment or in this doc.
2. **Build is clean at that target.** No availability warnings; any
   newer-API use is guarded with `if #available` or dropped.
3. **Verified at runtime, not just compile time.** The overlay,
   hotkey registration, and window placement are exercised on the
   minimum supported OS (VM or spare machine) — a clean compile
   against an older SDK does not prove the Accessibility path works.
4. **Documented.** The minimum is stated in the README
   ([[readme-and-install-docs]]), in release notes
   ([[release-artifact-and-signing]]), and in the Homebrew cask's
   `depends_on macos:` ([[homebrew-cask-distribution]]).
5. **Architecture support decided and stated** (arm64-only vs.
   universal).

## Out of Scope

- Back-porting features that genuinely require newer APIs.
- Supporting versions below whatever floor the acceptance criteria
  establish.

## Open Questions

- What is the actual floor? Candidate is macOS 14 (Sonoma) because of
  `@Observable` and `.onKeyPress`; macOS 13 would require replacing
  both. Is that trade worth it?
- Does the maintainer have access to older macOS versions for
  runtime testing, or is CI-compile-only acceptable evidence?
- Intel support: does anyone need it, given Intel Macs top out at
  macOS 26 / Tahoe being the last supported release?
