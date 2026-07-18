# maestro-mobile-automation

[![e2e-android](https://github.com/qasimmahmood95/maestro-mobile-automation/actions/workflows/e2e-android.yaml/badge.svg)](https://github.com/qasimmahmood95/maestro-mobile-automation/actions/workflows/e2e-android.yaml)

Mobile E2E testing with [Maestro](https://maestro.mobile.dev) against a real
Android app, run on emulators in GitHub Actions with recorded artifacts per
run. Project conventions live in [CLAUDE.md](CLAUDE.md); the milestone
history is in [docs/PLAN.md](docs/PLAN.md).

## App under test — and why

**[Sauce Labs My Demo App](https://github.com/saucelabs/my-demo-app-android)**
(native Android, `com.saucelabs.mydemoapp.android`), a small e-commerce demo
app purpose-built for test-automation practice.

Chosen over the alternatives for four reasons:

1. **Stable, pinnable builds.** Every release ships a prebuilt APK as a
   GitHub release asset (this repo pins `2.2.0`, `mda-2.2.0-25.apk`). CI
   downloads and checksum-verifies it — no app build step, no toolchain
   drift, and the suite can't break because the app silently changed.
2. **A deterministic negative path is built in.** The login screen accepts
   any non-empty credentials, but `alice@example.com` is a hard-coded
   locked-out user that always produces a specific error. That gives a real
   negative-path test with zero backend setup and zero flake.
3. **The flows we need exist without a backend.** Login, product catalog,
   cart, and checkout all work offline. No test accounts to provision, no
   network dependency in assertions, no rate limits in CI.
4. **Actively maintained lineage.** Sauce Labs deprecated its older demo
   apps (SwagLabs, the React Native app) *in favour of this one*, which is
   still receiving releases — and an iOS sibling exists for the documented
   local-only iOS lane.

Runner-up considered: the Wikipedia Android app (used in Maestro's own
examples) — rejected because its auth flow needs a real account and its
content-heavy screens make assertions timing-sensitive.

## The flows

| Flow | What it shows |
|---|---|
| `00-launch` | Cold start from cleared state, catalog renders |
| `10-login-success` | Auth happy path via the `login` subflow |
| `20-checkout-journey` | Catalog → cart → checkout → order placed |
| `11-login-locked-out` | Negative path: exact locked-out error asserted |

Composition instead of copy-paste — every shared behaviour is a subflow
under `.maestro/subflows/`, invoked with `runFlow`:

```
10-login-success ──▶ login ──▶ attempt-login
11-login-locked-out ─────────▶ attempt-login
20-checkout-journey ─▶ ensure-logged-in ─▶ login ─▶ attempt-login
                  └──▶ add-first-product-to-cart
```

**State reuse, honestly labelled:** the app keeps its login state in memory
only (a static flag — nothing persisted), so state can only be reused while
the process lives. The suite exploits that where it's real: flows run in a
fixed order (`.maestro/config.yaml`), the checkout journey launches with
`stopApp: false` to inherit the session from the login flow, and its
`ensure-logged-in` guard logs in again when running standalone.

## CI

One workflow, two parallel emulator jobs on KVM-enabled Linux runners
(API 30), budgeted under 15 minutes wall clock:

- **e2e** — installs the SHA-256-verified APK and runs the whole suite.
  Every run uploads artifacts: Maestro debug output (screenshots on
  failure), a full-session screen recording, and JUnit XML.
- **mutation-check** — inverts the locked-out assertion in the negative-path
  flow and requires that flow to *fail*, proving the assertion is
  load-bearing rather than vacuous.

iOS is a documented local-only lane — see
[docs/ios-local-lane.md](docs/ios-local-lane.md).

## Running it yourself

Emulator + CI is the reference environment; locally you need any Android
emulator or device with the app installed:

```sh
curl -fsSL "https://get.maestro.mobile.dev" | bash
# download + verify the pinned APK, then:
adb install mda-2.2.0-25.apk
maestro test .maestro
```

## What this demonstrates / what it doesn't

**Demonstrates:** Maestro flow design with real composition, auth state
reuse within a session, a negative-path test that provably can fail
(mutation-checked in CI), Android emulator CI with published evidence per
run, supply-chain hygiene for the app binary (pinned release + checksum),
and deliberate scope control.

**Doesn't demonstrate:** cross-platform CI matrices, device farms, visual
regression, large-suite orchestration, or testing against a real backend —
this repo intentionally closes a specific stack-coverage gap and stops
there.
