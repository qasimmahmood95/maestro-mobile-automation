#!/usr/bin/env bash
# Runs inside the emulator-runner step: install the verified APK, record the
# whole session, run the Maestro suite, then, only if the suite passed,
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

if [[ $status -ne 0 ]]; then
  # Artifact storage is not always reachable from every review environment,
  # so surface Maestro's own diagnosis straight into the job log. (A
  # uiautomator dump does NOT work here since Maestro's driver owns the
  # UiAutomation connection.)
  echo "--- maestro.log tail ---"
  tail -n 120 build/maestro-debug/.maestro/tests/*/maestro.log 2>/dev/null || true
  echo "--- failing flow command trace (tail) ---"
  for f in build/maestro-debug/.maestro/tests/*/commands-*.json; do
    [[ -f "$f" ]] || continue
    echo "== $f =="
    tail -c 4000 "$f" || true
    echo ""
  done
fi

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

# Tear down everything that can hold the runner step's stdout pipe open.
# Confirmed from CI logs: the suite and mutation check finish in ~4 min and
# the emulator is already dead ~2s after the run, yet the emulator-runner
# step then stalls ~9 min to the 15-minute job timeout, waiting on orphaned
# background processes (the adb server daemon and the emulator's
# crashpad_handler) that the runner only reaps at job cleanup. Kill them
# here so the step can complete promptly.
adb emu kill >/dev/null 2>&1 || true
sleep 2
pkill -9 -f qemu-system 2>/dev/null || true
pkill -9 -f crashpad_handler 2>/dev/null || true
adb kill-server >/dev/null 2>&1 || true

exit $status
