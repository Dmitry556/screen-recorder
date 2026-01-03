#!/bin/bash
#
# Start ContextRecorder in background
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$HOME/.context-recorder.pid"
LOG_FILE="$HOME/ScreenMemory/recorder.log"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "ContextRecorder is already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

mkdir -p "$HOME/ScreenMemory"

echo "Starting ContextRecorder..."
nohup "$SCRIPT_DIR/record.sh" >> "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "ContextRecorder started (PID: $(cat "$PID_FILE"))"
echo "Logs: $LOG_FILE"
echo "Recordings: ~/ScreenMemory/"
