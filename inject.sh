#!/bin/bash
# Usage: ./inject.sh <path-to-app-binary>
# Example: ./inject.sh Payload/BendyNightmareRun.app/BendyNightmareRun
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <app-binary>"
  exit 1
fi

BINARY="$1"
DYLIB="$(pwd)/RWFileManager.dylib"

if [ ! -f "$DYLIB" ]; then
  echo "RWFileManager.dylib not found. Run build.sh first."
  exit 1
fi

# Copy dylib next to binary (inside .app bundle)
APP_DIR="$(dirname "$BINARY")"
cp "$DYLIB" "$APP_DIR/RWFileManager.dylib"

# Inject load command
insert_dylib --strip-codesig --inplace \
  "@executable_path/RWFileManager.dylib" \
  "$BINARY"

echo "Injected. Now sign the .app bundle with KSign."
echo "Remember to also sign RWFileManager.dylib inside the bundle."
