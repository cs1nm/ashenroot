#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if (( $# == 0 )); then
  echo "Usage: $0 STATUS|SAVE|KICK peer_id|BAN peer_id|CLEAR_BANS|SHUTDOWN [reason]" >&2
  exit 2
fi
mkdir -p "$ROOT/data"
printf '%s\n' "$*" > "$ROOT/data/admin_commands.txt"
echo "Queued admin command: $*"
