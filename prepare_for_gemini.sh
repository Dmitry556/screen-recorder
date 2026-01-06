#!/bin/bash
#
# Prepare ContextRecorder videos for Gemini AI Studio
# Speeds up 0.25 FPS recordings by 4x to avoid token waste
#

set -e

if [[ $# -eq 0 ]]; then
    echo "Usage: ./prepare_for_gemini.sh <input.mp4>"
    echo ""
    echo "This script speeds up your 0.25 FPS recording by 4x."
    echo "Result: 1-hour recording becomes 15-minute file with same frames."
    echo "Saves 75% on Gemini tokens."
    exit 1
fi

INPUT="$1"
BASENAME=$(basename "$INPUT" .mp4)
DIRNAME=$(dirname "$INPUT")
OUTPUT="${DIRNAME}/${BASENAME}_gemini.mp4"

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: File not found: $INPUT"
    exit 1
fi

echo "Processing: $INPUT"
echo "Output: $OUTPUT"
echo ""
echo "Speeding up video 4x (removing audio)..."

/opt/homebrew/bin/ffmpeg \
    -i "$INPUT" \
    -filter:v "setpts=0.25*PTS" \
    -r 1 \
    -an \
    -y \
    "$OUTPUT"

echo ""
echo "✓ Done!"
echo ""
echo "Upload this file to AI Studio: $OUTPUT"
echo ""
echo "IMPORTANT: Copy this SYSTEM INSTRUCTION to AI Studio:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This video has been sped up 4x to save tokens."
echo ""
echo "IGNORE the video metadata timestamps. Instead, read the macOS menu bar"
echo "clock (top-right corner) to determine the actual real-world time for"
echo "all events."
echo ""
echo "When reporting activity, use the time shown on the screen clock."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
