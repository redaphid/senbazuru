#!/usr/bin/env bash
# Build, install to /Applications, and re-pin the Launch-at-Login item to the
# freshly signed bundle. Each ad-hoc rebuild gets a new cdhash, which orphans the
# previously registered SMAppService login item; re-registering the installed copy
# keeps Launch-at-Login working across rebuilds. Run this (not build.sh) whenever
# you want the login item to survive a rebuild.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

APP="/Applications/Senbazuru.app"
rm -rf "$APP"
cp -R "build/Senbazuru.app" "$APP"

# Re-pin the login item to the stable, freshly signed bundle.
"$APP/Contents/MacOS/Senbazuru" --register-login
