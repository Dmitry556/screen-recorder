#!/bin/bash
#
# Uninstall ContextRecorder service
#

PLIST_NAME="com.local.contextrecorder.plist"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "═══════════════════════════════════════════════════════════════════════"
echo " Uninstalling ContextRecorder Service"
echo "═══════════════════════════════════════════════════════════════════════"

if [[ -f "$PLIST_DST" ]]; then
    echo "Stopping service..."
    launchctl unload "$PLIST_DST" 2>/dev/null || true

    echo "Removing service..."
    rm -f "$PLIST_DST"

    echo ""
    echo "✓ ContextRecorder service removed."
    echo ""
    echo "Note: Your recordings in ~/ScreenMemory/ were NOT deleted."
else
    echo "Service not installed."
fi
