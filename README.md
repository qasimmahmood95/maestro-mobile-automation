# maestro-mobile-automation

[![e2e-android](https://github.com/qasimmahmood95/maestro-mobile-automation/actions/workflows/e2e-android.yaml/badge.svg)](https://github.com/qasimmahmood95/maestro-mobile-automation/actions/workflows/e2e-android.yaml)

Mobile E2E testing with [Maestro](https://maestro.mobile.dev) against a real
Android app, run on emulators in GitHub Actions with recorded artifacts per
run. Project conventions live in [CLAUDE.md](CLAUDE.md); the milestone
history is in [docs/PLAN.md](docs/PLAN.md).

## App under test, and why

**[Sauce Labs My Demo App](https://github.com/saucelabs/my-demo-app-android)**
(native Android, `com.saucelabs.mydemoapp.android`), a small e-commerce demo
app built for test-automation practice.

Reasons it won over the alternatives:

1. **Stable, pinnable builds.** Every release ships a prebuilt APK as a
   GitHub release asset (this repo pins `2.2.0`, `mda-2.2.0-25.apk`). CI
   downloads and checksum-verifies it. No app build step, no toolchain
   drift, and the suite can't break because the app silently changed.
2. **A deterministic negative path is built in.** The login screen accepts
   any non-empty credentials, but `alice@example.com` is a hard-coded
   locked-out user that always produces a specific error. That gives a real
   negative-path test with zero backend setup and zero flake.
3. **The flows we need exist without a backend.** Login, product catalog,
   cart, and checkout all work offline. No test accounts to provision, no
   network dependency in assertions, no rate limits in CI.
4. **Actively maintained lineage.** Sauce Labs deprecated its older demo
   apps (SwagLabs, the React Native app) in favour of this one, which still
   receives releases, and an iOS sibling exists for the local-only iOS lane.

Runner-up considered: the Wikipedia Android app (used in Maestro's own
examples). Rejected because its auth flow needs a real account and its
content-heavy screens make assertions timing-sensitive.

## The flows

| Flow | What it shows |
|---|---|
| `00-launch` | Cold start from cleared state, catalog renders |
| `10-login-success` | Auth happy path via the `login` subflow |
| `20-checkout-journey` | Catalog to cart to checkout to order placed |
| `11-login-locked-out` | Negative path: exact locked-out error asserted |

Shared behaviour lives in subflows under `.maestro/subflows/`, invoked with
`runFlow` rather than copy-pasted between flows:

```
10-login-success    -> login -> attempt-login
11-login-locked-out -> attempt-login
20-checkout-journey -> ensure-logged-in -> login -> attempt-login
                    -> add-first-product-to-cart
```

A note on state reuse: the app keeps its login state in memory only (a
static flag, nothing persisted), so state can only be reused while the
process lives. The suite exploits that where it can. Flows run in a fixed
order (`.maestro/config.yaml`), the checkout journey launches with
`stopApp: false` to inherit the session from the login flow, and its
`ensure-logged-in` guard logs in again when running standalone.

## CI

One workflow, one emulator job on a KVM-enabled Linux runner (API 30,
pixel_5 profile), budgeted under 15 minutes wall clock. The job installs
the SHA-256-verified APK, runs the whole suite, and then (in the same
emulator session) runs a **mutation check**: it inverts the locked-out
assertion in the negative-path flow and requires that flow to fail. Because
the un-mutated flow passed moments earlier on the same boot, a red inverted
run can only mean the assertion itself is load-bearing, not an
environmental accident. Every run uploads artifacts: Maestro debug output
(screenshots on failure), a full-session screen recording, and JUnit XML.

iOS is a documented local-only lane, see
[docs/ios-local-lane.md](docs/ios-local-lane.md).

## Running it yourself

Emulator + CI is the reference environment; locally you need any Android
emulator or device:

```sh
curl -fsSL "https://get.maestro.mobile.dev" | bash
# APK_URL and APK_SHA256 exactly as pinned in .github/workflows/e2e-android.yaml:
APK_URL=... APK_SHA256=... ./scripts/download-apk.sh
adb install -r build/app.apk
maestro test .maestro                       # full suite, suite order
maestro test --include-tags smoke .maestro  # quick launch-only check
```

## What this demonstrates / what it doesn't

**Demonstrates:** Maestro flow design with real composition, auth state
reuse within a session, a negative-path test that provably can fail
(mutation-checked in CI), Android emulator CI with published evidence per
run, supply-chain hygiene for the app binary (pinned release + checksum),
and deliberate scope control.

**Doesn't demonstrate:** cross-platform CI matrices, device farms, visual
regression, large-suite orchestration, or testing against a real backend.
This repo closes a specific stack-coverage gap and stops there.
