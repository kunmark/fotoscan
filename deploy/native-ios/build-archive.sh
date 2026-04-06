#!/bin/bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-/Volumes/work/C/fotoscan/source/native-ios/BarcodeCaptureApp.xcodeproj}"
SCHEME="${SCHEME:-BarcodeCaptureApp}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$PWD/BarcodeCaptureApp.xcarchive}"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "Archive created at: $ARCHIVE_PATH"
