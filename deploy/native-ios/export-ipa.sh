#!/bin/bash
set -euo pipefail

ARCHIVE_PATH="${ARCHIVE_PATH:-$PWD/BarcodeCaptureApp.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$PWD/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$PWD/ExportOptions.plist}"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "IPA export completed at: $EXPORT_PATH"
