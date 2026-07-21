#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-$(defaults read "$ROOT_DIR/Info.plist" CFBundleShortVersionString)}"
DMG_NAME="Snippy-$VERSION.dmg"

./scripts/build_app.sh release

rm -rf dist "$DMG_NAME"
mkdir -p dist
cp -R Snippy.app dist/
ln -s /Applications dist/Applications

hdiutil create -volname "Snippy" -srcfolder dist -ov -format UDZO "$DMG_NAME"
rm -rf dist

echo "Built $DMG_NAME"
