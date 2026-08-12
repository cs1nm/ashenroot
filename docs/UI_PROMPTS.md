# Промты для ИИ-генерации интерфейса Shadowgrove (UI v2)

> Стиль зафиксирован в docs/UI_DESIGN.md. Используй эти промты в любом
> генераторе (Midjourney, DALL·E, Stable Diffusion, Ideogram, Leonardo...).
> Лучше всего работают английские версии. Добавляй "--ar 16:9" / "16:9"
> для широких экранов, "9:16" для мобильных.

---

## 1. ОСНОВНОЙ ПРОМТ — концепт всего HUD (главный экран игры)

### EN (рекомендуется)
```
Pixel art game UI, top-down 2D sandbox adventure, 16-bit style, crisp
pixel-perfect edges, no anti-aliasing, no gradients, sharp 1px outlines.

Dark fantasy palette: deep charcoal background #0b0e13, dark navy panels
#141a23 and #1a2230, slate borders #3a4a5e with lighter highlights #5a7090,
warm amber accent #ffb84d, gold text #f5d78a, off-white body text #d8dee4,
muted gray secondary text #8a94a3, red health #e05252, blue mana #5aa9e8,
green success #82d49a.

Layout for a 2D adventure game screen:
- Top-left: pixel heart row (10 hearts, red full / half / dark empty),
  small armor DEF chip, air/bubble and temperature/thermometer icons,
  tiny status icons, class+seed caption.
- Top-center: small pixel day/time label and toast message banner with
  amber accent frame.
- Top-right: circular minimap in a brass/amber ring with N/E/S/W compass
  ticks, glowing player dot in the center.
- Bottom-center: hotbar of 5 square pixel slots (amber selection corners
  on the active slot), item icons inside.
- Bottom-right: two round pixel action buttons — JUMP (up arrow) and ATK
  (sword) — translucent dark circles with amber icons.
- Thin amber divider lines between sections.

Retro videogame UI mockup, clean composition, readable, cohesive, no
screenshot artifacts, no watermark, vector-like crisp pixel art.
```

### RU
```
Пиксель-арт интерфейс игры, 2D песочница-приключение, стиль 16-бит,
чёткие пиксельные края, без сглаживания и градиентов, резкие контуры 1px.

Тёмная фэнтези-палитра: глубокий угольный фон #0b0e13, тёмно-синие панели
#141a23 и #1a2230, шиферные границы #3a4a5e со светлыми бликами #5a7090,
тёплый янтарный акцент #ffb84d, золотой текст #f5d78a, основной текст
#d8dee4, приглушённый серый #8a94a3, красное здоровье #e05252, синяя мана
#5aa9e8, зелёный успех #82d49a.

Экран 2D приключенческой игры:
- Слева сверху: ряд пиксельных сердец (10 шт., красные полные / половинки /
  тёмные пустые), чип защиты DEF, иконки воздуха и термометра, мелкие
  иконки статусов, подпись класса и сида.
- Сверху по центру: пиксельная метка времени дня/ночи и баннер-тост в рамке
  с янтарным акцентом.
- Справа сверху: круглая миникарта в латунно-янтарном кольце с компасными
  насечками N/E/S/W, светящаяся точка игрока в центре.
- Снизу по центру: хотбар из 5 квадратных пиксельных слотов (активный слот
  с янтарными уголками), иконки предметов внутри.
- Справа снизу: две круглые пиксельные кнопки — JUMP (стрелка вверх) и ATK
  (меч) — полупрозрачные тёмные круги с янтарными иконками.
- Тонкие янтарные линии-разделители между секциями.

Ретро-игровой UI-макет, чистая композиция, читабельно, единый стиль.
```

---

## 2. ПРОМТ — панель инвентаря и крафта

### EN
```
Pixel art inventory UI for a 2D sandbox game, 16-bit pixel style, dark
fantasy palette (#0b0e13 background, #141a23 panels, #3a4a5e borders,
amber #ffb84d accents, gold #f5d78a titles).

Centered three-column layout:
- Left: character card — pixel portrait of a small adventurer, three
  equipment slots (weapon / armor / charm) as square pixel cells with
  amber highlight, stats text (class, damage, defense).
- Center: backpack grid 6x4 of square pixel slots with item icons, amber
  selection corners on one slot, title "SUPPLIES".
- Right: recipe forge panel — grid of craftable item slots, cost lines,
  a big CRAFT button (amber tab button), station filter tabs.

Pixel-perfect, 1px outlines, no gradients, readable, cohesive retro UI.
```

---

## 3. ПРОМТ — экран выбора пути (NPC диалог)

### EN
```
Pixel art dialogue UI, 16-bit style, dark fantasy palette, centered panel
with brass/amber pixel frame and pixel-rounded corners, amber accent line
on top. Inside: title "THE SKY WANDERER" in gold pixel font, a hooded
wanderer pixel portrait with glowing blue eyes, speech text in off-white,
and two large amber-bordered pixel buttons side by side: one with a rocket
icon "SCIENCE — STARS & MACHINES", the other with a glowing magic orb icon
"MAGIC — MANA & REALMS". A small caption "This choice is permanent".
Crisp 1px outlines, no gradients, retro RPG dialogue box.
```

---

## 4. ПРОМТ — босс-бар (экран боя)

### EN
```
Pixel art boss health bar UI, 16-bit retro style, dark palette. A wide
horizontal bar (20:1 ratio) with dark red background #3a1e22, slate border,
pixel skull icon on the left, gold boss name text above the bar, and a
bright red fill from left to right. Amber corner accents. Crisp 1px
outlines, no gradients, readable at a glance, retro game UI.
```

---

## 5. ПРОМТ — мобильные кнопки (геймпад на экране)

### EN
```
Pixel art mobile touch controls for a 2D game, 16-bit style, translucent
dark circles with amber pixel icons, crisp 1px amber outlines, subtle 2px
pixel shadow. Left: large movement joystick (dark base circle with lighter
knob). Right: two round buttons — JUMP (up arrow) and ATK (sword) — plus a
smaller GRAPPLE button with a hook icon. Rounded pixel edges, no gradients,
retro gamepad feel, cohesive dark fantasy palette.
```

---

## Советы
- Всегда добавляй: `pixel art, 16-bit, crisp 1px outlines, no gradients, no anti-aliasing, dark fantasy palette, retro game UI`.
- Для скриншотов конкретных экранов бери соответствующий раздел выше.
- Если генератор не умеет цвета hex — просто скажи «amber accent, dark navy panels, charcoal background».
- Для проверки «читаемости» проси: `readable, clean composition, cohesive UI`.
- Получившийся результат клади в `assets/ui/` (для 9-slice — режь по сетке, см. UI_DESIGN.md) или покажи мне — встрою в игру.
