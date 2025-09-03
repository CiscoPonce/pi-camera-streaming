#!/usr/bin/env bash

# Update the Pi repo, ensure SRS is running, and test camera streaming
# Usage:
#   scripts/ssh_update_and_test.sh [user@host]
# Default target: ciscopi@192.168.1.18

set -euo pipefail

TARGET="${1:-ciscopi@192.168.1.18}"
REMOTE_DIR="pi-camera-streaming"

ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$TARGET" true 2>/dev/null || {
  echo "[ERROR] SSH connection failed to $TARGET" >&2
  exit 2
}

echo "[INFO] Updating repository and services on $TARGET ..." >&2

ssh -o StrictHostKeyChecking=accept-new "$TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail
REPO_DIR="$HOME/pi-camera-streaming"

# 1) Ensure repo exists and is current
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://github.com/CiscoPonce/pi-camera-streaming.git "$REPO_DIR"
else
  git -C "$REPO_DIR" fetch --all --prune || true
  git -C "$REPO_DIR" reset --hard origin/main || true
fi
chmod +x "$REPO_DIR/scripts/start-camera.sh" || true

# 2) Ensure SRS is up
if command -v docker >/dev/null 2>&1; then
  # Prefer compose file inside the repo if present
  if [ -f "$REPO_DIR/docker-compose.yml" ]; then
    docker compose -f "$REPO_DIR/docker-compose.yml" up -d srs || true
  else
    docker restart srs 2>/dev/null || true
  fi
fi

# 3) Check SRS API
SRS_OK=0
if curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null 2>&1; then
  SRS_OK=1
fi

echo "SECTION:PRECHECK"
echo "SRS_OK=$SRS_OK"

# 4) Stop desktop services that may hold camera
systemctl --user stop pipewire wireplumber 2>/dev/null || true

# 5) Run stream script for a short time window
echo "SECTION:RUN"
timeout 10s bash "$REPO_DIR/scripts/start-camera.sh" 2>&1 || true

# 6) Restore desktop services
systemctl --user start pipewire wireplumber 2>/dev/null || true

REMOTE
' 

echo "[INFO] Gathering a brief status ..." >&2

ssh -o StrictHostKeyChecking=accept-new "$TARGET" 'bash -s' <<'REMOTE'
set -euo pipefail
REPO_DIR="$HOME/pi-camera-streaming"

echo "SECTION:SUMMARY"
# Camera blockers
if pgrep -a -f "rpicam|libcamera|ffmpeg" >/dev/null 2>&1; then
  echo "CAM_BUSY=1"
else
  echo "CAM_BUSY=0"
fi
# SRS API
if curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null 2>&1; then
  echo "SRS_OK=1"
else
  echo "SRS_OK=0"
fi
REMOTE

exit 0


