#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/assets/art/icon.svg"
PNG_SOURCE="$ROOT/assets/art/Qoob_icon_1024.png"
ICONSET="$ROOT/assets/art/Qoob.iconset"
ICNS="$ROOT/assets/art/Qoob.icns"

node "$ROOT/tools/generate_icon_png.mjs"

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

sips -z 16 16 "$PNG_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$PNG_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$PNG_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$PNG_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$PNG_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$PNG_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$PNG_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$PNG_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$PNG_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$PNG_SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET" -o "$ICNS"
echo "Generated $ICNS"
