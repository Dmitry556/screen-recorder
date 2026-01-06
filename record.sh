#!/bin/bash
#
# ContextRecorder - 24/7 Screen Recording for AI Analysis
# Optimized for M3 MacBook Air (fanless, hardware-accelerated)
# Designed to be 100% maintenance-free
#

# Don't exit on errors - we handle them ourselves
set -uo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

SAVE_DIR="$HOME/ScreenMemory"
CHUNK_DURATION=3600                # 1 hour in seconds (shorter = safer)
FPS=0.25                           # 1 frame per 4 seconds
BITRATE="150k"                     # ~25MB per hour
FFMPEG="/opt/homebrew/bin/ffmpeg"
LOG_FILE="$SAVE_DIR/recorder.log"
MAX_LOG_SIZE=10485760              # 10MB - rotate log if larger
RETENTION_DAYS=30                  # Auto-delete recordings older than this
MIN_DISK_GB=10                     # Pause recording if less than this free

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

rotate_log() {
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        log "Log rotated"
    fi
}

detect_screen_id() {
    # Auto-detect the screen capture device ID
    # Looks for "Capture screen" in avfoundation device list
    local screen_id
    screen_id=$("$FFMPEG" -f avfoundation -list_devices true -i "" 2>&1 | grep -i "Capture screen" | head -1 | sed 's/.*\[\([0-9]*\)\].*/\1/')

    if [[ -z "$screen_id" ]]; then
        # Fallback to common defaults
        screen_id="1"
    fi
    echo "$screen_id"
}

cleanup_old_recordings() {
    # Delete recordings older than RETENTION_DAYS
    local deleted=0
    if [[ -d "$SAVE_DIR" ]]; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((deleted++)) || true
        done < <(find "$SAVE_DIR" -name "*.mp4" -type f -mtime +$RETENTION_DAYS -print0 2>/dev/null)

        # Remove empty date directories
        find "$SAVE_DIR" -type d -empty -delete 2>/dev/null || true

        if [[ $deleted -gt 0 ]]; then
            log "Cleaned up $deleted old recordings (>$RETENTION_DAYS days)"
        fi
    fi
}

check_disk_space() {
    # Returns 0 if enough space, 1 if low
    local free_gb
    free_gb=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$free_gb" -lt "$MIN_DISK_GB" ]]; then
        return 1
    fi
    return 0
}

wait_for_screen() {
    # Wait until screen capture is available (handles sleep/wake)
    local screen_id="$1"
    local attempts=0
    local max_attempts=60  # Wait up to 5 minutes

    while [[ $attempts -lt $max_attempts ]]; do
        if "$FFMPEG" -f avfoundation -framerate 1 -i "$screen_id" -t 1 -c:v h264_videotoolbox -an -y /tmp/context-recorder-test-$$.mp4 2>/dev/null; then
            rm -f /tmp/context-recorder-test-$$.mp4
            return 0
        fi
        ((attempts++))
        sleep 5
    done
    return 1
}

handle_signal() {
    log "Recorder stopped (signal received)"
    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

trap handle_signal SIGINT SIGTERM

mkdir -p "$SAVE_DIR"
log "ContextRecorder starting..."

# Main loop - runs forever, handles all errors gracefully
while true; do
    # Rotate log if too large
    rotate_log

    # Clean up old recordings (runs daily effectively, since we check each loop)
    cleanup_old_recordings

    # Check disk space
    if ! check_disk_space; then
        log "Low disk space (<${MIN_DISK_GB}GB free). Cleaning aggressively..."
        # Try deleting recordings older than 7 days if we're low on space
        find "$SAVE_DIR" -name "*.mp4" -type f -mtime +7 -delete 2>/dev/null || true

        if ! check_disk_space; then
            log "Still low on disk space. Waiting 1 hour..."
            sleep 3600
            continue
        fi
    fi

    # Auto-detect screen (handles external monitor changes)
    SCREEN_ID=$(detect_screen_id)

    # Wait for screen to be available (handles wake from sleep)
    if ! wait_for_screen "$SCREEN_ID"; then
        log "Screen not available. Retrying in 30 seconds..."
        sleep 30
        continue
    fi

    # Create today's folder
    TODAY=$(date +"%Y-%m-%d")
    mkdir -p "$SAVE_DIR/$TODAY"

    # Calculate seconds until midnight (to ensure chunks break at day boundaries)
    SECONDS_UNTIL_MIDNIGHT=$(( 86400 - $(date +%s) % 86400 ))

    # Use shorter of: standard chunk duration OR time until midnight
    # This ensures recordings never span multiple days
    ACTUAL_DURATION=$((CHUNK_DURATION < SECONDS_UNTIL_MIDNIGHT ? CHUNK_DURATION : SECONDS_UNTIL_MIDNIGHT))

    # Generate filename
    NOW=$(date +"%H-%M-%S")
    FILEPATH="$SAVE_DIR/$TODAY/chunk_$NOW.mp4"

    log "Recording: $FILEPATH (screen:$SCREEN_ID, duration:${ACTUAL_DURATION}s)"

    # Record chunk - if it fails, loop will retry
    # -movflags: frag_keyframe+empty_moov makes file playable even if interrupted
    "$FFMPEG" \
        -f avfoundation \
        -framerate 1 \
        -capture_cursor 1 \
        -i "$SCREEN_ID" \
        -t "$ACTUAL_DURATION" \
        -vf "fps=$FPS" \
        -c:v h264_videotoolbox \
        -b:v "$BITRATE" \
        -pix_fmt yuv420p \
        -g 15 \
        -movflags +frag_keyframe+empty_moov \
        -an \
        -y \
        "$FILEPATH" \
        2>> "$LOG_FILE" || {
            log "Recording failed. Will retry..."
            sleep 10
            continue
        }

    log "Chunk complete: $FILEPATH"
    sleep 2
done
