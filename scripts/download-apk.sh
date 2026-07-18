#!/usr/bin/env bash
# Download the pinned app-under-test APK and verify it against the pinned
# SHA-256 before anything installs it. On mismatch the computed digest is
# printed so a legitimate re-pin (new release tag) is a one-line change.
set -euo pipefail

: "${APK_URL:?APK_URL must be set}"
: "${APK_SHA256:?APK_SHA256 must be set}"

mkdir -p build
curl -fsSL --retry 3 --retry-delay 2 -o build/app.apk "$APK_URL"

actual="$(sha256sum build/app.apk | awk '{print $1}')"
if [[ "$actual" != "$APK_SHA256" ]]; then
  echo "::error::APK SHA-256 mismatch for $APK_URL"
  echo "expected: $APK_SHA256"
  echo "actual:   $actual"
  exit 1
fi
echo "APK verified: sha256=$actual"
