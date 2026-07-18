#!/usr/bin/env bash
# Prove the negative-path test can actually fail. Inverts the locked-out
# assertion in 11-login-locked-out.yaml and expects the flow to go red — a
# passing inverted flow means the assertion is vacuous and the check fails.
set -euo pipefail

flow=.maestro/flows/11-login-locked-out.yaml
needle='- assertVisible: "Sorry this user has been locked out."'

grep -qF "$needle" "$flow" || {
  echo "::error::Locked-out assertion not found in $flow in the exact form mutation-check.sh expects."
  exit 1
}

adb install -r build/app.apk

sed -i 's/- assertVisible: "Sorry this user has been locked out."/- assertNotVisible: "Sorry this user has been locked out."/' "$flow"
trap 'git checkout -- "$flow"' EXIT

if maestro test "$flow" --debug-output build/maestro-debug-mutation; then
  echo "::error::Mutation NOT detected — the inverted locked-out assertion still passes."
  exit 1
fi
echo "Mutation detected: inverted assertion fails as expected."
