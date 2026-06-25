#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Senbazuru"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP/Contents/MacOS"
BIN="$MACOS_DIR/$APP_NAME"

rm -rf "$APP"
mkdir -p "$MACOS_DIR"

swiftc -O \
	-target "$(uname -m)-apple-macosx13.0" \
	-framework AppKit -framework WebKit -framework AVFoundation -framework ServiceManagement \
	-o "$BIN" \
	Sources/*.swift

cp Info.plist "$APP/Contents/Info.plist"

# Ad-hoc sign with hardened runtime so the microphone TCC prompt works.
codesign --force --options runtime \
	--entitlements "$APP_NAME.entitlements" \
	--sign - "$APP"

echo "Built $APP"
