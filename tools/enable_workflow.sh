#!/usr/bin/env bash
set -euo pipefail
# Активирует GitHub Actions workflow для сборки APK
# Запустите локально (где у вас есть права на workflows) или вручную скопируйте файл

SRC="docs/workflows/android.yml"
DST=".github/workflows/android.yml"

if [ ! -f "$SRC" ]; then
  echo "Не найден $SRC"
  exit 1
fi

mkdir -p .github/workflows
cp "$SRC" "$DST"
echo "✓ Скопирован $SRC → $DST"
echo ""
git add "$DST"
git status --short
echo ""
echo "Теперь выполните:"
echo "  git commit -m 'ci: enable Android workflow'"
echo "  git push origin $(git branch --show-current)"
echo ""
echo "После пуша: Actions → Android APK → запустится сборка (5-8 минут)"
echo "Готовый APK появится в Artifacts и в Releases"
