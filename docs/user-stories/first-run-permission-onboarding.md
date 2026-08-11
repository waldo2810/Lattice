# User Story: First-Run Permission Onboarding

## Story

As a first-time Lattice user, I want the app to tell me clearly that
it needs Accessibility permission, walk me to the right System
Settings pane, and start working as soon as I grant it — so that I am
never left pressing ⌃⌥Space and watching nothing happen.

## Context

`AppDelegate.applicationDidFinishLaunching` calls
`accessibility.requestPermission()`, which shows the system prompt and
logs a warning if untrusted (`Accesibility.swift`). That is the entire
onboarding. Consequences today:

- Lattice has no Dock icon and no window (`main.swift`,
  `.accessory`), so a user who dismisses the system prompt has no
  visible affordance to recover.
- `AXIsProcessTrustedWithOptions` is checked once at launch. If the
  user grants permission afterwards, nothing re-checks; the overlay
  opens but `Accessibility.setFrame` fails and only writes to
  `Log.error`, which the user never sees.
- Distribution changes this: a downloaded, notarized build
  ([[release-artifact-and-signing]]) will hit this path on every
  fresh machine, whereas the developer's machine was granted long ago.

## Acceptance Criteria

1. **State is observable.** The menu bar reflects permission state —
   a distinct icon or a menu item reading e.g. "Accessibility
   permission required" — whenever the process is untrusted.
2. **One-click path to the setting.** A menu item (and/or a button in
   an onboarding window) opens
   `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
   directly.
3. **Recovers without relaunch.** Lattice detects the grant while
   running (poll `AXIsProcessTrusted()` on an interval or on
   `NSWorkspace` activation) and clears the warning state — a manual
   relaunch is not required.
4. **Hotkey does something useful when untrusted.** Pressing ⌃⌥Space
   without permission shows the permission guidance instead of an
   overlay that cannot place anything.
5. **Failures are user-visible, not just logged.** When placement
   fails at commit time (per
   [[cell-selection-window-placement]] AC 9), the user gets some
   feedback beyond an `os_log` line.
6. **Verified against a truly first-run state** — tested with
   `tccutil reset Accessibility co.waasabi.Lattice`, not just in the
   developer's already-trusted environment.

## Out of Scope

- A full multi-screen onboarding tour.
- Screen Recording or Input Monitoring permissions (not currently
  used — confirm the Carbon hotkey path in `HotKeyManager` does not
  need Input Monitoring).

## Open Questions

- Onboarding window on first launch, or menu-bar-only guidance?
  A window requires temporarily switching to `.regular` activation
  policy (same problem `openSettings` in `AppDelegate` already has).
- Polling interval for the trust re-check, and does it need to stop
  once granted? (Cheap call, but it is a timer running forever.)
- What is the user-visible failure channel for AC 5 — a
  `NSUserNotification`/`UNNotification`, a brief overlay message, or
  a menu-bar badge?
- Does `tccutil reset` need the signed bundle ID to behave the same
  as a real first run on a stranger's Mac?
