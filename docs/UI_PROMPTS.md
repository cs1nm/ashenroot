# Промты для ИИ-генерации интерфейса Shadowgrove (UI v3)

> КОРОТКИЙ ПРОМТ ДЛЯ АБСОЛЮТНО НОВОГО UI (рекомендуется):

```
Design a brand-new video game UI for a 2D pixel-art sandbox adventure game.
High-quality 16-bit pixel art style, crisp 1px outlines, no anti-aliasing,
no gradients. Light warm Terraria-like palette: wooden brown panels, cream
parchment backgrounds, dark brown text, gold and amber accents, red health,
blue mana. Layout: player health/hearts top-left, minimap top-right,
item hotbar bottom-center, round jump and attack buttons bottom-right,
crafting and inventory panels centered. Clean, readable, cohesive,
premium feel. No text placeholders, no watermark, no UI mockup bars.
```

---

## Основной промт (подробный, HUD)

### EN
```
Pixel art game UI for a 2D sandbox adventure, high-quality 16-bit pixel
art, crisp 1px outlines, no anti-aliasing, no gradients, light warm
Terraria-style palette: wooden brown panels, cream parchment backgrounds,
dark brown text, gold + amber accents, red health, blue mana.

HUD layout:
- top-left: row of pixel hearts (red full / half / dark empty), small
  armor DEF chip, air and temperature icons, status icons.
- top-center: small day/night time label and a toast banner with amber frame.
- top-right: circular minimap in a brass ring with compass ticks, player dot.
- bottom-center: hotbar of square pixel slots, amber corners on the active
  slot, item icons inside.
- bottom-right: two round pixel buttons — JUMP (arrow) and ATK (sword),
  translucent dark circles with gold icons.
Clean, readable, cohesive, premium, no watermark.
```

### RU
```
Пиксель-арт интерфейс для 2D песочницы-приключения, качественный 16-бит
пиксель-арт, чёткие контуры 1px, без сглаживания и градиентов, светлая
тёплая палитра в стиле Terraria: деревянные коричневые панели, кремовые
пергаментные фоны, тёмно-коричневый текст, золотые и янтарные акценты,
красное здоровье, синяя мана.

HUD:
- сверху слева: ряд пиксельных сердец (красные полные/половинки/тёмные
  пустые), чип защиты DEF, иконки воздуха и температуры, иконки статусов.
- сверху по центру: метка времени дня/ночи и баннер-тост с янтарной рамкой.
- сверху справа: круглая миникарта в латунном кольце с компасными
  насечками, точка игрока.
- снизу по центру: хотбар из квадратных пиксельных слотов, активный слот
  с янтарными уголками, иконки предметов.
- снизу справа: две круглые кнопки — JUMP (стрелка) и ATK (меч),
  полупрозрачные тёмные круги с золотыми иконками.
Чисто, читабельно, единый стиль, премиально, без водяных знаков.
```

---

## 2. Промт — панель инвентаря и крафта
```
Pixel art inventory UI, 2D sandbox, 16-bit, light Terraria-style palette
(wooden panels, cream parchment, dark text, amber accents). Centered
3-column: character card with equipment slots left, backpack grid center,
recipe forge with craft button right. Pixel-perfect 1px outlines,
readable, cohesive, no watermark.
```

## 3. Промт — экран выбора пути (NPC диалог)
```
Pixel art dialogue UI, 16-bit, light Terraria-style, centered wooden panel
with gold frame. Title "THE SKY WANDERER", hooded wanderer portrait with
glowing eyes, two big buttons: rocket icon "SCIENCE" and magic orb icon
"MAGIC". Caption "This choice is permanent". Crisp 1px outlines, cohesive.
```

## 4. Промт — босс-бар
```
Pixel art boss health bar, 16-bit, wide horizontal bar, dark red background,
gold skull icon left, gold boss name above, bright red fill, amber accents.
Crisp 1px outlines, readable at a glance, no watermark.
```

## 5. Промт — мобильные кнопки
```
Pixel art mobile touch controls, 16-bit, light Terraria-style: big
movement joystick left (wooden base), right: round JUMP (arrow) and ATK
(sword) buttons + smaller GRAPPLE (hook) button, translucent dark circles
with gold icons, crisp 1px gold outlines. Cohesive, no watermark.
```

---

## Советы
- Всегда добавляй: `pixel art, 16-bit, crisp 1px outlines, no anti-aliasing,
  no gradients, light Terraria-style palette, wooden panels, parchment,
  amber accents, no watermark`.
- AI не умеет рисовать текст — проси «no text placeholders» и добавляй
  подписи вручную в игре.
- Картинки-мокапы используй как референс, но финальные ассеты всё равно
  собираем в коде (9-slice) — см. docs/UI_DESIGN.md.
