#!/bin/bash
#
# ContextRecorder - 24/7 Screen Recording for AI Analysis
# Optimized for M3 MacBook Air (fanless, hardware-accelerated)
#

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

SAVE_DIR="$HOME/ScreenMemory"
SCREEN_ID="2"                      # Capture screen 0 (verified via avfoundation)
CHUNK_DURATION=14400               # 4 hours in seconds
FPS=0.25                           # 1 frame per 4 seconds (sufficient for AI analysis)
BITRATE="150k"                     # ~15MB per hour at 0.25fps
FFMPEG="/opt/homebrew/bin/ffmpeg"
LOG_FILE="$SAVE_DIR/recorder.log"

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_dependencies() {
    if [[ ! -x "$FFMPEG" ]]; then
        echo "ERROR: ffmpeg not found at $FFMPEG"
        echo "Install with: brew install ffmpeg"
        exit 1
    fi
}

check_permissions() {
    # Try a quick 1-second test capture to verify permissions
    local test_file="/tmp/context-recorder-test-$$.mp4"
    if ! "$FFMPEG" -f avfoundation -framerate 1 -i "$SCREEN_ID" -t 1 -c:v h264_videotoolbox -an -y "$test_file" 2>/dev/null; then
        echo "═══════════════════════════════════════════════════════════════════════"
        echo "ERROR: Screen recording permission denied!"
        echo ""
        echo "To fix this:"
        echo "1. Open System Settings → Privacy & Security → Screen Recording"
        echo "2. Enable permission for 'Terminal' (or the app running this script)"
        echo "3. You may need to restart Terminal after granting permission"
        echo "═══════════════════════════════════════════════════════════════════════"
        exit 1
    fi
    rm -f "$test_file"
}

cleanup() {
    log "Recorder stopped (signal received)"
    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

trap cleanup SIGINT SIGTERM

echo "═══════════════════════════════════════════════════════════════════════"
echo " ContextRecorder - 24/7 Screen Memory"
echo " Save Dir: $SAVE_DIR"
echo " Chunk Duration: $(($CHUNK_DURATION / 3600)) hours"
echo " Target Size: ~15MB per hour (0.25 FPS)"
echo "═══════════════════════════════════════════════════════════════════════"

check_dependencies
mkdir -p "$SAVE_DIR"
check_permissions

log "Starting continuous recording..."

while true; do
    # Create today's folder
    TODAY=$(date +"%Y-%m-%d")
    mkdir -p "$SAVE_DIR/$TODAY"

    # Generate filename with timestamp
    NOW=$(date +"%H-%M-%S")
    FILEPATH="$SAVE_DIR/$TODAY/chunk_$NOW.mp4"

    log "Recording: $FILEPATH"

    # Record chunk using hardware acceleration
    # -f avfoundation: macOS screen capture
    # -framerate 1: Capture at 1fps (avfoundation minimum)
    # -vf fps=0.25: Downsample to 1 frame per 4 seconds
    # -c:v h264_videotoolbox: Apple Silicon hardware encoder (near-zero CPU)
    # -b:v 150k: Low bitrate for small files
    # -pix_fmt yuv420p: Required for QuickTime/AI compatibility
    # -g 15: Keyframe every 15 frames (~1 minute at 0.25fps)
    # -an: No audio (privacy)
    # -t: Duration in seconds

    "$FFMPEG" \
        -f avfoundation \
        -framerate 1 \
        -capture_cursor 1 \
        -i "$SCREEN_ID" \
        -t "$CHUNK_DURATION" \
        -vf "fps=$FPS" \
        -c:v h264_videotoolbox \
        -b:v "$BITRATE" \
        -pix_fmt yuv420p \
        -g 15 \
        -an \
        -y \
        "$FILEPATH" \
        2>> "$LOG_FILE"

    log "Chunk complete: $FILEPATH"

    # Brief pause before starting next chunk
    sleep 2
done
