#!/bin/bash
set -e

SDK=$(xcrun --sdk iphoneos --show-sdk-path)

clang -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -lobjc \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=13.0 \
  -fobjc-arc \          # ← ADD THIS LINE
  -o RWFileManager.dylib \
  RWFileManager.m

echo "Built RWFileManager.dylib"