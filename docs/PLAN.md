# Milestone plan

Status: all milestones complete. M0 approved; M1-M4 implemented and
verified in CI (run 8 on the milestone branch): 4/4 flows passed in 2m 40s
on a clean emulator boot, the mutation check confirmed the inverted
locked-out assertion fails ("Mutation detected"), and the full job took
about 6 minutes against the 15-minute budget, with JUnit, session videos,
and Maestro debug output uploaded. Stabilisation findings from the CI runs
are written up as rules in CLAUDE.md (keyboard discipline, anchored id
selectors, input values distinct from field hints).

Small repo, four milestones after the planning step. Each milestone is one
PR, reviewed by a code-review subagent before opening; flow-bearing
milestones additionally pass the verification gate (clean-emulator CI run
plus negative-path mutation check) before merge.

## M0: Charter

CLAUDE.md, this plan, demo-app choice with rationale in the README.
Done when: owner reviews and approves the plan. No flows written.

## M1: Skeleton + CI smoke

- `.maestro/` workspace with a single `00-launch.yaml`: cold start with
  `clearState: true`, assert the product catalog renders.
- `e2e-android.yaml` workflow: KVM-enabled ubuntu runner,
  `reactivecircus/android-emulator-runner` (API 30 x86_64, AVD snapshot
  cached), download the pinned APK (`2.2.0` / `mda-2.2.0-25.apk`) with
  SHA-256 verification, install, run Maestro with JUnit output.
- Artifacts wired up from day one: Maestro debug output (failure
  screenshots), full-session `adb screenrecord` video, JUnit XML.

Done when: CI is green twice in a row, artifacts are downloadable, wall
clock is comfortably under 15 min (target 10 or less to leave headroom).

## M2: Auth flows + negative path

- `subflows/login.yaml` (parameterised username/password via Maestro env).
- `10-login-success.yaml`: log in as `bob@example.com`, assert logged-in
  state; demonstrates state reuse. Subsequent flows launch without
  `clearState` and skip login if already authenticated (self-healing).
- `11-login-locked-out.yaml`: negative path with `alice@example.com`;
  assert the specific locked-out error message appears and login does not
  proceed.

Done when: full set green on clean emulator boot in CI, and the mutation
check passes: inverting the locked-out assertion makes
`11-login-locked-out` fail.

## M3: Core journey

- `20-checkout-journey.yaml`: catalog, product detail, add to cart, cart
  review, checkout (reusing `subflows/login.yaml`), payment and shipping
  screens, order-complete assertion.
- Extract `add-first-product-to-cart.yaml` subflow; the journey and any
  future flow compose it rather than copy-pasting step blocks.

Done when: same gates as M2 (clean-boot CI run; review subagent on the
PR). CI still under budget.

## M4: Polish and docs

- README: badge, quickstart, flow map (which flows compose which subflows),
  and the "What this demonstrates / What it doesn't" section.
- `docs/ios-local-lane.md`: how to run the same flows against the iOS
  sibling app locally with Maestro on macOS, and why iOS is not in CI
  (macOS runner cost and flake against the marginal signal for a
  portfolio repo).
- CI timing review; prune anything pushing the budget.

Done when: a stranger can clone the repo, read the README, and reproduce
a CI run without asking questions.

## Out of scope (deliberately)

Cross-API-level matrices, iOS in CI, visual regression, Maestro Cloud,
performance testing, parallel sharding. This repo closes a coverage gap;
breadth here is cost, not signal.
