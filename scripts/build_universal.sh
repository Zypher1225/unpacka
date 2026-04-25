#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/macos"
CORE_DIR="$ROOT_DIR/core"

cd "$APP_DIR"
swift build -c release

cd "$CORE_DIR"
cargo build --release

echo "Swift MVP and Rust core built successfully."
