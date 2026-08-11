# User Story: Clean Repo and Shared Scheme

## Story

As someone who clones Lattice from GitHub, I want the repository to
contain only project files (no per-developer Xcode state) and a
shared build scheme, so that the project opens and builds on my
machine — and on CI — without touching Xcode settings first.

## Context

`git ls-files` currently tracks per-user Xcode state that
`.gitignore:10` already declares ignored (it was committed before the
rule existed):

- `Lattice.xcodeproj/xcuserdata/wasabi.xcuserdatad/xcdebugger/Breakpoints_v2.xcbkptlist`
- `Lattice.xcodeproj/xcuserdata/wasabi.xcuserdatad/xcschemes/xcschememanagement.plist`

There is no `xcshareddata/xcschemes/Lattice.xcscheme`, so the scheme
exists only in the owner's `xcuserdata`. Anyone else — and any
`xcodebuild -scheme Lattice` invocation in CI — gets an autocreated
scheme or a "scheme not found" failure. Every other story that builds
a release ([[release-artifact-and-signing]],
[[ci-build-and-release-automation]]) depends on this one.

`.gitignore` has no `.DS_Store` rule; an untracked `.DS_Store` sits in
the repo root today.

## Acceptance Criteria

1. **Untrack per-user state.** `xcuserdata/` is removed from git
   tracking (`git rm -r --cached`) and stays ignored.
2. **Share the scheme.** A `Lattice` scheme is marked "Shared" in
   Xcode and committed at
   `Lattice.xcodeproj/xcshareddata/xcschemes/Lattice.xcscheme`.
3. **`.DS_Store` ignored.** `.gitignore` includes `.DS_Store`
   (and `**/.DS_Store`); any tracked copy is removed.
4. **Clean-clone build works.** From a fresh clone with no Xcode
   state, `xcodebuild -project Lattice.xcodeproj -scheme Lattice
   -configuration Release build` succeeds (signing to be settled in
   [[release-artifact-and-signing]]).
5. **No hardcoded developer identity.** `project.pbxproj` contains no
   `DEVELOPMENT_TEAM` value that blocks a different developer from
   building (currently `CODE_SIGN_STYLE = Automatic` with no team —
   verify this still resolves for a contributor with their own team).

## Out of Scope

- CI configuration itself ([[ci-build-and-release-automation]]).
- Signing identities and notarization
  ([[release-artifact-and-signing]]).

## Open Questions

- Should the project move to an `.xcworkspace` or stay a bare
  `.xcodeproj`? (Only matters if SPM deps like Sparkle arrive —
  see [[auto-update]].)
- Do we want `xcode-version`/`.tool-versions` pinning committed so
  contributors and CI agree on the toolchain?
- Rewrite history to purge `xcuserdata`, or just stop tracking it
  going forward? (Rewrite breaks the existing PR #1 lineage.)
