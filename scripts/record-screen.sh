#!/usr/bin/env bash
# Record the emulator screen in 3-minute segments (screenrecord's per-clip
# cap) until the recorder is stopped via SIGINT from run-e2e.sh, which also
# pulls the segments. 720p at 2 Mbps keeps UI text legible at ~45 MB per
# segment. A failed screenrecord ends the loop but is logged, so a missing
# video artifact is explained in the job log rather than silently absent.
set -u

i=0
while :; do
  i=$((i + 1))
  # Native resolution: a --size with a different aspect ratio makes
  # screenrecord fail outright on some emulator images.
  if ! adb shell screenrecord --time-limit 180 --bit-rate 2000000 \
    "/sdcard/e2e-$(printf '%02d' "$i").mp4"; then
    echo "record-screen: screenrecord ended (segment $i); stopping recorder" >&2
    exit 0
  fi
done
