# Manual Test Checklist

The unit tests in `LatticeTests` cover the pure logic: grid math, the
AppKit ↔ Accessibility coordinate flip, screen selection and the
two-keypress selection state machine. Everything below needs a real Mac
with a real TCC grant and real windows, so it cannot run in CI.

Run this list before tagging a release, and re-run the sections a pull
request touches.

## How to run

```sh
xcodebuild test -project Lattice.xcodeproj -scheme Lattice \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Then build and launch the app (`⌘R` in Xcode) and work through the
sections below.

## 1. Accessibility permission

Reset the grant first so you see the first-run path:

```sh
tccutil reset Accessibility co.waasabi.Lattice
```

- [ ] On first launch the system permission prompt appears.
- [ ] Denying it: the app stays alive, the menu bar icon is present, and
      triggering the overlay logs an error instead of crashing.
- [ ] Granting it (System Settings → Privacy & Security → Accessibility)
      and relaunching: window placement works.
- [ ] Revoking the grant while the app is running: the next placement
      attempt fails quietly, with no partial move or resize.

## 2. Menu bar item

- [ ] The Lattice icon appears in the menu bar at launch.
- [ ] No Dock icon and no app switcher entry (the app runs as an
      accessory).
- [ ] The menu shows Settings and Quit Lattice.
- [ ] Quit Lattice terminates the app and removes the icon.

## 3. Hotkey registration

- [ ] ⌃⌥Space opens the overlay from any frontmost app.
- [ ] It still works when the frontmost app is full-screen.
- [ ] It still works after the machine has been asleep and woken.
- [ ] With another app holding the same shortcut, Lattice's registration
      fails without crashing (check Console for the log line).
- [ ] Fast repeated triggers do not leave a second overlay window behind.

## 4. Overlay behaviour

- [ ] The overlay covers the visible frame only: the menu bar and the
      Dock stay visible and are not painted over.
- [ ] Cell letters read A, B, C… left to right, top to bottom.
- [ ] The first letter pressed highlights that cell and the overlay stays
      open.
- [ ] Pressing the same letter again does nothing — the overlay stays
      open and the highlight does not move.
- [ ] A second, different letter places the window and closes the
      overlay immediately.
- [ ] Escape closes the overlay with nothing selected, with an anchor
      selected, and mid-typing — never placing a window.
- [ ] A key that is not a cell letter is ignored.
- [ ] Clicking outside the overlay, or switching apps, leaves nothing
      stuck on screen.

## 5. Placement across apps

For each app: focus a window, press ⌃⌥Space, pick two cells, and check
the window lands exactly on the selected rectangle with no gap or
overshoot at the screen edges.

- [ ] **Safari** — a normal window, and a window with a pinned tab bar.
- [ ] **Terminal** — check the result is not one character row short;
      Terminal snaps to character cells and may refuse the exact height.
- [ ] **Finder** — a browser window, and a window that is currently at
      its minimum size.
- [ ] **An Electron app** (VS Code, Slack, Discord) — these are the most
      likely to ignore `kAXSizeAttribute` or apply it late.
- [ ] **System Settings** — a window with a hard minimum width.
- [ ] Any app that refuses to resize should leave the window untouched
      rather than half-moved.

Also check:

- [ ] A full-screen window is not moved into a broken state.
- [ ] A minimized window: triggering placement does not resurrect or
      corrupt it.
- [ ] The window that was frontmost when the overlay opened is the one
      that moves, even if focus changed in the meantime.

## 6. Multi-display arrangements

The Y-flip is measured against the *primary* display, so every
arrangement below is a distinct regression risk. In System Settings →
Displays, drag the arrangement into each shape and re-test section 5
with one app.

- [ ] Single display (baseline).
- [ ] Second display to the **right** of the primary.
- [ ] Second display to the **left** of the primary (negative x).
- [ ] Second display **above** the primary (negative Accessibility y).
- [ ] Second display **below** the primary.
- [ ] Displays of **different resolutions**, e.g. a 1440x900 primary with
      a 4K secondary.
- [ ] Displays with **different scale factors** (Retina + non-Retina).
- [ ] A display with a **notch** — nothing lands under it.
- [ ] Vertically **misaligned** displays (tops not level).
- [ ] The overlay opens on the display showing the frontmost window.
- [ ] With no window captured, the overlay opens on the display under the
      mouse cursor.
- [ ] **Unplugging a display while the overlay is open** dismisses it
      without placing anything.
- [ ] Rearranging displays while the overlay is open dismisses it.
- [ ] Placement onto a secondary display is not off by the primary
      display's height — the classic symptom is a window that is correct
      on the built-in screen and shifted vertically on the external one.

## 7. Sanity

- [ ] No crash logs in Console for `Lattice` after a full pass.
- [ ] Memory does not grow across ~50 overlay open/close cycles.
