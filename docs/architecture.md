# Lattice Architecture

A map of the source tree, for contributors. Lattice is a single macOS
app target with no dependencies; everything below is under `Lattice/`.

## The one flow that matters

Press the hotkey, type two letters, a window moves:

1. `HotKeyManager`'s Carbon event handler fires for **⌃⌥Space** and
   calls the action it was registered with — `OverlayManager.show`.
2. `OverlayManager.show` asks `FrontmostAppTracker` which app you were
   *actually* in (Lattice is about to steal focus), and calls
   `Accessibility.captureWindow(of:)` to grab that app's focused window
   **before** the overlay appears.
3. `OverlayWindow` goes up over the primary screen hosting `OverlayView`,
   a SwiftUI grid of lettered `OverlayCellView`s.
4. `OverlayView` collects two different letters and calls back with two
   `GridCell`s.
5. `OverlayGeometry.rect(from:to:in:rows:cols:)` turns those cells into
   a rect in the screen's visible frame, and `toAccessibility(_:)`
   flips it into Accessibility coordinates.
6. `Accessibility.setFrame(of:to:)` sets `kAXPosition` then `kAXSize` on
   the captured window. `OverlayManager.dismiss()` tears the overlay
   down either way.

## Files

### `main.swift`

The entry point — the target has no `@main` type. Creates
`NSApplication.shared` and the `AppDelegate`, sets the activation policy
to **`.accessory`** (no Dock icon, no menu bar of its own, no main
window — Lattice lives only in the status bar), and calls `app.run()`.

### `AppDelegate.swift`

Owns the app's lifetime objects: the `NSStatusItem`, `OverlayManager`,
`HotKeyManager`, `Accessibility` and `Settings`. On
`applicationDidFinishLaunching` it does three things in order:

1. `accessibility.requestPermission()` — prompts for Accessibility if
   Lattice is not trusted.
2. `setupMenuBar()` — a square status item using the SF Symbol `grid`,
   with **Settings** and **Quit Lattice**.
3. `setupDefaultShortcut()` — builds the hardcoded ⌃⌥Space `HotKey`,
   constructs the `OverlayManager`, registers the hotkey against
   `overlayManager.show`, and starts listening.

The **Settings** item is a placeholder: it flips the activation policy
to `.regular` and `print`s, without opening a window — and does not flip
back, so the Dock icon sticks until relaunch. A real settings window is
tracked in
[Settings window](user-stories/settings-window.md).

### `HotKey/` — the global hotkey

Carbon's `RegisterEventHotKey` is used because it is still the only
system-wide hotkey API that works without extra privileges (an
`NSEvent` global monitor would need Accessibility too, and would see
every keystroke).

- **`HotKey.swift`** — value types. `HotKey` is a `Key` plus
  `[Modifier]`; both wrap the raw Carbon constants
  (`kVK_Space`, `controlKey`, `optionKey`, …) so the rest of the code
  never imports `Carbon.HIToolbox`.
- **`HotKeyManager.swift`** — `register(hotKey:action:)` ORs the
  modifiers together, calls `RegisterEventHotKey` with an
  auto-incrementing `EventHotKeyID`, and stores the ref and the closure
  in dictionaries keyed by that id. `listen()` installs a single
  `kEventHotKeyPressed` handler (guarded so it only installs once),
  passes `self` through as an unretained opaque pointer, and on each
  event pulls the `EventHotKeyID` back out and invokes the matching
  closure.

Registration **fails silently** if another app already owns the
combination — the failure is only a `Log.error`. That is the first thing
to check when the hotkey "does nothing".

### `Overlay/` — the grid

- **`OverlayManager.swift`** — the coordinator described in the flow
  above. Holds the captured `AXUIElement` between the two keypresses.
  Always uses `NSScreen.screens.first`; multi-monitor is tracked in
  [Multi-monitor support](user-stories/multi-monitor-support.md).
- **`OverlayWindow.swift`** — a borderless `NSWindow` sized to the
  screen's `visibleFrame` (so the grid excludes the menu bar and Dock),
  non-opaque with a translucent blue background, hosting `OverlayView`
  in an `NSHostingView`. Overrides `canBecomeKey` so a
  `.fullSizeContentView` window can take keyboard focus, and
  `cancelOperation` so **Escape** closes it. `isReleasedWhenClosed` is
  false because `OverlayManager` keeps the reference.
- **`OverlayView.swift`** — SwiftUI. Builds an A–Z-labelled
  `LazyVGrid` from `Settings.overlaySettings` (hence the 26-cell
  ceiling), takes focus on appear, and handles `onKeyPress`: a letter
  maps back to a `GridCell` by index, the first pick becomes the
  `anchor`, the second (if different) fires `onSelect`. Escape is
  returned as `.ignored` so it falls through to the window's
  `cancelOperation`.
- **`OverlayCellView.swift`** — one cell: rounded rect, tint opacity and
  a white border that changes when it is the anchor, and the letter.
- **`OverlayGeometry.swift`** — the only pure-logic file, and where the
  coordinate-space rules live. `GridCell` is `(row, col)` with **row 0
  at the top**. `rect(from:to:in:rows:cols:)` normalizes the two corners
  (either order works), divides the area into equal cells, and returns
  an **AppKit** rect (y grows up, origin bottom-left).
  `toAccessibility(_:)` converts to the **Accessibility** space (y grows
  down, origin at the top-left of the primary screen). Confusing these
  two spaces is the classic bug in this codebase; new geometry belongs
  here, not in a view.

### `Accesibility.swift` — AX capture and placement

> **The filename is misspelled (one `s`) and is being left that way on
> purpose.** The type inside is `Accessibility`, spelled correctly.
> Renaming the file would touch `project.pbxproj`, break the file's
> history for a cosmetic gain, and conflict with in-flight branches.
> Please do not open a PR for it — see
> [CONTRIBUTING.md](../CONTRIBUTING.md#the-accesibilityswift-filename-typo).

Everything that talks to the Accessibility API:

- `requestPermission()` — `AXIsProcessTrustedWithOptions` with the
  prompt option; logs a warning when untrusted.
- `captureWindow(of:)` — `AXUIElementCreateApplication(pid)`, then
  `kAXFocusedWindowAttribute`, falling back to the first of
  `kAXWindowsAttribute` because some apps only expose a focused window
  while active. Logs the `AXError` code and the current trust state on
  failure.
- `setFrame(of:to:)` — wraps origin and size in `AXValue`s and sets
  **`kAXPosition` first, then `kAXSize`**: some apps clamp a size
  against the screen the window is currently on. Takes a rect in
  Accessibility coordinates.
- `resizeWindowOfApp(bundleId:newSize:)` — an earlier
  resize-by-bundle-ID helper, not on the overlay path.

Every failure here is logged and swallowed; nothing is surfaced in the
UI. Apps that refuse `kAXSizeAttribute`, full-screen windows, and
non-standard windows all fail here, which is why bug reports need the
name of the app whose window would not move.

### `Settings.swift`

An `@Observable` class injected into the SwiftUI environment, holding
`OverlaySettings` (rows/cols) and `HotKeySettings`. Both are
**hardcoded in `init`** — a 3×4 grid and ⌃⌥Space — with no persistence
and no UI. This is the seam a real settings window plugs into
([Settings window](user-stories/settings-window.md)). Note that
`AppDelegate` builds its own `HotKey` for registration rather than
reading `settings.hotKeySettings`, so changing the value here alone
would not change the hotkey.

### `FrontmostAppTracker.swift`

Remembers the last activated application that is not Lattice, by
observing `NSWorkspace.didActivateApplicationNotification` and filtering
on its own pid. Needed because opening the overlay makes Lattice
frontmost, so by the time the user picks a cell,
`NSWorkspace.frontmostApplication` would be Lattice itself.

### `Log.swift`

An `enum` namespace wrapping `os.Logger` with subsystem
`Bundle.main.bundleIdentifier ?? "co.waasabi.Lattice"` and category
`Lattice`, exposing `info` / `warn` / `error`. All diagnostics go
through it. To read them:

```sh
log stream --predicate 'subsystem == "co.waasabi.Lattice"' --level debug
```

## Not in the tree yet

No test target, no CI, no shared scheme, no app icon images, no
persistence layer, no update mechanism. Each of those is a story in
[`docs/user-stories/`](user-stories/).
