#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
WORLD="${WORLD:-0}"
PORT="${PORT:-24567}"
SERVER_NAME="${SERVER_NAME:-My Shadowgrove}"
PASSWORD="${PASSWORD:-}"
PVP="${PVP:-false}"

exec "$GODOT_BIN" --headless --path "$ROOT" -- \
  --dedicated \
  "--world=$WORLD" \
  "--port=$PORT" \
  "--name=$SERVER_NAME" \
  "--password=$PASSWORD" \
  "--pvp=$PVP" \
  "$@"
