# Lattice User Stories

One story per file. Each has **Story / Context / Acceptance Criteria /
Out of Scope**, and — for the not-yet-built ones — **Open Questions**
to resolve before work starts.

## Shipped

- [Select Two Grid Cells to Place the Active Window](cell-selection-window-placement.md)

## Making Lattice usable by people other than the author

Ordered roughly by dependency. Everything under "Distribution"
assumes the two foundation stories are done first.

### Foundation

| Story | Why it blocks |
|---|---|
| [Clean repo and shared scheme](repo-hygiene-and-shared-scheme.md) | Nobody else — and no CI — can build a scheme that lives in the author's `xcuserdata`. |
| [Minimum macOS version](minimum-macos-version.md) | Deployment target is 26.1 by accident; almost nobody can run the build. |

### Distribution

| Story | Why it matters |
|---|---|
| [Signed, notarized release artifact](release-artifact-and-signing.md) | No release exists. Signing is also what keeps the Accessibility grant across updates. |
| [CI build and release automation](ci-build-and-release-automation.md) | Makes releases repeatable and PRs verifiable. |
| [Homebrew cask](homebrew-cask-distribution.md) | The install path this audience expects. |
| [In-app updates](auto-update.md) | Direct downloaders otherwise never learn a new version shipped. Likely deferrable. |

### First-run experience

| Story | Why it matters |
|---|---|
| [App icon and visible menu bar item](app-identity-and-menu-bar-icon.md) | The app icon set is empty (no images), so Finder and the permission list show a placeholder. |
| [First-run permission onboarding](first-run-permission-onboarding.md) | Without Accessibility, the hotkey silently does nothing and the failure is log-only. |
| [Launch at login](launch-at-login.md) | A hotkey utility you must relaunch each boot gets abandoned. |

### Function

| Story | Why it matters |
|---|---|
| [Settings window](settings-window.md) | Settings menu item only `print`s; grid and hotkey are hardcoded. Biggest usability gap. |
| [Multi-monitor support](multi-monitor-support.md) | `NSScreen.screens.first` only. Predictable first bug report. |

### Sustainability

| Story | Why it matters |
|---|---|
| [README and install docs](readme-and-install-docs.md) | The README is four lines and documents no keystrokes. |
| [Contributor onboarding](contributor-onboarding.md) | No CONTRIBUTING, no issue templates; window-manager bug reports are useless without environment detail. |
| [Test target and coverage](test-target-and-coverage.md) | No tests. The geometry/Y-flip math is exactly what breaks silently. |

## Cross-cutting open questions

These recur across several stories and are worth deciding once:

1. **Paid Apple Developer account — yes or no?** Gates signing,
   notarization, Homebrew acceptance, Sparkle, and stable
   Accessibility grants. The single highest-leverage decision here.
2. **What is the real minimum macOS version?** Every distribution
   surface has to state it consistently.
3. **Are outside contributions wanted yet?** Changes how much of the
   Sustainability section is worth building now.
4. **Cell-label scheme beyond 26 cells** — caps how configurable the
   grid can get ([settings](settings-window.md),
   [multi-monitor](multi-monitor-support.md)).
5. **Icon and screenshot assets** — no designer on the project.
