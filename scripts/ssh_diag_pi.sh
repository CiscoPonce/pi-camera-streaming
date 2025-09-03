#!/usr/bin/env bash

# SSH diagnostics and optional remediation for Pi camera + SRS
# Usage:
#   scripts/ssh_diag_pi.sh [user@host] [--fix] [--run]
#     user@host: SSH target (default: ciscopi@192.168.1.18)
#     --fix:     Apply fixes (kill camera holders, restart SRS, git pull repo)
#     --run:     After fixes, run start-camera.sh on the Pi
#
# Checks:
# - SRS API health (1985) and listening ports
# - Camera blockers (rpicam/libcamera/ffmpeg/etc) and device users (pipewire)

set -euo pipefail

# Defaults
TARGET="ciscopi@192.168.1.18"
APPLY_FIX=0
RUN_STREAM=0

# Parse args
for arg in "$@"; do
  case "$arg" in
    --fix) APPLY_FIX=1 ;;
    --run) RUN_STREAM=1 ;;
    *@*) TARGET="$arg" ;;
    *) ;; # ignore unknown
  esac
done

remote() {
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$TARGET" "$@"
}

echo "[INFO] Connecting to $TARGET ..." >&2

if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$TARGET" true 2>/dev/null; then
  echo "[ERROR] SSH connection failed. Try: ssh $TARGET" >&2
  exit 2
fi

# Run diagnostics remotely and emit machine-friendly lines
REMOTE_OUTPUT=$(remote 'bash -s' <<'REMOTE'
set -euo pipefail

echo "SECTION:DOCKER_PS"
docker ps --format "table {{.Names}}	{{.Image}}	{{.Status}}	{{.Ports}}" || true

echo "SECTION:SRS_API"
if curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null 2>&1; then
  echo "SRS_API_OK=1"
else
  echo "SRS_API_OK=0"
fi

echo "SECTION:SRS_PORTS"
if command -v ss >/dev/null 2>&1; then
  ss -lntp | awk 'NR==1 || /:1985|:1935|:8080/' || true
else
  netstat -lntp 2>/dev/null | awk 'NR==1 || /:1985|:1935|:8080/' || true
fi

echo "SECTION:CAMERA_PROCS"
ps aux | egrep "rpicam|libcamera|ffmpeg|v4l2|gst|mediamtx|motion" | grep -v egrep || true

echo "SECTION:DEVICE_USERS"
fuser -v /dev/media* /dev/video* 2>/dev/null || true

echo "SECTION:LSOF"
lsof /dev/media* /dev/video* 2>/dev/null | awk "NR==1 || /libcamera|rpicam|ffmpeg|v4l2|gst|mediamtx|motion|pipewire|wireplumber/" || true

# Derive summary flags
CAM_BUSY=0
BUSY_PIDS=""
if pgrep -f "rpicam|libcamera|v4l2|mediamtx|motion|ffmpeg" >/dev/null 2>&1; then
  CAM_BUSY=1
  BUSY_PIDS=$(pgrep -a -f "rpicam|libcamera|v4l2|mediamtx|motion|ffmpeg" | tr "\n" ';')
fi

PIPEWIRE_BUSY=0
if pgrep -x pipewire >/dev/null 2>&1 || pgrep -x wireplumber >/dev/null 2>&1; then
  # Check if they actually hold media nodes
  if lsof /dev/media* /dev/video* 2>/dev/null | egrep -q "pipewire|wireplumber"; then
    PIPEWIRE_BUSY=1
  fi
fi

LISTEN_1985=0
if ss -lnt 2>/dev/null | egrep -q ":1985\s"; then LISTEN_1985=1; fi

echo "SECTION:SUMMARY"
echo "SRS_API_OK=${SRS_API_OK:-0}"
echo "SRS_LISTEN_1985=${LISTEN_1985}"
echo "CAMERA_BUSY=${CAM_BUSY}"
echo "PIPEWIRE_HOLDS_CAMERA=${PIPEWIRE_BUSY}"
echo "BUSY_PIDS=${BUSY_PIDS}"
REMOTE
)

echo "$REMOTE_OUTPUT"

echo "\n=== Parsed Summary ==="
SRS_API_OK=$(echo "$REMOTE_OUTPUT" | awk -F= '/^SRS_API_OK=/{print $2}' | tail -1)
SRS_LISTEN=$(echo "$REMOTE_OUTPUT" | awk -F= '/^SRS_LISTEN_1985=/{print $2}' | tail -1)
CAM_BUSY=$(echo "$REMOTE_OUTPUT" | awk -F= '/^CAMERA_BUSY=/{print $2}' | tail -1)
PIPEWIRE_BUSY=$(echo "$REMOTE_OUTPUT" | awk -F= '/^PIPEWIRE_HOLDS_CAMERA=/{print $2}' | tail -1)
BUSY_PIDS=$(echo "$REMOTE_OUTPUT" | awk -F= '/^BUSY_PIDS=/{print $2}' | tail -1)

echo "- SRS API reachable (1985): $([ "$SRS_API_OK" = "1" ] && echo YES || echo NO)"
echo "- SRS listening on 1985:    $([ "$SRS_LISTEN" = "1" ] && echo YES || echo NO)"
echo "- Camera busy:               $([ "$CAM_BUSY" = "1" ] && echo YES || echo NO)"
echo "- PipeWire holds camera:     $([ "$PIPEWIRE_BUSY" = "1" ] && echo YES || echo NO)"
if [ -n "$BUSY_PIDS" ]; then
  echo "- Busy PIDs:                 $BUSY_PIDS"
fi

# Apply fixes if requested
if [ "$APPLY_FIX" -eq 1 ]; then
  echo "\n[INFO] Applying fixes on $TARGET ..." >&2
  remote "RUN_STREAM_FLAG=$RUN_STREAM bash -s" <<'REMOTE_FIX'
set -euo pipefail

# 1) Kill camera-holding processes
if pgrep -a -f "rpicam|libcamera|v4l2|mediamtx|motion|ffmpeg" >/dev/null 2>&1; then
  pkill -f 'rpicam|libcamera|v4l2|mediamtx|motion|ffmpeg' || true
  sleep 1
fi

# If still busy, try stopping PipeWire services (desktop only)
if pgrep -f "rpicam|libcamera|v4l2|mediamtx|motion|ffmpeg" >/dev/null 2>&1; then
  systemctl --user stop wireplumber pipewire 2>/dev/null || true
  sleep 1
fi

# 2) Restart SRS and verify API
if command -v docker >/dev/null 2>&1; then
  docker restart srs >/dev/null 2>&1 || true
  sleep 3
fi
curl -sSf --connect-timeout 2 --max-time 4 http://localhost:1985/api/v1/summaries >/dev/null 2>&1 || true

# 3) Update repo and ensure script executable
REMOTE_REPO_DIR="$HOME/pi-camera-streaming"
if [ -d "$REMOTE_REPO_DIR/.git" ]; then
  git -C "$REMOTE_REPO_DIR" pull --ff-only || true
  chmod +x "$REMOTE_REPO_DIR/scripts/start-camera.sh" || true
fi

# 4) Optionally run streaming script
if [ "${RUN_STREAM_FLAG}" -eq 1 ]; then
  bash "$REMOTE_REPO_DIR/scripts/start-camera.sh" || true
fi
REMOTE_FIX
fi

exit 0


