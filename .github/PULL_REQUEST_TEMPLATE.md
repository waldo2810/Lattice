<!--
Thanks for the PR. Lattice has no automated tests and no CI yet, so the
"tested on" section below is the only verification that exists. Please
do not delete it.
-->

## What this changes

<!-- One or two sentences. What is different for the user or the
     contributor after this lands? -->

## Why

<!-- The problem, or a link to the issue / user story. If this
     implements a story in docs/user-stories/, link it and say which
     acceptance criteria it does and does not meet. -->

Related issue / story:

## Testing

**Tested on macOS __________** (version and build, e.g. 26.1.1 (25C101))
**Mac model / architecture:** __________ (e.g. MacBook Pro M3 — arm64)
**Display setup:** __________ (how many displays, which is primary)

### Verified manually how

<!-- Replace with what you actually did. Be specific: which apps, which
     cells, what you saw. "Tested locally" is not enough for a change
     that moves other apps' windows. -->

1.
2.
3.

### Checklist

- [ ] It builds: `xcodebuild -project Lattice.xcodeproj -scheme Lattice -configuration Debug build`
- [ ] I ran the built app and used the overlay end to end (hotkey, two letters, window moved).
- [ ] Escape still cancels the overlay, before and after the first letter.
- [ ] I re-granted Accessibility for this build before testing (a rebuild silently invalidates the old grant — see [CONTRIBUTING.md](https://github.com/waldo2810/Lattice/blob/main/CONTRIBUTING.md#the-accessibility-permission-caveat-for-local-builds)).
- [ ] I checked the log for new warnings/errors: `log stream --predicate 'subsystem == "co.waasabi.Lattice"' --level debug`
- [ ] No new `print` calls — diagnostics go through `Log`.
- [ ] Commit messages follow Conventional Commits.
- [ ] Docs updated if behaviour changed (README, `docs/architecture.md`, or the relevant user story).

### Not tested

<!-- Be honest here; it is more useful than a full set of ticks.
     e.g. "only on a single built-in display", "not tested with
     full-screen windows", "not tested on Intel". -->

## Screenshots / recording

<!-- Optional, but very helpful for anything that changes the overlay. -->
