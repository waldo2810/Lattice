# User Story: A Test Target for the Pure Logic

## Story

As a maintainer accepting pull requests from strangers, I want the
geometry and selection logic covered by automated tests, so that a
contributor's change that breaks window placement fails in CI instead
of on a user's Mac.

## Context

`Lattice.xcodeproj` has one target and no test target. Most of the app
is genuinely hard to test (Carbon hotkeys, AX permission prompts,
NSStatusItem), but the part most likely to break silently is pure
arithmetic:

- `Overlay/OverlayGeometry.swift` — grid → rect math.
- Two-cell corner normalization and the AppKit↔Accessibility Y-flip
  ([[cell-selection-window-placement]] AC 4/5), which is exactly the
  kind of code that is off by a menu bar height and nobody notices
  until a bug report.
- Cell-label → row/col mapping, which changes if grid size becomes
  configurable ([[settings-window]]).

Multi-monitor coordinate conversion
([[multi-monitor-support]]) multiplies these cases beyond what manual
testing covers.

## Acceptance Criteria

1. **Unit test target added** to the project and to the shared
   scheme ([[repo-hygiene-and-shared-scheme]]), runnable via
   `xcodebuild test`.
2. **Geometry covered.** Tests for: single-cell spans, full-grid
   spans, reversed corner order (bottom-right pressed first),
   non-square grids, and Y-flip conversion against a screen frame
   with a non-zero origin.
3. **Selection state machine covered.** First key sets anchor;
   same key twice is a no-op; second distinct key commits; Escape
   clears — testable if that logic is extracted from the SwiftUI view
   into a plain type.
4. **Testability refactor is minimal.** Pure logic is pulled out of
   `OverlayView`/`OverlayManager` into free functions or a small
   value type; no dependency-injection framework.
5. **CI runs tests** on every PR ([[ci-build-and-release-automation]]
   AC 1) and fails the build on failure.
6. **Manual test checklist** for what is not automatable (permission
   prompt, hotkey registration, real window placement across common
   apps: Safari, Terminal, Finder, an Electron app) lives in
   `docs/`.

## Out of Scope

- UI tests driving the overlay via XCUITest (fragile against a
  borderless key window and a global hotkey).
- Coverage percentage targets.
- Testing the Accessibility API against real apps in CI (headless
  runners have no windows and no TCC grant).

## Open Questions

- XCTest or Swift Testing? Swift Testing needs a recent toolchain,
  which the project already assumes.
- Is a refactor for testability welcome now, or premature while the
  overlay code is still moving?
- Which apps belong on the manual checklist — is there a known list
  of apps that ignore `kAXSizeAttribute`?
