# Ashen Roots Prototype

[![Android APK](https://github.com/cs1nm/ashenroot/actions/workflows/android.yml/badge.svg)](https://github.com/cs1nm/ashenroot/actions/workflows/android.yml)
[![Release](https://img.shields.io/github/v/release/cs1nm/ashenroot?label=APK)](https://github.com/cs1nm/ashenroot/releases)

Open this folder in Godot 4.7 or newer and run `Main.tscn`.

## 📱 Скачать APK (Android)

**Последний релиз:** https://github.com/cs1nm/ashenroot/releases — скачай `AshenRoots.apk`

- Автоматическая сборка каждый пуш в `main` через GitHub Actions (Godot 4.7.1 + Android SDK)
- Артефакты: `AshenRoots.apk` (release) и `AshenRoots-debug.apk` — ищи в **Actions → Android APK → Artifacts** или в **Releases**
- Установка: скачай APK → разреши установку из неизвестных источников → установи → играй (джойстик слева, прыжок/атака справа)
- Локальная сборка: `./tools/build_android.sh debug` или `release` (требует Godot + export templates)

Подробнее: [`docs/ANDROID_BUILD.md`](docs/ANDROID_BUILD.md)

## Controls

- `A` / `D` or arrow keys: move.
- `Space` / `W`: jump.
- Hold `Space` / `W` while in water or lava: swim upward.
- `1`-`5`: select hotbar slot.
- `Tab` / `I`: open or close inventory.
- Mouse wheel: zoom camera in/out slightly.
- Left mouse button: mine target block.
- Right mouse button: place the selected mined block.
- `Z` / `X`: select crafting recipe while inventory is open.
- `C`: craft the selected recipe while inventory is open.
- `E`: equip/use the selected hotbar item while inventory is open.
- `F`: attack with the equipped weapon.
- Right mouse button on a stone altar in caves: awaken Stone Beast.
- Drag an inventory stack onto a hotbar slot to assign that item to the selected bottom hotbar.
- `R`: generate a new random world.
- `F5`: save the world.
- `F9`: load the saved world.
- `F1` or backtick: open the debug console. Use `perception on` to inspect AI vision, noise, memory targets, and states.

## Interface

- **Pixel HUD (2026):** full pixel-art UI — 9-slice obsidian frames, Press Start 2P everywhere, ember accents. Health is now **10 hearts** (full/half/empty) in a top-left vitals plate with segmented DEF / AIR / TEMP bars, status-effect chips with pixel icons, class + seed row. Minimap is a circular **lens** with a riveted frame, hotbar slots are pixel bevels with an ember-selected slot, loot feed rows are dark chips, and the boss bar is a wide pixel frame with a skull icon and segmented HP.
- **«Ashen Archive» theme (2026):** obsidian-dark panels with ember-orange accents and gold-of-memory details; pixel font for titles and numbers.
- Normal gameplay HUD: health ring with radial ember fill, armor chip, status-effect chips with timers, day/night icon and biome label at top center, circular minimap lens, floating hotbar with raised selected slot, and an icon loot feed.
- Inventory screen (`Tab` / `I`): "Survivor's Kit" layout — character card with hero sprite and equipment slots on the left, 30-slot supply grid in the center, and a recipe forge on the right with station filters (ALL / HANDS / WORKBENCH / FURNACE / ANVIL).
- Left-drag an inventory stack to move it; right-drag a stack to split off half.
- Release a dragged stack outside the inventory/crafting UI to throw it into the world as animated loot.
- Equipment slots show weapon, armor, and accessory separately, plus a stat panel (class, damage, defense, cold/heat protection).
- Crafting recipes are shown as compact icons with ready/locked borders and material tooltips; the forge filters recipes by the station you are standing next to.
- World map (`M`) shows the explored world with a fog-of-war halo around the player and a biome legend.
- Field journal (`J`, "CHRONICLES") has tabs for recipes, bestiary (with creature sprite previews), materials, and alchemy experiments.
- Bottom panel: hotbar. The ember glow and arrow show the active slot.
- Top-right: circular minimap lens.

## What Works Now

- Seed-based 2D world generation.
- Larger seed-based world generation.
- Hills, larger cave networks, trees, roots, ash pockets, ores, underground rooms, shrines, ruins, and loot chests.
- The world is split into 7-9 wide surface biome bands (frost wasteland, marsh, forest, ash desert, ash ruins) with noisy weaving borders; the spawn band is always forest and every biome type appears in each world.
- Surface biomes own their whole topsoil layer, not just the top block: ash desert rests on deep ash sand, frost wasteland on frozen dirt, marsh on mud (with surface ponds and moss rims), ash ruins on rubble. Ash sand can be sifted by hand back into ash.
- Dead bleached trunks dot the ash desert; biome palettes tint the upper crust when digging.
- Biomes now shape the world: forest, ordinary caves, mushroom halls, ash cities, sunken ruins, lava roots, and the glass abyss.
- Each biome has its own blocks, enemy picks, material drops, chest loot, backdrop color/silhouettes, entry sound motif, rare item, and small mining-triggered mini-event.
- Sunken ruins contain water pools; lava-root chambers contain lava lakes.
- Water slows movement and drains air while the player's head is submerged. At zero air, drowning damage begins.
- Lava heavily slows movement, deals repeated fire damage, and applies burning.
- The HUD displays remaining air while swimming.
- Diving Charm grants underwater breathing. Ember Ward greatly reduces lava damage.
- Ancient chests open as a container on the right side in place of the mini-map while nearby.
- Copper, iron, ash, ruins, and stations have brighter pixel markings so they are easier to spot.
- Project-local pixel-art PNG textures for world tiles and item icons.
- Larger organic trees with branches and clustered crowns, including rare old trees with wider trunks and multi-direction branches.
- Humanoid placeholder player sprite drawn in pixel-art style with idle, walking, jumping, and falling animation poses.
- Basic player movement and collision.
- Hotbar inventory with placeable items and starter tools.
- Mining and placing blocks within a short range.
- Tree felling: mine the bottom trunk block to break the connected tree and collect its wood/leaves.
- Tool strength, mining speed, and block hardness.
- Crafting stations: workbench, furnace, and anvil.
- Ore smelting into copper and iron bars.
- Weapon, armor, accessory, tool, and class starter recipes.
- Rare materials from roots, ash, and ruin blocks.
- Day/night cycle: day lasts 25 minutes, night lasts 7 minutes 30 seconds.
- First combat loop with surface, cave, and night enemies.
- Damage types: physical, fire, poison, and arcane.
- Status effects: poison, burning, and slow. Active effects are shown near HP.
- New early enemies by zone: cave worm, bat, ash phantom, mushroom beetle, root crawler, and ruin drone.
- Biome enemies include mosslings, spore bats, ash sentinels, drowned guards, ember rootlings, and glass wraiths.
- Class weapon attacks: melee swings, spear reach, bows, hand cannon, spark staff, root spirit, acid flask, and engineer turret fire.
- Animated world loot for mined blocks, felled trees, enemy drops, and rare materials. Items bounce, bob, magnetize toward the player, and show stack counts.
- Loot pickup feed shows recent pickups such as `+ Wood x12` on the lower-right HUD.
- Floating damage numbers and small hit particles.
- Visible attack animations: sword/sickle slash, spear thrust, bow draw, staff flare, cannon recoil, flask throw, and turret muzzle flash.
- Boss health bar appears at the top of the screen while `Heartwood Core` or `Stone Beast` is alive.
- Stone Beast can awaken after enough stone is mined or by activating a stone altar in a cave.
- Defeating Stone Beast unlocks Stoneblood ore veins, Stoneblood recipes, and opens the first path toward the mushroom biome.
- Simple generated sounds for hits, mining, pickups, player damage, shots, and boss arrival.
- Spawn balance now considers day/night, cave depth, and nearby ruins.
- Enemies use perception states instead of knowing the player position automatically: light-sensitive line of sight, per-creature hearing, noise investigation, last-known-position search, return-to-home behavior, and nearby ally alerts.
- Footsteps, jumping and landing, mining, melee swings, shots, turret fire, and explosions create noise with different radii.
- Enemy drops for early progression, plus a first mini-boss after enough enemies are defeated.
- Player health and fall damage.
- Save/load for the current world, inventory, health, and position.
- Chunked visible-world drawing.
- Simple depth/player lighting.
- Mini-map.
- HUD showing seed, target tile, selected item, health, hotbar, and class foundation.
- Class definitions in `data/classes.json`.

## Next Good Step

Turn biome materials into a stronger progression ladder: armor sets, class weapons, one mini-boss per biome, and real looping music tracks.

## Art Pipeline

- Tile textures live in `assets/textures/tiles`.
- Item icons live in `assets/textures/items`.
- Regenerate the current placeholder pixel-art pack with:

```bash
node tools/generate_pixel_assets.js
```

These are original generated placeholders meant to be replaced or polished over time, but the game now uses real PNG assets instead of debug rectangles. The current generator avoids hard tile outlines and adds organic noise, cracks, grass variation, ore veins, rough station details, transparent station silhouettes, chest/altar silhouettes, moss, fungal caps, ash brickwork, sunken stone markings, lava-root veins, glass shards, crystals, and exposed-edge chips so the world does not read as a flat square grid. Physics is still grid-based for now; the non-square look is visual.

## Early Progression Test Path

1. Mine wood, dirt, stone, and copper ore.
2. Craft a workbench by selecting the recipe with `Z`/`X`, then pressing `C`.
3. Put the workbench from the hotbar with right mouse button.
4. Stand near it and craft a furnace.
5. Place the furnace, stand near it, and smelt copper bars.
6. Craft an anvil from copper bars and stone.
7. Place the anvil, then craft copper tools, armor, and class weapons.
8. Explore caves and ruins for stone altars, chests, and new enemy drops.
9. Mine about 140 stone blocks or activate a stone altar to awaken Stone Beast.
10. Defeat Stone Beast, then mine Stoneblood ore and craft the Stoneblood pickaxe or Stonebreaker Blade.
11. Push deeper to find mushroom halls, ash cities, sunken ruins, lava roots, and the glass abyss. Watch the HUD biome name and listen for the entry sound cue.
12. Use Drowned Pearls and Sunken Stone to craft the Diving Charm.
13. Use Ember Roots, Night Embers, and Stoneblood Bars to craft the Ember Ward before exploring lava lakes.
