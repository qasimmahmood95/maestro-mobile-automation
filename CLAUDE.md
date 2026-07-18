# maestro-mobile-automation

Portfolio repo: a small, well-organised Maestro E2E suite for Android, run
against the Sauce Labs **My Demo App** (prebuilt APK, no app build step).
This repo exists to close a stack-coverage gap — keep it small and finished,
not sprawling.

## What this repo is (and is not)

- **Is:** launch/onboarding coverage, an auth flow with state reuse, one core
  shopping journey, one negative-path test, Android emulator CI with recorded
  artifacts, and visible subflow composition.
- **Is not:** a flagship framework, a cross-platform matrix, or a place for
  speculative abstractions. One platform (Android) in CI. iOS is documented as
  a local-only lane — do not add macOS runners.

## App under test

- Sauce Labs My Demo App (native Android): `saucelabs/my-demo-app-android`.
- APK is downloaded from a **pinned GitHub release tag** (currently `2.2.0`,
  asset `mda-2.2.0-25.apk`) and verified by SHA-256 before install. Never
  point CI at "latest".
- App ID: `com.saucelabs.mydemoapp.android`.
- Login accepts any non-empty credentials; `alice@example.com` is a
  locked-out user (deterministic error → the negative-path test). Use
  `bob@example.com` / `10203040` as the canonical happy-path credentials.
- The app is fully offline for our flows — no backend, no test-account
  provisioning, no network flakiness in assertions.

## Repository layout

```
.maestro/
  config.yaml            # workspace config (flow ordering, tags)
  flows/                 # runnable top-level flows, one behaviour each
    00-launch.yaml
    10-login-success.yaml
    11-login-locked-out.yaml   # negative path
    20-checkout-journey.yaml
  subflows/              # composition units, invoked via runFlow — never run directly
    login.yaml
    add-first-product-to-cart.yaml
    ...
.github/workflows/e2e-android.yaml
docs/PLAN.md             # milestone plan and progress
docs/ios-local-lane.md   # (M4) how to run the suite locally on iOS — never in CI
```

Rules for flows:

- Shared steps live in `.maestro/subflows/` and are invoked with `runFlow`.
  If two flows share more than ~3 identical steps, extract a subflow.
- Prefer `id:` selectors (the app has stable resource-ids) over text; fall
  back to text only for assertions on user-visible copy, or combined with an
  `id:` to disambiguate views that share a resource-id (drawer rows).
  Write ids anchored at the resource-name boundary — `id: ".*:id/nameET"` —
  never as a bare suffix (`.*nameET` also matches `fullNameET`).
- `hideKeyboard` is a BACK keypress on Android: with the keyboard closed it
  pops the fragment instead. Use it ONLY on the line directly after an
  `inputText` (the soft keyboard is then guaranteed up — CI runs confirmed
  the IME appears and hides the lower half of long forms), never anywhere
  else.
  Subflows that take parameters must not declare `env:` defaults: a flow's
  own `env:` block overrides values passed via `runFlow`.
- State reuse: only `00-launch.yaml` uses `clearState: true`. Later flows
  launch without clearing so login state persists across the sequence where
  Maestro allows; each flow must still self-heal (log in via subflow if
  logged out) so it can run standalone.
- Negative-path test must assert on the specific locked-out error message,
  not merely "login did not succeed".

## CI

- Single workflow, single job: `.github/workflows/e2e-android.yaml`,
  ubuntu-latest with KVM, `reactivecircus/android-emulator-runner`, API 30
  x86_64, pixel_5 profile. The mutation check runs in the same emulator
  session right after the suite passes (the suite's green run of the
  negative-path flow is its control) — don't split it into a second job;
  that doubles emulator cost and races the AVD cache.
- Hard budget: **15 minutes wall clock**. If a change pushes past that, cut
  scope (AVD snapshot caching first, then fewer API levels — never add more).
- Every run uploads artifacts: Maestro debug output (screenshots on failure),
  a full-session `adb screenrecord` video, and JUnit XML.
- Emulators cannot run in local dev containers here (no KVM) — treat CI as
  the only execution environment; verify YAML locally with `maestro check`
  / dry-run tooling only.

## Workflow conventions

- **Conventional commits** (`feat:`, `fix:`, `ci:`, `docs:`, `test:`).
- Work happens in milestone branches/PRs per `docs/PLAN.md`.
- **Before each milestone PR:** run a code-review subagent over the diff and
  address findings.
- **Before merging flow changes:** run the verification subagent — it
  triggers a clean-emulator CI run of the full flow set, and additionally
  confirms the negative-path test *fails* when its locked-out assertion is
  inverted (mutation check), proving the test can actually fail.
- README must keep an honest "What this demonstrates / What it doesn't"
  section — update it when scope changes, in either direction.
