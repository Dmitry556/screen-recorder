#!/bin/bash
#
# Install ContextRecorder as a persistent launchd service
# Runs on boot, restarts on crash, survives sleep
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.local.contextrecorder.plist"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "═══════════════════════════════════════════════════════════════════════"
echo " Installing ContextRecorder Service"
echo "═══════════════════════════════════════════════════════════════════════"

# Create LaunchAgents directory if needed
mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/ScreenMemory"

# Stop existing service if running
if launchctl list | grep -q "com.local.contextrecorder"; then
    echo "Stopping existing service..."
    launchctl unload "$PLIST_DST" 2>/dev/null || true
fi

# Copy plist
echo "Installing service..."
cp "$PLIST_SRC" "$PLIST_DST"

# Load service
echo "Starting service..."
launchctl load "$PLIST_DST"

# Verify
sleep 2
if launchctl list | grep -q "com.local.contextrecorder"; then
    echo ""
    echo "✓ ContextRecorder installed and running!"
    echo ""
    echo "  • Starts automatically on login"
    echo "  • Restarts if it crashes"
    echo "  • Recordings: ~/ScreenMemory/"
    echo ""
    echo "Commands:"
    echo "  ./status.sh      - Check status"
    echo "  ./uninstall.sh   - Remove service"
    echo ""
else
    echo "ERROR: Service failed to start. Check ~/ScreenMemory/launchd-error.log"
    exit 1
fi
