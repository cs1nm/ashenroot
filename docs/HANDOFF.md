# Shadowgrove — Инструктаж для нового чата (HANDOFF)

Прочитай это ПЕРВЫМ, затем `docs/GAME_PLAN.md` (сюжет/дизайн),
затем `docs/UI_DESIGN.md` + `docs/UI_PROMPTS.md` (интерфейс).

## Операционка (как делать APK и управлять репо)
- Репозиторий: `https://github.com/cs1nm/ashenroot` (игра Shadowgrove, Godot 4.7.1, Android).
- Токен для пуша (без workflow-скоупа!): спроси у игрока в чате.
- Пуш: `git remote add origin https://x-access-token:ТОКЕН@github.com/cs1nm/ashenroot.git`
- Git-идентичность: `git config user.name "arena-ai-coding-agent[bot]"` /
  `git config user.email "arena-ai-coding-agent[bot]@users.noreply.github.com"`
- ПЕРЕД коммитом: `git checkout -- '*.import' 2>/dev/null` и
  `git checkout -- build/android tools/build_android.sh tools/enable_workflow.sh`
  (эти файлы пачкаются локальными запусками; .import НЕ коммитим).
- **НЕ трогай `.github/workflows/android.yml`** — токен без workflow-скоупа,
  пуш будет отклонён.
- После пуша в main GitHub Actions сам соберёт APK и создаст релиз
  `v0.1.0-buildNN` (~4 мин). Артефакты: `AshenRoots.apk` + `AshenRoots-debug.apk`.
  Ссылка: `https://github.com/cs1nm/ashenroot/releases` (последний тег).
- Игрок качает APK на Android, тестит, шлёт скриншоты/отзыв. Отвечай по-русски, неформально.

## Тестирование
- Godot в `/tmp` стирается — перекачивай:
  `https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip`
- Проверка компиляции: `Godot --headless --path . --quit-after 120`.
- Скриншоты через Xvfb: `sudo apt-get install -y xvfb`, `sudo Xvfb :99 ...`, потом Godot с DISPLAY=:99.
  Xvfb капризный — предпочитай headless-проверки.
- После удаления `.godot` пересобирай: `Godot --headless --path . --import`
  (иначе сломаются class_name LiquidSim/RendererManager).

## Ключевые факты кода
- `scripts/main.gd` (~13 тыс. строк) — вся логика + UI.
- `scripts/game_data.gd` — константы (TILE_SIZE=16, WORLD 1280×190, скорости).
- Мир/сейвы: `user://worlds/world_<idx>.json`; UI layout: `user://ui_layout.json`.
- Новые тайлы добавлять ТОЛЬКО в конец enum Tile (иначе ломаются старые сейвы),
  синхронно обновлять словари: tile_names, tile_colors, solid_tiles,
  tile_hardness, tile_required_power, tile_to_item, item_to_tile, item_names,
  tile_texture_paths.
- Мобильное управление: левый стик, JUMP/ATK/GRAPPLE справа, тап по миру.
- Сюжет: гл. I (Storm Herald→Wind Shard), II (Depth Warden→Earth Shard),
  III (Небесные острова: джетпак/крылья, Sky Herald, Левиафан→чешуя+Sky Shard,
  NPC-Странник с выбором НАУКА/МАГИЯ). Главы IV–VII запланированы, но ПОСТАВЛЕНЫ НА ПАУЗУ.
- Сейчас приоритет: ПОЛИРОВКА (текстуры/UI/анимации/баги/баланс), контент глав IV+ не делать.

## Текущая ситуация по UI (важно!)
- Игрок сказал: интерфейс «ужасный», прошлые попытки были просто перекраской панелей.
- Нужен ПО-НАСТОЯЩЕМУ новый интерфейс (дизайн/текстуры/цвета/расположение).
- У агента НЕТ зрения — нельзя оценить красоту по скриншоту. Поэтому:
  - либо игрок даёт чёткое словесное ТЗ/референсы, и агент перестраивает
    компоновку и компоненты структурно в коде;
  - либо игрок генерирует ассеты по `docs/UI_PROMPTS.md` и кидает сюда,
    агент встраивает их в игру (9-slice и т.п.).
- Папка загрузок игрока: `/home/user/uploads/` (референсы, скриншоты).
