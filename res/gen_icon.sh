#!/bin/bash
# gen_icon.sh - Generate a single icon with configurable padding
# Usage: ./gen_icon.sh <source> <output> <size> <padding_percent> [monochrome]
#
# Arguments:
#   source          - Source image file (e.g., icon.png)
#   output          - Output file path
#   size            - Target size in pixels (e.g., 128)
#   padding_percent - Padding percentage (0-50, e.g., 34 means logo is 66% of canvas)
#   monochrome      - Optional: "mono" to create white silhouette

set -e

SOURCE="$1"
OUTPUT="$2"
SIZE="$3"
PADDING="$4"
MONO="$5"

if [ -z "$SOURCE" ] || [ -z "$OUTPUT" ] || [ -z "$SIZE" ] || [ -z "$PADDING" ]; then
    echo "Usage: $0 <source> <output> <size> <padding_percent> [mono]"
    echo "Example: $0 icon.png output.png 108 34"
    echo "Example: $0 icon.png output.png 48 15 mono"
    exit 1
fi

# Calculate the logo size (canvas minus padding on both sides)
# padding_percent is the total padding, so logo takes (100 - padding)% of canvas
LOGO_SIZE=$(echo "scale=0; $SIZE * (100 - $PADDING) / 100" | bc)

if [ "$MONO" = "mono" ]; then
    # Create monochrome (white) version - use alpha channel as mask for white silhouette
    convert "$SOURCE" \
        -resize "${LOGO_SIZE}x${LOGO_SIZE}" \
        -gravity center \
        -background none \
        -extent "${SIZE}x${SIZE}" \
        -alpha extract \
        -background white \
        -alpha shape \
        "$OUTPUT"
else
    # Normal colored icon
    convert "$SOURCE" \
        -resize "${LOGO_SIZE}x${LOGO_SIZE}" \
        -gravity center \
        -background none \
        -extent "${SIZE}x${SIZE}" \
        "$OUTPUT"
fi

echo "Generated: $OUTPUT (${SIZE}x${SIZE}, padding: ${PADDING}%)"
