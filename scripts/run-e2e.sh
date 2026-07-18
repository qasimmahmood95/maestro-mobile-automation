#!/usr/bin/env bash
# Runs inside the emulator-runner step: install the verified APK, record the
# whole session, run the Maestro suite, and gather every artifact regardless
# of the outcome. Exit code is Maestro's.
set -uo pipefail

mkdir -p build/reports build/recordings build/maestro-debug

adb install -r build/app.apk

./scripts/record-screen.sh &
recorder_pid=$!

maestro test .maestro \
  --format junit \
  --output build/reports/junit.xml \
  --debug-output build/maestro-debug
status=$?

# Stop the segment loop before interrupting the on-device recorder, then give
# screenrecord a moment to finalize the mp4 index.
kill "$recorder_pid" 2>/dev/null || true
adb shell pkill -INT screenrecord 2>/dev/null || true
sleep 3
for f in $(adb shell 'ls /sdcard/e2e-*.mp4 2>/dev/null' | tr -d '\r'); do
  adb pull "$f" build/recordings/ || true
done

exit $status
