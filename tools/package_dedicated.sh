#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_VERSION="${GODOT_VERSION:-4.7.1-stable}"
GODOT_BIN="${GODOT_BIN:-godot}"
GODOT_LINUX_BIN="${GODOT_LINUX_BIN:-$GODOT_BIN}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/dist/dedicated}"
CACHE_DIR="${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ashenroot-dedicated}"
DOWNLOAD_BASE="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"
WINDOWS_ARCHIVE="Godot_v${GODOT_VERSION}_win64.exe.zip"
WINDOWS_URL="${GODOT_WINDOWS_URL:-$DOWNLOAD_BASE/$WINDOWS_ARCHIVE}"
WINDOWS_SHA512="${GODOT_WINDOWS_SHA512:-a6b02c527c18ba9936e63562032701432b2dc57d98d6483ceaccb00fe14af16af5773ae8a55e7b4d614edf121c4d9e420d870f804edb1dac16362298a01ce6c4}"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" log -1 --format=%ct 2>/dev/null || date +%s)}"

for command in curl unzip zip tar gzip sha256sum sha512sum python3; do
  command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 2; }
done
if [[ "$GODOT_BIN" != */* ]]; then
  GODOT_BIN="$(command -v "$GODOT_BIN" || true)"
fi
if [[ "$GODOT_LINUX_BIN" != */* ]]; then
  GODOT_LINUX_BIN="$(command -v "$GODOT_LINUX_BIN" || true)"
fi
[[ -x "$GODOT_BIN" ]] || { echo "GODOT_BIN is not executable: $GODOT_BIN" >&2; exit 2; }
[[ -x "$GODOT_LINUX_BIN" ]] || { echo "GODOT_LINUX_BIN is not executable: $GODOT_LINUX_BIN" >&2; exit 2; }

mkdir -p "$CACHE_DIR" "$OUTPUT_DIR"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ashenroot-dedicated-package.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

if [[ -n "${GODOT_WINDOWS_BIN:-}" ]]; then
  WINDOWS_BIN="$GODOT_WINDOWS_BIN"
  [[ -f "$WINDOWS_BIN" ]] || { echo "GODOT_WINDOWS_BIN does not exist: $WINDOWS_BIN" >&2; exit 2; }
else
  archive_path="$CACHE_DIR/$WINDOWS_ARCHIVE"
  if [[ ! -s "$archive_path" ]]; then
    echo "Downloading pinned Godot Windows runtime $GODOT_VERSION..."
    curl --fail --location --retry 3 --output "$archive_path.part" "$WINDOWS_URL"
    mv "$archive_path.part" "$archive_path"
  fi
  printf '%s  %s\n' "$WINDOWS_SHA512" "$archive_path" | sha512sum --check --status || {
    echo "Windows Godot runtime checksum mismatch: $archive_path" >&2
    exit 1
  }
  mkdir -p "$WORK_DIR/windows-runtime"
  unzip -q "$archive_path" -d "$WORK_DIR/windows-runtime"
  WINDOWS_BIN="$(find "$WORK_DIR/windows-runtime" -maxdepth 2 -type f -iname '*win64.exe' ! -iname '*console.exe' | head -n 1)"
  [[ -n "$WINDOWS_BIN" ]] || { echo "Windows Godot runtime was not found in $archive_path" >&2; exit 2; }
fi

linux_version="$($GODOT_LINUX_BIN --version | head -n 1)"
if [[ "$linux_version" != 4.7.1.* ]]; then
  echo "Expected Godot 4.7.1, got: $linux_version" >&2
  exit 2
fi

echo "Exporting platform-neutral dedicated PCK..."
PCK="$WORK_DIR/AshenRootsServer.pck"
"$GODOT_BIN" --headless --path "$ROOT" --export-pack Android "$PCK" >"$WORK_DIR/export-pack.log" 2>&1 || {
  cat "$WORK_DIR/export-pack.log" >&2
  exit 1
}
[[ -s "$PCK" ]] || { echo "Godot did not create the dedicated PCK." >&2; exit 1; }

LINUX_ROOT="$WORK_DIR/AshenRootsServer-linux-x86_64"
WINDOWS_ROOT="$WORK_DIR/AshenRootsServer-windows-x86_64"
mkdir -p "$LINUX_ROOT/data" "$WINDOWS_ROOT/data"
cp "$GODOT_LINUX_BIN" "$LINUX_ROOT/AshenRootsServer"
cp "$WINDOWS_BIN" "$WINDOWS_ROOT/AshenRootsServer.exe"
cp "$PCK" "$LINUX_ROOT/AshenRootsServer.pck"
cp "$PCK" "$WINDOWS_ROOT/AshenRootsServer.pck"
cp "$ROOT/server/package/start_server.sh" "$LINUX_ROOT/start_server.sh"
cp "$ROOT/server/package/admin.sh" "$LINUX_ROOT/admin.sh"
cp "$ROOT/server/package/start_server.bat" "$WINDOWS_ROOT/start_server.bat"
cp "$ROOT/server/package/admin.bat" "$WINDOWS_ROOT/admin.bat"
cp "$ROOT/server/package/README.txt" "$LINUX_ROOT/README.txt"
cp "$ROOT/server/package/README.txt" "$WINDOWS_ROOT/README.txt"
cp "$ROOT/server/package/GODOT_LICENSE.txt" "$LINUX_ROOT/GODOT_LICENSE.txt"
cp "$ROOT/server/package/GODOT_LICENSE.txt" "$WINDOWS_ROOT/GODOT_LICENSE.txt"
cp "$ROOT/server/package/GODOT_COPYRIGHT.txt" "$LINUX_ROOT/GODOT_COPYRIGHT.txt"
cp "$ROOT/server/package/GODOT_COPYRIGHT.txt" "$WINDOWS_ROOT/GODOT_COPYRIGHT.txt"
chmod 755 "$LINUX_ROOT/AshenRootsServer" "$LINUX_ROOT/start_server.sh" "$LINUX_ROOT/admin.sh"
printf 'Runtime data; preserve this directory when upgrading.\n' > "$LINUX_ROOT/data/README.txt"
printf 'Runtime data; preserve this directory when upgrading.\r\n' > "$WINDOWS_ROOT/data/README.txt"

commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf unknown)"
python3 - "$LINUX_ROOT/build-manifest.json" "$commit" "$GODOT_VERSION" "$PCK" "$GODOT_LINUX_BIN" <<'PY'
import hashlib, json, pathlib, sys
out, commit, version, pck, runtime = sys.argv[1:]
def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()
data = {
    "project_commit": commit,
    "godot_version": version,
    "pck_sha256": digest(pck),
    "runtime_sha256": digest(runtime),
    "platform": "linux-x86_64",
}
pathlib.Path(out).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
python3 - "$WINDOWS_ROOT/build-manifest.json" "$commit" "$GODOT_VERSION" "$PCK" "$WINDOWS_BIN" <<'PY'
import hashlib, json, pathlib, sys
out, commit, version, pck, runtime = sys.argv[1:]
def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()
data = {
    "project_commit": commit,
    "godot_version": version,
    "pck_sha256": digest(pck),
    "runtime_sha256": digest(runtime),
    "platform": "windows-x86_64",
}
pathlib.Path(out).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY

# Normalize timestamps and archive metadata so identical inputs yield identical files.
find "$LINUX_ROOT" "$WINDOWS_ROOT" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
LINUX_ARCHIVE="$OUTPUT_DIR/AshenRootsServer-linux-x86_64.tar.gz"
WINDOWS_ARCHIVE_OUT="$OUTPUT_DIR/AshenRootsServer-windows-x86_64.zip"
rm -f "$LINUX_ARCHIVE" "$WINDOWS_ARCHIVE_OUT" "$OUTPUT_DIR/SHA256SUMS.txt"
tar --sort=name --mtime="@$SOURCE_DATE_EPOCH" --owner=0 --group=0 --numeric-owner \
  -C "$WORK_DIR" -cf - "$(basename "$LINUX_ROOT")" | gzip -n -9 > "$LINUX_ARCHIVE"
(
  cd "$WORK_DIR"
  find "$(basename "$WINDOWS_ROOT")" -type f -print0 | LC_ALL=C sort -z | xargs -0 zip -q -X "$WINDOWS_ARCHIVE_OUT"
)
(
  cd "$OUTPUT_DIR"
  sha256sum "$(basename "$LINUX_ARCHIVE")" "$(basename "$WINDOWS_ARCHIVE_OUT")" > SHA256SUMS.txt
)

cat <<EOF
DEDICATED_PACKAGES_OK
  $LINUX_ARCHIVE
  $WINDOWS_ARCHIVE_OUT
  $OUTPUT_DIR/SHA256SUMS.txt
EOF
