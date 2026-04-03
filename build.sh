#!/bin/bash
# PZFB — Video Framebuffer: Build Script
# Compiles patched Color.java and packages class files for distribution.
#
# Usage:
#   ./build.sh            # Compile only
#   ./build.sh --deploy   # Compile + deploy to PZ install directory

set -e

PZ="$HOME/.local/share/Steam/steamapps/common/ProjectZomboid/projectzomboid"
JAVAC="/usr/lib64/openjdk-25/bin/javac"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify prerequisites
if [ ! -f "$PZ/projectzomboid.jar" ]; then
    echo "ERROR: PZ jar not found at $PZ/projectzomboid.jar"
    exit 1
fi
if [ ! -x "$JAVAC" ]; then
    echo "ERROR: Java 25 javac not found at $JAVAC"
    exit 1
fi

# Clean and compile
echo "Compiling Color.java with Java 25..."
rm -rf "$REPO_DIR/build/zombie"
mkdir -p "$REPO_DIR/build"
$JAVAC -cp "$PZ/projectzomboid.jar" "$REPO_DIR/java/zombie/core/Color.java" -d "$REPO_DIR/build/"

# Copy to class_files for distribution
echo "Copying to class_files/..."
mkdir -p "$REPO_DIR/class_files"
rm -f "$REPO_DIR/class_files/"Color*.class
cp "$REPO_DIR/build/zombie/core/"Color*.class "$REPO_DIR/class_files/"

COUNT=$(ls -1 "$REPO_DIR/class_files/"Color*.class | wc -l)
echo "Built $COUNT class files."

# Optional: deploy to PZ install directory
if [ "$1" = "--deploy" ]; then
    echo "Deploying to PZ install directory..."
    rm -f "$PZ/zombie/core/"Color*.class
    mkdir -p "$PZ/zombie/core"
    cp "$REPO_DIR/class_files/"Color*.class "$PZ/zombie/core/"
    echo "Deployed. Restart PZ to test."
fi

echo "Done."
