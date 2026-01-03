# ContextRecorder

24/7 screen recording for AI productivity analysis. Optimized for M3 MacBook Air.

## Quick Start

```bash
# First time: Grant screen recording permission
./record.sh  # Will prompt you to enable permissions

# Start recording in background
./start.sh

# Check status
./status.sh

# Stop recording
./stop.sh
```

## How It Works

- Records at **1 FPS** using **hardware acceleration** (near-zero CPU usage)
- Creates **4-hour chunks** saved to `~/ScreenMemory/YYYY-MM-DD/`
- Each hour produces approximately **50MB** of video
- No audio recorded (privacy)

## Files

| File | Description |
|------|-------------|
| `record.sh` | Main recording script |
| `start.sh` | Start recording in background |
| `stop.sh` | Stop recording |
| `status.sh` | Check status and disk usage |
| `ContextRecorder.app` | Double-click launcher (copy to Applications) |

## Permissions Setup

1. Run `./record.sh` once from Terminal
2. When it fails, go to **System Settings → Privacy & Security → Screen Recording**
3. Enable permission for **Terminal** (or iTerm, etc.)
4. Restart Terminal and run again

If using the `.app`:
1. Copy `ContextRecorder.app` to `/Applications/`
2. Double-click to launch
3. Grant screen recording permission when prompted
4. Relaunch the app

## Using with AI

Drag a 4-hour chunk into Google AI Studio and ask:

> "Watch this recording of my work day. Summarize what I worked on,
> how focused I was, and identify my biggest time-wasters."

## Auto-Start on Login

To start recording automatically on boot:

```bash
# Add to Login Items
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Users/dmitry/projects/context-recorder/ContextRecorder.app", hidden:true}'
```

Or manually: System Settings → General → Login Items → add ContextRecorder.app

## Disk Space

| Duration | Approximate Size |
|----------|-----------------|
| 1 hour   | ~50 MB          |
| 4 hours  | ~200 MB         |
| 8 hours  | ~400 MB         |
| 24 hours | ~1.2 GB         |
| 30 days  | ~36 GB          |

## Cleanup Old Recordings

```bash
# Delete recordings older than 7 days
find ~/ScreenMemory -name "*.mp4" -mtime +7 -delete
find ~/ScreenMemory -type d -empty -delete
```
