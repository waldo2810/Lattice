# User Story: Working Settings Window

## Story

As a Lattice user, I want a Settings window where I can change the
grid size and the hotkey, and have those choices survive a restart —
so that Lattice fits my screen and my existing shortcuts instead of
forcing a hardcoded 3×4 grid and ⌃⌥Space on me.

## Context

The Settings menu item exists but does nothing useful —
`AppDelegate.openSettings` switches activation policy to `.regular`,
activates, and then `print("Open Settings!")`. It never opens a
window and never switches back to `.accessory`, so clicking it leaves
a stray Dock icon behind.

`Settings.swift` is an `@Observable` class with `OverlaySettings(rows:
3, cols: 4)` and a fixed `HotKey(.space, [.control, .option])`,
constructed in `init()` with no persistence layer. `AppDelegate`
separately builds its *own* duplicate `HotKey` in
`setupDefaultShortcut` instead of reading `settings.hotKeySettings` —
so even changing the value in `Settings` would not change the
registered hotkey.

`HotKeyManager` can `register`, but has no `unregister`, so rebinding
at runtime needs new API.

This is the largest single blocker to Lattice being usable by people
whose screens and shortcut habits differ from the author's.

## Acceptance Criteria

1. **Settings window opens and closes cleanly.** Clicking Settings
   shows a real window; closing it returns the app to `.accessory`
   so the Dock icon disappears. Re-opening reuses/refocuses the same
   window rather than stacking copies.
2. **Grid size configurable.** Rows and columns are editable within
   sane bounds; the overlay reflects the new grid the next time it
   opens. Cell labels remain unique and typeable at the maximum
   allowed size ([[cell-selection-window-placement]] assumes one
   letter per cell).
3. **Hotkey configurable.** A recorder control captures a new
   shortcut; `HotKeyManager` gains `unregister` so the old binding is
   released and the new one takes effect immediately.
4. **Conflicts handled.** If `RegisterEventHotKey` fails (shortcut
   already taken by the system or another app), the UI says so and
   keeps the previous binding rather than silently leaving the app
   with no hotkey — `HotKeyManager.register` currently just logs.
5. **Single source of truth.** `AppDelegate` registers from
   `settings.hotKeySettings.current`; the duplicated literal in
   `setupDefaultShortcut` is removed.
6. **Persistence.** Settings survive relaunch (`UserDefaults` or a
   JSON file in Application Support), with sensible defaults on
   first run and on a corrupt/missing store.
7. **Reset to defaults** is available.

## Out of Scope

- Per-app or per-screen grid profiles.
- Named layout presets / multiple saved grids.
- Import/export of settings.

## Open Questions

- SwiftUI `Settings` scene vs. an AppKit `NSWindowController`? The
  app is `NSApplication`-based with no SwiftUI `App` entry point
  (`main.swift`), which rules out the `Settings` scene as-is.
- Which labeling scheme scales past 26 cells — cap grid size at 26,
  or move to two-key sequences (which changes the selection story)?
- `UserDefaults` or a file? A file is easier for users to inspect
  and for us to version.
- Should changing the grid while the overlay is open live-update it,
  or is next-open good enough?
- Does hotkey recording need Input Monitoring permission, or does
  local `NSEvent` monitoring inside our own key window suffice?
