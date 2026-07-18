#!/usr/bin/env bash
# Record the emulator screen in 3-minute segments (screenrecord's per-clip
# cap) until the recorder process is killed. run-e2e.sh pulls the segments.
set -u

i=0
while :; do
  i=$((i + 1))
  adb shell screenrecord --time-limit 180 --bit-rate 4000000 \
    "/sdcard/e2e-$(printf '%02d' "$i").mp4" || exit 0
done
