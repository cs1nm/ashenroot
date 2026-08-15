#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/data"
WORLD="${WORLD:-0}"
PORT="${PORT:-24567}"
SERVER_NAME="${SERVER_NAME:-My Shadowgrove}"
PASSWORD="${PASSWORD:-}"
PVP="${PVP:-false}"
exec "$ROOT/AshenRootsServer" --headless -- \
  --dedicated \
  "--world=$WORLD" \
  "--port=$PORT" \
  "--name=$SERVER_NAME" \
  "--password=$PASSWORD" \
  "--pvp=$PVP" \
  "--admin=$ROOT/data/admin_commands.txt" \
  "--export=$ROOT/data/world_export.json" \
  "$@"
