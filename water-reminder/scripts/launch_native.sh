#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/Water Reminder.app"

if [ ! -d "$APP_BUNDLE" ]; then
  "$ROOT_DIR/scripts/package_app.sh"
fi

open "$APP_BUNDLE"
