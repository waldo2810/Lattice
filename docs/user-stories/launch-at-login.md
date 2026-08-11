# User Story: Launch at Login

## Story

As a daily Lattice user, I want Lattice to start automatically when I
log in, toggleable from the app, so that my window-tiling hotkey is
always available without me remembering to launch a menu-bar app.

## Context

Nothing in the codebase registers a login item. A hotkey utility that
must be manually launched after every reboot is a utility people stop
using in week two.

Modern approach is `SMAppService.mainApp.register()` (macOS 13+),
which requires no helper bundle and no deprecated
`SMLoginItemSetEnabled`. It does require the app to be properly signed
([[release-artifact-and-signing]]) and living in a stable location —
registering from `~/Downloads` or from Xcode's DerivedData produces
confusing results.

## Acceptance Criteria

1. **Toggle exists.** A "Launch at Login" checkbox in Settings
   ([[settings-window]]) or a checkmarked menu item in the status
   menu.
2. **Reflects real state.** The toggle reads
   `SMAppService.mainApp.status` at display time, so it stays correct
   if the user removes Lattice via System Settings → General →
   Login Items.
3. **Registration errors surfaced.** A failed `register()` (unsigned
   build, app not in `/Applications`) tells the user why instead of
   silently leaving the toggle on.
4. **Verified across a reboot** with a signed build installed in
   `/Applications` — Lattice appears in the menu bar with no window
   and no Dock icon.
5. **Off by default.** Never enabled without the user asking.
6. **Clean uninstall.** Documented: deleting the app leaves no
   orphaned login item ([[readme-and-install-docs]] troubleshooting).

## Out of Scope

- A separate launcher helper bundle.
- MDM / enterprise deployment.

## Open Questions

- Offer this in first-run onboarding
  ([[first-run-permission-onboarding]]), or leave it entirely
  opt-in from Settings?
- `SMAppService` requires macOS 13+ — consistent with whatever
  [[minimum-macos-version]] settles on?
- Should Lattice detect it is running from a non-`/Applications`
  path and warn (also relevant to Accessibility grant stability)?
