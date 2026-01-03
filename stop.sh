#!/bin/bash
#
# Stop ContextRecorder
#

PID_FILE="$HOME/.context-recorder.pid"

if [[ ! -f "$PID_FILE" ]]; then
    echo "ContextRecorder is not running (no PID file)"
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping ContextRecorder (PID: $PID)..."
    kill "$PID"
    # Also kill any child ffmpeg processes
    pkill -P "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "Stopped."
else
    echo "Process not running, cleaning up stale PID file"
    rm -f "$PID_FILE"
fi
