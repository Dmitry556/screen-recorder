#!/bin/bash
#
# Check ContextRecorder status
#

SAVE_DIR="$HOME/ScreenMemory"
PLIST_NAME="com.local.contextrecorder"

echo "═══════════════════════════════════════════════════════════════════════"
echo " ContextRecorder Status"
echo "═══════════════════════════════════════════════════════════════════════"

# Check launchd service
if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
    PID=$(launchctl list | grep "$PLIST_NAME" | awk '{print $1}')
    if [[ "$PID" != "-" && -n "$PID" ]]; then
        echo "Status: RUNNING (launchd service, PID: $PID)"
    else
        echo "Status: INSTALLED but not running (check logs)"
    fi
# Check manual PID file
elif [[ -f "$HOME/.context-recorder.pid" ]] && kill -0 "$(cat "$HOME/.context-recorder.pid")" 2>/dev/null; then
    echo "Status: RUNNING (manual, PID: $(cat "$HOME/.context-recorder.pid"))"
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
