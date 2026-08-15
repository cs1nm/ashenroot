#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
PORT="${PORT:-$((30000 + RANDOM % 2000))}"
PASSWORD="${PASSWORD:-admin}"
RUN_DIR="${RUN_DIR:-$(mktemp -d /tmp/ashenroot-network-admin.XXXXXX)}"
mkdir -p "$RUN_DIR/server-home" "$RUN_DIR/client-home"
SERVER_LOG="$RUN_DIR/server.log"
CLIENT_LOG="$RUN_DIR/client.log"
ADMIN_FILE="$RUN_DIR/admin_commands.txt"
SERVER_PID=""
CLIENT_PID=""

cleanup() {
  local exit_code=$?
  [[ -n "$CLIENT_PID" ]] && kill "$CLIENT_PID" 2>/dev/null || true
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    printf 'SHUTDOWN admin smoke cleanup\n' > "$ADMIN_FILE" || true
    sleep 2
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  if (( exit_code != 0 )); then
    echo "Admin smoke logs kept at: $RUN_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

HOME="$RUN_DIR/server-home" "$GODOT_BIN" --headless --path "$ROOT" -- \
  --dedicated --world=0 --port="$PORT" --name="Admin Smoke" --password="$PASSWORD" \
  --pvp=false --admin="$ADMIN_FILE" --export="$RUN_DIR/world_export.json" \
  >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

for _attempt in $(seq 1 180); do
  grep -q 'DEDICATED_SERVER_READY' "$SERVER_LOG" 2>/dev/null && break
  kill -0 "$SERVER_PID" 2>/dev/null || { cat "$SERVER_LOG" >&2; exit 1; }
  sleep 0.5
done
grep -q 'DEDICATED_SERVER_READY' "$SERVER_LOG" || { echo "Admin server startup timed out." >&2; exit 1; }

profile_id="$(printf 'ashenroot-admin-ban-smoke' | sha256sum | cut -c1-48)"
HOME="$RUN_DIR/client-home" \
ASHENROOT_TEST_PROFILE_ID="$profile_id" \
ASHENROOT_TEST_PORT="$PORT" \
ASHENROOT_TEST_PASSWORD="$PASSWORD" \
  "$GODOT_BIN" --headless --path "$ROOT" --script res://tests/network_ban_client_test.gd \
  >"$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!

peer_id=""
for _attempt in $(seq 1 120); do
  peer_id="$(sed -n 's/.*NETWORK_BAN_CLIENT_READY peer=\([0-9][0-9]*\).*/\1/p' "$CLIENT_LOG" | tail -n 1)"
  [[ -n "$peer_id" ]] && break
  kill -0 "$CLIENT_PID" 2>/dev/null || { cat "$CLIENT_LOG" >&2; exit 1; }
  sleep 0.25
done
[[ -n "$peer_id" ]] || { echo "Ban client did not become ready." >&2; exit 1; }
printf 'BAN %s\n' "$peer_id" > "$ADMIN_FILE"

if ! wait "$CLIENT_PID"; then
  cat "$CLIENT_LOG" >&2
  exit 1
fi
CLIENT_PID=""
grep -q 'NETWORK_BAN_CLIENT_OK' "$CLIENT_LOG" || { cat "$CLIENT_LOG" >&2; exit 1; }

printf 'STATUS\nCLEAR_BANS\nSAVE\nSHUTDOWN admin smoke complete\n' > "$ADMIN_FILE"
for _attempt in $(seq 1 60); do
  kill -0 "$SERVER_PID" 2>/dev/null || break
  sleep 0.25
done
if kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "Admin server did not shut down gracefully." >&2
  exit 1
fi
wait "$SERVER_PID"
SERVER_PID=""

python3 - "$RUN_DIR" <<'PY'
import json
import pathlib
import re
import sys
root = pathlib.Path(sys.argv[1])
server = (root / "server.log").read_text(errors="replace")
client = (root / "client.log").read_text(errors="replace")
for name, text in (("server", server), ("client", client)):
    if re.search(r"SCRIPT ERROR|Parse Error|ERROR:", text):
        raise SystemExit(f"{name} log contains script/runtime errors")
required = ["ADMIN_BAN peer=", "ADMIN_CLEAR_BANS removed=1", "ADMIN_SAVE_OK", "diagnostics/final"]
missing = [item for item in required if item not in server]
if missing:
    raise SystemExit("Missing admin results: " + ", ".join(missing))
logs = list((root / "server-home").rglob("server_connections.log"))
if len(logs) != 1:
    raise SystemExit("Connection journal was not created")
events = [json.loads(line)["event"] for line in logs[0].read_text().splitlines() if line.strip()]
for event in ("server_start", "connect", "join", "ban", "reject", "server_stop"):
    if event not in events:
        raise SystemExit(f"Connection journal is missing event: {event}")
ban_files = list((root / "server-home").rglob("server_bans.json"))
if len(ban_files) != 1 or json.loads(ban_files[0].read_text()) != {}:
    raise SystemExit("CLEAR_BANS did not persist an empty ban-list")
print("NETWORK_ADMIN_SMOKE_OK events=%d" % len(events))
PY

echo "Admin smoke logs: $RUN_DIR"
trap - EXIT INT TERM
