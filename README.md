# maestro-mobile-automation

Mobile E2E testing with [Maestro](https://maestro.mobile.dev) against a real
Android app, run on emulators in GitHub Actions with recorded artifacts per
run.

> **Status: planning.** Flows land per the [milestone plan](docs/PLAN.md);
> project conventions live in [CLAUDE.md](CLAUDE.md).

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

## Planned coverage

| Flow | What it shows |
|---|---|
| `00-launch` | Cold start / first-screen assertions |
| `10-login-success` | Auth happy path + login state reuse across flows |
| `11-login-locked-out` | Negative path: exact locked-out error asserted |
| `20-checkout-journey` | Catalog → cart → checkout, composed from subflows |

Shared steps (login, add-to-cart) live in `.maestro/subflows/` and are
composed with `runFlow` — no copy-pasted YAML between flows.

## CI

One Android emulator lane in GitHub Actions (KVM-enabled Linux runner,
API 30), budgeted under 15 minutes, uploading per-run artifacts: failure
screenshots, a full-session screen recording, and JUnit results. iOS is a
documented local-only lane — see `docs/ios-local-lane.md` (M4).

## What this demonstrates / what it doesn't

**Demonstrates:** Maestro flow design with real composition, auth state
reuse, a negative-path test that provably can fail, Android emulator CI with
published evidence per run, and deliberate scope control.

**Doesn't demonstrate:** cross-platform CI matrices, device farms, visual
regression, or large-suite orchestration — this repo intentionally closes a
specific stack-coverage gap and stops there.
