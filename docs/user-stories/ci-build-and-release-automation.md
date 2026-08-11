# User Story: CI Build and Release Automation

## Story

As a maintainer, I want GitHub Actions to build Lattice on every pull
request and to produce a signed, notarized release artifact when I
push a version tag — so that broken code is caught before merge and
cutting a release does not depend on my laptop.

## Context

No `.github/` directory exists. PR #1 (`ece0ea0`) merged with no
automated verification. Releasing today would mean manual
`xcodebuild` + `codesign` + `notarytool` runs, which is exactly the
kind of step that silently rots.

Requires [[repo-hygiene-and-shared-scheme]] (CI needs a shared
scheme) and the signing decisions in
[[release-artifact-and-signing]].

## Acceptance Criteria

1. **PR workflow.** On `pull_request` and pushes to `main`, a
   `macos-latest` runner builds the `Lattice` scheme in Release and
   fails the job on any compile error or warning-as-error policy the
   project adopts.
2. **Runner image matches the deployment target.** The workflow pins
   an Xcode version capable of building against
   `MACOSX_DEPLOYMENT_TARGET` ([[minimum-macos-version]]) via
   `xcode-select` / `maxim-lobanov/setup-xcode`, rather than relying
   on the default image.
3. **Release workflow.** On a `v*` tag: build, sign with a Developer
   ID certificate imported from secrets into a temporary keychain,
   notarize, staple, package, and attach the artifact plus its
   checksum to a GitHub Release.
4. **Secrets handled safely.** Certificate `.p12`, its password, and
   the notarization App Store Connect key live in GitHub Actions
   secrets; the temporary keychain is deleted in an `always()` step;
   no secret is ever echoed to logs.
5. **Version consistency check.** The workflow fails if the tag does
   not match `MARKETING_VERSION`.
6. **Status visible.** A build badge in the README
   ([[readme-and-install-docs]]).
7. **Forked PRs do not need secrets.** The PR workflow builds
   unsigned (`CODE_SIGNING_ALLOWED=NO`) so external contributions can
   pass CI.

## Out of Scope

- Test execution — there is no test target yet
  ([[test-target-and-coverage]]).
- Homebrew cask bumping ([[homebrew-cask-distribution]]) and appcast
  publishing ([[auto-update]]), though both may later hang off this
  workflow.

## Open Questions

- Are GitHub-hosted macOS runners fast/cheap enough here, or is a
  self-hosted Mac preferred? (Public repos get free macOS minutes;
  confirm the repo stays public.)
- Notarization can take minutes — accept a slow release job, or
  notarize asynchronously and staple in a follow-up job?
- Should `main` be protected with CI as a required check?
- Do we want a lint/format step (`swift-format` or SwiftLint), and
  with which rules?
