#!/usr/bin/env bash
set -euo pipefail

# Локальная сборка Android APK для Ashen Roots
# Требует: Godot 4.4+ с Android export templates, Java 17, Android SDK (для подписи)
# Использование: ./tools/build_android.sh [debug|release]

BUILD_TYPE="${1:-debug}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build/android"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" &>/dev/null; then
  echo "Godot не найден. Укажите GODOT_BIN или установите Godot 4.7+"
  echo "  https://godotengine.org/download"
  exit 1
fi

echo "Godot: $($GODOT_BIN --version)"
echo "Build type: $BUILD_TYPE"

mkdir -p "$OUTPUT_DIR"

# Импорт проекта (генерирует .godot)
echo "→ Импорт проекта..."
"$GODOT_BIN" --headless --import --verbose 2>&1 | tail -n 30 || true

# Создаём debug keystore если нет
if [ ! -f "$HOME/.android/debug.keystore" ]; then
  echo "→ Создаём debug keystore..."
  mkdir -p "$HOME/.android"
  keytool -genkeypair -v \
    -keystore "$HOME/.android/debug.keystore" \
    -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

if [ "$BUILD_TYPE" = "release" ]; then
  OUTPUT="$OUTPUT_DIR/AshenRoots.apk"
  echo "→ Экспорт release APK → $OUTPUT"
  "$GODOT_BIN" --headless --verbose --export-release "Android" "$OUTPUT" 2>&1 | tail -n 100
else
  OUTPUT="$OUTPUT_DIR/AshenRoots-debug.apk"
  echo "→ Экспорт debug APK → $OUTPUT"
  "$GODOT_BIN" --headless --verbose --export-debug "Android" "$OUTPUT" 2>&1 | tail -n 100
fi

ls -lh "$OUTPUT_DIR"/*.apk 2>&1 || true

# Проверка подписи
if command -v apksigner &>/dev/null; then
  echo "→ Проверка подписи..."
  apksigner verify --verbose "$OUTPUT" 2>&1 | head -n 20 || echo "APK не подписан, подпишите вручную"
else
  # Попробовать найти apksigner в ANDROID_HOME
  if [ -n "${ANDROID_HOME:-}" ]; then
    APKSigner=$(find "$ANDROID_HOME"/build-tools -name apksigner -type f 2>/dev/null | head -n1 || true)
    if [ -n "$APKSigner" ]; then
      "$APKSigner" verify --verbose "$OUTPUT" 2>&1 | head -n 20 || true
    fi
  fi
fi

echo ""
echo "✓ Готово: $OUTPUT"
echo "  Установите на устройство: adb install -r \"$OUTPUT\""
