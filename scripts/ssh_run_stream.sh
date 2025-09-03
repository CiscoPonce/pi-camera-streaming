#!/usr/bin/env bash

# SSH helper to run start-camera.sh on the Pi and summarise status
# Usage:
#   scripts/ssh_run_stream.sh [user@host]
# Default target: ciscopi@192.168.1.18

set -euo pipefail

TARGET="${1:-ciscopi@192.168.1.18}"
REMOTE_REPO_DIR="$HOME/pi-camera-streaming"

ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$TARGET" true 2>/dev/null || {
  echo "[ERROR] SSH connection failed to $TARGET" >&2
  exit 2
}

echo "[INFO] Running start-camera.sh on $TARGET ..." >&2

# Run remotely with a timeout so it doesn't block forever; capture output
REMOTE_OUT=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail

REPO_DIR="$HOME/pi-camera-streaming"

echo "SECTION:SRS_CHECK_BEFORE"
curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null && echo OK || echo FAIL

# Stop desktop services that may hold camera
systemctl --user stop pipewire wireplumber 2>/dev/null || true

echo "SECTION:START_STREAM"
# Run for ~8s then stop, capturing output
(
  timeout 8s bash "$REPO_DIR/scripts/start-camera.sh" 2>&1 || true
) | sed -n '1,200p'

echo "SECTION:SRS_CHECK_AFTER"
curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null && echo OK || echo FAIL

# Restore services
systemctl --user start pipewire wireplumber 2>/dev/null || true

REMOTE
)

echo "$REMOTE_OUT"

# Parse a brief summary
echo
echo "=== Summary ==="
if echo "$REMOTE_OUT" | grep -q "Camera detected and available"; then
  echo "- Camera: OK"
else
  echo "- Camera: NOT OK"
fi

if echo "$REMOTE_OUT" | grep -q "SRS server is running"; then
  echo "- SRS API: OK"
else
  echo "- SRS API: NOT OK"
fi

if echo "$REMOTE_OUT" | grep -q "Executing: rpicam-vid"; then
  echo "- Launch: rpicam-vid executed"
fi

if echo "$REMOTE_OUT" | grep -qi "failed to start camera\|Broken pipe\|failed to acquire camera"; then
  echo "- Result: FAILED (camera/V4L2 error)"
elif echo "$REMOTE_OUT" | grep -qi "Output #0, flv"; then
  echo "- Result: Streaming initialised"
else
  echo "- Result: Inconclusive"
fi

exit 0


