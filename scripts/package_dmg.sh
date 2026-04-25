#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/macos"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/package"
VERSION="${VERSION:-0.1.0}"

rm -rf "$DIST_DIR" "$BUILD_DIR"
mkdir -p "$DIST_DIR" "$BUILD_DIR"

build_arch() {
  local arch="$1"
  local build_product="$APP_DIR/.build/${arch}-apple-macosx/release/Unpacka"
  local app_bundle="$BUILD_DIR/${arch}/Unpacka.app"
  local staging="$BUILD_DIR/dmg-${arch}"
  local dmg="$DIST_DIR/Unpacka-${VERSION}-macOS-${arch}.dmg"

  cd "$APP_DIR"
  swift build -c release --arch "$arch"

  rm -rf "$app_bundle" "$staging"
  mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources" "$staging"
  cp "$build_product" "$app_bundle/Contents/MacOS/Unpacka"

  cat > "$app_bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Unpacka</string>
  <key>CFBundleDisplayName</key>
  <string>解包鸭</string>
  <key>CFBundleExecutable</key>
  <string>Unpacka</string>
  <key>CFBundleIdentifier</key>
  <string>com.zypher.unpacka</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

  codesign --force --deep --sign - "$app_bundle"

  cp -R "$app_bundle" "$staging/"
  ln -s /Applications "$staging/Applications"
  hdiutil create -volname "Unpacka ${VERSION}" -srcfolder "$staging" -ov -format UDZO "$dmg"
  echo "Created $dmg"
}

build_arch arm64
build_arch x86_64

cd "$ROOT_DIR/core"
cargo build --release

echo "Release artifacts are in $DIST_DIR"
