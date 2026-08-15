#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
BOT_COUNT="${BOT_COUNT:-8}"
DURATION="${DURATION:-45}"
PORT="${PORT:-$((25000 + RANDOM % 5000))}"
PASSWORD="${PASSWORD:-stress}"

if ! [[ "$BOT_COUNT" =~ ^[0-9]+$ ]] || (( BOT_COUNT < 4 || BOT_COUNT > 8 )); then
  echo "BOT_COUNT must be between 4 and 8." >&2
  exit 2
fi
if ! [[ "$DURATION" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "DURATION must be a number of seconds." >&2
  exit 2
fi

RUN_DIR="${RUN_DIR:-$(mktemp -d /tmp/ashenroot-network-stress.XXXXXX)}"
mkdir -p "$RUN_DIR/server-home"
SERVER_LOG="$RUN_DIR/server.log"
ADMIN_FILE="$RUN_DIR/admin_commands.txt"
WORLD_EXPORT="$RUN_DIR/world_export.json"
SERVER_PID=""
BOT_PIDS=()

cleanup() {
  local exit_code=$?
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    printf 'SHUTDOWN stress orchestrator cleanup\n' > "$ADMIN_FILE" || true
    sleep 2
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  for pid in "${BOT_PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  if (( exit_code != 0 )); then
    echo "Stress logs kept at: $RUN_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

echo "Starting dedicated server on UDP $PORT ($BOT_COUNT bots, ${DURATION}s)..."
HOME="$RUN_DIR/server-home" "$GODOT_BIN" --headless --path "$ROOT" -- \
  --dedicated \
  --world=0 \
  --port="$PORT" \
  --name="Automated Soak" \
  --password="$PASSWORD" \
  --pvp=true \
  --admin="$ADMIN_FILE" \
  --export="$WORLD_EXPORT" \
  >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

ready=0
for _attempt in $(seq 1 180); do
  if grep -q 'DEDICATED_SERVER_READY' "$SERVER_LOG" 2>/dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Dedicated server exited before becoming ready." >&2
    cat "$SERVER_LOG" >&2
    exit 1
  fi
  sleep 0.5
done
if (( ready == 0 )); then
  echo "Dedicated server startup timed out." >&2
  tail -n 100 "$SERVER_LOG" >&2
  exit 1
fi

for index in $(seq 0 $((BOT_COUNT - 1))); do
  bot_log="$RUN_DIR/bot_${index}.log"
  profile_id="$(printf 'ashenroot-stress-bot-%s' "$index" | sha256sum | cut -c1-48)"
  HOME="$RUN_DIR/bot-home-$index" \
  ASHENROOT_TEST_PROFILE_ID="$profile_id" \
  ASHENROOT_TEST_PORT="$PORT" \
  ASHENROOT_TEST_PASSWORD="$PASSWORD" \
  ASHENROOT_BOT_INDEX="$index" \
  ASHENROOT_BOT_COUNT="$BOT_COUNT" \
  ASHENROOT_BOT_DURATION="$DURATION" \
    "$GODOT_BIN" --headless --path "$ROOT" --script res://tests/network_stress_bot.gd \
    >"$bot_log" 2>&1 &
  BOT_PIDS+=("$!")
done

bot_failures=0
for index in $(seq 0 $((BOT_COUNT - 1))); do
  if ! wait "${BOT_PIDS[$index]}"; then
    echo "Bot $index failed:" >&2
    tail -n 100 "$RUN_DIR/bot_${index}.log" >&2
    bot_failures=$((bot_failures + 1))
  fi
done
BOT_PIDS=()

printf 'SAVE\nSTATUS\n' > "$ADMIN_FILE"
sleep 2
printf 'SHUTDOWN automated soak complete\n' > "$ADMIN_FILE"

server_stopped=0
for _attempt in $(seq 1 40); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    server_stopped=1
    break
  fi
  sleep 0.25
done
if (( server_stopped == 0 )); then
  echo "Dedicated server did not complete graceful shutdown." >&2
  exit 1
fi
wait "$SERVER_PID" || {
  echo "Dedicated server exited with an error." >&2
  tail -n 120 "$SERVER_LOG" >&2
  exit 1
}
SERVER_PID=""

if (( bot_failures > 0 )); then
  exit 1
fi

python3 - "$RUN_DIR" "$BOT_COUNT" <<'PY'
import json
import pathlib
import re
import sys

run_dir = pathlib.Path(sys.argv[1])
bot_count = int(sys.argv[2])
server_text = (run_dir / "server.log").read_text(errors="replace")
if re.search(r"SCRIPT ERROR|Parse Error|ERROR:", server_text):
    raise SystemExit("Server log contains script/runtime errors")
if "ADMIN_SAVE_OK" not in server_text:
    raise SystemExit("Dedicated forced-save command did not complete")

bot_results = []
for index in range(bot_count):
    text = (run_dir / f"bot_{index}.log").read_text(errors="replace")
    if re.search(r"SCRIPT ERROR|Parse Error|ERROR:", text):
        raise SystemExit(f"Bot {index} log contains script/runtime errors")
    matches = re.findall(r"NETWORK_STRESS_BOT_OK (\{.*\})", text)
    if len(matches) != 1:
        raise SystemExit(f"Bot {index} did not emit exactly one success result")
    bot_results.append(json.loads(matches[0]))

final_matches = re.findall(r"\[network\] diagnostics/final (\{.*\})", server_text)
if not final_matches:
    raise SystemExit("Server did not emit final network diagnostics")
diag = json.loads(final_matches[-1])
checks = {
    "accepted joins": diag.get("joins_accepted", 0) >= bot_count * 2,
    "compressed snapshots": diag.get("entity_snapshots_out", 0) > 0,
    "compression ratio": 0 < diag.get("entity_compression_ratio", 0) < 1,
    "entity traffic": diag.get("entity_bytes_per_second", 0) > 0,
    "accepted actions": diag.get("actions_accepted", 0) >= bot_count * 3,
    "snapshot rejects": diag.get("entity_snapshots_rejected", 0) == 0,
    "bot reconnects": all(item.get("reconnects") == 1 for item in bot_results),
    "bot snapshots": all(item.get("snapshots", 0) > 0 for item in bot_results),
    "bot chat": all(item.get("chat_received", 0) > 0 for item in bot_results),
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit("Stress assertions failed: " + ", ".join(failed))

summary = {
    "bots": bot_count,
    "joins": diag["joins_accepted"],
    "snapshots": diag["entity_snapshots_out"],
    "compression_ratio": diag["entity_compression_ratio"],
    "estimated_entity_bytes_per_second": diag["entity_bytes_per_second"],
    "actions": diag["actions_accepted"],
    "rate_limited": diag["actions_rate_limited"],
    "max_ping_ms": max(item["ping_ms"] for item in bot_results),
    "min_peak_roster": min(item["peak_roster"] for item in bot_results),
}
print("NETWORK_STRESS_OK " + json.dumps(summary, sort_keys=True))
PY

echo "Stress logs: $RUN_DIR"
trap - EXIT INT TERM
