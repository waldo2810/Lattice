# User Story: App Icon and a Visible Menu Bar Item

## Story

As a user who downloads Lattice, I want it to have a real app icon in
Finder and a recognizable, always-visible menu bar item — so that I
can tell it installed correctly and find it after launch, instead of
staring at a generic placeholder and an empty menu bar slot.

## Acceptance Criteria

1. **Menu bar icon is deliberate and available at the minimum OS.**
   `AppDelegate.swift:25` uses `NSImage(systemSymbolName: "grid",
   ...)`. `grid` resolves on macOS 26, but SF Symbol availability is
   versioned — confirm it exists at whatever
   [[minimum-macos-version]] settles on, or switch to a
   longer-standing symbol (e.g. `square.grid.3x3`) or a custom
   template image.
2. **Fallback if the image is nil.** `statusItem.button?.title` is
   set (or an assertion fires in debug) so an unavailable symbol name
   can never produce an invisible, unfindable menu bar item on a
   user's older OS.
3. **Template rendering.** The icon is a template image so it adapts
   to light/dark menu bars and to menu-bar tinting.
4. **App icon shipped.** `Assets.xcassets/AppIcon.appiconset`
   currently contains only `Contents.json` with zero image files —
   the build has no icon. Provide all listed sizes (16–512 @1x/2x)
   so Finder, Spotlight, and the Accessibility permission list show
   Lattice properly.
5. **Icon appears in the permission prompt.** The System Settings →
   Accessibility row for Lattice shows the real icon, not a
   placeholder — this is the first impression for every new user
   ([[first-run-permission-onboarding]]).
6. **Menu polish.** Menu title/items reflect the shipped app: an
   "About Lattice" item showing version, and correct copyright in
   `INFOPLIST_KEY_NSHumanReadableCopyright` (currently empty in
   `project.pbxproj`).
7. **Accessibility description.** The status item keeps a meaningful
   `accessibilityDescription` for VoiceOver.

## Out of Scope

- Icon variations per app state (permission-required badging belongs
  to [[first-run-permission-onboarding]]).
- Marketing assets beyond the app icon.

## Open Questions

- Who makes the icon? No designer is on the project — commission,
  use an SF Symbol rendered to a `.icns`, or draw something simple
  grid-shaped?
- macOS 26 icons want the layered/liquid-glass `.icon` format for
  best results; is a flat `.png` set acceptable for v1?
- Should the menu bar item be hideable, or is always-visible fine
  for a hotkey-driven app?
- Since when is the `grid` symbol available? If it is macOS 26-only,
  it must be swapped as part of lowering the deployment target.
