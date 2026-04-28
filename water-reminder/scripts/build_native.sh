#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT_DIR/build"

clang \
  -fobjc-arc \
  -framework Cocoa \
  "$ROOT_DIR/App/main.m" \
  -o "$ROOT_DIR/build/WaterReminder"
