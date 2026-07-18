#!/usr/bin/env bash
# Download the pinned app-under-test APK and verify it against the pinned
# SHA-256 before anything installs it. Nothing is ever installed unverified:
# on mismatch (including the initial PINNED_ON_FIRST_RUN bootstrap) the
# computed digest is printed and the run stops, so pinning or re-pinning a
# release is a deliberate one-line change, never an automatic one.
set -euo pipefail

: "${APK_URL:?APK_URL must be set}"
: "${APK_SHA256:?APK_SHA256 must be set}"

mkdir -p build
curl -fsSL --retry 3 --retry-delay 2 -o build/app.apk "$APK_URL"

actual="$(sha256sum build/app.apk | awk '{print $1}')"
if [[ "$APK_SHA256" == "PINNED_ON_FIRST_RUN" ]]; then
  echo "::error::APK_SHA256 is not pinned yet. Bootstrap: set APK_SHA256 to the digest below (computed from the pinned release URL) and re-run."
  echo "computed: $actual"
  exit 1
fi
if [[ "$actual" != "$APK_SHA256" ]]; then
  echo "::error::APK SHA-256 mismatch for $APK_URL"
  echo "expected: $APK_SHA256"
  echo "actual:   $actual"
  exit 1
fi
echo "APK verified: sha256=$actual"
