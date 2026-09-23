#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
PORT="${PORT:-$((27000 + RANDOM % 2000))}"
RUN_DIR="${RUN_DIR:-$(mktemp -d /tmp/ashenroot-network-liquid.XXXXXX)}"
mkdir -p "$RUN_DIR/server-home" "$RUN_DIR/client-home"
SERVER_LOG="$RUN_DIR/server.log"
CLIENT_LOG="$RUN_DIR/client.log"
SERVER_PID=""

cleanup() {
  local exit_code=$?
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  if (( exit_code != 0 )); then
    echo "Liquid smoke logs kept at: $RUN_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

HOME="$RUN_DIR/server-home" ASHENROOT_TEST_PORT="$PORT" \
  "$GODOT_BIN" --headless --path "$ROOT" --script res://tests/network_liquid_server_test.gd \
  >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _attempt in $(seq 1 120); do
  grep -q 'NETWORK_LIQUID_SERVER_READY' "$SERVER_LOG" 2>/dev/null && break
  kill -0 "$SERVER_PID" 2>/dev/null || { cat "$SERVER_LOG" >&2; exit 1; }
  sleep 0.1
done
grep -q 'NETWORK_LIQUID_SERVER_READY' "$SERVER_LOG" || { echo "Liquid server startup timed out." >&2; exit 1; }

HOME="$RUN_DIR/client-home" ASHENROOT_TEST_PORT="$PORT" \
  "$GODOT_BIN" --headless --path "$ROOT" --script res://tests/network_liquid_client_test.gd \
  >"$CLIENT_LOG" 2>&1

for _attempt in $(seq 1 120); do
  kill -0 "$SERVER_PID" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "Liquid server did not finish after client disconnect." >&2
  exit 1
fi
wait "$SERVER_PID"
SERVER_PID=""

python3 - "$SERVER_LOG" "$CLIENT_LOG" <<'PY'
import json
import pathlib
import re
import sys
server = pathlib.Path(sys.argv[1]).read_text(errors="replace")
client = pathlib.Path(sys.argv[2]).read_text(errors="replace")
for name, text in (("server", server), ("client", client)):
    if re.search(r"SCRIPT ERROR|Parse Error|ERROR:", text):
        raise SystemExit(f"{name} log contains script/runtime errors")
for marker, text in (
    ("NETWORK_LIQUID_SERVER_SETTLED", server),
    ("NETWORK_LIQUID_SERVER_OK", server),
    ("NETWORK_LIQUID_CLIENT_OK", client),
):
    if marker not in text:
        raise SystemExit(f"Missing liquid synchronization result: {marker}")
match = re.search(r"diagnostics/final (\{.*\})", server)
if not match:
    raise SystemExit("Missing final network diagnostics")
diagnostics = json.loads(match.group(1))
if diagnostics.get("liquid_states_out", 0) < 2:
    raise SystemExit("Server did not send both liquid states")
if diagnostics.get("liquid_batches_rejected", 0) != 0:
    raise SystemExit("Liquid state batch was rejected")
print("NETWORK_LIQUID_SMOKE_OK")
PY

echo "Liquid smoke logs: $RUN_DIR"
trap - EXIT INT TERM
