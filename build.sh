#!/bin/bash
set -e

SDK=$(xcrun --sdk iphoneos --show-sdk-path)

clang -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework QuartzCore \
  -framework UniformTypeIdentifiers \
  -lobjc \
  -arch arm64 \
  -isysroot "$SDK" \
  -miphoneos-version-min=13.0 \
  -fobjc-arc \
  -o RWFileManager.dylib \
  RWFileManager.m

echo "Built RWFileManager.dylib"