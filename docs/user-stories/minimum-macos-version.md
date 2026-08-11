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

## Resolved

**Floor: macOS 14.0 (Sonoma).** `MACOSX_DEPLOYMENT_TARGET` is now `14.0`
in both the Debug and Release configurations. Determined empirically with
Xcode 26.1.1 (SDK `macosx26.1`): the Release build is clean at 14.0 and
fails at 13.0 with these availability errors, which are the APIs that set
the floor:

- `@Observable` on `Settings` (`Lattice/Settings.swift`) — the Observation
  framework, including the generated `ObservationTracked` /
  `ObservationIgnored` / `ObservationRegistrar` members, is macOS 14.0+.
- `@Environment(Settings.self)` (`Lattice/Overlay/OverlayView.swift`) —
  the Observable-backed environment initializer is macOS 14.0+.
- `.onKeyPress { … }` (`Lattice/Overlay/OverlayView.swift`) —
  `onKeyPress(phases:action:)` is macOS 14.0+. `KeyEquivalent: Equatable`
  (used by `press.key == .escape`) is also macOS 14.0+.
- `View.environment(_:)` for an Observable object
  (`Lattice/Overlay/OverlayWindow.swift`) — macOS 14.0+.

Nothing else pushes the floor up. `NSStatusItem`, the Carbon hotkey API
(`RegisterEventHotKey` / `InstallEventHandler`), `AXUIElement`,
`NSHostingView`, `os.Logger` and `NSWorkspace.didActivateApplicationNotification`
are all long-standing and available well below 14.0. The `grid` SF Symbol
used for the menu-bar icon is *not* macOS 26-only: `name_availability.plist`
in `SFSymbols.framework` lists it under release year `2019`, i.e. macOS
10.15, and it carries no usage restriction — so it was left as is.

**Build check.** `xcodebuild -project Lattice.xcodeproj -scheme Lattice
-configuration Release clean build CODE_SIGNING_ALLOWED=NO` succeeds with
zero availability warnings at 14.0. The only remaining warning is the
pre-existing Swift 6 concurrency one in `Lattice/main.swift`
("main actor-isolated conformance of 'AppDelegate' to
'NSApplicationDelegate'"), which is unrelated to the deployment target —
it is emitted identically at 26.1.

**Architecture: universal (arm64 + x86_64).** `ARCHS` is not set
explicitly in `project.pbxproj`, so it resolves from the Xcode default
`$(ARCHS_STANDARD)` to `arm64 x86_64`, and `ONLY_ACTIVE_ARCH` is `NO` for
Release. Release builds are therefore universal binaries that run natively
on Apple silicon and on Intel Macs. This was left unchanged deliberately:
Intel Macs can run macOS 14, so an arm64-only build would exclude machines
the 14.0 floor otherwise admits, and the extra slice costs only build time
and a few MB.

**Still open (not done here):** AC 3, runtime verification on macOS 14
(overlay, hotkey registration, Accessibility window placement), needs a VM
or spare machine and has not been performed. AC 4, stating the minimum in
the README, release notes and the Homebrew cask, belongs to
[[readme-and-install-docs]], [[release-artifact-and-signing]] and
[[homebrew-cask-distribution]].
