# User Story: Select Two Grid Cells to Place the Active Window

## Story

As a Lattice user, after I trigger the overlay (⌃⌥Space) and see the
lettered grid, I want to press two cell letters in sequence — one for
the top-left corner, one for the bottom-right corner — so that the
frontmost application's window snaps to the rectangle spanning those
two cells, and the overlay disappears.

Two distinct letters are always required; single-cell placement is
not supported by this story (see Out of Scope).

## Context

The overlay already renders a labeled grid (`OverlayView`,
`OverlayCellView`) sized from `Settings.overlaySettings`. Key handling
exists but is a stub:

- `OverlayView.swift:26-32` — `.onKeyPress` currently ignores every
  key except a TODO comment for cell-selection.
- `Accessibility.swift` — `resizeWindowOfApp(bundleId:newSize:)` can
  resize a window by bundle ID, but cannot move it, and has no notion
  of "the window that was frontmost when the overlay opened."
- `OverlayManager.show()` creates the overlay window but has no
  callback for "cell chosen" or "dismissed without selection."

This story covers wiring those pieces together: turning a two-key
sequence into a target rect, and applying that rect to the captured
window.

## Acceptance Criteria

1. **Capture target window at overlay open, not at selection.**
   `OverlayManager.show()` captures the frontmost app's window (via
   Accessibility) *before* the overlay window is shown/becomes key.
   That captured window reference is what gets moved and resized,
   regardless of what has focus by the time selection commits.

2. **First keypress selects the anchor corner.**
   Pressing a letter matching a visible cell label marks that cell as
   the top-left anchor. `OverlayCellView` renders that cell with a
   distinct highlighted state (border/fill) that persists until the
   overlay closes.

3. **Second keypress must differ from the anchor and commits.**
   Pressing a second, *different* letter marks that cell as the
   opposite corner and immediately commits the placement. Re-pressing
   the same anchor letter is ignored (no-op) — it does not commit and
   does not change the anchor.

4. **Corner order is normalized.**
   The two picked cells are normalized by row/col (min/max) so the
   resulting rect is well-formed regardless of which corner —
   top-left/bottom-right or top-right/bottom-left — was pressed first
   or second.

5. **Compute target frame from the two cells.**
   Given the two normalized cell row/cols and the overlay's screen
   geometry, compute a `CGRect` (origin + size) spanning from the
   top-left of the min(row,col) cell to the bottom-right of the
   max(row,col) cell, converted into the coordinate space the
   Accessibility API expects (flipped Y vs. AppKit's screen
   coordinates).

6. **Move and resize via a captured-window Accessibility method.**
   Add a new `Accessibility` method that takes the `AXUIElement`
   captured in (1) plus a target `CGRect`, and sets both
   `kAXPositionAttribute` and `kAXSizeAttribute` on it directly — no
   bundle ID re-lookup. `resizeWindowOfApp(bundleId:newSize:)` is left
   as-is for any other existing callers.

7. **Dismiss overlay on successful commit.**
   After placement is applied, the overlay window closes (same path
   `OverlayWindow` already uses for Escape, per commit `6a73a07`).

8. **Escape cancels at any point.**
   Escape closes the overlay whether pressed before the anchor, after
   the anchor but before the 2nd cell, or in general — no partial or
   accidental placement is ever applied on Escape.

9. **No-op on failure.**
   If accessibility permission is missing, or the captured window
   reference is no longer valid by commit time, log via `Log.error`
   (see existing pattern in `Accessibility.swift`) and dismiss the
   overlay without crashing and without a partial placement.

## Out of Scope

- Single-cell placement (pressing one letter alone, or the same
  letter twice) — explicitly not supported for now.
- Multi-monitor cell math beyond the primary screen (`OverlayManager`
  currently only uses `NSScreen.screens.first`).
- Mouse-driven / drag-based cell selection.
- Persisting or undoing placements.
