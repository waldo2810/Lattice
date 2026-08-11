# Lattice

A keyboard-driven window tiling tool for macOS.

Press a global hotkey, a lettered grid appears over your screen, and you
type two letters to snap the window you were just using into the
rectangle spanning those two cells.

<!-- TODO(maintainer): add a screenshot or GIF of the overlay grid over real
     windows here. No image assets exist in the repo yet, and this README
     deliberately does not link to one that does not exist. -->

## Similar Projects

This project came to existence as I really missed a GNOME extension called
[Tactile](https://extensions.gnome.org/extension/4548/tactile/), which is where
the two-corner, letter-per-cell idea comes from.

## Status

Early. Lattice is usable but rough: there is no released binary, the grid and
the hotkey are hardcoded, the **Settings** menu item does not open anything
yet, and only the primary display is supported. Expect to build it yourself and
to hit sharp edges. See [docs/user-stories/](docs/user-stories/) for the
planned work, written up story by story.

## Requirements

- **macOS 26.1 or newer.** The project currently sets
  `MACOSX_DEPLOYMENT_TARGET = 26.1` in `Lattice.xcodeproj/project.pbxproj`, so
  the built app refuses to launch on anything older. That value was Xcode's
  default rather than a deliberate choice — lowering it to the real floor is
  tracked in
  [Run on More Than the Newest macOS](docs/user-stories/minimum-macos-version.md).
  This README will be updated when that lands.
- **Apple Silicon.** The project uses Xcode's default architecture settings; a
  local Release build on an Apple Silicon Mac produces an `arm64`-only binary.
  A universal or Intel build has not been produced or tested.
- **Xcode 26.1 or newer** to build from source (verified with Xcode 26.1.1).
- The **Accessibility** permission, granted on first run (see below).

## Install

There are no signed releases and no Homebrew cask yet — both are planned
([release artifact](docs/user-stories/release-artifact-and-signing.md),
[Homebrew cask](docs/user-stories/homebrew-cask-distribution.md)). For now the
only way to run Lattice is to build it.

### Build from source

```sh
git clone https://github.com/waldo2810/Lattice.git
cd Lattice
xcodebuild -project Lattice.xcodeproj -scheme Lattice -configuration Release build
```

The build signs the app locally ("Sign to Run Locally"), so no Apple Developer
account or team is required.

By default the product lands in Xcode's derived data directory. To get it
somewhere you can find, build into a local path and copy the app out:

```sh
xcodebuild -project Lattice.xcodeproj -scheme Lattice -configuration Release \
  -derivedDataPath build build
cp -R build/Build/Products/Release/Lattice.app /Applications/
open /Applications/Lattice.app
```

Note that the Xcode scheme is not shared in the repository yet; `xcodebuild`
auto-creates it from the `Lattice` target, which is why the command above
works on a fresh clone. If your Xcode version ever declines to do that, use
`-target Lattice` instead of `-scheme Lattice`. Sharing the scheme is tracked
in [Clean repo and shared scheme](docs/user-stories/repo-hygiene-and-shared-scheme.md).

### Or open it in Xcode

```sh
git clone https://github.com/waldo2810/Lattice.git
cd Lattice
open Lattice.xcodeproj
```

Select the **Lattice** scheme and press **⌘R**.

## First run

1. **Grant Accessibility.** Lattice needs the Accessibility permission to move
   and resize other applications' windows. On launch it asks the system to
   prompt you. Approve the prompt, or grant it manually in
   **System Settings → Privacy & Security → Accessibility**: enable the switch
   next to **Lattice**, adding it with **+** if it is not listed.
2. **Restart Lattice** after granting the permission if the hotkey does not
   work immediately.
3. **Look in the menu bar, not the Dock.** Lattice runs as an accessory app: no
   Dock icon, no main window, just a grid icon in the menu bar. Clicking it
   gives you **Settings** and **Quit Lattice**.

Because the app is only locally signed, macOS treats a rebuilt copy as a
different app and you may have to re-grant Accessibility after rebuilding.
The app icon slot is also still empty, so Lattice shows a placeholder icon in
Finder and in the Accessibility list
([tracked here](docs/user-stories/app-identity-and-menu-bar-icon.md)).

## Usage

1. Focus the window you want to move.
2. Press **⌃⌥Space** (Control + Option + Space). A translucent grid appears
   over the primary screen, each cell labelled with a letter starting at **A**
   in the top-left and running left to right, row by row.
3. Press the letter of the cell for one corner of the target rectangle. That
   cell highlights and stays highlighted.
4. Press the letter of the cell for the opposite corner. The window snaps to
   the rectangle spanning both cells and the overlay closes.

Details worth knowing:

- The two letters must be **different**. Pressing the same letter twice is
  ignored — single-cell placement is not supported.
- Corner order does not matter: any two opposite corners work in either order.
- **Escape** cancels at any point, before or after the first letter, without
  moving anything.
- The window that moves is the one from the last app you were in before the
  overlay opened, not Lattice itself.
- The grid is **3 rows × 4 columns** (cells **A**–**L**) and is not yet
  configurable; neither is the hotkey. Both are hardcoded in
  `Lattice/Settings.swift`. A settings UI is tracked in
  [Settings window](docs/user-stories/settings-window.md).
- Placement uses the screen's visible frame, so tiled windows avoid the menu
  bar and the Dock.

## Troubleshooting

**Nothing happens when I press ⌃⌥Space.**

- Accessibility permission is missing or stale. Check
  **System Settings → Privacy & Security → Accessibility**, toggle **Lattice**
  off and on, and relaunch the app. A rebuild invalidates a previous grant.
- Another app owns the shortcut. Control+Option+Space is registered as a global
  Carbon hotkey and will silently fail to register if something else — an input
  source switcher, Spotlight, Alfred, Raycast — already has it. Free it in
  **System Settings → Keyboard → Keyboard Shortcuts**, or quit the other app to
  test. The hotkey is not remappable in Lattice yet.
- Lattice isn't running. There is no Dock icon; look for the grid icon in the
  menu bar and relaunch if it is gone.

**The overlay appears but the window doesn't move.**

Accessibility can capture some windows and not others; full-screen and some
non-standard windows reject position or size changes. Check the logs below —
failures are logged, never shown on screen.

**The Settings menu item does nothing.**

Correct, for now: it only logs to stdout and switches the app to a regular
(Dock-visible) app without opening a window. Quit and relaunch to get back to
the menu-bar-only state. Tracked in
[Settings window](docs/user-stories/settings-window.md).

**Reading the logs.**

Lattice logs through `os.Logger` with subsystem `co.waasabi.Lattice` and
category `Lattice`. In **Console.app**, select your Mac under *Devices*, press
**Start streaming**, and search for `co.waasabi.Lattice` (switch the search
field to *Subsystem* for an exact match). Or from a terminal:

```sh
log stream --predicate 'subsystem == "co.waasabi.Lattice"' --level debug
```

Permission problems and failed placements show up there as warnings and errors.

## Known limitations

- **Primary screen only.** The overlay is always drawn on
  `NSScreen.screens.first` (`Lattice/Overlay/OverlayManager.swift`), and cell
  geometry is computed against that screen. Multi-monitor support is tracked in
  [Multi-monitor support](docs/user-stories/multi-monitor-support.md).
- **Hotkey and grid are hardcoded** (`Lattice/Settings.swift`).
- **Maximum 26 cells**, because cells are labelled A–Z.
- **No released binary, no auto-update, no launch at login** yet.

## Documentation

- [docs/user-stories/](docs/user-stories/) — planned work, one story per file,
  each with acceptance criteria and open questions.
- [docs/architecture.md](docs/architecture.md) — a map of the source tree and
  how a hotkey press becomes a moved window.
- [CONTRIBUTING.md](CONTRIBUTING.md) — building from source, the Accessibility
  caveat for local builds, code style, and how to report a bug or propose a
  change.

## License

MIT. See [LICENSE](LICENSE).
