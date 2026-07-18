#!/usr/bin/env bash
# Runs inside the emulator-runner step: install the verified APK, record the
# whole session, run the Maestro suite, then — only if the suite passed —
# run the mutation check in the same emulator session (the suite's green
# run of the negative-path flow is the control for it). Artifacts are
# gathered regardless of the outcome.
set -euo pipefail

mkdir -p build/reports build/recordings build/maestro-debug

adb install -r build/app.apk

./scripts/record-screen.sh &
recorder_pid=$!

status=0
# Bounded below the job's 15-minute timeout so the artifact steps below
# always get to run, even if a flow hangs.
timeout --signal=INT 600 maestro test .maestro \
  --format junit \
  --output build/reports/junit.xml \
  --debug-output build/maestro-debug || status=$?

if [[ $status -eq 0 ]]; then
  ./scripts/mutation-check.sh || status=$?
fi

# Stop the segment loop before interrupting the on-device recorder, then give
# screenrecord a moment to finalize the mp4 index.
kill "$recorder_pid" 2>/dev/null || true
adb shell pkill -INT screenrecord 2>/dev/null || true
sleep 3
for f in $(adb shell 'ls /sdcard/e2e-*.mp4 2>/dev/null' | tr -d '\r'); do
  adb pull "$f" build/recordings/ || true
done

exit $status
