#!/bin/bash
# update_all_icons.sh - Generate and replace all XConnect icons
# Requires: ImageMagick (convert, identify)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source files
SOURCE_PNG="$SCRIPT_DIR/icon.png"
SOURCE_SVG="$SCRIPT_DIR/logo.svg"

# Temp directory for generated icons
TEMP_DIR="$SCRIPT_DIR/temp_icons"

# Android resource base
ANDROID_RES="$PROJECT_ROOT/flutter/android/app/src/main/res"

echo "=== XConnect Icon Generator ==="
echo "Project root: $PROJECT_ROOT"
echo "Source PNG: $SOURCE_PNG"
echo "Source SVG: $SOURCE_SVG"
echo ""

# Check dependencies
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is required. Install with: sudo apt install imagemagick"
    exit 1
fi

if [ ! -f "$SOURCE_PNG" ]; then
    echo "Error: Source PNG not found: $SOURCE_PNG"
    exit 1
fi

# ============================================
# Phase 1: Setup
# ============================================
echo "Phase 1: Setting up temp directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# ============================================
# Phase 2: Generate Icons
# ============================================
echo ""
echo "Phase 2: Generating icons..."

# Android Foreground (34% padding = 66% visible)
echo "  - Android Foreground icons (34% padding)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/foreground_108.png" 108 34
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/foreground_162.png" 162 34
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/foreground_216.png" 216 34
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/foreground_324.png" 324 34
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/foreground_432.png" 432 34

# Android Launcher (15% padding)
echo "  - Android Launcher icons (15% padding)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/launcher_48.png" 48 15
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/launcher_72.png" 72 15
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/launcher_96.png" 96 15
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/launcher_144.png" 144 15
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/launcher_192.png" 192 15

# Android Notification - Monochrome (15% padding)
echo "  - Android Notification icons (15% padding, monochrome)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/stat_24.png" 24 15 mono
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/stat_36.png" 36 15 mono
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/stat_48.png" 48 15 mono
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/stat_72.png" 72 15 mono
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/stat_96.png" 96 15 mono

# Windows icons (10% padding)
echo "  - Windows icons (10% padding)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/win_16.png" 16 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/win_32.png" 32 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/win_48.png" 48 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/win_128.png" 128 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/win_256.png" 256 10

# Linux icons (10% padding)
echo "  - Linux icons (10% padding)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/linux_32.png" 32 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/linux_64.png" 64 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/linux_128.png" 128 10
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/linux_256.png" 256 10

# Fastlane/Flutter store icon (10% padding)
echo "  - Fastlane store icon (10% padding)..."
"$SCRIPT_DIR/gen_icon.sh" "$SOURCE_PNG" "$TEMP_DIR/store_512.png" 512 10

# Generate ICO files
echo "  - Generating ICO files..."
convert "$TEMP_DIR/win_16.png" "$TEMP_DIR/win_32.png" "$TEMP_DIR/win_48.png" \
        "$TEMP_DIR/win_128.png" "$TEMP_DIR/win_256.png" "$TEMP_DIR/icon.ico"
convert "$TEMP_DIR/win_16.png" "$TEMP_DIR/win_32.png" "$TEMP_DIR/tray.ico"

# ============================================
# Phase 3: Copy to Destinations
# ============================================
echo ""
echo "Phase 3: Copying to destinations..."

# Android Foreground
echo "  - Android Foreground..."
cp "$TEMP_DIR/foreground_108.png" "$ANDROID_RES/mipmap-mdpi/ic_launcher_foreground.png"
cp "$TEMP_DIR/foreground_162.png" "$ANDROID_RES/mipmap-hdpi/ic_launcher_foreground.png"
cp "$TEMP_DIR/foreground_216.png" "$ANDROID_RES/mipmap-xhdpi/ic_launcher_foreground.png"
cp "$TEMP_DIR/foreground_324.png" "$ANDROID_RES/mipmap-xxhdpi/ic_launcher_foreground.png"
cp "$TEMP_DIR/foreground_432.png" "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher_foreground.png"

# Android Launcher
echo "  - Android Launcher..."
cp "$TEMP_DIR/launcher_48.png" "$ANDROID_RES/mipmap-mdpi/ic_launcher.png"
cp "$TEMP_DIR/launcher_72.png" "$ANDROID_RES/mipmap-hdpi/ic_launcher.png"
cp "$TEMP_DIR/launcher_96.png" "$ANDROID_RES/mipmap-xhdpi/ic_launcher.png"
cp "$TEMP_DIR/launcher_144.png" "$ANDROID_RES/mipmap-xxhdpi/ic_launcher.png"
cp "$TEMP_DIR/launcher_192.png" "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png"

# Android Round (same as launcher)
echo "  - Android Round..."
cp "$TEMP_DIR/launcher_48.png" "$ANDROID_RES/mipmap-mdpi/ic_launcher_round.png"
cp "$TEMP_DIR/launcher_72.png" "$ANDROID_RES/mipmap-hdpi/ic_launcher_round.png"
cp "$TEMP_DIR/launcher_96.png" "$ANDROID_RES/mipmap-xhdpi/ic_launcher_round.png"
cp "$TEMP_DIR/launcher_144.png" "$ANDROID_RES/mipmap-xxhdpi/ic_launcher_round.png"
cp "$TEMP_DIR/launcher_192.png" "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher_round.png"

# Android Notification
echo "  - Android Notification..."
cp "$TEMP_DIR/stat_24.png" "$ANDROID_RES/mipmap-mdpi/ic_stat_logo.png"
cp "$TEMP_DIR/stat_36.png" "$ANDROID_RES/mipmap-hdpi/ic_stat_logo.png"
cp "$TEMP_DIR/stat_48.png" "$ANDROID_RES/mipmap-xhdpi/ic_stat_logo.png"
cp "$TEMP_DIR/stat_72.png" "$ANDROID_RES/mipmap-xxhdpi/ic_stat_logo.png"
cp "$TEMP_DIR/stat_96.png" "$ANDROID_RES/mipmap-xxxhdpi/ic_stat_logo.png"

# Windows ICO
echo "  - Windows ICO..."
cp "$TEMP_DIR/icon.ico" "$SCRIPT_DIR/icon.ico"
cp "$TEMP_DIR/tray.ico" "$SCRIPT_DIR/tray-icon.ico"
cp "$TEMP_DIR/icon.ico" "$PROJECT_ROOT/flutter/windows/runner/resources/app_icon.ico"

# Linux
echo "  - Linux icons..."
cp "$TEMP_DIR/linux_32.png" "$SCRIPT_DIR/32x32.png"
cp "$TEMP_DIR/linux_64.png" "$SCRIPT_DIR/64x64.png"
cp "$TEMP_DIR/linux_128.png" "$SCRIPT_DIR/128x128.png"
cp "$TEMP_DIR/linux_256.png" "$SCRIPT_DIR/128x128@2x.png"

# Fastlane
FASTLANE_DIR="$PROJECT_ROOT/flutter/android/fastlane/metadata/android/en-US/images"
if [ -d "$FASTLANE_DIR" ]; then
    echo "  - Fastlane store icon..."
    cp "$TEMP_DIR/store_512.png" "$FASTLANE_DIR/icon.png"
else
    echo "  - Fastlane directory not found, skipping..."
fi

# ============================================
# Phase 4: SVG Replacement
# ============================================
echo ""
echo "Phase 4: SVG replacement..."

if [ -f "$SOURCE_SVG" ]; then
    # scalable.svg (32x32)
    echo "  - res/scalable.svg (32x32)..."
    sed 's/height="[^"]*"/height="32"/; s/width="[^"]*"/width="32"/' "$SOURCE_SVG" > "$SCRIPT_DIR/scalable.svg"
    
    # flutter/assets/icon.svg (150x150)
    echo "  - flutter/assets/icon.svg (150x150)..."
    sed 's/height="[^"]*"/height="150"/; s/width="[^"]*"/width="150"/' "$SOURCE_SVG" > "$PROJECT_ROOT/flutter/assets/icon.svg"
else
    echo "  - Warning: Source SVG not found, skipping SVG replacement..."
fi

# ============================================
# Phase 5: Cleanup
# ============================================
echo ""
echo "Phase 5: Cleanup..."
rm -rf "$TEMP_DIR"
echo "  - Removed temp directory"

# ============================================
# Phase 6: Verification
# ============================================
echo ""
echo "Phase 6: Verification..."

ERRORS=0

verify_file() {
    local file="$1"
    local expected_size="$2"
    
    if [ ! -f "$file" ]; then
        echo "  ✗ MISSING: $file"
        ERRORS=$((ERRORS + 1))
        return
    fi
    
    if [ -n "$expected_size" ]; then
        local actual=$(identify -format "%wx%h" "$file" 2>/dev/null || echo "unknown")
        if [ "$actual" = "$expected_size" ]; then
            echo "  ✓ $file ($actual)"
        else
            echo "  ✗ WRONG SIZE: $file (expected $expected_size, got $actual)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "  ✓ $file (exists)"
    fi
}

echo "Verifying Android icons..."
verify_file "$ANDROID_RES/mipmap-mdpi/ic_launcher_foreground.png" "108x108"
verify_file "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher_foreground.png" "432x432"
verify_file "$ANDROID_RES/mipmap-mdpi/ic_launcher.png" "48x48"
verify_file "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png" "192x192"
verify_file "$ANDROID_RES/mipmap-mdpi/ic_stat_logo.png" "24x24"
verify_file "$ANDROID_RES/mipmap-xxxhdpi/ic_stat_logo.png" "96x96"

echo "Verifying Windows icons..."
verify_file "$SCRIPT_DIR/icon.ico" ""
verify_file "$SCRIPT_DIR/tray-icon.ico" ""
verify_file "$PROJECT_ROOT/flutter/windows/runner/resources/app_icon.ico" ""

echo "Verifying Linux icons..."
verify_file "$SCRIPT_DIR/32x32.png" "32x32"
verify_file "$SCRIPT_DIR/128x128.png" "128x128"

echo "Verifying SVG files..."
verify_file "$SCRIPT_DIR/scalable.svg" ""
verify_file "$PROJECT_ROOT/flutter/assets/icon.svg" ""

echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All icons generated and verified successfully!"
else
    echo "✗ $ERRORS errors found. Please check the output above."
    exit 1
fi
