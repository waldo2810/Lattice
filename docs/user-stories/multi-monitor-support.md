# User Story: Works on the Screen I Am Using

## Story

As a user with more than one display, I want the overlay to appear on
the screen where I am currently working and place the window within
that screen's bounds — so that Lattice is not effectively
single-monitor software.

## Context

`OverlayManager.swift:17` uses `NSScreen.screens.first`
unconditionally, and [[cell-selection-window-placement]] explicitly
scoped multi-monitor out. That was fine for a personal tool; it is a
common first bug report for a published one, because multi-display
setups are exactly the population that wants a tiling tool.

Coordinate conversion matters here: AppKit screen coordinates are
bottom-left-origin with the primary screen at the origin, while the
Accessibility API (`Accessibility.setFrame`) expects top-left-origin
coordinates relative to the *primary* screen. Secondary displays —
especially those positioned above or to the left of the primary —
produce negative coordinates in one space and not the other, which is
where flipped-Y bugs hide.

## Acceptance Criteria

1. **Overlay targets the active screen.** The overlay opens on the
   screen containing the frontmost window (or the mouse cursor, if
   that is the chosen rule), not always `screens.first`.
2. **Correct coordinate conversion per screen.** The computed frame
   converts correctly for displays positioned left of, right of,
   above, and below the primary — verified with actual arrangements,
   not just arithmetic review.
3. **Mixed scale factors.** Placement is correct when Retina and
   non-Retina displays are mixed, and when displays have different
   resolutions.
4. **Visible frame respected.** Placement accounts for the menu bar,
   the Dock, and (on notched displays) the safe area, using
   `visibleFrame` rather than `frame`.
5. **Display hot-plug.** Connecting/disconnecting a display or
   changing the arrangement while Lattice runs does not leave a stale
   overlay or place windows off-screen
   (`NSApplication.didChangeScreenParametersNotification`).
6. **Documented behavior.** The README states the multi-monitor rule
   in one sentence ([[readme-and-install-docs]]).

## Out of Scope

- Moving a window *between* displays as an explicit gesture (e.g. a
  key to cycle target screens) — placement stays within one screen.
- Per-display grid configuration ([[settings-window]] is
  single-grid).
- Spaces / Mission Control interactions.

## Open Questions

- Which screen wins: the one with the frontmost window, or the one
  under the mouse? (Tactile uses the focused window's monitor;
  mouse-based is easier to reason about.)
- Show the grid on *all* screens simultaneously with distinct label
  sets, so the user picks screen and cell in one gesture? More
  powerful, much more label pressure ([[settings-window]] open
  question on labeling).
- Does the maintainer have a multi-display setup to test AC 2/3, or
  do we need contributor help?
