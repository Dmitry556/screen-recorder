#!/bin/bash
#
# Check ContextRecorder status
#

PID_FILE="$HOME/.context-recorder.pid"
SAVE_DIR="$HOME/ScreenMemory"

echo "═══════════════════════════════════════════════════════════════════════"
echo " ContextRecorder Status"
echo "═══════════════════════════════════════════════════════════════════════"

# Check if running
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Status: RUNNING (PID: $(cat "$PID_FILE"))"
else
    echo "Status: STOPPED"
fi

# Show disk usage
if [[ -d "$SAVE_DIR" ]]; then
    echo ""
    echo "Storage:"
    du -sh "$SAVE_DIR" 2>/dev/null | awk '{print "  Total: " $1}'

    # Count files by day
    echo ""
    echo "Recent recordings:"
    for day in $(ls -1 "$SAVE_DIR" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' | tail -5); do
        count=$(ls -1 "$SAVE_DIR/$day"/*.mp4 2>/dev/null | wc -l | tr -d ' ')
        size=$(du -sh "$SAVE_DIR/$day" 2>/dev/null | awk '{print $1}')
        echo "  $day: $count chunks ($size)"
    done
fi

echo "═══════════════════════════════════════════════════════════════════════"
