#!/bin/bash
# PZFB — Video Framebuffer: Linux Installer
# Copies patched Color class files to the PZ install directory.
# Run once after subscribing, then restart Project Zomboid.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLASS_DIR="$SCRIPT_DIR/class_files"

# Verify class files exist
if [ ! -f "$CLASS_DIR/Color.class" ]; then
    echo "ERROR: class_files/Color.class not found in $SCRIPT_DIR"
    echo "Make sure you're running this from the PZFB mod directory."
    exit 1
fi

# Auto-detect PZ install directory
PZ_DIR=""

# Check default Steam location
DEFAULT_PATH="$HOME/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
if [ -f "$DEFAULT_PATH/projectzomboid.jar" ]; then
    PZ_DIR="$DEFAULT_PATH"
fi

# Check Flatpak Steam location
FLATPAK_PATH="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
if [ -z "$PZ_DIR" ] && [ -f "$FLATPAK_PATH/projectzomboid.jar" ]; then
    PZ_DIR="$FLATPAK_PATH"
fi

# Check Steam library folders for alternate install locations
if [ -z "$PZ_DIR" ]; then
    for VDF in "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf" \
               "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/libraryfolders.vdf"; do
        if [ -f "$VDF" ]; then
            while IFS= read -r line; do
                path=$(echo "$line" | grep -oP '"path"\s+"\K[^"]+')
                if [ -n "$path" ] && [ -f "$path/steamapps/common/ProjectZomboid/projectzomboid/projectzomboid.jar" ]; then
                    PZ_DIR="$path/steamapps/common/ProjectZomboid/projectzomboid"
                    break 2
                fi
            done < "$VDF"
        fi
    done
fi

if [ -z "$PZ_DIR" ]; then
    echo "ERROR: Could not find Project Zomboid installation."
    echo ""
    echo "Please specify the path manually:"
    echo "  $0 /path/to/ProjectZomboid/projectzomboid"
    exit 1
fi

# Allow manual override via argument
if [ -n "$1" ]; then
    if [ -f "$1/projectzomboid.jar" ]; then
        PZ_DIR="$1"
    else
        echo "ERROR: $1/projectzomboid.jar not found."
        exit 1
    fi
fi

echo "PZ install: $PZ_DIR"

# Deploy class files
mkdir -p "$PZ_DIR/zombie/core"
cp "$CLASS_DIR"/Color*.class "$PZ_DIR/zombie/core/"

COUNT=$(ls -1 "$PZ_DIR/zombie/core/Color"*.class 2>/dev/null | wc -l)
echo ""
echo "SUCCESS: $COUNT class files deployed to $PZ_DIR/zombie/core/"
echo "Restart Project Zomboid to activate Video Framebuffer."
