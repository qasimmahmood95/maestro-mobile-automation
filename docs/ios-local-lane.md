# iOS: a local-only lane

This suite runs Android in CI, full stop. iOS is supported by the same
tooling but only as something you run on your own Mac. This page explains
how, and why that boundary is deliberate.

## Why iOS is not in CI

- macOS runners are the most expensive class on GitHub Actions, and iOS
  simulator jobs are markedly slower and flakier (simulator boot, Xcode
  version drift) than Linux+KVM Android jobs. For a portfolio-scale repo the
  extra signal is near zero — the flows and the harness design are already
  demonstrated on Android.
- The 15-minute CI budget (see `CLAUDE.md`) exists to keep this repo honest.
  An iOS lane would either blow it or force cuts to the Android lane that
  actually carries the coverage.

## What you need

- A Mac with Xcode and an iOS simulator installed.
- Maestro CLI: `curl -fsSL "https://get.maestro.mobile.dev" | bash`
- The iOS sibling of the app under test:
  [saucelabs/my-demo-app-ios](https://github.com/saucelabs/my-demo-app-ios)
  — download `MyDemoApp.app` (simulator build) from its releases, or build
  it from source with Xcode.

## Running

```sh
xcrun simctl boot "iPhone 15"           # or any installed simulator
xcrun simctl install booted MyDemoApp.app
maestro test .maestro
```

## The honest caveat

These flows select elements by **Android resource-id** (`id: ".*productTV"`
etc.). The iOS app exposes accessibility identifiers with different names,
so the flows do not pass on iOS as-is. Making them cross-platform means
either a selector indirection layer (per-platform env files mapping logical
names → selectors) or duplicated per-platform flows — both are real
maintenance costs that this repo deliberately does not take on. If you want
to explore it, start by running `maestro studio` against the booted iOS
simulator to inspect the iOS accessibility tree, and port `00-launch.yaml`
first — it is the smallest flow and fails fastest.
