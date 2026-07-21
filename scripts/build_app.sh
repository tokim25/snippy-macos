#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG="${1:-debug}"
swift build -c "$CONFIG"

APP_DIR="$ROOT_DIR/Snippy.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/$CONFIG/Snippy" "$MACOS_DIR/Snippy"
cp "Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

SIGNING_IDENTITY="Snippy Development"
codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"

echo "Built $APP_DIR"
