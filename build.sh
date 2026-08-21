#!/bin/bash
set -e

echo "=== Vercel Flutter Web Build Start ==="

# 1. Allow running Flutter as root in Vercel build environment
export FLUTTER_ALLOW_ROOT=1

# 2. Mark all git directories safe to avoid ownership errors in /tmp
git config --global --add safe.directory '*' || true

FLUTTER_DIR="/tmp/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "Using cached Flutter SDK..."
fi

export PATH="$PATH:$FLUTTER_DIR/bin"
export DART_VM_OPTIONS="--old_gen_heap_size=2048"

git config --global --add safe.directory "$FLUTTER_DIR" || true

flutter config --no-analytics

echo "Checking Flutter version..."
flutter --version

echo "Compiling Flutter Web (Release mode)..."
flutter build web --release --no-tree-shake-icons

echo "=== Vercel Flutter Web Build Completed Successfully ==="
