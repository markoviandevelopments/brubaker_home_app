#!/bin/bash

set -e

# Ensure required environment variables are set
if [ -z "$SCHEME_NAME" ] || [ -z "$PROJECT_NAME" ] || [ -z "$ARCHIVE_PATH" ] || [ -z "$EXPORT_PATH" ]; then
  echo "Error: Missing required environment variables (SCHEME_NAME, PROJECT_NAME, ARCHIVE_PATH, EXPORT_PATH)"
  exit 1
fi

# Create build directory
mkdir -p "$(dirname "$ARCHIVE_PATH")"
mkdir -p "$EXPORT_PATH"

# Build the archive for generic iOS device
xcodebuild archive \
  -project "$PROJECT_NAME.xcodeproj" \
  -scheme "$SCHEME_NAME" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Export the unsigned IPA
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ./scripts/exportOptions.plist
