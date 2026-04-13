#!/bin/bash
# PZFB — Video Framebuffer: Linux Uninstaller
# Removes patched Color class files from the PZ install directory.

set -e

# Auto-detect PZ install directory (same logic as install.sh)
PZ_DIR=""
DEFAULT_PATH="$HOME/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
FLATPAK_PATH="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"

if [ -f "$DEFAULT_PATH/projectzomboid.jar" ]; then
    PZ_DIR="$DEFAULT_PATH"
elif [ -f "$FLATPAK_PATH/projectzomboid.jar" ]; then
    PZ_DIR="$FLATPAK_PATH"
elif [ -n "$1" ] && [ -f "$1/projectzomboid.jar" ]; then
    PZ_DIR="$1"
fi

if [ -z "$PZ_DIR" ]; then
    echo "ERROR: Could not find Project Zomboid installation."
    echo "  $0 /path/to/ProjectZomboid/projectzomboid"
    exit 1
fi

echo "PZ install: $PZ_DIR"

# Remove class files
rm -f "$PZ_DIR/zombie/core/Color"*.class

echo ""
echo "SUCCESS: PZFB class files removed."
echo "Restart Project Zomboid to restore vanilla Color class."
