# Android APK — сборка Ashen Roots

## Быстрый старт (скачать готовый APK)

1. Открой **Releases**: https://github.com/cs1nm/ashenroot/releases
2. Скачай `AshenRoots.apk` из последнего релиза `v0.1.0-build*` (или из Artifacts последнего workflow run)
3. На телефоне: **Настройки → Безопасность → Неизвестные источники → Разрешить**
4. Установи APK, запусти — управление тачем уже встроено (virtual joystick)

> Также APK доступен в **Actions → Android APK → последний run → Artifacts → AshenRoots-APK**

## Как собирается APK

### Автоматически (GitHub Actions)

Файл: `.github/workflows/android.yml`

- Триггер: `push` в `main` / `arena/*`, `pull_request`, `workflow_dispatch`
- Runner: `ubuntu-latest`
- Шаги:
  1. `actions/checkout@v4`
  2. `actions/setup-java@v4` (Java 17 Temurin)
  3. `android-actions/setup-android@v3` (Android SDK)
  4. `chickensoft-games/setup-godot@v2` — Godot **4.7.1-stable** + export templates
  5. Создаёт `~/.android/debug.keystore` (keytool) + release keystore
  6. `godot --headless --import` — импорт ресурсов
  7. `godot --headless --export-debug "Android" build/android/AshenRoots-debug.apk`
  8. `godot --headless --export-release "Android" build/android/AshenRoots.apk`
  9. Подпись через `apksigner` (если нужно) + `SHA256SUMS.txt`
  10. `actions/upload-artifact@v4` — артефакт на 30 дней
  11. `softprops/action-gh-release@v2` — публикует в **Releases** как `v0.1.0-build<run_number>` (только для веток `main`/`arena/*`)

### Локально

```bash
# Требования: Godot 4.7+ (с Android export templates), Java 17, Android SDK (для подписи)
./tools/build_android.sh debug    # → build/android/AshenRoots-debug.apk
./tools/build_android.sh release  # → build/android/AshenRoots.apk

# Установка на устройство
adb install -r build/android/AshenRoots.apk
# или закинь APK на телефон и установи вручную
```

Скрипт `tools/build_android.sh`:
- Проверяет `godot` в PATH (или `GODOT_BIN` env)
- Делает `godot --headless --import`
- Создаёт `~/.android/debug.keystore` если нет
- Экспортирует через `godot --headless --export-debug/release "Android"`

## Конфигурация Godot

- `export_presets.cfg` — пресет `Android`, `platform="Android"`, `export_path="build/android/AshenRoots.apk"`
  - Архитектуры: `armeabi-v7a=true`, `arm64-v8a=true`, `x86=false`
  - `package/unique_name="com.ashenroots.game"`, `version/name="0.1.0"`, `version/code=1`
  - `package/signed=true` — использует `~/.android/debug.keystore` в CI (создаётся автоматически)
  - Без Gradle (`gradle_build/use_gradle_build=false`) — экспорт напрямую через шаблоны, без необходимости локального SDK

Если нужен Gradle-сбор (AAB для Play Store):
```ini
gradle_build/use_gradle_build=true
gradle_build/export_format=1
```

## Подпись

- **Debug**: `~/.android/debug.keystore` (`android`/`androiddebugkey`/`android`) — генерируется в CI через `keytool`
- **Release**: `$HOME/release.keystore` (`ashenroot`/`ashenroot`) — self-signed, для Releases достаточно
- Проверка: `apksigner verify --verbose build/android/AshenRoots.apk`

Для Play Store заведи свой keystore и добавь как GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASS`, `KEY_ALIAS`, `KEY_PASS`), затем используй `r0adkll/sign-android-release`.

## Troubleshooting

- **Godot не найден**: установи Godot 4.7.1 с https://godotengine.org/download и добавь в PATH, или укажи `GODOT_BIN=/path/to/godot`
- **Export templates missing**: `chickensoft-games/setup-godot` ставит их автоматически; локально — **Editor → Manage Export Templates → Download**
- **APK не устанавливается**: проверь `adb logcat`, убедись что `minSdk 21` соответствует устройству (Android 5.0+)
- **Чёрный экран**: проверь `renderer/rendering_method="gl_compatibility"` (уже в `project.godot`) — подходит для большинства устройств

## История версий APK

- `v0.1.0` — первый релиз, включает virtual joystick, теплоту/кислород, биомы, боссов, сохранение
