#!/bin/bash

# Pi Camera Streaming Script
# Created by CiscoPonce
# Optimized for Raspberry Pi 5 with Camera Module 3

set -e

# Configuration
STREAM_NAME=${STREAM_NAME:-"cam"}
WIDTH=${CAMERA_WIDTH:-1280}
HEIGHT=${CAMERA_HEIGHT:-720}
FPS=${CAMERA_FPS:-30}
BITRATE=${CAMERA_BITRATE:-6000000}
GOP=${GOP_SIZE:-60}
SRS_HOST=${SRS_HOST:-"localhost"}
SRS_PORT=${SRS_PORT:-1935}

# Performance profiles
DAY_PROFILE="1920x1080@25:8000000:120"    # 1080p25, 8Mbps, 4s GOP
NIGHT_PROFILE="1280x720@30:4000000:60"    # 720p30, 4Mbps, 2s GOP
LOW_LATENCY_PROFILE="1280x720@60:6000000:30"  # 720p60, 6Mbps, 0.5s GOP

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if camera is available
check_camera() {
    log "Checking camera availability..."
    
    if ! command -v rpicam-vid &> /dev/null; then
        error "rpicam-vid not found. Please install libcamera-tools:"
        error "sudo apt update && sudo apt install libcamera-tools"
        exit 1
    fi
    
    # List available cameras
    if ! rpicam-vid --list-cameras &> /dev/null; then
        error "No cameras detected. Please check:"
        error "1. Camera Module 3 is properly connected"
        error "2. Camera is enabled in raspi-config"
        error "3. No other processes are using the camera"
        exit 1
    fi
    
    success "Camera detected and available"
}

# Check if SRS is running
check_srs() {
    log "Checking SRS server..."
    
    if ! curl -s "http://${SRS_HOST}:1985/api/v1/summaries" &> /dev/null; then
        error "SRS server not responding. Please start it with:"
        error "docker-compose up -d srs"
        exit 1
    fi
    
    success "SRS server is running"
}

# Get current time of day for profile selection
get_time_profile() {
    local hour=$(date +%H)
    if [ $hour -ge 6 ] && [ $hour -lt 18 ]; then
        echo "day"
    else
        echo "night"
    fi
}

# Apply performance profile
apply_profile() {
    local profile=$1
    case $profile in
        "day")
            log "Applying day profile (1080p25, 8Mbps)"
            WIDTH=1920
            HEIGHT=1080
            FPS=25
            BITRATE=8000000
            GOP=120
            ;;
        "night")
            log "Applying night profile (720p30, 4Mbps)"
            WIDTH=1280
            HEIGHT=720
            FPS=30
            BITRATE=4000000
            GOP=60
            ;;
        "low-latency")
            log "Applying low-latency profile (720p60, 6Mbps)"
            WIDTH=1280
            HEIGHT=720
            FPS=60
            BITRATE=6000000
            GOP=30
            ;;
        *)
            log "Using custom profile: ${WIDTH}x${HEIGHT}@${FPS}, ${BITRATE}bps"
            ;;
    esac
}

# Start camera streaming
start_streaming() {
    local profile=$1
    apply_profile $profile
    
    log "Starting camera stream..."
    log "Resolution: ${WIDTH}x${HEIGHT}"
    log "Framerate: ${FPS} fps"
    log "Bitrate: ${BITRATE} bps"
    log "GOP: ${GOP} frames"
    log "Stream name: ${STREAM_NAME}"
    
    # Build rpicam-vid command
    local cmd="rpicam-vid"
    cmd="$cmd --width $WIDTH"
    cmd="$cmd --height $HEIGHT"
    cmd="$cmd --framerate $FPS"
    cmd="$cmd --bitrate $BITRATE"
    cmd="$cmd --inline"
    cmd="$cmd --keyframe $GOP"
    cmd="$cmd --timeout 0"
    cmd="$cmd --output -"
    
    # Add camera-specific optimizations for Pi 5
    cmd="$cmd --mode 1640:1232:12:U"  # 4:3 mode for better quality
    cmd="$cmd --awb auto"
    cmd="$cmd --exposure auto"
    cmd="$cmd --gain auto"
    
    # Add libav encoding
    cmd="$cmd --codec h264"
    cmd="$cmd --libav-format flv"
    cmd="$cmd --libav-video-codec libx264"
    cmd="$cmd --libav-video-bitrate $BITRATE"
    cmd="$cmd --libav-video-extra 'preset=ultrafast,tune=zerolatency,profile=baseline,level=3.1'"
    
    # Stream to SRS
    cmd="$cmd | ffmpeg -f flv -i - -c copy -f flv rtmp://${SRS_HOST}:${SRS_PORT}/live/${STREAM_NAME}"
    
    log "Executing: $cmd"
    
    # Execute the command
    eval $cmd
}

# Signal handler for cleanup
cleanup() {
    log "Stopping camera stream..."
    pkill -f rpicam-vid || true
    pkill -f ffmpeg || true
    success "Camera stream stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main function
main() {
    log "Pi Camera Streaming Script Starting..."
    
    # Parse command line arguments
    PROFILE="auto"
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --width)
                WIDTH="$2"
                shift 2
                ;;
            --height)
                HEIGHT="$2"
                shift 2
                ;;
            --fps)
                FPS="$2"
                shift 2
                ;;
            --bitrate)
                BITRATE="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --profile PROFILE    Set performance profile (day|night|low-latency|auto)"
                echo "  --width WIDTH        Set video width (default: 1280)"
                echo "  --height HEIGHT      Set video height (default: 720)"
                echo "  --fps FPS           Set framerate (default: 30)"
                echo "  --bitrate BITRATE   Set bitrate in bps (default: 6000000)"
                echo "  --help              Show this help"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Determine profile
    if [ "$PROFILE" = "auto" ]; then
        PROFILE=$(get_time_profile)
        log "Auto-selected profile: $PROFILE"
    fi
    
    # Pre-flight checks
    check_camera
    check_srs
    
    # Start streaming
    start_streaming $PROFILE
}

# Run main function
main "$@"
