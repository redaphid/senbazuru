#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Senbazuru"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP/Contents/MacOS"
RES_DIR="$APP/Contents/Resources"
BIN="$MACOS_DIR/$APP_NAME"

rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES_DIR"

swiftc -O \
	-target "$(uname -m)-apple-macosx13.0" \
	-framework AppKit -framework WebKit -framework AVFoundation -framework ServiceManagement \
	-o "$BIN" \
	Sources/*.swift

cp Info.plist "$APP/Contents/Info.plist"
cp icon/AppIcon.icns "$RES_DIR/AppIcon.icns"
cp icon/menubar.png "$RES_DIR/menubar.png"

# Ad-hoc sign with hardened runtime so the microphone TCC prompt works.
codesign --force --options runtime \
	--entitlements "$APP_NAME.entitlements" \
	--sign - "$APP"

echo "Built $APP"
