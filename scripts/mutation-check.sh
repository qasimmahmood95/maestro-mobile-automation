#!/usr/bin/env bash
# Prove the negative-path test can actually fail. Inverts the locked-out
# assertion in 11-login-locked-out.yaml and expects the flow to go red — a
# passing inverted flow means the assertion is vacuous and the check fails.
#
# Run by run-e2e.sh only after the full suite (including the un-mutated
# flow) has just passed on this same emulator session — that green run is
# the control proving the flow reaches the assertion, so a red inverted run
# can only mean the assertion itself flipped.
set -euo pipefail

flow=.maestro/flows/11-login-locked-out.yaml
needle='- assertVisible: "Sorry this user has been locked out."'
inverted="${needle/assertVisible/assertNotVisible}"

grep -qF "$needle" "$flow" || {
  echo "::error::Locked-out assertion not found in $flow in the exact form mutation-check.sh expects."
  exit 1
}

sed -i "s|$needle|$inverted|" "$flow"
trap 'git checkout -- "$flow"' EXIT

if timeout --signal=INT 180 maestro test "$flow" --debug-output build/maestro-debug-mutation; then
  echo "::error::Mutation NOT detected — the inverted locked-out assertion still passes."
  exit 1
fi
echo "Mutation detected: inverted assertion fails as expected."
