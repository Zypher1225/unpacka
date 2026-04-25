#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/macos"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/package"
VERSION="${VERSION:-0.1.0}"
ICON_SOURCE="$ROOT_DIR/apps/macos/Assets/AppIcon.appiconset"

rm -rf "$DIST_DIR" "$BUILD_DIR"
mkdir -p "$DIST_DIR" "$BUILD_DIR"

build_icon() {
  local output="$1"
  local iconset="$BUILD_DIR/AppIcon.iconset"
  rm -rf "$iconset"
  mkdir -p "$iconset"

  cp "$ICON_SOURCE/16.png" "$iconset/icon_16x16.png"
  cp "$ICON_SOURCE/32.png" "$iconset/icon_16x16@2x.png"
  cp "$ICON_SOURCE/32.png" "$iconset/icon_32x32.png"
  cp "$ICON_SOURCE/64.png" "$iconset/icon_32x32@2x.png"
  cp "$ICON_SOURCE/128.png" "$iconset/icon_128x128.png"
  cp "$ICON_SOURCE/256.png" "$iconset/icon_128x128@2x.png"
  cp "$ICON_SOURCE/256.png" "$iconset/icon_256x256.png"
  cp "$ICON_SOURCE/512.png" "$iconset/icon_256x256@2x.png"
  cp "$ICON_SOURCE/512.png" "$iconset/icon_512x512.png"
  cp "$ICON_SOURCE/1024.png" "$iconset/icon_512x512@2x.png"
  iconutil -c icns "$iconset" -o "$output"
}

build_arch() {
  local arch="$1"
  local build_product="$APP_DIR/.build/${arch}-apple-macosx/release/Unpacka"
  local app_bundle="$BUILD_DIR/${arch}/解包鸭.app"
  local staging="$BUILD_DIR/dmg-${arch}"
  local dmg="$DIST_DIR/Unpacka-${VERSION}-macOS-${arch}.dmg"

  cd "$APP_DIR"
  swift build -c release --arch "$arch"

  rm -rf "$app_bundle" "$staging"
  mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources" "$staging"
  cp "$build_product" "$app_bundle/Contents/MacOS/Unpacka"
  build_icon "$app_bundle/Contents/Resources/AppIcon.icns"
  mkdir -p "$app_bundle/Contents/Resources/bin"
  cp "$ROOT_DIR/vendor/sevenzip/${arch}/7zz" "$app_bundle/Contents/Resources/bin/7zz"
  chmod +x "$app_bundle/Contents/Resources/bin/7zz"

  cat > "$app_bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>解包鸭</string>
  <key>CFBundleDisplayName</key>
  <string>解包鸭</string>
  <key>CFBundleExecutable</key>
  <string>Unpacka</string>
  <key>CFBundleIdentifier</key>
  <string>com.zypher.unpacka</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSMenuItem</key>
      <dict>
        <key>default</key>
        <string>用解包鸭解压</string>
      </dict>
      <key>NSMessage</key>
      <string>extractService</string>
      <key>NSPortName</key>
      <string>解包鸭</string>
      <key>NSSendTypes</key>
      <array>
        <string>NSFilenamesPboardType</string>
        <string>public.file-url</string>
      </array>
    </dict>
  </array>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>Archive</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Owner</string>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>zip</string>
        <string>7z</string>
        <string>rar</string>
        <string>tar</string>
        <string>gz</string>
        <string>tgz</string>
        <string>bz2</string>
        <string>tbz2</string>
        <string>xz</string>
        <string>txz</string>
      </array>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.zip-archive</string>
        <string>org.7-zip.7-zip-archive</string>
        <string>com.rarlab.rar-archive</string>
        <string>public.tar-archive</string>
        <string>org.gnu.gnu-zip-archive</string>
        <string>org.gnu.bzip2-archive</string>
        <string>org.tukaani.xz-archive</string>
      </array>
    </dict>
  </array>
  <key>UTImportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeIdentifier</key>
      <string>org.7-zip.7-zip-archive</string>
      <key>UTTypeDescription</key>
      <string>7Z Archive</string>
      <key>UTTypeConformsTo</key>
      <array><string>public.archive</string></array>
      <key>UTTypeTagSpecification</key>
      <dict><key>public.filename-extension</key><array><string>7z</string></array></dict>
    </dict>
    <dict>
      <key>UTTypeIdentifier</key>
      <string>com.rarlab.rar-archive</string>
      <key>UTTypeDescription</key>
      <string>RAR Archive</string>
      <key>UTTypeConformsTo</key>
      <array><string>public.archive</string></array>
      <key>UTTypeTagSpecification</key>
      <dict><key>public.filename-extension</key><array><string>rar</string></array></dict>
    </dict>
  </array>
</dict>
</plist>
PLIST

  codesign --force --sign - "$app_bundle/Contents/Resources/bin/7zz"
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
