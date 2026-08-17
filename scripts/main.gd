extends Node2D

const GameData = preload("res://scripts/game_data.gd")

const TILE_SIZE := GameData.TILE_SIZE
const WORLD_WIDTH := GameData.WORLD_WIDTH
const WORLD_HEIGHT := GameData.WORLD_HEIGHT
const VIEW_PADDING := GameData.VIEW_PADDING
const GRAVITY := GameData.GRAVITY
const MOVE_SPEED := GameData.MOVE_SPEED
const JUMP_SPEED := GameData.JUMP_SPEED
const PLAYER_SIZE := GameData.PLAYER_SIZE
const AUTO_STEP_HEIGHT := GameData.AUTO_STEP_HEIGHT
const INTERACT_RANGE_TILES := GameData.INTERACT_RANGE_TILES
const SAVE_PATH := GameData.SAVE_PATH
const WORLDS_DIR := GameData.WORLDS_DIR
const WORLDS_INDEX := GameData.WORLDS_INDEX
const MAX_HEALTH := GameData.MAX_HEALTH
const FALL_DAMAGE_SPEED := GameData.FALL_DAMAGE_SPEED
const CHUNK_SIZE := GameData.CHUNK_SIZE
const MINIMAP_WIDTH := GameData.MINIMAP_WIDTH
const MINIMAP_HEIGHT := GameData.MINIMAP_HEIGHT
const FULL_MAP_WIDTH := GameData.FULL_MAP_WIDTH
const FULL_MAP_HEIGHT := GameData.FULL_MAP_HEIGHT
const HOTBAR_SIZE := GameData.HOTBAR_SIZE
const INVENTORY_GRID_SIZE := GameData.INVENTORY_GRID_SIZE
const VIRTUAL_JOYSTICK_SCRIPT := preload("res://scripts/virtual_joystick.gd")
const ACTION_BUTTON_SCRIPT := preload("res://scripts/action_button.gd")
const NETWORK_SESSION_SCRIPT := preload("res://scripts/network_session.gd")
const SLOT_SIZE := GameData.SLOT_SIZE
const MIN_CAMERA_ZOOM := GameData.MIN_CAMERA_ZOOM
const MAX_CAMERA_ZOOM := GameData.MAX_CAMERA_ZOOM
const DAY_DURATION := GameData.DAY_DURATION
const NIGHT_DURATION := GameData.NIGHT_DURATION
const FULL_DAY_DURATION := GameData.FULL_DAY_DURATION
const MAX_ENEMIES := GameData.MAX_ENEMIES
const ENEMY_SPAWN_INTERVAL := GameData.ENEMY_SPAWN_INTERVAL
const PLAYER_HURT_COOLDOWN := GameData.PLAYER_HURT_COOLDOWN
const USE_EXTERNAL_ENEMY_ANIMATION_STRIPS := GameData.USE_EXTERNAL_ENEMY_ANIMATION_STRIPS
const LOOT_PICKUP_RADIUS := GameData.LOOT_PICKUP_RADIUS
# Unified damage feedback: every creature flashes red when hit (runtime tint
# on top of whatever hurt frames the sprite pack provides).
const ENEMY_HIT_FLASH_COLOR := Color(1.0, 0.42, 0.36, 1.0)
const STRUCTURE_CHEST_CHANCE := 0.75
const CAVE_CHEST_CHANCE := 0.08
const CHEST_GROUND_SEARCH_RADIUS := 6
const CHEST_GROUND_SEARCH_DEPTH := 16
const TREE_BASE_HARDNESS_MULTIPLIER := 2.25
const MIN_TREE_SPACING := 10
# Automatic mobile budgets keep combat/weather readable without allowing
# short-lived visual effects or map refreshes to create frame spikes.
const MOBILE_MINIMAP_REFRESH_INTERVAL := 1.35
const MOBILE_MAX_HIT_PARTICLES := 72
const MOBILE_MAX_DAMAGE_NUMBERS := 28
const MOBILE_MAX_COMBAT_IMPACTS := 20
# Surface biome bands: wide procedural regions instead of narrow fixed strips.
const SURFACE_BAND_MIN_WIDTH := 120
const SURFACE_BAND_MAX_WIDTH := 210
# Columns on each side of a band seam where neighboring terrain interlocks.
const SURFACE_BORDER_BLEND := 24
# Maximum horizontal drift of that seam as it descends through the upper crust.
const SURFACE_BORDER_MEANDER := 11.0
const SURFACE_BAND_BIOMES: Array[String] = [
	"frost_wasteland", "marsh", "ash_desert", "ash_ruins", "forest"
]
const LOOT_MAGNET_RADIUS := GameData.LOOT_MAGNET_RADIUS
const LOOT_DESPAWN_TIME := GameData.LOOT_DESPAWN_TIME
const MAX_OXYGEN := GameData.MAX_OXYGEN
const NORMAL_BODY_TEMPERATURE := GameData.NORMAL_BODY_TEMPERATURE
const MIN_BODY_TEMPERATURE := GameData.MIN_BODY_TEMPERATURE
const MAX_BODY_TEMPERATURE := GameData.MAX_BODY_TEMPERATURE

const PERCEPTION_CALM := "calm"
const PERCEPTION_SUSPICIOUS := "suspicious"
const PERCEPTION_INVESTIGATE := "investigate"
const PERCEPTION_COMBAT := "combat"
const PERCEPTION_SEARCH := "search"
const PERCEPTION_RETURN := "return"
const NOISE_EVENT_LIFETIME := 0.85
const ENEMY_HEARING_RADIUS_MULTIPLIER := 3.0
const ENEMY_VISION_RANGE_MULTIPLIER := 2.0

# Global atmospheric weather. The host/dedicated server owns transitions and
# enemy-perception effects; clients render snapshots and apply deterministic
# local exposure effects to their own movement and body temperature.
const WEATHER_CLEAR := "clear"
const WEATHER_RAIN := "rain"
const WEATHER_STORM := "storm"
const WEATHER_BLIZZARD := "blizzard"
const WEATHER_ASHFALL := "ashfall"
const WEATHER_FOG := "fog"
const WEATHER_TYPES: Array[String] = [
	WEATHER_RAIN, WEATHER_STORM, WEATHER_BLIZZARD, WEATHER_ASHFALL, WEATHER_FOG
]
const WEATHER_DEPTH_FADE_START := 6
const WEATHER_DEPTH_SILENT := 20
const WEATHER_LIGHTNING_MIN_INTERVAL := 3.4
const WEATHER_LIGHTNING_MAX_INTERVAL := 9.0

enum Tile {
	AIR,
	GRASS,
	SNOW_BLOCK,
	DIRT,
	STONE,
	COPPER,
	IRON,
	ASH,
	ROOT,
	WOOD,
	LEAVES,
	RUIN,
	WORKBENCH,
	FURNACE,
	ANVIL,
	TURRET,
	HEART,
	CHEST,
	STONE_ALTAR,
	STONEBLOOD,
	MOSS,
	MUSHROOM_SOIL,
	GLOW_MUSHROOM,
	ASH_BRICK,
	SUNKEN_STONE,
	LAVA_ROOT,
	GLASS_STONE,
	ABYSS_CRYSTAL,
	WATER,
	LAVA,
	WATER_PLANT,
	BUBBLE_VENT,
	DRAIN_VALVE,
	SAPLING,
	TORCH,
	# Surface biome topsoil blocks. Appended after the original tiles so ids in
	# existing save files keep their meaning.
	ASH_SAND,
	FROZEN_DIRT,
	MUD,
	RUBBLE,
	# Building tiles (appended so existing save ids keep their meaning).
	DOOR,
	PLATFORM,
	LADDER,
	BED,
	FENCE,
	WINDOW,
	TRAPDOOR,
	ROPE,
	LANTERN,
	TABLE,
	CHAIR,
	# Chapter II tiles
	DEPTH_ALTAR,
	DEPTH_STONE,
	# Chapter III sky tiles (appended so existing save ids keep their meaning).
	SKY_GRASS,
	CLOUDSTONE,
	SKY_CRYSTAL,
	SKY_OBELISK
}

var tile_names: Dictionary = {
	Tile.AIR: "Air",
	Tile.GRASS: "Grass",
	Tile.SNOW_BLOCK: "Snow Block",
	Tile.DIRT: "Dirt",
	Tile.STONE: "Stone",
	Tile.COPPER: "Copper",
	Tile.IRON: "Iron",
	Tile.ASH: "Ash",
	Tile.ROOT: "Root",
	Tile.WOOD: "Wood",
	Tile.LEAVES: "Leaves",
	Tile.RUIN: "Ruin Brick",
	Tile.WORKBENCH: "Workbench",
	Tile.FURNACE: "Furnace",
	Tile.ANVIL: "Anvil",
	Tile.TURRET: "Small Turret",
	Tile.HEART: "Heart of Settlement",
	Tile.CHEST: "Ancient Chest",
	Tile.STONE_ALTAR: "Stone Altar",
	Tile.STONEBLOOD: "Stoneblood Ore",
	Tile.MOSS: "Mossy Loam",
	Tile.MUSHROOM_SOIL: "Fungal Soil",
	Tile.GLOW_MUSHROOM: "Glow Mushroom",
	Tile.ASH_BRICK: "Ash City Brick",
	Tile.SUNKEN_STONE: "Sunken Stone",
	Tile.LAVA_ROOT: "Lava Root",
	Tile.GLASS_STONE: "Glass Stone",
	Tile.ABYSS_CRYSTAL: "Abyss Crystal",
	Tile.WATER: "Water",
	Tile.LAVA: "Lava",
	Tile.WATER_PLANT: "Water Plant",
	Tile.BUBBLE_VENT: "Bubble Vent",
	Tile.DRAIN_VALVE: "Drain Valve",
	Tile.SAPLING: "Sapling",
	Tile.TORCH: "Torch",
	Tile.ASH_SAND: "Ash Sand",
	Tile.FROZEN_DIRT: "Frozen Dirt",
	Tile.MUD: "Mud",
	Tile.RUBBLE: "Rubble",
	Tile.DOOR: "Door",
	Tile.PLATFORM: "Platform",
	Tile.LADDER: "Ladder",
	Tile.BED: "Bed",
	Tile.FENCE: "Fence",
	Tile.WINDOW: "Window",
	Tile.TRAPDOOR: "Trapdoor",
	Tile.ROPE: "Rope",
	Tile.LANTERN: "Lantern",
	Tile.TABLE: "Table",
	Tile.CHAIR: "Chair",
	Tile.DEPTH_ALTAR: "Depth Altar",
	Tile.DEPTH_STONE: "Depth Stone",
	Tile.SKY_GRASS: "Cloud Grass",
	Tile.CLOUDSTONE: "Cloudstone",
	Tile.SKY_CRYSTAL: "Sky Crystal",
	Tile.SKY_OBELISK: "Sky Obelisk"
}

var tile_colors: Dictionary = {
	Tile.GRASS: Color("4f9f5f"),
	Tile.SNOW_BLOCK: Color("b8deed"),
	Tile.DIRT: Color("7a4a2a"),
	Tile.STONE: Color("60646f"),
	Tile.COPPER: Color("b66d3f"),
	Tile.IRON: Color("b9b6a7"),
	Tile.ASH: Color("4b4a54"),
	Tile.ROOT: Color("8d6939"),
	Tile.WOOD: Color("9a6132"),
	Tile.LEAVES: Color("4a7b50"),
	Tile.RUIN: Color("746b83"),
	Tile.WORKBENCH: Color("a0703f"),
	Tile.FURNACE: Color("3d4650"),
	Tile.ANVIL: Color("485468"),
	Tile.TURRET: Color("748c9c"),
	Tile.HEART: Color("d45f7e"),
	Tile.CHEST: Color("b98746"),
	Tile.STONE_ALTAR: Color("7f7368"),
	Tile.STONEBLOOD: Color("6fb3a2"),
	Tile.MOSS: Color("426f47"),
	Tile.MUSHROOM_SOIL: Color("5f4d70"),
	Tile.GLOW_MUSHROOM: Color("6fd6b8"),
	Tile.ASH_BRICK: Color("5d5562"),
	Tile.SUNKEN_STONE: Color("3f6974"),
	Tile.LAVA_ROOT: Color("a04431"),
	Tile.GLASS_STONE: Color("8ccad6"),
	Tile.ABYSS_CRYSTAL: Color("b8f4ff"),
	Tile.WATER: Color("327d9b", 0.72),
	Tile.LAVA: Color("ff9d4d", 0.90),
	Tile.WATER_PLANT: Color("4aa88c"),
	Tile.BUBBLE_VENT: Color("6b8790"),
	Tile.DRAIN_VALVE: Color("7893a0"),
	Tile.SAPLING: Color("63a75e"),
	Tile.TORCH: Color("ffd36b"),
	Tile.ASH_SAND: Color("c9b591"),
	Tile.FROZEN_DIRT: Color("5d7083"),
	Tile.MUD: Color("4f3d2a"),
	Tile.RUBBLE: Color("77695c"),
	Tile.DOOR: Color("8a6a42"),
	Tile.PLATFORM: Color("8a6a42"),
	Tile.LADDER: Color("8a6a42"),
	Tile.BED: Color("a0524a"),
	Tile.FENCE: Color("8a6a42"),
	Tile.WINDOW: Color("78aad6"),
	Tile.TRAPDOOR: Color("8a6a42"),
	Tile.ROPE: Color("b4965a"),
	Tile.LANTERN: Color("ffbe5a"),
	Tile.TABLE: Color("8a6a42"),
	Tile.CHAIR: Color("8a6a42"),
	Tile.DEPTH_ALTAR: Color("7a5a8a"),
	Tile.DEPTH_STONE: Color("5a4a6a"),
	Tile.SKY_GRASS: Color("9fe8e0"),
	Tile.CLOUDSTONE: Color("d8e8f2"),
	Tile.SKY_CRYSTAL: Color("9fe6ff"),
	Tile.SKY_OBELISK: Color("bcd6ff")
}

var solid_tiles: Dictionary = {
	Tile.GRASS: true,
	Tile.SNOW_BLOCK: true,
	Tile.DIRT: true,
	Tile.STONE: true,
	Tile.COPPER: true,
	Tile.IRON: true,
	Tile.ASH: true,
	Tile.ROOT: true,
	Tile.WOOD: true,
	Tile.RUIN: true,
	Tile.WORKBENCH: true,
	Tile.FURNACE: true,
	Tile.ANVIL: true,
	Tile.TURRET: true,
	Tile.HEART: true,
	Tile.CHEST: true,
	Tile.STONE_ALTAR: true,
	Tile.STONEBLOOD: true,
	Tile.MOSS: true,
	Tile.MUSHROOM_SOIL: true,
	Tile.GLOW_MUSHROOM: true,
	Tile.ASH_BRICK: true,
	Tile.SUNKEN_STONE: true,
	Tile.LAVA_ROOT: true,
	Tile.GLASS_STONE: true,
	Tile.ABYSS_CRYSTAL: true,
	Tile.BUBBLE_VENT: true,
	Tile.DRAIN_VALVE: true,
	Tile.ASH_SAND: true,
	Tile.FROZEN_DIRT: true,
	Tile.MUD: true,
	Tile.RUBBLE: true,
	Tile.DOOR: true,
	Tile.BED: true,
	Tile.FENCE: true,
	Tile.WINDOW: true,
	Tile.TRAPDOOR: true,
	Tile.TABLE: true,
	Tile.CHAIR: true,
	Tile.DEPTH_ALTAR: true,
	Tile.DEPTH_STONE: true,
	Tile.SKY_GRASS: true,
	Tile.CLOUDSTONE: true,
	Tile.SKY_CRYSTAL: true,
	Tile.SKY_OBELISK: true
}

var tile_hardness: Dictionary = {
	Tile.GRASS: 0.28,
	Tile.SNOW_BLOCK: 0.34,
	Tile.DIRT: 0.24,
	Tile.STONE: 0.55,
	Tile.COPPER: 0.75,
	Tile.IRON: 0.95,
	Tile.ASH: 0.70,
	Tile.ROOT: 0.40,
	Tile.WOOD: 1.05,
	Tile.LEAVES: 0.22,
	Tile.RUIN: 0.85,
	Tile.WORKBENCH: 0.35,
	Tile.FURNACE: 0.65,
	Tile.ANVIL: 0.75,
	Tile.TURRET: 0.55,
	Tile.HEART: 1.20,
	Tile.CHEST: 0.65,
	Tile.STONE_ALTAR: 1.10,
	Tile.STONEBLOOD: 1.15,
	Tile.MOSS: 0.32,
	Tile.MUSHROOM_SOIL: 0.38,
	Tile.GLOW_MUSHROOM: 0.20,
	Tile.ASH_BRICK: 0.95,
	Tile.SUNKEN_STONE: 0.90,
	Tile.LAVA_ROOT: 0.70,
	Tile.GLASS_STONE: 1.05,
	Tile.ABYSS_CRYSTAL: 1.30,
	Tile.WATER_PLANT: 0.16,
	Tile.BUBBLE_VENT: 0.85,
	Tile.DRAIN_VALVE: 1.15,
	Tile.SAPLING: 0.12,
	Tile.TORCH: 0.10,
	Tile.ASH_SAND: 0.20,
	Tile.FROZEN_DIRT: 0.32,
	Tile.MUD: 0.26,
	Tile.RUBBLE: 0.48,
	Tile.DOOR: 0.5,
	Tile.PLATFORM: 0.3,
	Tile.LADDER: 0.3,
	Tile.BED: 0.5,
	Tile.FENCE: 0.35,
	Tile.WINDOW: 0.3,
	Tile.TRAPDOOR: 0.3,
	Tile.ROPE: 0.2,
	Tile.LANTERN: 0.15,
	Tile.TABLE: 0.4,
	Tile.CHAIR: 0.3,
	Tile.DEPTH_ALTAR: 1.2,
	Tile.DEPTH_STONE: 0.9,
	Tile.SKY_GRASS: 0.30,
	Tile.CLOUDSTONE: 0.45,
	Tile.SKY_CRYSTAL: 0.85,
	Tile.SKY_OBELISK: 1.20
}

var tile_required_power: Dictionary = {
	Tile.GRASS: 1,
	Tile.SNOW_BLOCK: 1,
	Tile.DIRT: 1,
	Tile.STONE: 1,
	Tile.COPPER: 1,
	Tile.IRON: 2,
	Tile.ASH: 2,
	Tile.ROOT: 1,
	Tile.WOOD: 1,
	Tile.LEAVES: 1,
	Tile.RUIN: 2,
	Tile.WORKBENCH: 1,
	Tile.FURNACE: 1,
	Tile.ANVIL: 2,
	Tile.TURRET: 2,
	Tile.HEART: 2,
	Tile.CHEST: 1,
	Tile.STONE_ALTAR: 2,
	Tile.STONEBLOOD: 3,
	Tile.MOSS: 1,
	Tile.MUSHROOM_SOIL: 1,
	Tile.GLOW_MUSHROOM: 1,
	Tile.ASH_BRICK: 2,
	Tile.SUNKEN_STONE: 2,
	Tile.LAVA_ROOT: 3,
	Tile.GLASS_STONE: 3,
	Tile.ABYSS_CRYSTAL: 4,
	Tile.WATER_PLANT: 1,
	Tile.BUBBLE_VENT: 2,
	Tile.DRAIN_VALVE: 2,
	Tile.SAPLING: 1,
	Tile.TORCH: 1,
	Tile.ASH_SAND: 1,
	Tile.FROZEN_DIRT: 1,
	Tile.MUD: 1,
	Tile.RUBBLE: 1,
	Tile.DOOR: 0,
	Tile.PLATFORM: 0,
	Tile.LADDER: 0,
	Tile.BED: 0,
	Tile.FENCE: 0,
	Tile.WINDOW: 0,
	Tile.TRAPDOOR: 0,
	Tile.ROPE: 0,
	Tile.LANTERN: 0,
	Tile.TABLE: 0,
	Tile.CHAIR: 0,
	Tile.SKY_GRASS: 1,
	Tile.CLOUDSTONE: 1,
	Tile.SKY_CRYSTAL: 2,
	Tile.SKY_OBELISK: 0
}

var tile_to_item: Dictionary = {
	Tile.GRASS: "dirt",
	Tile.SNOW_BLOCK: "snow_block",
	Tile.DIRT: "dirt",
	Tile.STONE: "stone",
	Tile.COPPER: "copper_ore",
	Tile.IRON: "iron_ore",
	Tile.ASH: "ash",
	Tile.ROOT: "root",
	Tile.WOOD: "wood",
	Tile.LEAVES: "leaf",
	Tile.RUIN: "ruin_brick",
	Tile.WORKBENCH: "workbench",
	Tile.FURNACE: "furnace",
	Tile.ANVIL: "anvil",
	Tile.TURRET: "small_turret",
	Tile.HEART: "settlement_heart",
	Tile.CHEST: "ancient_chest",
	Tile.STONE_ALTAR: "stone_altar",
	Tile.STONEBLOOD: "stoneblood_ore",
	Tile.MOSS: "moss_fiber",
	Tile.MUSHROOM_SOIL: "mushroom_spore",
	Tile.GLOW_MUSHROOM: "glowcap",
	Tile.ASH_BRICK: "ash_city_brick",
	Tile.SUNKEN_STONE: "sunken_stone",
	Tile.LAVA_ROOT: "ember_root",
	Tile.GLASS_STONE: "glass_shard",
	Tile.ABYSS_CRYSTAL: "abyss_crystal",
	Tile.WATER_PLANT: "kelp_fiber",
	Tile.BUBBLE_VENT: "sunken_mechanism",
	Tile.DRAIN_VALVE: "drain_valve",
	Tile.SAPLING: "sapling",
	Tile.TORCH: "torch",
	Tile.ASH_SAND: "ash_sand",
	Tile.FROZEN_DIRT: "frozen_dirt",
	Tile.MUD: "mud",
	Tile.RUBBLE: "rubble",
	Tile.DOOR: "door",
	Tile.PLATFORM: "platform",
	Tile.LADDER: "ladder",
	Tile.BED: "bed",
	Tile.FENCE: "fence",
	Tile.WINDOW: "window",
	Tile.TRAPDOOR: "trapdoor",
	Tile.ROPE: "rope",
	Tile.LANTERN: "lantern",
	Tile.TABLE: "table",
	Tile.CHAIR: "chair",
	Tile.DEPTH_ALTAR: "stone",
	Tile.DEPTH_STONE: "stone",
	Tile.SKY_GRASS: "cloudstone",
	Tile.CLOUDSTONE: "cloudstone",
	Tile.SKY_CRYSTAL: "sky_crystal",
	Tile.SKY_OBELISK: "cloudstone"
}

var item_to_tile: Dictionary = {
	"dirt": Tile.DIRT,
	"snow_block": Tile.SNOW_BLOCK,
	"stone": Tile.STONE,
	"ash": Tile.ASH,
	"root": Tile.ROOT,
	"wood": Tile.WOOD,
	"leaf": Tile.LEAVES,
	"ruin_brick": Tile.RUIN,
	"workbench": Tile.WORKBENCH,
	"furnace": Tile.FURNACE,
	"anvil": Tile.ANVIL,
	"small_turret": Tile.TURRET,
	"settlement_heart": Tile.HEART,
	"ancient_chest": Tile.CHEST,
	"stone_altar": Tile.STONE_ALTAR,
	"stoneblood_ore": Tile.STONEBLOOD,
	"moss_fiber": Tile.MOSS,
	"mushroom_spore": Tile.MUSHROOM_SOIL,
	"glowcap": Tile.GLOW_MUSHROOM,
	"ash_city_brick": Tile.ASH_BRICK,
	"sunken_stone": Tile.SUNKEN_STONE,
	"ember_root": Tile.LAVA_ROOT,
	"glass_shard": Tile.GLASS_STONE,
	"abyss_crystal": Tile.ABYSS_CRYSTAL,
	"kelp_fiber": Tile.WATER_PLANT,
	"sunken_mechanism": Tile.BUBBLE_VENT,
	"drain_valve": Tile.DRAIN_VALVE,
	"sapling": Tile.SAPLING,
	"torch": Tile.TORCH,
	"ash_sand": Tile.ASH_SAND,
	"frozen_dirt": Tile.FROZEN_DIRT,
	"mud": Tile.MUD,
	"rubble": Tile.RUBBLE,
	"door": Tile.DOOR,
	"platform": Tile.PLATFORM,
	"ladder": Tile.LADDER,
	"bed": Tile.BED,
	"fence": Tile.FENCE,
	"window": Tile.WINDOW,
	"trapdoor": Tile.TRAPDOOR,
	"rope": Tile.ROPE,
	"lantern": Tile.LANTERN,
	"table": Tile.TABLE,
	"chair": Tile.CHAIR,
	"cloudstone": Tile.CLOUDSTONE,
	"sky_crystal": Tile.SKY_CRYSTAL
}

var item_names: Dictionary = {
	"dirt": "Dirt",
	"snow_block": "Snow Block",
	"stone": "Stone",
	"copper_ore": "Copper Ore",
	"iron_ore": "Iron Ore",
	"ash": "Ash",
	"root": "Root",
	"wood": "Wood",
	"leaf": "Leaf",
	"sapling": "Sapling",
	"ruin_brick": "Ruin Brick",
	"copper_bar": "Copper Bar",
	"iron_bar": "Iron Bar",
	"ash_glass": "Ash Glass",
	"root_core": "Root Core",
	"spark_shard": "Spark Shard",
	"memory_shard": "Memory Shard",
	"world_memory": "World Memory",
	"wild_ichor": "Wild Ichor",
	"night_ember": "Night Ember",
	"heartwood_core": "Heartwood Core",
	"wind_shard": "Wind Shard",
	"earth_shard": "Earth Shard",
	"wind_boots": "Wind Boots",
	"zephyr_feather": "Zephyr Feather",
	"sky_feather": "Sky Feather",
	"sky_crystal": "Sky Crystal",
	"cloudstone": "Cloudstone",
	"star_dust": "Star Dust",
	"sky_fragment": "Sky Fragment",
	"leviathan_scale": "Leviathan Scale",
	"sky_shard": "Sky Shard",
	"sky_scale_armor": "Sky Scale Armor",
	"sky_lance": "Sky Lance",
	"cloudwing_amulet": "Cloudwing Amulet",
	"sky_compass": "Sky Compass",
	"jetpack": "Jetpack",
	"wind_wings": "Wind Wings",
	"grappling_hook": "Grappling Hook",
	"moss_armor": "Moss Armor",
	"fungal_salve": "Fungal Salve",
	"heartwood_ward": "Heartwood Ward",
	"blueprint": "Blueprint",
	"table": "Table",
	"chair": "Chair",
	"ancient_chest": "Ancient Chest",
	"torch": "Torch",
	"stone_altar": "Stone Altar",
	"door": "Door",
	"platform": "Platform",
	"ladder": "Ladder",
	"bed": "Bed",
	"fence": "Fence",
	"window": "Window",
	"trapdoor": "Trapdoor",
	"rope": "Rope",
	"lantern": "Lantern",
	"stoneblood_ore": "Stoneblood Ore",
	"stoneblood_bar": "Stoneblood Bar",
	"beast_core": "Beast Core",
	"mushroom_spore": "Mushroom Spore",
	"moss_fiber": "Moss Fiber",
	"glowcap": "Glowcap",
	"ash_city_brick": "Ash City Brick",
	"sunken_stone": "Sunken Stone",
	"drowned_pearl": "Drowned Pearl",
	"kelp_fiber": "Kelp Fiber",
	"sunken_mechanism": "Sunken Mechanism",
	"drain_valve": "Drain Valve",
	"ash_relic": "Ash Relic",
	"ember_root": "Ember Root",
	"glass_shard": "Glass Shard",
	"abyss_crystal": "Abyss Crystal",
	"abyss_lens": "Abyss Lens",
	"diving_charm": "Diving Charm",
	"ember_ward": "Ember Ward",
	"harpoon": "Ruin Harpoon",
	"tidal_trident": "Tidal Trident",
	"tide_staff": "Tide Staff",
	"drowned_armor": "Drowned Armor",
	"guardian_core": "Guardian Core",
	"stoneblood_pickaxe": "Stoneblood Pickaxe",
	"stonebreaker_blade": "Stonebreaker Blade",
	"workbench": "Workbench",
	"furnace": "Furnace",
	"anvil": "Anvil",
	"settlement_heart": "Heart of Settlement",
	"wooden_pickaxe": "Wooden Pickaxe",
	"copper_pickaxe": "Copper Pickaxe",
	"iron_pickaxe": "Iron Pickaxe",
	"ash_pickaxe": "Ash Pickaxe",
	"builder_hammer": "Builder Hammer",
	"wooden_sword": "Wooden Sword",
	"copper_sword": "Copper Sword",
	"iron_spear": "Iron Spear",
	"wooden_shield": "Wooden Shield",
	"copper_shield": "Copper Shield",
	"wooden_bow": "Wooden Bow",
	"copper_bow": "Copper Bow",
	"fire_arrows": "Fire Arrows",
	"hand_cannon": "Ruin Hand Cannon",
	"spark_staff": "Spark Staff",
	"root_spirit_rod": "Root Spirit Rod",
	"acid_flasks": "Acid Flasks",
	"small_turret": "Small Turret",
	"ash_sickle": "Ash Sickle",
	"copper_armor": "Copper Armor",
	"iron_armor": "Iron Armor",
	"ash_charm": "Ash Charm",
	"root_ring": "Root Ring",
	"wild_badge": "Wild Badge",
	"ash_sand": "Ash Sand",
	"frozen_dirt": "Frozen Dirt",
	"mud": "Mud",
	"rubble": "Rubble"
}

var tools: Dictionary = {
	"wooden_pickaxe": {"name": "Wooden Pickaxe", "power": 1, "speed": 0.78},
	"copper_pickaxe": {"name": "Copper Pickaxe", "power": 2, "speed": 1.15},
	"iron_pickaxe": {"name": "Iron Pickaxe", "power": 3, "speed": 1.55},
	"ash_pickaxe": {"name": "Ash Pickaxe", "power": 4, "speed": 1.85},
	"stoneblood_pickaxe": {"name": "Stoneblood Pickaxe", "power": 5, "speed": 2.05},
	"builder_hammer": {"name": "Builder Hammer", "power": 1, "speed": 0.75}
}

var gear_stats: Dictionary = {
	"wooden_sword": {"slot": "weapon", "class": "Warrior", "damage": 6},
	"copper_sword": {"slot": "weapon", "class": "Warrior", "damage": 11},
	"iron_spear": {"slot": "weapon", "class": "Warrior", "damage": 15},
	"wooden_shield": {"slot": "accessory", "class": "Shieldbearer", "defense": 3},
	"copper_shield": {"slot": "accessory", "class": "Shieldbearer", "defense": 6},
	"wooden_bow": {"slot": "weapon", "class": "Archer", "damage": 7},
	"copper_bow": {"slot": "weapon", "class": "Archer", "damage": 12},
	"fire_arrows": {"slot": "accessory", "class": "Archer", "damage": 4},
	"hand_cannon": {"slot": "weapon", "class": "Sniper", "damage": 21},
	"spark_staff": {"slot": "weapon", "class": "Mage", "damage": 13},
	"root_spirit_rod": {"slot": "weapon", "class": "Summoner", "damage": 9},
	"acid_flasks": {"slot": "weapon", "class": "Alchemist", "damage": 10},
	"small_turret": {"slot": "weapon", "class": "Engineer", "damage": 8},
	"ash_sickle": {"slot": "weapon", "class": "Memory Reaper", "damage": 17},
	"stonebreaker_blade": {"slot": "weapon", "class": "Warrior", "damage": 26},
	"copper_armor": {"slot": "armor", "class": "Any", "defense": 5, "cold_protection": 0.08, "heat_protection": 0.06},
	"iron_armor": {"slot": "armor", "class": "Any", "defense": 9, "cold_protection": 0.18, "heat_protection": 0.10},
	"ash_charm": {"slot": "accessory", "class": "Memory Reaper", "damage": 3},
	"root_ring": {"slot": "accessory", "class": "Summoner", "defense": 2},
	"wild_badge": {"slot": "accessory", "class": "Any", "damage": 2, "defense": 1},
	"diving_charm": {"slot": "accessory", "class": "Any", "defense": 1, "water_breathing": true, "cold_protection": 0.12},
	"ember_ward": {"slot": "accessory", "class": "Any", "defense": 2, "heat_resistance": true, "heat_protection": 0.58},
	"wind_boots": {"slot": "accessory", "class": "Any", "defense": 0, "speed_bonus": 0.10},
	"moss_armor": {"slot": "armor", "class": "Any", "defense": 2, "cold_protection": 0.05},
	"heartwood_ward": {"slot": "accessory", "class": "Any", "damage": 4, "defense": 2},
	"jetpack": {"slot": "accessory", "class": "Any", "defense": 1, "flight": true},
	"wind_wings": {"slot": "accessory", "class": "Any", "defense": 1, "flight": true},
	"grappling_hook": {"slot": "accessory", "class": "Any", "defense": 0, "grapple": true},
	"harpoon": {"slot": "weapon", "class": "Sniper", "damage": 23},
	"tidal_trident": {"slot": "weapon", "class": "Warrior", "damage": 21},
	"tide_staff": {"slot": "weapon", "class": "Mage", "damage": 19},
	"drowned_armor": {"slot": "armor", "class": "Any", "defense": 13, "water_affinity": true, "cold_protection": 0.45, "heat_protection": 0.04},
	"sky_scale_armor": {"slot": "armor", "class": "Any", "defense": 14, "cold_protection": 0.12, "heat_protection": 0.12},
	"sky_lance": {"slot": "weapon", "class": "Warrior", "damage": 30},
	"cloudwing_amulet": {"slot": "accessory", "class": "Any", "defense": 2, "flight_bonus": true},
	"sky_compass": {"slot": "accessory", "class": "Any", "defense": 1, "sky_compass": true},
}

# Per-enemy perception tuning. Values are intentionally data-driven so new
# creatures can hear, see, remember and alert allies differently without
# changing the state machine.
var enemy_perception_profiles: Dictionary = {
	"wild_slime": {"vision_range": 150.0, "vision_angle": 105.0, "hearing": 0.75, "light_sensitivity": 1.0, "suspicion_rate": 1.15, "memory_time": 3.0, "search_time": 4.0, "alert_radius": 105.0},
	"mossling": {"vision_range": 175.0, "vision_angle": 125.0, "hearing": 1.0, "light_sensitivity": 0.85, "suspicion_rate": 1.35, "memory_time": 4.0, "search_time": 5.0, "alert_radius": 135.0},
	"root_crawler": {"vision_range": 145.0, "vision_angle": 95.0, "hearing": 1.35, "light_sensitivity": 0.45, "suspicion_rate": 1.10, "memory_time": 5.5, "search_time": 7.0, "alert_radius": 145.0},
	"cave_worm": {"vision_range": 105.0, "vision_angle": 80.0, "hearing": 1.65, "light_sensitivity": 0.15, "suspicion_rate": 1.25, "memory_time": 6.0, "search_time": 7.5, "alert_radius": 140.0},
	"bat": {"vision_range": 135.0, "vision_angle": 210.0, "hearing": 1.75, "light_sensitivity": 0.20, "suspicion_rate": 1.55, "memory_time": 4.5, "search_time": 6.0, "alert_radius": 170.0},
	"cave_husk": {"vision_range": 165.0, "vision_angle": 115.0, "hearing": 1.05, "light_sensitivity": 0.75, "suspicion_rate": 1.30, "memory_time": 5.0, "search_time": 6.0, "alert_radius": 145.0},
	"spore_bat": {"vision_range": 155.0, "vision_angle": 220.0, "hearing": 1.65, "light_sensitivity": 0.25, "suspicion_rate": 1.65, "memory_time": 5.0, "search_time": 6.5, "alert_radius": 185.0},
	"mushroom_beetle": {"vision_range": 145.0, "vision_angle": 100.0, "hearing": 1.20, "light_sensitivity": 0.45, "suspicion_rate": 1.20, "memory_time": 5.0, "search_time": 6.0, "alert_radius": 135.0},
	"ash_phantom": {"vision_range": 215.0, "vision_angle": 240.0, "hearing": 0.85, "light_sensitivity": 0.55, "suspicion_rate": 1.65, "memory_time": 7.0, "search_time": 8.0, "alert_radius": 190.0},
	"ash_wisp": {"vision_range": 185.0, "vision_angle": 260.0, "hearing": 0.95, "light_sensitivity": 0.35, "suspicion_rate": 1.55, "memory_time": 5.0, "search_time": 6.0, "alert_radius": 165.0},
	"ruin_drone": {"vision_range": 245.0, "vision_angle": 150.0, "hearing": 0.80, "light_sensitivity": 0.90, "suspicion_rate": 1.85, "memory_time": 8.0, "search_time": 9.0, "alert_radius": 225.0},
	"ash_sentinel": {"vision_range": 225.0, "vision_angle": 125.0, "hearing": 1.10, "light_sensitivity": 0.75, "suspicion_rate": 1.60, "memory_time": 8.0, "search_time": 9.0, "alert_radius": 210.0},
	"drowned_guard": {"vision_range": 185.0, "vision_angle": 120.0, "hearing": 1.30, "light_sensitivity": 0.50, "suspicion_rate": 1.45, "memory_time": 7.0, "search_time": 8.0, "alert_radius": 190.0},
	"ember_rootling": {"vision_range": 190.0, "vision_angle": 115.0, "hearing": 1.20, "light_sensitivity": 0.30, "suspicion_rate": 1.50, "memory_time": 6.5, "search_time": 7.0, "alert_radius": 180.0},
	"glass_wraith": {"vision_range": 260.0, "vision_angle": 280.0, "hearing": 0.95, "light_sensitivity": 0.10, "suspicion_rate": 1.90, "memory_time": 9.0, "search_time": 10.0, "alert_radius": 230.0},
	"night_ember": {"vision_range": 210.0, "vision_angle": 250.0, "hearing": 1.10, "light_sensitivity": 0.15, "suspicion_rate": 1.75, "memory_time": 6.0, "search_time": 7.0, "alert_radius": 185.0},
	"stone_beast": {"vision_range": 290.0, "vision_angle": 170.0, "hearing": 1.45, "light_sensitivity": 0.20, "suspicion_rate": 2.40, "memory_time": 12.0, "search_time": 10.0, "alert_radius": 260.0},
	"heartwood_boss": {"vision_range": 320.0, "vision_angle": 220.0, "hearing": 1.50, "light_sensitivity": 0.10, "suspicion_rate": 2.60, "memory_time": 14.0, "search_time": 12.0, "alert_radius": 280.0}
}

var recipes: Array[Dictionary] = [
	{"id": "workbench", "station": "hand", "cost": {"wood": 8}, "result": "workbench", "amount": 1},
	{"id": "ash_sift", "station": "hand", "cost": {"ash_sand": 4}, "result": "ash", "amount": 1},
	{"id": "ancient_chest", "station": "workbench", "cost": {"wood": 12, "stone": 6}, "result": "ancient_chest", "amount": 1},
	{"id": "wooden_pickaxe", "station": "workbench", "cost": {"wood": 10, "stone": 4}, "result": "wooden_pickaxe", "amount": 1},
	{"id": "copper_bar", "station": "furnace", "cost": {"copper_ore": 3, "wood": 1}, "result": "copper_bar", "amount": 1},
	{"id": "iron_bar", "station": "furnace", "cost": {"iron_ore": 3, "wood": 1}, "result": "iron_bar", "amount": 1},
	{"id": "ash_glass", "station": "furnace", "cost": {"ash": 4, "stone": 1}, "result": "ash_glass", "amount": 1},
	{"id": "copper_pickaxe", "station": "anvil", "cost": {"copper_bar": 6, "wood": 3}, "result": "copper_pickaxe", "amount": 1},
	{"id": "iron_pickaxe", "station": "anvil", "cost": {"iron_bar": 8, "wood": 3}, "result": "iron_pickaxe", "amount": 1},
	{"id": "ash_pickaxe", "station": "anvil", "cost": {"iron_bar": 6, "ash_glass": 6, "memory_shard": 2}, "result": "ash_pickaxe", "amount": 1},
	{"id": "wooden_sword", "station": "workbench", "cost": {"wood": 8}, "result": "wooden_sword", "amount": 1},
	{"id": "copper_sword", "station": "anvil", "cost": {"copper_bar": 5, "wood": 2}, "result": "copper_sword", "amount": 1},
	{"id": "iron_spear", "station": "anvil", "cost": {"iron_bar": 6, "wood": 4}, "result": "iron_spear", "amount": 1},
	{"id": "wooden_shield", "station": "workbench", "cost": {"wood": 10, "root": 2}, "result": "wooden_shield", "amount": 1},
	{"id": "copper_shield", "station": "anvil", "cost": {"copper_bar": 6, "root_core": 1}, "result": "copper_shield", "amount": 1},
	{"id": "wooden_bow", "station": "workbench", "cost": {"wood": 9, "root": 2}, "result": "wooden_bow", "amount": 1},
	{"id": "copper_bow", "station": "anvil", "cost": {"copper_bar": 4, "wood": 4, "root": 3}, "result": "copper_bow", "amount": 1},
	{"id": "fire_arrows", "station": "workbench", "cost": {"wood": 2, "ash": 2, "copper_ore": 1}, "result": "fire_arrows", "amount": 25},
	{"id": "hand_cannon", "station": "anvil", "cost": {"ruin_brick": 8, "iron_bar": 5, "spark_shard": 1}, "result": "hand_cannon", "amount": 1},
	{"id": "spark_staff", "station": "anvil", "cost": {"spark_shard": 2, "wood": 6, "copper_bar": 2}, "result": "spark_staff", "amount": 1},
	{"id": "root_spirit_rod", "station": "workbench", "cost": {"root_core": 2, "wood": 6}, "result": "root_spirit_rod", "amount": 1},
	{"id": "acid_flasks", "station": "furnace", "cost": {"ash_glass": 2, "ash": 4, "copper_ore": 2}, "result": "acid_flasks", "amount": 12},
	{"id": "small_turret", "station": "anvil", "cost": {"iron_bar": 6, "copper_bar": 4, "ruin_brick": 4}, "result": "small_turret", "amount": 1},
	{"id": "ash_sickle", "station": "anvil", "cost": {"ash_glass": 4, "iron_bar": 4, "memory_shard": 2}, "result": "ash_sickle", "amount": 1},
	{"id": "copper_armor", "station": "anvil", "cost": {"copper_bar": 10}, "result": "copper_armor", "amount": 1},
	{"id": "iron_armor", "station": "anvil", "cost": {"iron_bar": 12}, "result": "iron_armor", "amount": 1},
	{"id": "ash_charm", "station": "workbench", "cost": {"memory_shard": 2, "ash": 8}, "result": "ash_charm", "amount": 1},
	{"id": "root_ring", "station": "workbench", "cost": {"root_core": 2, "copper_bar": 1}, "result": "root_ring", "amount": 1},
	{"id": "wild_badge", "station": "workbench", "cost": {"wild_ichor": 4, "night_ember": 2, "wood": 6}, "result": "wild_badge", "amount": 1},
	{"id": "stoneblood_bar", "station": "furnace", "cost": {"stoneblood_ore": 3, "ash": 1}, "result": "stoneblood_bar", "amount": 1},
	{"id": "stoneblood_pickaxe", "station": "anvil", "cost": {"stoneblood_bar": 8, "beast_core": 1, "wood": 4}, "result": "stoneblood_pickaxe", "amount": 1},
	{"id": "stonebreaker_blade", "station": "anvil", "cost": {"stoneblood_bar": 10, "beast_core": 1}, "result": "stonebreaker_blade", "amount": 1},
	{"id": "abyss_lens", "station": "anvil", "cost": {"abyss_crystal": 4, "glass_shard": 6, "drowned_pearl": 1}, "result": "abyss_lens", "amount": 1},
	{"id": "diving_charm", "station": "anvil", "cost": {"drowned_pearl": 2, "sunken_stone": 8, "iron_bar": 4}, "result": "diving_charm", "amount": 1},
	{"id": "ember_ward", "station": "anvil", "cost": {"ember_root": 8, "night_ember": 4, "stoneblood_bar": 2}, "result": "ember_ward", "amount": 1},
	{"id": "harpoon", "station": "anvil", "cost": {"sunken_mechanism": 2, "iron_bar": 7, "kelp_fiber": 4}, "result": "harpoon", "amount": 1},
	{"id": "tidal_trident", "station": "anvil", "cost": {"guardian_core": 1, "drowned_pearl": 3, "stoneblood_bar": 6}, "result": "tidal_trident", "amount": 1},
	{"id": "wind_boots", "station": "workbench", "cost": {"wind_shard": 1, "root": 4, "wood": 6}, "result": "wind_boots", "amount": 1},
	{"id": "grappling_hook", "station": "anvil", "cost": {"iron_bar": 6, "root": 4, "rope": 6}, "result": "grappling_hook", "amount": 1},
	{"id": "blueprint", "station": "workbench", "cost": {"wood": 8, "stone": 4}, "result": "blueprint", "amount": 1},
	# Early armor + consumables (use materials that used to be dead drops).
	{"id": "moss_armor", "station": "workbench", "cost": {"moss_fiber": 12, "root": 4}, "result": "moss_armor", "amount": 1},
	{"id": "fungal_salve", "station": "hand", "cost": {"glowcap": 2, "mushroom_spore": 2}, "result": "fungal_salve", "amount": 3},
	{"id": "ash_charm_alt", "station": "workbench", "cost": {"ash_relic": 1, "ash": 12}, "result": "ash_charm", "amount": 1},
	{"id": "heartwood_ward", "station": "anvil", "cost": {"heartwood_core": 1, "root": 8, "iron_bar": 6}, "result": "heartwood_ward", "amount": 1},
	{"id": "jetpack", "station": "anvil", "cost": {"sky_feather": 4, "copper_bar": 8, "iron_bar": 6, "spark_shard": 2}, "result": "jetpack", "amount": 1},
	{"id": "wind_wings", "station": "workbench", "cost": {"zephyr_feather": 6, "sky_feather": 2, "root": 8, "memory_shard": 2}, "result": "wind_wings", "amount": 1},
	{"id": "sky_scale_armor", "station": "anvil", "cost": {"leviathan_scale": 8, "sky_crystal": 6, "cloudstone": 12}, "result": "sky_scale_armor", "amount": 1},
	{"id": "sky_lance", "station": "anvil", "cost": {"leviathan_scale": 6, "sky_crystal": 4, "iron_bar": 8}, "result": "sky_lance", "amount": 1},
	{"id": "cloudwing_amulet", "station": "workbench", "cost": {"leviathan_scale": 2, "sky_feather": 4, "star_dust": 12}, "result": "cloudwing_amulet", "amount": 1},
	{"id": "sky_compass", "station": "workbench", "cost": {"sky_crystal": 6, "sky_feather": 4, "cloudstone": 8, "star_dust": 6}, "result": "sky_compass", "amount": 1},
	{"id": "tide_staff", "station": "anvil", "cost": {"guardian_core": 1, "abyss_crystal": 3, "drowned_pearl": 4}, "result": "tide_staff", "amount": 1},
	{"id": "drowned_armor", "station": "anvil", "cost": {"guardian_core": 1, "sunken_stone": 16, "kelp_fiber": 8}, "result": "drowned_armor", "amount": 1}
]

var world: Array = []
var surface_heights: Array[int] = []
# One deterministic biome id per world column. Surface biomes are kept separate
# from underground biome patches so their borders remain stable after loading.
var surface_biomes: Array[String] = []
# Derived seam data lets the two neighboring palettes and topsoils overlap in a
# stable strip without bloating save files or network world transfers.
var border_distances: Array[int] = []
var border_neighbors: Array[String] = []
# Per-column topsoil depth noise, reseeded with the world on every generation.
var topsoil_noise: FastNoiseLite = null
var transition_noise: FastNoiseLite = null
var border_meander_noise: FastNoiseLite = null
var chest_loot: Dictionary = {}
var seed := 0
var rng := RandomNumberGenerator.new()
# Weather uses isolated random streams so particles never perturb authoritative
# combat/spawn RNG and rendering cadence cannot change future weather choices.
var weather_state_rng := RandomNumberGenerator.new()
var weather_visual_rng := RandomNumberGenerator.new()
var player_position := Vector2.ZERO
var player_velocity := Vector2.ZERO
var facing := 1
var inventory: Dictionary = {}
var player_statuses: Dictionary = {}
var hotbar: Array[String] = ["wooden_pickaxe", "dirt", "stone", "wood", "workbench"]
var selected_slot := 0
var selected_block := Tile.DIRT
var current_tool := "wooden_pickaxe"
var selected_recipe_index := 0
var equipped_weapon := ""
var equipped_armor := ""
var equipped_accessory := ""
var selected_inventory_item_id := ""
var held_item_id := ""
var held_item_amount := 0
var pending_inventory_right_drop_id := ""
var pending_inventory_right_drop_consumed := false
var sapling_growth_timer := 0.0
var sapling_positions: Dictionary = {}
var tree_tile_owners: Dictionary = {}
var next_tree_id := 1
var biome_check_timer := 0.0
var cached_biome := "forest"
var hud_update_timer := 0.0
var last_message := "Gather wood and stone, then craft a workbench."
var inventory_open := false
# Inventory, crafting and journal are separate screens. This value chooses
# which of the first two is shown while inventory_open is true.
var inventory_screen := "inventory"
var health := MAX_HEALTH
# Passive regeneration (Terraria-like): after 6s without damage, +1 HP every
# 2s. Any hit resets the 6s delay. Keeps exploration survivable without a
# food/healing economy.
# Consumables used from the hotbar (tap ATK / press F while selected).
var consumables: Dictionary = {
	"fungal_salve": {"heal": 25},
}
var player_regen_timer := 0.0
# Flight charge (jetpack / Wind Wings): spent while flying, slowly refills
# on the ground, instantly refilled by consuming star_dust.
var flight_charge := 100.0
const FLIGHT_CHARGE_MAX := 100.0
const FLIGHT_CHARGE_COST := 16.0
var flight_charge_label: Label
const REGEN_DELAY := 6.0
const REGEN_INTERVAL := 2.0
var oxygen := MAX_OXYGEN
var drowning_tick := 0.0
var lava_tick := 0.0
var body_temperature := NORMAL_BODY_TEMPERATURE
var ambient_temperature := 20.0
var temperature_sample_timer := 0.0
var temperature_damage_tick := 0.0
var temperature_visual_state := ""
var liquid_flow_timer := 0.0
var liquid_flow_phase := 0
var mining_target := Vector2i(-999, -999)
var mining_progress := 0.0
# Direct desktop input state. Physical A/D keeps movement working with non-English keyboard layouts.
var physical_move_left_held := false
var physical_move_right_held := false
var physical_noclip_up_held := false
var physical_noclip_down_held := false
var mouse_mine_held := false
var debug_console_open := false
var debug_console_panel: PanelContainer
var debug_console_output: RichTextLabel
var debug_console_input: LineEdit
var debug_console_history: Array[String] = []
var debug_console_history_index := 0
var noclip_unlocked := false
var noclip_enabled := false
var god_mode_enabled := false
var creative_mode := false
var last_space_press_msec := -10000
var landing_speed := 0.0
var camera: Camera2D
var hud_label: Label
var hud_health_bar: ProgressBar
var hud_armor_value: Label
var hud_status_label: Label
var oxygen_panel: Control
var oxygen_bar: ProgressBar
var oxygen_value: Label
var temperature_panel: Control
var temperature_title: Label
var temperature_bar: ProgressBar
var temperature_value: Label
var minimap_time_label: Label
var minimap_biome_label: Label
var context_hint_panel: Control
var context_hint_label: Label
var hotbar_buttons: Array[Button] = []
var inventory_slot_buttons: Array[Button] = []
var inventory_panel: PanelContainer
var crafting_panel: PanelContainer
var inventory_backdrop: ColorRect
var equipment_overlay: Control
var inventory_title_label: Label
var equipment_label: Label
var equipment_environment_label: Label
var crafting_label: Label
var stations_label: Label
var message_label: Label
var controls_label: Label
# ============================================================
# ASHEN ARCHIVE UI (new concept theme)
# ============================================================
var ui_pixel_font: Font
var ring_fill_texture: Texture2D
var ring_track_texture: Texture2D
var circle_texture: Texture2D
var lens_vignette_texture: Texture2D
var hp_ring_bar: TextureProgressBar
var hp_ring_number: Label
var hp_ring_caption: Label
var armor_chip_label: Label
var hud_class_label: Label
var status_chips_root: Control
var status_chips_cache := ""
var day_icon_rect: TextureRect
var day_time_label: Label
var hud_toast_panel: PanelContainer
var hud_toast_label: Label
var ui_tex_cache: Dictionary = {}
var health_hearts: Array[TextureRect] = []
var heart_full_tex: Texture2D
var heart_half_tex: Texture2D
var heart_empty_tex: Texture2D
var vitals_seed_label: Label
var lens_vignette_rect: TextureRect
var lens_dot_rect: TextureRect
var hotbar_arrow_labels: Array[Label] = []
var hero_sprite_rect: TextureRect
var char_stats_label: Label
var station_filter_buttons: Array[Button] = []
var recipe_station_filter := "all"
var journal_detail_sprite: TextureRect
var map_wrap: Control
var map_fog_rect: TextureRect
var map_legend_label: RichTextLabel
var loot_feed_icons: Array[TextureRect] = []
var selected_item_label: Label
var assign_hotbar_button: Button
var equip_inventory_button: Button
var drop_inventory_button: Button
var held_item_panel: PanelContainer
var held_item_icon: TextureRect
var held_item_amount_label: Label
var weapon_slot_button: Button
var armor_slot_button: Button
var accessory_slot_button: Button
var recipe_buttons: Array[Button] = []
var craft_button: Button
var boss_panel: PanelContainer
var boss_label: Label
var boss_hp_bar: ProgressBar
var loot_feed_labels: Array[Label] = []
var minimap_panel: Control
var full_map_panel: Control
var full_map_rect: TextureRect
var full_map_open := false
var map_close_catcher: Control
var full_map_backdrop: ColorRect
var journal_open := false
var journal_panel: PanelContainer
var journal_backdrop: ColorRect
var journal_tab_buttons: Dictionary = {}
var journal_entry_list: VBoxContainer
var journal_detail_title: Label
var journal_detail_text: RichTextLabel
var journal_progress_label: Label
var journal_access_button: Button
var journal_active_tab := "Recipes"
var journal_selected_entry := ""
var journal_unread_count := 0
var journal_observation_timer := 0.0
var known_recipes: Dictionary = {}
var bestiary_knowledge: Dictionary = {}
var material_knowledge: Dictionary = {}
var alchemy_knowledge: Dictionary = {}
var world_map_image: Image
var world_map_dirty := true
# Monotonic terrain revision drives lightweight render/minimap caches.
var world_tile_revision := 0
var minimap_rendered_revision := -1
var minimap_rendered_center := Vector2i(-99999, -99999)
var minimap_rebuild_count := 0
# Persistent fog of war: 0 = unexplored, 1 = discovered.
var explored_tiles := PackedByteArray()
var last_explored_tile := Vector2i(-999, -999)
var visible_light_sources: Array[Dictionary] = []
var cached_static_light_sources: Array[Dictionary] = []
var cached_light_bounds := Rect2i()
var cached_light_revision := -1
var static_light_scan_count := 0
var perception_noise_events: Array[Dictionary] = []
var next_noise_event_id := 1
var next_enemy_perception_id := 1
var player_footstep_noise_timer := 0.0
var perception_debug_enabled := false
var mobile_controls: Control
var mobile_gameplay_controls: Control
var mobile_joystick: Control
var loot_feed_chips: Array[PanelContainer] = []
var mobile_ui_enabled := false
var mobile_target_tile := Vector2i(-999, -999)
var mobile_target_valid := false
var mobile_world_touch_index := -1
var mobile_attack_target := Vector2.ZERO
var mobile_attack_target_valid := false
# --- Mobile lifecycle & safe-area state -------------------------------------
# Edge-anchored HUD controls register base offsets once; display cutout /
# system bar insets are then applied on top without touching the visual style.
var safe_area_registry: Array[Dictionary] = []
var safe_area_insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
# Diagnostics for regression tests; incremented rarely (lifecycle events only).
var transient_input_release_count := 0
var lifecycle_resume_count := 0
var background_save_count := 0
var safe_area_apply_count := 0
var last_background_save_msec := -100000
const BACKGROUND_SAVE_DEBOUNCE_MSEC := 3000
const SAFE_AREA_MAX_INSET := 120.0
# Long-press tooltip state for touch hotbar/inventory slots.
var slot_longpress_kind := ""
var slot_longpress_index := -1
var slot_longpress_pointer := -1
var slot_longpress_timer := 0.0
var slot_longpress_origin := Vector2.ZERO
var slot_longpress_fired := false
var touch_tooltip_panel: PanelContainer
var touch_tooltip_label: Label
const SLOT_LONG_PRESS_TIME := 0.45
const SLOT_LONG_PRESS_SLOP := 26.0
var item_icon_cache: Dictionary = {}
var tile_texture_paths: Dictionary = {}
var tile_textures: Dictionary = {}
var tile_texture_variants: Dictionary = {}
var biome_tile_textures: Dictionary = {}
var enemy_textures: Dictionary = {}
var enemy_animation_textures: Dictionary = {}
var enemy_animation_specs: Dictionary = {}
var enemy_animation_pack_specs: Dictionary = {}
var enemy_sprite_ground_anchors: Dictionary = {}
var enemy_sprite_specs: Dictionary = {
	"wild_slime": {"frame": Vector2i(40, 32), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 4, "fps": 7.0, "scale": 0.58},
	"mossling": {"frame": Vector2i(48, 32), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 8, "fps": 8.0, "scale": 0.58},
	"root_crawler": {"frame": Vector2i(64, 32), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 8, "fps": 9.0, "scale": 0.58},
	"cave_worm": {"frame": Vector2i(80, 32), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 8, "fps": 8.0, "scale": 0.58},
	"bat": {"frame": Vector2i(48, 32), "idle_row": 0, "idle_frames": 6, "move_row": 0, "move_frames": 6, "fps": 11.0, "scale": 0.58},
	"cave_husk": {"frame": Vector2i(48, 64), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 8, "fps": 7.0, "scale": 0.58},
	"spore_bat": {"frame": Vector2i(48, 32), "idle_row": 0, "idle_frames": 6, "move_row": 0, "move_frames": 6, "fps": 10.0, "scale": 0.58},
	"mushroom_beetle": {"frame": Vector2i(48, 32), "idle_row": 0, "idle_frames": 4, "move_row": 1, "move_frames": 8, "fps": 8.0, "scale": 0.58},
	"ash_phantom": {"frame": Vector2i(40, 40), "idle_row": 0, "idle_frames": 23, "move_row": 0, "move_frames": 23, "fps": 13.0, "scale": 0.72},
	"ash_wisp": {"frame": Vector2i(40, 40), "idle_row": 0, "idle_frames": 6, "move_row": 0, "move_frames": 6, "fps": 10.0, "scale": 0.58},
	"ruin_drone": {"frame": Vector2i(48, 48), "idle_row": 0, "idle_frames": 6, "move_row": 0, "move_frames": 6, "fps": 9.0, "scale": 0.58},
	"ash_sentinel": {"frame": Vector2i(64, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 7.0, "scale": 0.58},
	"drowned_guard": {"frame": Vector2i(64, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 7.0, "scale": 0.58},
	"ember_rootling": {"frame": Vector2i(64, 48), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 8.0, "scale": 0.58},
	"glass_wraith": {"frame": Vector2i(48, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 9.0, "scale": 0.58},
	"storm_herald": {"frame": Vector2i(48, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 9.0, "scale": 0.72},
	"sky_herald": {"frame": Vector2i(48, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 9.0, "scale": 0.62},
	"leviathan": {"frame": Vector2i(48, 64), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 8.0, "scale": 1.30},
	"depth_warden": {"frame": Vector2i(144, 112), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 6.0, "scale": 0.6},
	"night_ember": {"frame": Vector2i(40, 40), "idle_row": 0, "idle_frames": 6, "move_row": 0, "move_frames": 6, "fps": 11.0, "scale": 0.58},
	"stone_beast": {"frame": Vector2i(144, 112), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 6.0, "scale": 0.64},
	"heartwood_boss": {"frame": Vector2i(112, 128), "idle_row": 0, "idle_frames": 8, "move_row": 1, "move_frames": 8, "fps": 6.0, "scale": 0.64}
}
var minimap_rect: TextureRect
var chest_panel: PanelContainer
var chest_slot_buttons: Array[Button] = []
var active_chest_key := ""
var active_chest_pos := Vector2i(-999, -999)
var minimap_timer := 0.0
var player_on_floor := false
var active_class := "Warrior"
var ui_font: Font
var world_time := 28.0
var weather := WEATHER_CLEAR
var weather_timer := 90.0
var weather_intensity := 0.0
var weather_target_intensity := 0.0
var weather_lightning_timer := 0.0
var weather_lightning_flash := 0.0
var weather_effect_timer := 0.0
var weather_particles: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var dying_enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var enemy_impact_effects: Array[Dictionary] = []
var dropped_items: Array[Dictionary] = []
var next_network_loot_id := 1
var network_pending_loot: Dictionary = {}
var damage_numbers: Array[Dictionary] = []
var hit_particles: Array[Dictionary] = []
# Short-lived combat feedback drawn in world space (impact cross, ring, muzzle).
var combat_impacts: Array[Dictionary] = []
var combat_hit_stop_timer := 0.0
var camera_shake_strength := 0.0
var camera_shake_time := 0.0
var camera_shake_duration := 0.0
var camera_shake_phase := 0.0
var player_hurt_flash := 0.0
var attack_cooldown := 0.0
var attack_anim_time := 0.0
var attack_anim_duration := 0.0
var attack_anim_kind := ""
var attack_anim_dir := Vector2.RIGHT
var attack_anim_color := Color("f0d27a")
var enemy_spawn_timer := 45.0
var player_hurt_timer := 0.0
var defeated_enemies := 0
var boss_spawned := false
var boss_defeated := false
var stone_broken_count := 0
var stone_beast_spawned := false
var stone_beast_defeated := false
var mushroom_path_opened := false
var last_biome := ""
var loot_notifications: Array[Dictionary] = []
# --- Storm story arc: "The Awakening Storm" ---
var storm_active := false
var storm_herald_defeated := false
var storm_tornado_pos := Vector2.ZERO
var storm_tornado_phase := ""          # "" | forming | active | sucking
var storm_tornado_timer := 0.0
var storm_wind_dir := Vector2.RIGHT
var storm_research_timer := 0.0
var storm_forced := false
var storm_warning_1 := false
var storm_warning_2 := false
var storm_warning_3 := false
var wind_shard_picked := false
var grapple_button: Control
var atk_button: Control
var jump_button: Control
# --- UI layout ---
var ui_layout: Dictionary = {}
var ui_layout_loaded := false
const UI_LAYOUT_PATH := "user://ui_layout.json"
const UI_LAYOUT_VERSION := 2
var editing_ui := false
var editor_dragging := ""
var editor_drag_offset := Vector2.ZERO
var editor_resize_target := ""
var editor_overlay: Control
# --- Chapter II: The Call from Below ---
var depth_warden_defeated := false
var depth_sanctum_pos := Vector2i(-1, -1)
var depth_sanctum_activated := false
var depth_warden_spawned := false
# --- Chapter III: Sky Islands ---
var sky_island_positions: Array = []
var sky_arena_pos := Vector2i(-1, -1)
var sky_leviathan_spawned := false
var sky_leviathan_defeated := false
const SKY_FRAGMENTS_NEEDED := 3
# --- First NPC + path choice (after Chapter III) ---
var npc_wanderer_active := false
var npc_wanderer_pos := Vector2(-1.0, -1.0)
var path_choice := ""            # "" | "science" | "magic"
var observatory_pos := Vector2i(-1, -1)
var moon_altar_pos := Vector2i(-1, -1)
var path_dialog_open := false
var path_dialog_panel: PanelContainer
const SKY_ZONE_TOP := 2
const SKY_ZONE_BOTTOM := 15
# --- Blueprint building ---
var active_build_id := ""
var build_panel: PanelContainer
var build_grid: GridContainer
var build_catalog: Dictionary = {
	"torch": {"name": "Torch", "tile": Tile.TORCH, "cost": {"wood": 1, "ash": 1}},
	"door": {"name": "Door", "tile": Tile.DOOR, "cost": {"wood": 6}},
	"platform": {"name": "Platform", "tile": Tile.PLATFORM, "cost": {"wood": 1}},
	"ladder": {"name": "Ladder", "tile": Tile.LADDER, "cost": {"wood": 1}},
	"rope": {"name": "Rope", "tile": Tile.ROPE, "cost": {"root": 1}},
	"fence": {"name": "Fence", "tile": Tile.FENCE, "cost": {"wood": 1}},
	"trapdoor": {"name": "Trapdoor", "tile": Tile.TRAPDOOR, "cost": {"wood": 4}},
	"window": {"name": "Window", "tile": Tile.WINDOW, "cost": {"wood": 4, "glass_shard": 2}},
	"lantern": {"name": "Lantern", "tile": Tile.LANTERN, "cost": {"wood": 4, "ash": 2}},
	"table": {"name": "Table", "tile": Tile.TABLE, "cost": {"wood": 8}},
	"chair": {"name": "Chair", "tile": Tile.CHAIR, "cost": {"wood": 4}},
	"bed": {"name": "Bed", "tile": Tile.BED, "cost": {"wood": 12, "leaf": 4, "root": 2}},
	"workbench": {"name": "Workbench", "tile": Tile.WORKBENCH, "cost": {"wood": 8}},
	"furnace": {"name": "Furnace", "tile": Tile.FURNACE, "cost": {"stone": 18, "wood": 4}},
	"anvil": {"name": "Anvil", "tile": Tile.ANVIL, "cost": {"copper_bar": 5, "stone": 8}},
	"chest": {"name": "Chest", "tile": Tile.CHEST, "cost": {"wood": 12, "stone": 6}},
	"turret": {"name": "Turret", "tile": Tile.TURRET, "cost": {"iron_bar": 6, "copper_bar": 4, "ruin_brick": 4}},
}
var bed_spawn_pos := Vector2(-1.0, -1.0)
# --- Grappling hook ---
var grapple_hook_pos := Vector2(-1.0, -1.0)
var grapple_attached := false
var grapple_attached_to := Vector2i(-1, -1)
var grapple_cooldown := 0.0
const GRAPPLE_SPEED := 520.0
const GRAPPLE_RANGE := 160.0
# --- World slots (multiple saves) ---
var current_world_index := -1
var current_world_name := ""
var worlds_meta: Array = []          # [{index, name, seed, time}]
var world_loaded := false
# --- Main menu / pause / settings ---
var in_main_menu := true
var game_paused := false
var main_menu_panel: PanelContainer
var worlds_list_box: VBoxContainer
var new_world_name_edit: LineEdit
var settings_panel: PanelContainer
var settings_volume_slider: HSlider
var settings_volume_value: Label
var settings_volume := 0.8
const SETTINGS_PATH := "user://settings.cfg"
var pause_panel: PanelContainer
var pause_players_box: VBoxContainer
var pause_admin_row: HBoxContainer
# --- Multiplayer / self-hosted ENet session ---
var network_session
var multiplayer_panel: PanelContainer
var multiplayer_world_selector: OptionButton
var multiplayer_name_edit: LineEdit
var multiplayer_server_name_edit: LineEdit
var multiplayer_address_edit: LineEdit
var multiplayer_recent_button: MenuButton
var multiplayer_port_edit: LineEdit
var multiplayer_password_edit: LineEdit
var multiplayer_pvp_check: CheckButton
var multiplayer_status_label: Label
var network_badge_label: Label
var pause_pvp_button: Button
var network_chat_log_label: RichTextLabel
var network_chat_edit: LineEdit
var network_chat_lines: Array[String] = []
var network_applying_snapshot := false
var network_applying_respawn := false
var network_player_profiles: Dictionary = {}
var network_open_chests: Dictionary = {}
var network_open_tiles: Dictionary = {}
var network_mine_ready_msec: Dictionary = {}
var network_profile_regen_timer := 0.0
var network_autosave_timer := 0.0
var world_backup_msec: Dictionary = {}
var recent_network_addresses: Array[String] = []
const WORLD_BACKUP_INTERVAL_MSEC := 5 * 60 * 1000
const WORLD_BACKUP_LIMIT := 5
const NETWORK_RECENT_PATH := "user://recent_servers.json"
const NETWORK_RECENT_LIMIT := 8
var dedicated_export_path := ""
var dedicated_admin_path := ""
var dedicated_admin_timer := 0.0
var graceful_shutdown_started := false
var storm_progress_label: Label
const STORM_BESTIARY_NEED := 6
const STORM_ALCHEMY_NEED := 2
const STORM_RECIPES_NEED: Array[String] = ["anvil", "copper_pickaxe", "iron_bar", "spark_staff"]
var sound_players: Dictionary = {}
var player_texture: Texture2D
var player_frame_size := Vector2i(48, 64)

# ============================================================
# OPTIMIZATION MODULES
# ============================================================
var liquid_sim: LiquidSim
var renderer_mgr: RendererManager
var world_generation_in_progress := false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	ui_font = ThemeDB.fallback_font
	ui_pixel_font = ResourceLoader.load("res://assets/ui/ps2p.ttf") as Font
	if ui_pixel_font != null and ui_pixel_font.has_method("add_fallback"):
		ui_pixel_font.add_fallback(ThemeDB.fallback_font)
	# ASHEN_FORCE_MOBILE_UI=1 lets headless regression tests exercise the
	# touch HUD path on machines without a touchscreen.
	mobile_ui_enabled = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() \
		or OS.get_environment("ASHEN_FORCE_MOBILE_UI") == "1"
	_load_settings()
	
	# Initialize optimization modules
	liquid_sim = LiquidSim.new()
	liquid_sim.setup(Tile.WATER, Tile.LAVA, Tile.AIR, Tile.STONE)
	renderer_mgr = RendererManager.new()
	renderer_mgr.setup(TILE_SIZE, CHUNK_SIZE, WORLD_WIDTH, WORLD_HEIGHT, Tile.AIR)

	network_session = NETWORK_SESSION_SCRIPT.new()
	network_session.name = "NetworkSession"
	add_child(network_session)
	network_session.setup(self)
	network_session.status_changed.connect(_on_network_status_changed)
	network_session.roster_changed.connect(_on_network_roster_changed)
	network_session.latency_changed.connect(_on_network_latency_changed)
	network_session.chat_received.connect(_on_network_chat_received)
	network_session.session_started.connect(_on_network_roster_changed)
	network_session.session_stopped.connect(_on_network_session_stopped)
	_load_recent_network_addresses()
	
	_setup_texture_paths()
	_load_texture_assets()
	_setup_input_actions()
	_setup_camera()
	_setup_hud()
	_setup_audio()
	_generate_world()
	
	# Mark all chunks dirty for initial render
	renderer_mgr.mark_all_dirty()
	
	get_viewport().size_changed.connect(_on_window_size_changed)
	_apply_safe_area_insets()

	set_process(true)
	_startup_flow()


func _process(delta: float) -> void:
	if network_session != null:
		network_session.tick(delta)
		if network_session.is_server() and world_loaded:
			network_profile_regen_timer += delta
			if network_profile_regen_timer >= 1.0:
				network_profile_regen_timer = 0.0
				_network_update_remote_regeneration()
			network_autosave_timer += delta
			if network_autosave_timer >= 60.0:
				network_autosave_timer = 0.0
				_save_game()
				if dedicated_export_path != "":
					_export_world_file(dedicated_export_path)
		if network_session.is_dedicated() and dedicated_admin_path != "":
			dedicated_admin_timer += delta
			if dedicated_admin_timer >= 1.0:
				dedicated_admin_timer = 0.0
				_process_dedicated_admin_commands()
	_update_slot_longpress(delta)
	# Opening the pause menu must not freeze a shared server world. Player input
	# still stops in _physics_process, while the authoritative simulation runs.
	if in_main_menu or editing_ui or (game_paused and (network_session == null or not network_session.is_active())):
		return
	if network_session != null and network_session.is_dedicated() and not network_session.players.is_empty():
		var first_peer_id := int(network_session.players.keys()[0])
		var dedicated_target: Dictionary = network_session.players[first_peer_id]
		player_position = dedicated_target.get("pos", player_position)
	if debug_console_open:
		player_velocity = Vector2.ZERO
		_update_camera()
		_update_hud()
		queue_redraw()
		return
	# A very short freeze on confirmed hits gives contact weight without
	# changing cooldowns or balance. Camera feedback keeps running during it.
	if combat_hit_stop_timer > 0.0:
		combat_hit_stop_timer = maxf(0.0, combat_hit_stop_timer - delta)
		_update_camera()
		queue_redraw()
		return
	if Input.is_action_just_pressed("grapple") and _equipped_accessory_has("grapple"):
		_throw_grapple(get_global_mouse_position())
	if Input.is_action_just_pressed("toggle_build"):
		_toggle_build_panel()
	if Input.is_action_just_pressed("regen_world"):
		if liquid_sim != null:
			liquid_sim.clear()
		if renderer_mgr != null:
			renderer_mgr.mark_all_dirty()
		_generate_world()
		return
	if Input.is_action_just_pressed("save_world"):
		_save_game()
	if Input.is_action_just_pressed("load_world"):
		_load_game()
	if Input.is_action_just_pressed("toggle_journal"):
		_set_journal_open(not journal_open)
	if journal_open:
		player_velocity = Vector2.ZERO
		_update_hud()
		queue_redraw()
		return
	if not inventory_open and not full_map_open and Input.is_action_just_pressed("zoom_in"):
		_adjust_camera_zoom(0.14)
	if not inventory_open and not full_map_open and Input.is_action_just_pressed("zoom_out"):
		_adjust_camera_zoom(-0.14)
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_open and inventory_screen == "inventory":
			_close_inventory_screens()
		else:
			_open_inventory_screen("inventory")
	if Input.is_action_just_pressed("toggle_map"):
		_set_full_map_open(not full_map_open)
	if inventory_open and inventory_screen == "crafting" and Input.is_action_just_pressed("recipe_prev"):
		_select_recipe(-1)
	if inventory_open and inventory_screen == "crafting" and Input.is_action_just_pressed("recipe_next"):
		_select_recipe(1)
	if inventory_open and inventory_screen == "crafting" and Input.is_action_just_pressed("craft_item"):
		_craft_selected_recipe()
	if inventory_open and inventory_screen == "inventory" and Input.is_action_just_pressed("equip_item"):
		_equip_selected_item()
	if Input.is_action_just_pressed("attack"):
		_try_player_attack()

	var network_client: bool = network_session != null and network_session.is_client() and bool(network_session.joined)
	var dedicated_server: bool = network_session != null and network_session.is_dedicated()
	if not network_client:
		_update_day_night(delta)
		_update_storm_arc(delta)
	_update_weather(delta, not network_client, not dedicated_server)
	if not dedicated_server:
		_update_weather_player_effects(delta)
	_update_grapple(delta)
	if not dedicated_server:
		_update_player(delta)
	
	# The server owns liquids and world growth. Clients receive authoritative
	# terrain/entity updates and only predict their own movement.
	if liquid_sim != null and not network_client:
		var liquid_centers: Array[Vector2i] = []
		if not dedicated_server:
			liquid_centers.append(Vector2i(int(player_position.x / TILE_SIZE), int(player_position.y / TILE_SIZE)))
		if network_session != null and network_session.is_server():
			var liquid_peer_ids: Array = network_session.players.keys()
			liquid_peer_ids.sort()
			for peer_variant in liquid_peer_ids:
				var peer_id := int(peer_variant)
				if peer_id == 1:
					continue
				var remote_state: Dictionary = network_session.players.get(peer_id, {})
				if not remote_state.has("pos"):
					continue
				var remote_pos: Vector2 = remote_state.get("pos", Vector2.ZERO)
				liquid_centers.append(Vector2i(int(remote_pos.x / TILE_SIZE), int(remote_pos.y / TILE_SIZE)))
		if liquid_centers.is_empty():
			liquid_centers.append(Vector2i(int(player_position.x / TILE_SIZE), int(player_position.y / TILE_SIZE)))
		if liquid_sim.process_centers(delta, world, liquid_centers, solid_tiles) > 0:
			world_map_dirty = true
			_invalidate_world_tile_caches()
			var liquid_changes: Array = liquid_sim.consume_state_changes(world)
			for state_variant in liquid_changes:
				var state: Array = state_variant
				if renderer_mgr != null and state.size() >= 2:
					renderer_mgr.mark_chunk_dirty(int(state[0]), int(state[1]))
			if network_session != null and network_session.is_server():
				network_session.notify_liquid_states(liquid_changes)
	
	if not network_client:
		_update_saplings(delta)
	_update_biome_cache(delta)
	if not dedicated_server:
		_update_temperature(delta)
		_update_biome_audio()
		_update_selection()
		_handle_block_actions()
	if network_client:
		_update_network_client_combat(delta)
	else:
		_update_combat(delta)
	_update_regen(delta)
	_update_attack_animation(delta)
	_update_world_loot_and_fx(delta)
	_update_knowledge_observations(delta)
	_update_camera()
	_update_minimap(delta)
	hud_update_timer += delta
	if hud_update_timer >= 0.10:
		hud_update_timer = 0.0
		_update_hud()
	_update_boss_bar()
	_update_loot_feed()
	_update_held_item_preview()
	queue_redraw()


func _minimap_tap_zone_contains(screen_pos: Vector2) -> bool:
	# Only the circular lens itself opens the full map. A rectangular zone that
	# grows around the panel would swallow taps on the labels/buttons that sit
	# just below the minimap and open the map by accident.
	if minimap_panel == null or not minimap_panel.visible:
		return false
	var rect := minimap_panel.get_global_rect()
	var center := rect.get_center()
	var radius := rect.size.x * 0.5 + 12.0
	return center.distance_to(screen_pos) <= radius


func _input(event: InputEvent) -> void:
	if editing_ui:
		_ui_editor_input(event)
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			if path_dialog_open:
				_close_path_dialog()
			elif settings_panel != null and settings_panel.visible:
				_hide_settings()
			elif in_main_menu:
				pass
			else:
				_toggle_pause()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch and not full_map_open and not inventory_open and not journal_open:
		var st := event as InputEventScreenTouch
		if st.pressed and _minimap_tap_zone_contains(st.position):
			_toggle_map_from_ui()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey:
		var console_key := event as InputEventKey
		if console_key.pressed and not console_key.echo and (console_key.keycode == KEY_F1 or console_key.keycode == KEY_QUOTELEFT):
			_set_debug_console_open(not debug_console_open)
			get_viewport().set_input_as_handled()
			return
		if debug_console_open:
			if console_key.pressed and console_key.keycode == KEY_ESCAPE:
				_set_debug_console_open(false)
				get_viewport().set_input_as_handled()
			return
		if journal_open and console_key.pressed and console_key.keycode == KEY_ESCAPE:
			_set_journal_open(false)
			get_viewport().set_input_as_handled()
			return
		if console_key.pressed and not console_key.echo and console_key.physical_keycode == KEY_SPACE and noclip_unlocked:
			var now := Time.get_ticks_msec()
			if now - last_space_press_msec <= 360:
				_set_noclip_enabled(not noclip_enabled)
				last_space_press_msec = -10000
			else:
				last_space_press_msec = now
	_track_desktop_input(event)
	if inventory_open and event is InputEventMouseButton:
		var inventory_mouse_event := event as InputEventMouseButton
		if inventory_mouse_event.button_index == MOUSE_BUTTON_RIGHT and not inventory_mouse_event.pressed and pending_inventory_right_drop_id != "":
			if not pending_inventory_right_drop_consumed:
				_drop_inventory_item_to_world(pending_inventory_right_drop_id, 1)
			pending_inventory_right_drop_id = ""
			pending_inventory_right_drop_consumed = false
	if not inventory_open or held_item_id == "":
		return
	if event is InputEventMouseButton and not event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_release_held_item(mouse_event.position)


func _track_desktop_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return
		# physical_keycode is independent of the current keyboard language.
		if key_event.physical_keycode == KEY_A:
			physical_move_left_held = key_event.pressed
		elif key_event.physical_keycode == KEY_D:
			physical_move_right_held = key_event.pressed
		elif key_event.physical_keycode == KEY_W or key_event.physical_keycode == KEY_SPACE or key_event.physical_keycode == KEY_UP:
			physical_noclip_up_held = key_event.pressed
		elif key_event.physical_keycode == KEY_S or key_event.physical_keycode == KEY_DOWN:
			physical_noclip_down_held = key_event.pressed
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		# Touch emulation can drop the synthetic release when Android cancels
		# a gesture, which would leave mining stuck; only real mice count here.
		if mouse_event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_mine_held = mouse_event.pressed


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all_transient_input()
		_autopause_and_save()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		# Android onPause: the process may be killed at any moment afterwards,
		# so this is the last safe point to persist progress.
		_release_all_transient_input()
		_autopause_and_save()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_handle_application_resumed()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_begin_graceful_shutdown("Server is shutting down.")


func _release_all_transient_input() -> void:
	## Clears every held key/touch/pointer so nothing stays pressed across a
	## suspend, focus loss or menu transition.
	transient_input_release_count += 1
	physical_move_left_held = false
	physical_move_right_held = false
	physical_noclip_up_held = false
	physical_noclip_down_held = false
	mouse_mine_held = false
	_cancel_slot_longpress()
	if mobile_joystick != null and mobile_joystick.has_method("force_release"):
		mobile_joystick.force_release()
	for action_control in [jump_button, atk_button, grapple_button]:
		if action_control != null and action_control.has_method("force_release"):
			action_control.force_release()
	_release_mobile_actions()


func _handle_application_resumed() -> void:
	## Android onResume / focus regained: transient input must start from a
	## clean slate and cached surfaces must be repainted after a possible GL
	## context recreation.
	lifecycle_resume_count += 1
	_release_all_transient_input()
	_apply_safe_area_insets()
	if renderer_mgr != null:
		renderer_mgr.mark_all_dirty()
	queue_redraw()


func _force_server_save() -> bool:
	if not world_loaded or current_world_index < 0:
		return false
	_save_game()
	if dedicated_export_path != "":
		_export_world_file(dedicated_export_path)
	print("SERVER_SAVE_OK world=%d" % current_world_index)
	return true


func _begin_graceful_shutdown(reason := "Server is shutting down.") -> void:
	if graceful_shutdown_started:
		return
	graceful_shutdown_started = true
	_force_server_save()
	if network_session != null and network_session.is_server():
		var peer_ids: Array = network_session.players.keys()
		for peer_variant in peer_ids:
			var peer_id := int(peer_variant)
			if peer_id > 1:
				network_session.kick_peer(peer_id, reason)
		await get_tree().create_timer(0.3).timeout
		network_session.shutdown(reason)
	get_tree().quit()


func _autopause_and_save() -> void:
	if in_main_menu or not world_loaded:
		return
	if not game_paused:
		game_paused = true
		if pause_panel != null:
			pause_panel.visible = true
	# Focus-out and application-pause often arrive back to back; debounce so
	# a single suspend does not serialize the world twice in a row.
	var now := Time.get_ticks_msec()
	if now - last_background_save_msec < BACKGROUND_SAVE_DEBOUNCE_MSEC:
		return
	last_background_save_msec = now
	background_save_count += 1
	_save_game()


func _unhandled_input(event: InputEvent) -> void:
	if not _mobile_controls_enabled() or full_map_open or inventory_open or journal_open:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Tap on the minimap lens opens the full map (fallback for touch devices).
			if _minimap_tap_zone_contains(touch.position):
				_toggle_map_from_ui()
				get_viewport().set_input_as_handled()
				return
			var world_pos := get_canvas_transform().affine_inverse() * touch.position
			mobile_world_touch_index = touch.index
			_handle_mobile_world_press(world_pos)
			get_viewport().set_input_as_handled()
		elif touch.index == mobile_world_touch_index:
			mobile_world_touch_index = -1
			Input.action_release("mine")
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == mobile_world_touch_index:
			var world_pos := get_canvas_transform().affine_inverse() * drag.position
			mobile_target_tile = Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
			mobile_target_valid = _in_bounds(mobile_target_tile.x, mobile_target_tile.y)
			get_viewport().set_input_as_handled()


func _toggle_door(tile_pos: Vector2i) -> void:
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	if tile == Tile.DOOR:
		if network_session != null and network_session.is_server():
			_network_allow_direct_tile_change(1, tile_pos.x, tile_pos.y, Tile.AIR)
		_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
		_play_sound("hit")
	elif tile == Tile.AIR and _tile_has_support(tile_pos):
		if network_session != null and network_session.is_server():
			_network_allow_direct_tile_change(1, tile_pos.x, tile_pos.y, Tile.DOOR)
		_set_tile(tile_pos.x, tile_pos.y, Tile.DOOR)
		_play_sound("hit")


func _toggle_trapdoor(tile_pos: Vector2i) -> void:
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	if tile == Tile.TRAPDOOR:
		# Open: remove the tile so the player can fall through.
		if network_session != null and network_session.is_server():
			_network_allow_direct_tile_change(1, tile_pos.x, tile_pos.y, Tile.AIR)
		_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
		_play_sound("hit")
	elif tile == Tile.AIR:
		if network_session != null and network_session.is_server():
			_network_allow_direct_tile_change(1, tile_pos.x, tile_pos.y, Tile.TRAPDOOR)
		_set_tile(tile_pos.x, tile_pos.y, Tile.TRAPDOOR)
		_play_sound("hit")


func _tile_has_support(tile_pos: Vector2i) -> bool:
	# A door needs a floor under it (or a block below).
	return _is_solid(tile_pos.x, tile_pos.y + 1)


func _handle_mobile_world_press(world_pos: Vector2) -> void:
	mobile_target_tile = Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
	mobile_target_valid = _in_bounds(mobile_target_tile.x, mobile_target_tile.y)
	if not mobile_target_valid:
		_try_player_attack_at(world_pos)
		return
	if npc_wanderer_active and player_position.distance_to(npc_wanderer_pos) < 90.0:
		_open_path_dialog()
		return
	if _enemy_at_world_position(world_pos):
		_try_player_attack_at(world_pos)
		return
	var tile := _get_tile(mobile_target_tile.x, mobile_target_tile.y)
	if tile == Tile.DOOR:
		_toggle_door(mobile_target_tile)
		return
	if tile == Tile.TRAPDOOR:
		_toggle_trapdoor(mobile_target_tile)
		return
	if _can_interact(mobile_target_tile) and (tile == Tile.CHEST or tile == Tile.STONE_ALTAR or tile == Tile.SKY_OBELISK):
		_place_target_tile()
		return
	if _can_interact(mobile_target_tile) and tile != Tile.AIR and tile != Tile.WATER and tile != Tile.LAVA:
		Input.action_press("mine")
		return
	if _can_interact(mobile_target_tile) and tile == Tile.AIR and item_to_tile.has(_selected_item()):
		_place_target_tile()
		return
	_try_player_attack_at(world_pos)


func _enemy_at_world_position(world_pos: Vector2) -> bool:
	for enemy in enemies:
		if not _enemy_can_be_hit(enemy):
			continue
		var enemy_rect := _enemy_hitbox_rect(enemy)
		if enemy_rect.grow(10.0).has_point(world_pos):
			return true
	return false


func _draw() -> void:
	_collect_visible_light_sources()
	_draw_background()
	_draw_visible_world()
	_draw_combat_entities()
	_draw_world_loot_and_fx()
	_draw_player()
	_draw_network_players()
	_draw_attack_animation()
	_draw_weather()
	_draw_darkness_overlay()
	_draw_player_damage_flash()
	_draw_grapple()
	_draw_storm()
	_draw_perception_debug()
	_draw_target_cursor()
	_draw_wanderer_npc()
	_draw_sky_compass()


func _draw_storm() -> void:
	if not storm_active:
		return
	# Dark storm tint over the whole view
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var top_left := center - view_rect.size * 0.5 / camera.zoom
	var bottom_right := center + view_rect.size * 0.5 / camera.zoom
	draw_rect(Rect2(top_left, bottom_right - top_left), Color(0.02, 0.03, 0.09, 0.34))
	# Occasional lightning bolt somewhere in view
	if rng.randf() < 0.01:
		var bolt_x := center.x + rng.randf_range(-view_rect.size.x * 0.4, view_rect.size.x * 0.4)
		var bolt_y := center.y + rng.randf_range(-view_rect.size.y * 0.3, view_rect.size.y * 0.1)
		_draw_lightning(Vector2(bolt_x, bolt_y))
	# Tornado column
	if storm_tornado_phase != "":
		var tp := storm_tornado_pos
		var sway := sin(Time.get_ticks_msec() * 0.004) * 12.0
		var widths := [64.0, 50.0, 38.0, 26.0, 16.0]
		var alpha_vals := [0.13, 0.17, 0.21, 0.24, 0.26]
		for i in range(widths.size()):
			var y0: float = tp.y + 70.0 - float(i) * 52.0
			var w: float = widths[i]
			draw_rect(Rect2(tp.x + sway - w * 0.5, y0, w, 54.0), Color(0.55, 0.63, 0.78, alpha_vals[i]))
		# Debris streaks
		for k in range(5):
			var ox := tp.x + sway + rng.randf_range(-70.0, 70.0)
			var oy := tp.y + rng.randf_range(-30.0, 90.0)
			draw_line(Vector2(ox, oy), Vector2(ox + rng.randf_range(8.0, 26.0), oy - rng.randf_range(4.0, 18.0)),
				Color(0.7, 0.75, 0.85, 0.5), 2.0)


func _draw_lightning(start: Vector2) -> void:
	var pos := start
	var dir := Vector2(rng.randf_range(-0.5, 0.5), 1.0).normalized()
	var color := Color(0.92, 0.96, 1.0, 0.85)
	for seg in range(5):
		var next := pos + dir * rng.randf_range(14.0, 30.0) + Vector2(rng.randf_range(-14.0, 14.0), 0.0)
		draw_line(pos, next, color, 2.0)
		pos = next
		dir = Vector2(rng.randf_range(-0.5, 0.5), 1.0).normalized()


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.5, 2.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	add_child(camera)
	camera.make_current()


func _setup_texture_paths() -> void:
	tile_texture_paths = {
		Tile.GRASS: "res://assets/textures/tiles/grass.png",
		Tile.SNOW_BLOCK: "res://assets/textures/tiles/snow_block.png",
		Tile.DIRT: "res://assets/textures/tiles/dirt.png",
		Tile.STONE: "res://assets/textures/tiles/stone.png",
		Tile.COPPER: "res://assets/textures/tiles/copper.png",
		Tile.IRON: "res://assets/textures/tiles/iron.png",
		Tile.ASH: "res://assets/textures/tiles/ash.png",
		Tile.ROOT: "res://assets/textures/tiles/root.png",
		Tile.WOOD: "res://assets/textures/tiles/wood.png",
		Tile.LEAVES: "res://assets/textures/tiles/leaves.png",
		Tile.RUIN: "res://assets/textures/tiles/ruin.png",
		Tile.WORKBENCH: "res://assets/textures/tiles/workbench.png",
		Tile.FURNACE: "res://assets/textures/tiles/furnace.png",
		Tile.ANVIL: "res://assets/textures/tiles/anvil.png",
		Tile.TURRET: "res://assets/textures/tiles/turret.png",
		Tile.HEART: "res://assets/textures/tiles/heart.png",
		Tile.CHEST: "res://assets/textures/tiles/chest.png",
		Tile.STONE_ALTAR: "res://assets/textures/tiles/stone_altar.png",
		Tile.STONEBLOOD: "res://assets/textures/tiles/stoneblood.png",
		Tile.MOSS: "res://assets/textures/tiles/moss.png",
		Tile.MUSHROOM_SOIL: "res://assets/textures/tiles/mushroom_soil.png",
		Tile.GLOW_MUSHROOM: "res://assets/textures/tiles/glow_mushroom.png",
		Tile.ASH_BRICK: "res://assets/textures/tiles/ash_brick.png",
		Tile.SUNKEN_STONE: "res://assets/textures/tiles/sunken_stone.png",
		Tile.LAVA_ROOT: "res://assets/textures/tiles/lava_root.png",
		Tile.GLASS_STONE: "res://assets/textures/tiles/glass_stone.png",
		Tile.ABYSS_CRYSTAL: "res://assets/textures/tiles/abyss_crystal.png",
		Tile.WATER: "res://assets/textures/tiles/water.png",
		Tile.LAVA: "res://assets/textures/tiles/lava.png",
		Tile.SAPLING: "res://assets/textures/tiles/sapling.png",
		Tile.ASH_SAND: "res://assets/textures/tiles/ash_sand.png",
		Tile.FROZEN_DIRT: "res://assets/textures/tiles/frozen_dirt.png",
		Tile.MUD: "res://assets/textures/tiles/mud.png",
		Tile.RUBBLE: "res://assets/textures/tiles/rubble.png",
		Tile.DOOR: "res://assets/textures/tiles/door.png",
		Tile.PLATFORM: "res://assets/textures/tiles/platform.png",
		Tile.LADDER: "res://assets/textures/tiles/ladder.png",
		Tile.BED: "res://assets/textures/tiles/bed.png",
		Tile.FENCE: "res://assets/textures/tiles/fence.png",
		Tile.WINDOW: "res://assets/textures/tiles/window.png",
		Tile.TRAPDOOR: "res://assets/textures/tiles/trapdoor.png",
		Tile.ROPE: "res://assets/textures/tiles/rope.png",
		Tile.LANTERN: "res://assets/textures/tiles/lantern.png",
		Tile.TABLE: "res://assets/textures/tiles/table.png",
		Tile.CHAIR: "res://assets/textures/tiles/chair.png",
		Tile.DEPTH_ALTAR: "res://assets/textures/tiles/depth_altar.png",
		Tile.DEPTH_STONE: "res://assets/textures/tiles/depth_stone.png"
	}


func _load_texture_assets() -> void:
	tile_textures.clear()
	tile_texture_variants.clear()
	biome_tile_textures.clear()
	var surface_biome_ids := ["frost_wasteland", "marsh", "ash_desert", "ash_ruins"]
	var surface_tile_names := {Tile.GRASS: "grass", Tile.SNOW_BLOCK: "snow_block", Tile.DIRT: "dirt", Tile.STONE: "stone", Tile.LEAVES: "leaves", Tile.WOOD: "wood", Tile.MOSS: "moss"}
	for biome in surface_biome_ids:
		var biome_tiles: Dictionary = {}
		for tile in surface_tile_names.keys():
			var texture := _load_png_texture("res://assets/textures/biomes/%s/%s.png" % [biome, surface_tile_names[tile]])
			if texture != null:
				biome_tiles[int(tile)] = texture
		if not biome_tiles.is_empty():
			biome_tile_textures[biome] = biome_tiles
	for tile in tile_texture_paths.keys():
		var base_path := str(tile_texture_paths[tile])
		var variants: Array[Texture2D] = []
		for suffix in ["", "_1", "_2", "_3"]:
			var variant_path := base_path.replace(".png", "%s.png" % suffix)
			var texture: Texture2D = _load_png_texture(variant_path)
			if texture != null:
				variants.append(texture)
		if not variants.is_empty():
			tile_textures[tile] = variants[0]
			tile_texture_variants[tile] = variants
	for item_id in item_names.keys():
		var texture: Texture2D = _load_png_texture("res://assets/textures/items/%s.png" % str(item_id))
		if texture != null:
			item_icon_cache[str(item_id)] = texture
	enemy_textures.clear()
	enemy_sprite_ground_anchors.clear()
	for enemy_type in enemy_sprite_specs.keys():
		var texture: Texture2D = _load_png_texture("res://assets/textures/enemies/%s.png" % str(enemy_type))
		if texture != null:
			enemy_textures[str(enemy_type)] = texture
			var sprite_spec: Dictionary = enemy_sprite_specs[enemy_type]
			var frame_size: Vector2i = sprite_spec.get("frame", Vector2i(32, 32))
			var idle_row := int(sprite_spec.get("idle_row", 0))
			var idle_frames := int(sprite_spec.get("idle_frames", 1))
			enemy_sprite_ground_anchors[str(enemy_type)] = _opaque_bottom_anchor(texture, frame_size.x, frame_size.y, idle_frames, idle_row * frame_size.y)
	enemy_animation_textures.clear()
	enemy_animation_specs.clear()
	enemy_animation_pack_specs.clear()
	_load_enemy_animation_pack("wild_slime", "res://assets/textures/enemies/anims/wild_slime/wild_slime_anim.json")
	_load_enemy_animation_pack("mossling", "res://assets/textures/enemies/anims/mossling/mossling_anim.json")
	_load_enemy_animation_pack("root_crawler", "res://assets/textures/enemies/anims/root_crawler/rootcrawler_anim.json")
	_load_enemy_animation_pack("cave_worm", "res://assets/textures/enemies/anims/cave_worm/cave_worm_anim.json")
	_load_enemy_animation_pack("bat", "res://assets/textures/enemies/anims/bat/bat_anim.json")
	_load_enemy_animation_pack("spore_bat", "res://assets/textures/enemies/anims/spore_bat/spore_bat_anim.json")
	_load_enemy_animation_pack("cave_husk", "res://assets/textures/enemies/anims/cave_husk/cave_husk_anim.json")
	_load_enemy_animation_pack("mushroom_beetle", "res://assets/textures/enemies/anims/mushroom_beetle/mushroom_beetle_anim.json")
	_load_enemy_animation_pack("ash_phantom", "res://assets/textures/enemies/anims/ash_phantom/ash_phantom_anim.json")
	_load_enemy_animation_pack("ash_wisp", "res://assets/textures/enemies/anims/ash_wisp/ash_wisp_anim.json")
	_load_enemy_animation_pack("ash_sentinel", "res://assets/textures/enemies/anims/ash_sentinel/ash_sentinel_anim.json")
	_load_enemy_animation_pack("drowned_guard", "res://assets/textures/enemies/anims/drowned_guard/drowned_guard_anim.json")
	_load_enemy_animation_pack("ember_rootling", "res://assets/textures/enemies/anims/ember_rootling/ember_rootling_anim.json")
	_load_enemy_animation_pack("glass_wraith", "res://assets/textures/enemies/anims/glass_wraith/glass_wraith_anim.json")
	_load_enemy_animation_pack("night_ember", "res://assets/textures/enemies/anims/night_ember/night_ember_anim.json")
	_load_enemy_animation_pack("ruin_drone", "res://assets/textures/enemies/anims/ruin_drone/ruin_drone_anim.json")
	_load_enemy_animation_pack("stone_beast", "res://assets/textures/enemies/anims/stone_beast/stone_beast_anim.json")
	_load_enemy_visual_variant("frost_wild_slime", "wild_slime", "res://assets/textures/enemies/anims/wild_slime/frost_variant.png", "res://assets/textures/enemies/anims/wild_slime/frost_variant/wild_slime_anim.json")
	_load_enemy_visual_variant("desert_wild_slime", "wild_slime", "res://assets/textures/enemies/anims/wild_slime/desert_variant.png", "res://assets/textures/enemies/anims/wild_slime/desert_variant/wild_slime_anim.json")
	_load_enemy_visual_variant("frost_bat", "bat", "res://assets/textures/enemies/anims/bat/frost_variant.png", "res://assets/textures/enemies/anims/bat/frost_variant/bat_anim.json")
	if USE_EXTERNAL_ENEMY_ANIMATION_STRIPS:
		var animation_states := {
			"root_crawler": ["idle", "move", "attack_1", "attack_2", "attack_3", "death"],
			"cave_worm": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"bat": ["idle", "move", "attack_1", "attack_2", "hurt", "death"],
			"cave_husk": ["idle", "move", "attack_1", "attack_2", "attack_3", "death"],
			"spore_bat": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"mushroom_beetle": ["idle", "move", "attack_1", "attack_2", "attack_3", "attack_4", "hurt", "death"],
			"ash_phantom": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"ash_wisp": ["idle", "move", "attack_1", "attack_2", "hurt", "death"],
			"ash_sentinel": ["idle", "move", "attack_1", "attack_2", "attack_3", "attack_4", "hurt", "death"],
			"ruin_drone": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"drowned_guard": ["idle", "move", "attack_1", "attack_2", "attack_3", "attack_4", "hurt", "death"],
			"ember_rootling": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"night_ember": ["idle", "move", "attack_1", "attack_2", "attack_3", "hurt", "death"],
			"glass_wraith": ["idle", "move", "attack_1", "attack_2", "attack_3", "attack_4", "hurt", "death"],
			"stone_beast": ["idle", "move", "attack_1", "attack_2", "attack_3", "attack_4", "attack_5", "attack_6", "hurt", "death"],
			"heartwood_boss": ["idle", "move", "spawn", "phase_2", "attack_1", "attack_2", "attack_3", "attack_4", "attack_5", "attack_6", "hurt", "death"]
		}
		for enemy_type in animation_states.keys():
			var state_textures: Dictionary = {}
			for state in animation_states[enemy_type]:
				var anim_texture := _load_png_texture("res://assets/textures/enemies/anims/%s_%s.png" % [str(enemy_type), str(state)])
				if anim_texture != null:
					state_textures[str(state)] = anim_texture
			if not state_textures.is_empty():
				enemy_animation_textures[str(enemy_type)] = state_textures
	player_texture = _load_png_texture("res://assets/textures/player.png")

	# Bosses reuse existing packs. Share textures AND the animation specs +
	# pack metadata: without the specs the renderer sliced the strips with
	# the default 6-frame grid, which distorted the shared boss sprites.
	for boss_alias in [["storm_herald", "glass_wraith"], ["leviathan", "glass_wraith"], ["sky_herald", "glass_wraith"], ["depth_warden", "stone_beast"]]:
		var alias := str(boss_alias[0])
		var source := str(boss_alias[1])
		if enemy_textures.has(source):
			enemy_textures[alias] = enemy_textures[source]
			enemy_animation_textures[alias] = enemy_animation_textures.get(source, {})
			enemy_animation_specs[alias] = enemy_animation_specs.get(source, {})
			enemy_animation_pack_specs[alias] = enemy_animation_pack_specs.get(source, {})
			if enemy_sprite_ground_anchors.has(source):
				enemy_sprite_ground_anchors[alias] = enemy_sprite_ground_anchors[source]


func _load_png_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


func _load_enemy_visual_variant(variant_type: String, base_type: String, texture_path: String, animation_json_path: String) -> void:
	var texture: Texture2D = _load_png_texture(texture_path)
	if texture == null or not enemy_sprite_specs.has(base_type):
		return
	enemy_textures[variant_type] = texture
	enemy_sprite_specs[variant_type] = enemy_sprite_specs[base_type].duplicate(true)
	var base_spec: Dictionary = enemy_sprite_specs[variant_type]
	var frame_size: Vector2i = base_spec.get("frame", Vector2i(32, 32))
	var idle_row := int(base_spec.get("idle_row", 0))
	var idle_frames := int(base_spec.get("idle_frames", 1))
	enemy_sprite_ground_anchors[variant_type] = _opaque_bottom_anchor(texture, frame_size.x, frame_size.y, idle_frames, idle_row * frame_size.y)
	_load_enemy_animation_pack(variant_type, animation_json_path)


func _load_enemy_animation_pack(enemy_type: String, json_path: String) -> void:
	if not FileAccess.file_exists(json_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not parsed is Dictionary:
		push_warning("Invalid enemy animation metadata: %s" % json_path)
		return
	var pack: Dictionary = parsed
	var animations: Dictionary = pack.get("animations", {})
	var textures: Dictionary = {}
	var specs: Dictionary = {}
	var pack_dir := json_path.get_base_dir()
	for state_key in animations.keys():
		var state := str(state_key)
		var metadata: Dictionary = animations[state_key]
		var filename := str(metadata.get("file", ""))
		if filename == "":
			continue
		var texture := _load_png_texture(pack_dir.path_join(filename))
		if texture == null:
			push_warning("Missing enemy animation texture: %s" % filename)
			continue
		textures[state] = texture
		specs[state] = metadata.duplicate(true)
	if not textures.is_empty():
		enemy_animation_textures[enemy_type] = textures
		enemy_animation_specs[enemy_type] = specs
		enemy_animation_pack_specs[enemy_type] = pack.duplicate(true)
		if textures.has("idle"):
			var idle_spec: Dictionary = specs.get("idle", {})
			var idle_texture: Texture2D = textures["idle"]
			var idle_frames := maxi(1, int(idle_spec.get("frames", 1)))
			var idle_frame_width := maxi(1, int(idle_texture.get_width() / idle_frames))
			var pack_anchor: Variant = pack.get("anchor", null)
			if pack_anchor is Dictionary:
				enemy_sprite_ground_anchors[enemy_type] = float((pack_anchor as Dictionary).get("y", idle_texture.get_height()))
			else:
				enemy_sprite_ground_anchors[enemy_type] = _opaque_bottom_anchor(idle_texture, idle_frame_width, idle_texture.get_height(), idle_frames)


func _opaque_bottom_anchor(texture: Texture2D, frame_width: int, frame_height: int, frame_count: int, source_y := 0) -> float:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return float(frame_height)
	var bottom := -1
	var safe_frames := maxi(1, mini(frame_count, int(image.get_width() / maxi(1, frame_width))))
	for frame_index in range(safe_frames):
		var source_x := frame_index * frame_width
		for y in range(frame_height):
			for x in range(frame_width):
				if image.get_pixel(source_x + x, source_y + y).a > 0.04:
					bottom = maxi(bottom, y)
	return float(bottom + 1) if bottom >= 0 else float(frame_height)


func _enemy_animation_spec(enemy_type: String, state: String) -> Dictionary:
	var type_specs: Dictionary = enemy_animation_specs.get(enemy_type, {})
	return type_specs.get(state, {})


func _enemy_animation_visual_state(enemy_type: String, requested_state: String) -> String:
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	if animation_sets.has(requested_state):
		return requested_state
	var pack: Dictionary = enemy_animation_pack_specs.get(enemy_type, {})
	var state_fallbacks: Dictionary = pack.get("state_fallbacks", {})
	var fallback_state := str(state_fallbacks.get(requested_state, requested_state))
	if animation_sets.has(fallback_state):
		return fallback_state
	return requested_state


func _enemy_animation_ground_clearance(enemy_type: String) -> float:
	var pack: Dictionary = enemy_animation_pack_specs.get(enemy_type, {})
	return maxf(0.0, float(pack.get("ground_clearance", 0.0)))


func _enemy_animation_anchor(enemy_type: String, frame_size: Vector2) -> Vector2:
	var pack: Dictionary = enemy_animation_pack_specs.get(enemy_type, {})
	var anchor: Variant = pack.get("anchor", null)
	if anchor is Dictionary:
		var anchor_data: Dictionary = anchor
		return Vector2(float(anchor_data.get("x", frame_size.x * 0.5)), float(anchor_data.get("y", frame_size.y)))
	return frame_size * 0.5


func _enemy_animation_state_anchor(enemy_type: String, state: String, frame_size: Vector2) -> Vector2:
	var spec := _enemy_animation_spec(enemy_type, state)
	var anchor: Variant = spec.get("anchor", null)
	if anchor is Dictionary:
		var anchor_data: Dictionary = anchor
		return Vector2(float(anchor_data.get("x", frame_size.x * 0.5)), float(anchor_data.get("y", frame_size.y * 0.5)))
	return _enemy_animation_anchor(enemy_type, frame_size)


func _enemy_animation_attack_event_key(spec: Dictionary) -> String:
	if spec.has("projectile_frames"):
		return "projectile_frames"
	if spec.has("laser_start_frames"):
		return "laser_start_frames"
	return "hit_frames"


func _enemy_animation_duration(enemy_type: String, state: String, fallback: float) -> float:
	var spec := _enemy_animation_spec(enemy_type, state)
	if spec.is_empty():
		return fallback
	var fps := maxf(1.0, float(spec.get("fps", 1.0)))
	return float(maxi(1, int(spec.get("frames", 1)))) / fps


func _enemy_animation_event_time(enemy_type: String, state: String, event_key: String, fallback: float) -> float:
	var spec := _enemy_animation_spec(enemy_type, state)
	var event_frames: Array = spec.get(event_key, [])
	if event_frames.is_empty():
		return fallback
	return float(int(event_frames[0])) / maxf(1.0, float(spec.get("fps", 1.0)))


func _enemy_attack_recovery(enemy_type: String, attack_index: int) -> float:
	var state := "attack_%d" % attack_index
	var spec := _enemy_animation_spec(enemy_type, state)
	var event_key := _enemy_animation_attack_event_key(spec)
	var event_time := _enemy_animation_event_time(enemy_type, state, event_key, 0.0)
	return maxf(0.08, _enemy_animation_duration(enemy_type, state, 0.24) - event_time)


func _startup_flow() -> void:
	_load_worlds_meta()
	_migrate_legacy_save()
	_refresh_worlds_list()
	_show_main_menu()
	if "--dedicated" in OS.get_cmdline_user_args():
		_start_dedicated_server_from_args.call_deferred()


func _start_dedicated_server_from_args() -> void:
	var options := _network_command_line_options()
	var world_index := int(options.get("world", "0"))
	var found_meta := not _world_meta(world_index).is_empty()
	if not found_meta:
		worlds_meta.append({
			"index": world_index,
			"name": str(options.get("name", "Dedicated World")),
			"seed": int(Time.get_unix_time_from_system()) % 1000000000,
			"time": int(Time.get_unix_time_from_system())
		})
		_save_worlds_meta()
	current_world_index = world_index
	current_world_name = str(_world_meta(world_index).get("name", "Dedicated World"))
	var import_path := str(options.get("import", ""))
	if import_path != "" and not _import_world_file(import_path, world_index):
		push_error("DEDICATED_IMPORT_FAILED %s" % import_path)
		get_tree().quit(3)
		return
	if FileAccess.file_exists(_world_path(world_index)):
		_load_game_from_path(_world_path(world_index))
	else:
		seed = int(_world_meta(world_index).get("seed", randi()))
		_generate_world()
		_save_game()
	world_loaded = true
	_hide_main_menu()
	if multiplayer_panel != null:
		multiplayer_panel.visible = false
	var port := clampi(int(options.get("port", str(NETWORK_SESSION_SCRIPT.DEFAULT_PORT))), 1, 65535)
	var pvp_text := str(options.get("pvp", "false")).to_lower()
	var enable_pvp := pvp_text in ["1", "true", "yes", "on"]
	var result: int = int(network_session.host_server(
		port,
		str(options.get("password", "")),
		str(options.get("name", current_world_name)),
		"SERVER",
		enable_pvp,
		true
	))
	if result != OK:
		push_error("DEDICATED_SERVER_FAILED %s" % network_session.last_error)
		get_tree().quit(2)
		return
	dedicated_export_path = str(options.get("export", ""))
	if dedicated_export_path != "":
		_export_world_file(dedicated_export_path)
	dedicated_admin_path = str(options.get("admin", ""))
	if dedicated_admin_path != "":
		var admin_file := FileAccess.open(dedicated_admin_path, FileAccess.WRITE)
		if admin_file == null:
			push_warning("DEDICATED_ADMIN_FILE_FAILED %s" % dedicated_admin_path)
			dedicated_admin_path = ""
		else:
			admin_file.store_string("")
			print("DEDICATED_ADMIN_FILE_READY %s" % dedicated_admin_path)
	print("DEDICATED_SERVER_READY port=%d world=%d mode=%s" % [port, world_index, "pvp" if enable_pvp else "pve"])


func _network_command_line_options() -> Dictionary:
	var out: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		out[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return out


func _process_dedicated_admin_commands() -> void:
	if dedicated_admin_path == "" or not FileAccess.file_exists(dedicated_admin_path):
		return
	var contents := FileAccess.get_file_as_string(dedicated_admin_path)
	if contents.strip_edges() == "":
		return
	var clear_file := FileAccess.open(dedicated_admin_path, FileAccess.WRITE)
	if clear_file == null:
		push_warning("Could not clear dedicated admin command file.")
		return
	clear_file.store_string("")
	for line_variant in contents.split("\n"):
		var line := str(line_variant).strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		_execute_dedicated_admin_command(line)


func _execute_dedicated_admin_command(line: String) -> void:
	var parts := line.split(" ", false, 1)
	var command := str(parts[0]).to_upper()
	var argument := str(parts[1]).strip_edges() if parts.size() > 1 else ""
	match command:
		"STATUS":
			print("SERVER_STATUS %s" % JSON.stringify({"players": network_session.players, "bans": network_session.ban_count(), "diagnostics": network_session.get_diagnostics()}))
		"SAVE", "FORCE_SAVE":
			print("ADMIN_SAVE_OK" if _force_server_save() else "ADMIN_SAVE_FAILED")
		"KICK":
			if argument.is_valid_int():
				network_session.kick_peer(int(argument), "Removed by server administrator.")
				print("ADMIN_KICK peer=%s" % argument)
			else:
				push_warning("ADMIN_KICK requires a numeric peer id.")
		"BAN":
			if argument.is_valid_int() and network_session.ban_peer(int(argument), "Banned by server administrator."):
				print("ADMIN_BAN peer=%s" % argument)
			else:
				push_warning("ADMIN_BAN requires a connected numeric peer id.")
		"CLEAR_BANS":
			print("ADMIN_CLEAR_BANS removed=%d" % int(network_session.clear_bans()))
		"SHUTDOWN":
			_begin_graceful_shutdown(argument if argument != "" else "Server administrator requested shutdown.")
		_:
			push_warning("Unknown dedicated admin command: %s" % command)


func _setup_build_panel(canvas: CanvasLayer) -> void:
	build_panel = PanelContainer.new()
	build_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	build_panel.z_index = 80
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0b0e13", 0.92)
	build_panel.add_theme_stylebox_override("panel", bg)
	build_panel.visible = false
	canvas.add_child(build_panel)

	var inner := Control.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_panel.add_child(inner)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -300
	box.offset_top = -240
	box.offset_right = 300
	box.offset_bottom = 260
	box.add_theme_constant_override("separation", 12)
	inner.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "BUILD  —  SELECT WHAT TO PLACE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("f2a33a"))
	header.add_child(title)
	var close_btn := _make_compass_action_button("X")
	close_btn.custom_minimum_size = Vector2(40, 30)
	close_btn.pressed.connect(_toggle_build_panel)
	header.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	box.add_child(scroll)
	build_grid = GridContainer.new()
	build_grid.columns = 4
	build_grid.add_theme_constant_override("h_separation", 10)
	build_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(build_grid)

	var hint := Label.new()
	hint.text = "TAP A STRUCTURE TO SELECT. PLACE WITH RMB / TAP ON THE WORLD."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", ui_pixel_font)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color("99a4b0"))
	box.add_child(hint)
	_refresh_build_grid()


func _refresh_build_grid() -> void:
	if build_grid == null:
		return
	for child in build_grid.get_children():
		build_grid.remove_child(child)
		child.queue_free()
	for bid in build_catalog.keys():
		var def: Dictionary = build_catalog[bid]
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(120, 120)
		cell.add_theme_constant_override("separation", 4)
		var btn := _make_compass_action_button("")
		btn.custom_minimum_size = Vector2(90, 90)
		btn.icon = _item_icon(str(bid))
		btn.expand_icon = true
		btn.pressed.connect(_select_build_entry.bind(str(bid)))
		cell.add_child(btn)
		var name_label := Label.new()
		name_label.text = str(def.get("name", bid))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", ui_pixel_font)
		name_label.add_theme_font_size_override("font_size", 7)
		name_label.add_theme_color_override("font_color", Color("e8edf2"))
		cell.add_child(name_label)
		var cost_label := Label.new()
		var cost_parts: Array[String] = []
		var cost: Dictionary = def.get("cost", {})
		for item_id in cost.keys():
			cost_parts.append("%sx%d" % [str(item_id).substr(0, 1).to_upper(), int(cost[item_id])])
		cost_label.text = " ".join(cost_parts)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_override("font", ui_pixel_font)
		cost_label.add_theme_font_size_override("font_size", 7)
		cost_label.add_theme_color_override("font_color", Color("99a4b0"))
		cell.add_child(cost_label)
		build_grid.add_child(cell)


func _toggle_build_panel() -> void:
	if inventory_open or full_map_open or journal_open or in_main_menu or game_paused:
		if build_panel != null and build_panel.visible:
			build_panel.visible = false
		return
	if build_panel == null:
		return
	if int(inventory.get("blueprint", 0)) <= 0:
		last_message = "You need a Blueprint to build. Craft one at a workbench."
		_toast_message(last_message, 4.0)
		return
	build_panel.visible = not build_panel.visible
	if build_panel.visible:
		_refresh_build_grid()


func _select_build_entry(bid: String) -> void:
	if not build_catalog.has(bid):
		return
	active_build_id = bid
	if build_panel != null:
		build_panel.visible = false
	last_message = "Build: %s. Place with RMB / tap on the world." % str(build_catalog[bid].get("name", bid))
	_toast_message(last_message, 3.0)


func _setup_main_menu(canvas: CanvasLayer) -> void:
	# Backdrop dims the world behind the menu
	main_menu_panel = PanelContainer.new()
	main_menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	main_menu_panel.z_index = 90
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("0b0e13", 0.92)
	main_menu_panel.add_theme_stylebox_override("panel", bg_style)
	canvas.add_child(main_menu_panel)

	var menu_inner := Control.new()
	menu_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu_panel.add_child(menu_inner)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -240
	center.offset_top = -230
	center.offset_right = 240
	center.offset_bottom = 240
	center.add_theme_constant_override("separation", 14)
	menu_inner.add_child(center)

	var title := Label.new()
	title.text = "SHADOWGROVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f2a33a"))
	center.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "WORLDS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", ui_pixel_font)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color("99a4b0"))
	center.add_child(subtitle)

	var worlds_frame := _make_inner_panel()
	worlds_frame.custom_minimum_size = Vector2(0, 150)
	center.add_child(worlds_frame)
	worlds_list_box = VBoxContainer.new()
	worlds_list_box.add_theme_constant_override("separation", 6)
	worlds_frame.add_child(worlds_list_box)

	# New world row
	var new_row := HBoxContainer.new()
	new_row.add_theme_constant_override("separation", 8)
	center.add_child(new_row)
	new_world_name_edit = LineEdit.new()
	new_world_name_edit.placeholder_text = "World name..."
	new_world_name_edit.custom_minimum_size = Vector2(220, 30)
	new_world_name_edit.add_theme_font_override("font", ui_pixel_font)
	new_world_name_edit.add_theme_font_size_override("font_size", 9)
	new_row.add_child(new_world_name_edit)
	var create_btn := _make_compass_action_button("CREATE")
	create_btn.custom_minimum_size = Vector2(120, 30)
	create_btn.pressed.connect(_on_create_world_pressed)
	new_row.add_child(create_btn)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(bottom_row)
	var multiplayer_btn := _make_compass_action_button("MULTIPLAYER")
	multiplayer_btn.pressed.connect(_show_multiplayer_panel)
	bottom_row.add_child(multiplayer_btn)
	var settings_btn := _make_compass_action_button("SETTINGS")
	settings_btn.pressed.connect(_show_settings)
	bottom_row.add_child(settings_btn)

	# Settings panel (hidden initially)
	settings_panel = PanelContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_panel.z_index = 95
	var s_style := StyleBoxFlat.new()
	s_style.bg_color = Color("0b0e13", 0.38)
	settings_panel.add_theme_stylebox_override("panel", s_style)
	settings_panel.visible = false
	canvas.add_child(settings_panel)
	var settings_inner := Control.new()
	settings_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_panel.add_child(settings_inner)
	var settings_box := VBoxContainer.new()
	settings_box.set_anchors_preset(Control.PRESET_CENTER)
	settings_box.offset_left = -200
	settings_box.offset_top = -140
	settings_box.offset_right = 200
	settings_box.offset_bottom = 160
	settings_box.add_theme_constant_override("separation", 16)
	settings_inner.add_child(settings_box)
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_override("font", ui_pixel_font)
	settings_title.add_theme_font_size_override("font_size", 14)
	settings_title.add_theme_color_override("font_color", Color("f2a33a"))
	settings_box.add_child(settings_title)
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 10)
	settings_box.add_child(volume_row)
	var volume_label := Label.new()
	volume_label.text = "VOLUME"
	volume_label.add_theme_font_override("font", ui_pixel_font)
	volume_label.add_theme_font_size_override("font_size", 8)
	volume_label.custom_minimum_size = Vector2(90, 24)
	volume_row.add_child(volume_label)
	settings_volume_slider = HSlider.new()
	settings_volume_slider.min_value = 0.0
	settings_volume_slider.max_value = 1.0
	settings_volume_slider.step = 0.05
	settings_volume_slider.value = settings_volume
	settings_volume_slider.custom_minimum_size = Vector2(180, 24)
	settings_volume_slider.value_changed.connect(_on_settings_volume_changed)
	volume_row.add_child(settings_volume_slider)
	settings_volume_value = Label.new()
	settings_volume_value.text = "%d%%" % int(round(settings_volume * 100.0))
	settings_volume_value.custom_minimum_size = Vector2(52, 24)
	settings_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	settings_volume_value.add_theme_font_override("font", ui_pixel_font)
	settings_volume_value.add_theme_font_size_override("font_size", 8)
	volume_row.add_child(settings_volume_value)
	var edit_ui_btn := _make_compass_action_button("EDIT UI LAYOUT")
	edit_ui_btn.pressed.connect(_start_ui_editor)
	settings_box.add_child(edit_ui_btn)
	var reset_ui_btn := _make_compass_action_button("RESET UI")
	reset_ui_btn.pressed.connect(_reset_ui_layout)
	settings_box.add_child(reset_ui_btn)
	var back_btn := _make_compass_action_button("BACK")
	back_btn.pressed.connect(_hide_settings)
	settings_box.add_child(back_btn)

	# Pause panel
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.z_index = 85
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color("0b0e13", 0.8)
	pause_panel.add_theme_stylebox_override("panel", p_style)
	pause_panel.visible = false
	canvas.add_child(pause_panel)
	var pause_inner := Control.new()
	pause_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(pause_inner)
	var pause_box := VBoxContainer.new()
	pause_box.set_anchors_preset(Control.PRESET_CENTER)
	pause_box.offset_left = -190
	pause_box.offset_top = -260
	pause_box.offset_right = 190
	pause_box.offset_bottom = 260
	pause_box.add_theme_constant_override("separation", 10)
	pause_inner.add_child(pause_box)
	var pause_title := Label.new()
	pause_title.text = "PAUSED"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_override("font", ui_pixel_font)
	pause_title.add_theme_font_size_override("font_size", 16)
	pause_title.add_theme_color_override("font_color", Color("f2a33a"))
	pause_box.add_child(pause_title)
	var resume_btn := _make_compass_action_button("RESUME")
	resume_btn.pressed.connect(_toggle_pause)
	pause_box.add_child(resume_btn)
	var save_btn := _make_compass_action_button("SAVE")
	save_btn.pressed.connect(func() -> void: _save_game(); last_message = "Game saved.")
	pause_box.add_child(save_btn)
	pause_pvp_button = _make_compass_action_button("SERVER MODE: PVE")
	pause_pvp_button.visible = false
	pause_pvp_button.pressed.connect(_toggle_network_pvp_mode)
	pause_box.add_child(pause_pvp_button)
	pause_admin_row = HBoxContainer.new()
	pause_admin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_admin_row.add_theme_constant_override("separation", 6)
	pause_admin_row.visible = false
	pause_box.add_child(pause_admin_row)
	var force_save_btn := _make_compass_action_button("FORCE SAVE")
	force_save_btn.custom_minimum_size = Vector2(108, 28)
	force_save_btn.add_theme_font_size_override("font_size", 7)
	force_save_btn.pressed.connect(_on_force_server_save)
	pause_admin_row.add_child(force_save_btn)
	var clear_bans_btn := _make_compass_action_button("CLEAR BANS")
	clear_bans_btn.custom_minimum_size = Vector2(108, 28)
	clear_bans_btn.add_theme_font_size_override("font_size", 7)
	clear_bans_btn.pressed.connect(_clear_network_bans)
	pause_admin_row.add_child(clear_bans_btn)
	var copy_host_btn := _make_compass_action_button("COPY HOST IP")
	copy_host_btn.custom_minimum_size = Vector2(120, 28)
	copy_host_btn.add_theme_font_size_override("font_size", 7)
	copy_host_btn.pressed.connect(_copy_host_address)
	pause_admin_row.add_child(copy_host_btn)
	var players_scroll := ScrollContainer.new()
	players_scroll.custom_minimum_size = Vector2(0, 116)
	players_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	players_scroll.visible = false
	pause_box.add_child(players_scroll)
	pause_players_box = VBoxContainer.new()
	pause_players_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_players_box.add_theme_constant_override("separation", 4)
	players_scroll.add_child(pause_players_box)
	pause_players_box.set_meta("scroll", players_scroll)
	network_chat_log_label = RichTextLabel.new()
	network_chat_log_label.custom_minimum_size = Vector2(0, 66)
	network_chat_log_label.bbcode_enabled = false
	network_chat_log_label.scroll_active = true
	network_chat_log_label.scroll_following = true
	network_chat_log_label.fit_content = false
	network_chat_log_label.add_theme_font_override("normal_font", ui_pixel_font)
	network_chat_log_label.add_theme_font_size_override("normal_font_size", 7)
	network_chat_log_label.visible = false
	pause_box.add_child(network_chat_log_label)
	var chat_row := HBoxContainer.new()
	chat_row.add_theme_constant_override("separation", 6)
	chat_row.visible = false
	pause_box.add_child(chat_row)
	network_chat_edit = LineEdit.new()
	network_chat_edit.placeholder_text = "Message…"
	network_chat_edit.max_length = 160
	network_chat_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_chat_edit.add_theme_font_override("font", ui_pixel_font)
	network_chat_edit.add_theme_font_size_override("font_size", 7)
	network_chat_edit.text_submitted.connect(func(_text: String) -> void: _send_network_chat())
	chat_row.add_child(network_chat_edit)
	var chat_send_btn := _make_compass_action_button("SEND")
	chat_send_btn.custom_minimum_size = Vector2(72, 30)
	chat_send_btn.add_theme_font_size_override("font_size", 7)
	chat_send_btn.pressed.connect(_send_network_chat)
	chat_row.add_child(chat_send_btn)
	network_chat_log_label.set_meta("row", chat_row)
	var pause_settings_btn := _make_compass_action_button("SETTINGS")
	pause_settings_btn.pressed.connect(_show_settings)
	pause_box.add_child(pause_settings_btn)
	var quit_btn := _make_compass_action_button("TO MENU")
	quit_btn.pressed.connect(_quit_to_menu)
	pause_box.add_child(quit_btn)

	_setup_multiplayer_panel(canvas)


func _setup_multiplayer_panel(canvas: CanvasLayer) -> void:
	multiplayer_panel = PanelContainer.new()
	multiplayer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	multiplayer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	multiplayer_panel.z_index = 98
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color("080b10", 0.96)
	multiplayer_panel.add_theme_stylebox_override("panel", backdrop)
	multiplayer_panel.visible = false
	canvas.add_child(multiplayer_panel)

	var inner := Control.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	multiplayer_panel.add_child(inner)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -310
	box.offset_top = -310
	box.offset_right = 310
	box.offset_bottom = 315
	box.add_theme_constant_override("separation", 9)
	inner.add_child(box)

	var title := Label.new()
	title.text = "MULTIPLAYER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("f2a33a"))
	box.add_child(title)
	var hint := Label.new()
	hint.text = "DIRECT INTERNET / HOTSPOT  •  UP TO 8 PLAYERS"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", ui_pixel_font)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color("99a4b0"))
	box.add_child(hint)

	var form := _make_inner_panel()
	form.custom_minimum_size = Vector2(0, 330)
	box.add_child(form)
	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 7)
	form.add_child(fields)

	var player_row := HBoxContainer.new()
	fields.add_child(player_row)
	var player_label := _network_form_label("PLAYER")
	player_row.add_child(player_label)
	multiplayer_name_edit = _network_form_edit("Wanderer")
	player_row.add_child(multiplayer_name_edit)

	var server_row := HBoxContainer.new()
	fields.add_child(server_row)
	var server_label := _network_form_label("SERVER")
	server_row.add_child(server_label)
	multiplayer_server_name_edit = _network_form_edit("Shadowgrove Server")
	server_row.add_child(multiplayer_server_name_edit)

	var world_row := HBoxContainer.new()
	fields.add_child(world_row)
	var world_label := _network_form_label("HOST WORLD")
	world_row.add_child(world_label)
	multiplayer_world_selector = OptionButton.new()
	multiplayer_world_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	multiplayer_world_selector.custom_minimum_size = Vector2(0, 30)
	multiplayer_world_selector.add_theme_font_override("font", ui_pixel_font)
	multiplayer_world_selector.add_theme_font_size_override("font_size", 8)
	world_row.add_child(multiplayer_world_selector)

	var address_row := HBoxContainer.new()
	fields.add_child(address_row)
	var address_label := _network_form_label("ADDRESS")
	address_row.add_child(address_label)
	multiplayer_address_edit = _network_form_edit("127.0.0.1")
	multiplayer_address_edit.placeholder_text = "IP or domain"
	address_row.add_child(multiplayer_address_edit)
	multiplayer_recent_button = MenuButton.new()
	multiplayer_recent_button.text = "RECENT"
	multiplayer_recent_button.custom_minimum_size = Vector2(86, 30)
	multiplayer_recent_button.add_theme_font_override("font", ui_pixel_font)
	multiplayer_recent_button.add_theme_font_size_override("font_size", 7)
	multiplayer_recent_button.get_popup().id_pressed.connect(_select_recent_network_address)
	address_row.add_child(multiplayer_recent_button)
	_refresh_recent_network_menu()
	multiplayer_port_edit = _network_form_edit(str(NETWORK_SESSION_SCRIPT.DEFAULT_PORT))
	multiplayer_port_edit.custom_minimum_size = Vector2(104, 30)
	multiplayer_port_edit.size_flags_horizontal = Control.SIZE_SHRINK_END
	address_row.add_child(multiplayer_port_edit)

	var password_row := HBoxContainer.new()
	fields.add_child(password_row)
	var password_label := _network_form_label("PASSWORD")
	password_row.add_child(password_label)
	multiplayer_password_edit = _network_form_edit("")
	multiplayer_password_edit.placeholder_text = "Optional"
	multiplayer_password_edit.secret = true
	password_row.add_child(multiplayer_password_edit)
	multiplayer_pvp_check = CheckButton.new()
	multiplayer_pvp_check.text = "PvP"
	multiplayer_pvp_check.add_theme_font_override("font", ui_pixel_font)
	multiplayer_pvp_check.add_theme_font_size_override("font_size", 8)
	password_row.add_child(multiplayer_pvp_check)

	multiplayer_status_label = Label.new()
	multiplayer_status_label.text = "Choose a world to host, or enter a server address."
	multiplayer_status_label.custom_minimum_size = Vector2(0, 50)
	multiplayer_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	multiplayer_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplayer_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	multiplayer_status_label.add_theme_font_override("font", ui_pixel_font)
	multiplayer_status_label.add_theme_font_size_override("font_size", 7)
	multiplayer_status_label.add_theme_color_override("font_color", Color("b8c3cf"))
	fields.add_child(multiplayer_status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var host_btn := _make_compass_action_button("HOST WORLD")
	host_btn.pressed.connect(_host_selected_world)
	actions.add_child(host_btn)
	var join_btn := _make_compass_action_button("JOIN IP")
	join_btn.pressed.connect(_join_network_server)
	actions.add_child(join_btn)
	var export_btn := _make_compass_action_button("EXPORT")
	export_btn.tooltip_text = "Export the selected world for a dedicated server."
	export_btn.pressed.connect(_export_selected_world)
	actions.add_child(export_btn)
	var import_btn := _make_compass_action_button("IMPORT")
	import_btn.tooltip_text = "Import shadowgrove_world_N.json back into the selected slot."
	import_btn.pressed.connect(_import_selected_world)
	actions.add_child(import_btn)
	var browser_btn := _make_compass_action_button("SERVER LIST")
	browser_btn.disabled = true
	browser_btn.tooltip_text = "Public master-server browser is the next multiplayer stage."
	actions.add_child(browser_btn)
	var back_btn := _make_compass_action_button("BACK")
	back_btn.pressed.connect(_hide_multiplayer_panel)
	actions.add_child(back_btn)

	network_badge_label = Label.new()
	network_badge_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	network_badge_label.offset_left = -220
	network_badge_label.offset_top = 82
	network_badge_label.offset_right = 220
	network_badge_label.offset_bottom = 104
	network_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network_badge_label.add_theme_font_override("font", ui_pixel_font)
	network_badge_label.add_theme_font_size_override("font_size", 7)
	network_badge_label.add_theme_color_override("font_color", Color("80d9bd"))
	network_badge_label.visible = false
	canvas.add_child(network_badge_label)


func _network_form_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(118, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ui_pixel_font)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color("99a4b0"))
	return label


func _network_form_edit(value: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(0, 30)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_override("font", ui_pixel_font)
	edit.add_theme_font_size_override("font_size", 8)
	return edit


func _show_multiplayer_panel() -> void:
	if multiplayer_panel == null:
		return
	_refresh_multiplayer_worlds()
	multiplayer_panel.visible = true
	if main_menu_panel != null:
		main_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_mobile_controls_visibility()


func _hide_multiplayer_panel() -> void:
	if multiplayer_panel != null:
		multiplayer_panel.visible = false
	if main_menu_panel != null:
		main_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_mobile_controls_visibility()


func _refresh_multiplayer_worlds() -> void:
	if multiplayer_world_selector == null:
		return
	multiplayer_world_selector.clear()
	for meta in _list_worlds():
		var item_index := multiplayer_world_selector.item_count
		multiplayer_world_selector.add_item(str(meta.get("name", "World")))
		multiplayer_world_selector.set_item_metadata(item_index, int(meta.get("index", -1)))
	if multiplayer_world_selector.item_count == 0:
		multiplayer_world_selector.add_item("Create an offline world first")
		multiplayer_world_selector.set_item_disabled(0, true)


func _load_recent_network_addresses() -> void:
	recent_network_addresses.clear()
	if not FileAccess.file_exists(NETWORK_RECENT_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(NETWORK_RECENT_PATH))
	if not parsed is Array:
		return
	for endpoint_variant in parsed:
		var endpoint := str(endpoint_variant).strip_edges().substr(0, 160)
		if endpoint != "" and endpoint not in recent_network_addresses:
			recent_network_addresses.append(endpoint)
		if recent_network_addresses.size() >= NETWORK_RECENT_LIMIT:
			break


func _remember_network_address(address: String, port: int) -> void:
	var clean_address := address.strip_edges()
	if clean_address == "":
		clean_address = "127.0.0.1"
	var endpoint := "%s:%d" % [clean_address.substr(0, 144), clampi(port, 1, 65535)]
	recent_network_addresses.erase(endpoint)
	recent_network_addresses.push_front(endpoint)
	while recent_network_addresses.size() > NETWORK_RECENT_LIMIT:
		recent_network_addresses.pop_back()
	var file := FileAccess.open(NETWORK_RECENT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(recent_network_addresses, "\t"))
	_refresh_recent_network_menu()


func _refresh_recent_network_menu() -> void:
	if multiplayer_recent_button == null:
		return
	var popup := multiplayer_recent_button.get_popup()
	popup.clear()
	if recent_network_addresses.is_empty():
		popup.add_item("No recent servers", 0)
		popup.set_item_disabled(0, true)
		return
	for index in range(recent_network_addresses.size()):
		popup.add_item(recent_network_addresses[index], index)


func _select_recent_network_address(index: int) -> void:
	if index < 0 or index >= recent_network_addresses.size():
		return
	var endpoint := recent_network_addresses[index]
	var separator := endpoint.rfind(":")
	if separator <= 0:
		multiplayer_address_edit.text = endpoint
		return
	var port_text := endpoint.substr(separator + 1)
	if not port_text.is_valid_int():
		multiplayer_address_edit.text = endpoint
		return
	multiplayer_address_edit.text = endpoint.substr(0, separator)
	multiplayer_port_edit.text = port_text


func _network_port_from_ui() -> int:
	if multiplayer_port_edit == null or not multiplayer_port_edit.text.is_valid_int():
		return NETWORK_SESSION_SCRIPT.DEFAULT_PORT
	return clampi(int(multiplayer_port_edit.text), 1, 65535)


func _network_local_ipv4_hint() -> String:
	for address in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		return address
	return "127.0.0.1"


func _world_transfer_fallback_path(world_index: int) -> String:
	var transfer_dir := ProjectSettings.globalize_path("user://exports")
	DirAccess.make_dir_recursive_absolute(transfer_dir)
	return transfer_dir.path_join("shadowgrove_world_%d.json" % world_index)


func _world_transfer_path(world_index: int) -> String:
	var transfer_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if transfer_dir == "" or not DirAccess.dir_exists_absolute(transfer_dir):
		return _world_transfer_fallback_path(world_index)
	return transfer_dir.path_join("shadowgrove_world_%d.json" % world_index)


func _export_selected_world() -> void:
	if multiplayer_world_selector == null or multiplayer_world_selector.item_count == 0:
		return
	var metadata: Variant = multiplayer_world_selector.get_item_metadata(multiplayer_world_selector.selected)
	if metadata == null or int(metadata) < 0:
		_on_network_status_changed("No world selected for export.")
		return
	var world_index := int(metadata)
	var source := _world_path(world_index)
	if not FileAccess.file_exists(source):
		_on_network_status_changed("Open this world once before exporting it.")
		return
	var target := _world_transfer_path(world_index)
	if _copy_file_bytes(source, target):
		_on_network_status_changed("World exported: %s" % target)
		return
	var fallback := _world_transfer_fallback_path(world_index)
	if target != fallback and _copy_file_bytes(source, fallback):
		_on_network_status_changed("Downloads unavailable. World exported: %s" % fallback)
	else:
		_on_network_status_changed("World export failed: %s" % target)


func _import_selected_world() -> void:
	if network_session != null and network_session.is_active():
		_on_network_status_changed("Disconnect before importing a world.")
		return
	if multiplayer_world_selector == null or multiplayer_world_selector.item_count == 0:
		return
	var metadata: Variant = multiplayer_world_selector.get_item_metadata(multiplayer_world_selector.selected)
	if metadata == null or int(metadata) < 0:
		_on_network_status_changed("No target world selected for import.")
		return
	var world_index := int(metadata)
	var source := _world_transfer_path(world_index)
	var imported := _import_world_file(source, world_index)
	if not imported:
		var fallback := _world_transfer_fallback_path(world_index)
		if fallback != source:
			source = fallback
			imported = _import_world_file(source, world_index)
	if imported:
		_on_network_status_changed("World imported into slot %d. Open it offline to verify." % (world_index + 1))
		_refresh_multiplayer_worlds()
	else:
		_on_network_status_changed("Import failed. Expected a valid file at %s" % source)


func _import_world_file(source: String, world_index: int) -> bool:
	if not FileAccess.file_exists(source):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source))
	if not parsed is Dictionary:
		return false
	var imported_world: Array = parsed.get("world", [])
	if imported_world.size() != WORLD_HEIGHT or imported_world.is_empty() or (imported_world[0] as Array).size() != WORLD_WIDTH:
		return false
	return _copy_file_bytes(source, _world_path(world_index))


func _export_world_file(target: String) -> bool:
	if current_world_index < 0:
		return false
	_save_game()
	if target == "":
		return false
	return _copy_file_bytes(_world_path(current_world_index), target)


func _copy_file_bytes(source: String, target: String) -> bool:
	if not FileAccess.file_exists(source):
		return false
	var absolute_target := ProjectSettings.globalize_path(target) if target.begins_with("user://") else target
	DirAccess.make_dir_recursive_absolute(absolute_target.get_base_dir())
	var output := FileAccess.open(absolute_target, FileAccess.WRITE)
	if output == null:
		return false
	output.store_buffer(FileAccess.get_file_as_bytes(source))
	return true


func _host_selected_world() -> void:
	if network_session == null or multiplayer_world_selector == null or multiplayer_world_selector.item_count == 0:
		return
	var selected := multiplayer_world_selector.selected
	var metadata: Variant = multiplayer_world_selector.get_item_metadata(selected)
	if metadata == null or int(metadata) < 0:
		_on_network_status_changed("Create an offline world before hosting.")
		return
	var world_index := int(metadata)
	_on_play_world(world_index)
	var result: int = int(network_session.host_server(
		_network_port_from_ui(),
		multiplayer_password_edit.text,
		multiplayer_server_name_edit.text,
		multiplayer_name_edit.text,
		multiplayer_pvp_check.button_pressed,
		false
	))
	if result != OK:
		_show_main_menu()
		_show_multiplayer_panel()
		return
	if multiplayer_panel != null:
		multiplayer_panel.visible = false
	game_paused = false
	var address_hint := _network_local_ipv4_hint()
	last_message = "Server: %s:%d (UDP)." % [address_hint, network_session.listen_port]
	_toast_message(last_message, 6.0)
	_update_network_badge()


func _join_network_server() -> void:
	if network_session == null:
		return
	var result: int = int(network_session.join_server(
		multiplayer_address_edit.text,
		_network_port_from_ui(),
		multiplayer_password_edit.text,
		multiplayer_name_edit.text
	))
	if result == OK:
		_remember_network_address(multiplayer_address_edit.text, _network_port_from_ui())
		multiplayer_status_label.text = "Connecting…"


func _on_network_status_changed(message: String) -> void:
	if multiplayer_status_label != null:
		multiplayer_status_label.text = message
	if not in_main_menu and message != "":
		last_message = message
	_update_network_badge()


func _on_network_roster_changed() -> void:
	_update_network_badge()
	_update_pause_player_list()


func _on_network_latency_changed(_ping_ms: int, _quality: String) -> void:
	_update_network_badge()
	if game_paused:
		_update_pause_player_list()


func _on_network_chat_received(_peer_id: int, player_name: String, message: String) -> void:
	var line := "%s: %s" % [player_name, message]
	network_chat_lines.append(line)
	while network_chat_lines.size() > 50:
		network_chat_lines.pop_front()
	if network_chat_log_label != null:
		network_chat_log_label.text = "\n".join(network_chat_lines)
		network_chat_log_label.scroll_to_line(maxi(0, network_chat_lines.size() - 1))
	_toast_message(line, 4.0)


func _send_network_chat() -> void:
	if network_session == null or not network_session.is_active() or not network_session.joined or network_chat_edit == null:
		return
	var message := network_chat_edit.text.strip_edges()
	if message == "":
		return
	network_chat_edit.clear()
	network_session.send_chat(message)


func _on_network_session_stopped(_reason: String) -> void:
	network_chat_lines.clear()
	if network_chat_log_label != null:
		network_chat_log_label.text = ""
	_update_network_badge()
	_update_pause_player_list()


func _update_pause_player_list() -> void:
	if pause_players_box == null:
		return
	for child in pause_players_box.get_children():
		pause_players_box.remove_child(child)
		child.queue_free()
	var scroll: ScrollContainer = pause_players_box.get_meta("scroll") as ScrollContainer
	var active: bool = network_session != null and bool(network_session.is_active()) and bool(network_session.joined)
	if pause_admin_row != null:
		pause_admin_row.visible = active and bool(network_session.is_server()) and not bool(network_session.is_dedicated())
	if scroll != null:
		scroll.visible = active
	if network_chat_log_label != null:
		network_chat_log_label.visible = active
		var chat_row: Control = network_chat_log_label.get_meta("row") as Control
		if chat_row != null:
			chat_row.visible = active
	if not active:
		return
	var title := Label.new()
	title.text = "PLAYERS  %d/%d" % [network_session.player_count(), NETWORK_SESSION_SCRIPT.MAX_PLAYERS]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Color("80d9bd"))
	pause_players_box.add_child(title)
	var peer_ids: Array = network_session.players.keys()
	peer_ids.sort()
	for peer_variant in peer_ids:
		var peer_id := int(peer_variant)
		var state: Dictionary = network_session.players.get(peer_id, {})
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		pause_players_box.add_child(row)
		var label := Label.new()
		var peer_ping := int(network_session.ping_ms) if network_session.is_client() and peer_id == int(network_session.local_peer_id()) else int(state.get("ping", 0 if peer_id == 1 else -1))
		var peer_suffix := "  (HOST)" if peer_id == 1 and not network_session.is_dedicated() else ("  %dms" % peer_ping if peer_ping >= 0 else "")
		label.text = "%s%s" % [str(state.get("name", "Player")), peer_suffix]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", ui_pixel_font)
		label.add_theme_font_size_override("font_size", 7)
		row.add_child(label)
		if network_session.is_server() and peer_id > 1:
			var kick_btn := _make_compass_action_button("KICK")
			kick_btn.custom_minimum_size = Vector2(58, 26)
			kick_btn.add_theme_font_size_override("font_size", 7)
			kick_btn.pressed.connect(_kick_network_peer.bind(peer_id))
			row.add_child(kick_btn)
			var ban_btn := _make_compass_action_button("BAN")
			ban_btn.custom_minimum_size = Vector2(58, 26)
			ban_btn.add_theme_font_size_override("font_size", 7)
			ban_btn.pressed.connect(_ban_network_peer.bind(peer_id))
			row.add_child(ban_btn)


func _kick_network_peer(peer_id: int) -> void:
	if network_session != null and network_session.is_server():
		network_session.kick_peer(peer_id, "Removed by the server owner.")


func _ban_network_peer(peer_id: int) -> void:
	if network_session != null and network_session.is_server() and network_session.ban_peer(peer_id, "Banned by the server owner."):
		last_message = "Player banned."
		_toast_message(last_message, 3.0)


func _clear_network_bans() -> void:
	if network_session == null or not network_session.is_server():
		return
	var removed := int(network_session.clear_bans())
	last_message = "Cleared %d ban%s." % [removed, "" if removed == 1 else "s"]
	_toast_message(last_message, 3.0)


func _on_force_server_save() -> void:
	last_message = "Server save complete." if _force_server_save() else "Nothing to save."
	_toast_message(last_message, 3.0)


func _copy_host_address() -> void:
	if network_session == null or not network_session.is_server():
		return
	var endpoint := "%s:%d" % [_network_local_ipv4_hint(), int(network_session.listen_port)]
	DisplayServer.clipboard_set(endpoint)
	last_message = "Copied %s" % endpoint
	_toast_message(last_message, 4.0)


func _toggle_network_pvp_mode() -> void:
	if network_session == null or not network_session.is_server():
		return
	network_session.set_pvp_enabled(not network_session.pvp_enabled)
	_update_network_badge()


func _update_network_badge() -> void:
	if network_badge_label == null or network_session == null:
		return
	network_badge_label.visible = network_session.is_active() and network_session.joined and not network_session.is_dedicated()
	if network_badge_label.visible:
		var latency_text := ""
		if network_session.is_client():
			latency_text = "  •  %dMS %s" % [int(network_session.ping_ms), str(network_session.connection_quality).to_upper()]
		network_badge_label.text = "%s  •  %d/%d  •  %s%s" % [
			network_session.server_name.to_upper(),
			network_session.player_count(),
			NETWORK_SESSION_SCRIPT.MAX_PLAYERS,
			"PVP" if network_session.pvp_enabled else "PVE",
			latency_text
		]
	if pause_pvp_button != null:
		pause_pvp_button.visible = network_session.is_server() and not network_session.is_dedicated()
		pause_pvp_button.text = "SERVER MODE: %s" % ("PVP" if network_session.pvp_enabled else "PVE")


func _refresh_worlds_list() -> void:
	if worlds_list_box == null:
		return
	for child in worlds_list_box.get_children():
		worlds_list_box.remove_child(child)
		child.queue_free()
	var worlds := _list_worlds()
	if worlds.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No worlds yet. Create one above."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_override("font", ui_pixel_font)
		empty_label.add_theme_font_size_override("font_size", 8)
		empty_label.add_theme_color_override("font_color", Color("99a4b0"))
		worlds_list_box.add_child(empty_label)
		return
	for meta in worlds:
		var idx := int(meta.get("index", -1))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		worlds_list_box.add_child(row)
		var play_btn := _make_compass_action_button("%s  %s" % [str(meta.get("name", "World")), "LOAD" if bool(meta.get("has_save", false)) else "NEW"])
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_btn.pressed.connect(_on_play_world.bind(idx))
		row.add_child(play_btn)
		var del_btn := _make_compass_action_button("X")
		del_btn.custom_minimum_size = Vector2(40, 30)
		del_btn.pressed.connect(_on_delete_world.bind(idx))
		row.add_child(del_btn)


func _show_main_menu() -> void:
	in_main_menu = true
	_refresh_worlds_list()
	_hide_settings()
	if main_menu_panel != null:
		main_menu_panel.visible = true
	_update_mobile_controls_visibility()


func _hide_main_menu() -> void:
	in_main_menu = false
	if main_menu_panel != null:
		main_menu_panel.visible = false
	_update_mobile_controls_visibility()


func _on_create_world_pressed() -> void:
	var name := new_world_name_edit.text.strip_edges()
	var idx := _create_world(name)
	_on_play_world(idx)


func _on_play_world(index: int) -> void:
	if index < 0:
		return
	current_world_index = index
	current_world_name = str(_world_meta(index).get("name", "World"))
	if FileAccess.file_exists(_world_path(index)):
		_load_game_from_path(_world_path(index))
	else:
		# Fresh world: new seed from meta, generate terrain
		seed = int(_world_meta(index).get("seed", randi()))
		_generate_world()
		_save_game()
	world_loaded = true
	_hide_main_menu()
	_update_hud()


func _on_delete_world(index: int) -> void:
	_delete_world(index)
	if current_world_index == index:
		current_world_index = -1
		world_loaded = false
	_refresh_worlds_list()


func _load_settings(path := SETTINGS_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		settings_volume = clampf(float(config.get_value("audio", "master_volume", settings_volume)), 0.0, 1.0)
	_apply_master_volume()
	if settings_volume_slider != null:
		settings_volume_slider.set_value_no_signal(settings_volume)
	if settings_volume_value != null:
		settings_volume_value.text = "%d%%" % int(round(settings_volume * 100.0))


func _save_settings(path := SETTINGS_PATH) -> Error:
	var config := ConfigFile.new()
	# Preserve future settings sections when only the volume changes.
	config.load(path)
	config.set_value("audio", "master_volume", clampf(settings_volume, 0.0, 1.0))
	return config.save(path)


func _apply_master_volume() -> void:
	# Preserve the game's existing volume curve; zero is a real mute now.
	var volume_db := -80.0 if settings_volume <= 0.001 else lerpf(-30.0, 0.0, settings_volume)
	for player_variant in sound_players.values():
		var player := player_variant as AudioStreamPlayer
		if player != null:
			player.volume_db = volume_db


func _on_settings_volume_changed(value: float) -> void:
	settings_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	if settings_volume_value != null:
		settings_volume_value.text = "%d%%" % int(round(settings_volume * 100.0))
	var save_error := _save_settings()
	if save_error != OK:
		push_warning("Could not save audio settings: %s" % error_string(save_error))


func _show_settings() -> void:
	if settings_panel != null:
		settings_panel.visible = true
	# The pause panel is a LATER sibling in the HUD tree, and GUI input picking
	# uses tree order (z_index is ignored) — so its buttons would keep stealing
	# clicks from the settings panel. Hide it while settings is open and put it
	# back afterwards.
	if pause_panel != null:
		pause_panel.visible = false
	if main_menu_panel != null:
		main_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_mobile_controls_visibility()


func _hide_settings() -> void:
	if settings_panel != null:
		settings_panel.visible = false
	if pause_panel != null:
		pause_panel.visible = game_paused
	if main_menu_panel != null:
		main_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_mobile_controls_visibility()


func _toggle_pause() -> void:
	if in_main_menu:
		return
	game_paused = not game_paused
	if pause_panel != null:
		pause_panel.visible = game_paused
	if game_paused:
		# The full-rect pause panel swallows the release events of any touch
		# that is currently held, so drop all transient input right away.
		_release_all_transient_input()
		_update_pause_player_list()
		_save_game()


func _quit_to_menu() -> void:
	_save_game()
	if network_session != null and network_session.is_server():
		var peer_ids: Array = network_session.players.keys()
		for peer_variant in peer_ids:
			var peer_id := int(peer_variant)
			if peer_id > 1:
				network_session.kick_peer(peer_id, "Server stopped by its owner.")
		await get_tree().create_timer(0.3).timeout
	if network_session != null and network_session.is_active():
		network_session.shutdown("Server stopped." if network_session.is_server() else "Left the server.")
	game_paused = false
	world_loaded = false
	if pause_panel != null:
		pause_panel.visible = false
	_hide_multiplayer_panel()
	_hide_main_menu()
	_show_main_menu()


func _setup_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	# --- UI textures ------------------------------------------------------
	ring_fill_texture = _make_ring_texture(128, 0.80, Color("f2a33a"), Color("d63434"))
	ring_track_texture = _make_ring_texture(128, 0.80, Color("3a424e"), Color("3a424e"))
	circle_texture = _make_circle_texture(24, Color("ffe9a8"))
	lens_vignette_texture = _make_lens_vignette_texture(148)

	# Minimal vitals rail (top-left): compact, edge-aligned and free of the
	# previous oversized wooden plate.
	heart_full_tex = _ui_tex("res://assets/ui/heart_full.png")
	heart_half_tex = _ui_tex("res://assets/ui/heart_half.png")
	heart_empty_tex = _ui_tex("res://assets/ui/heart_empty.png")
	var vitals_panel := Panel.new()
	vitals_panel.position = Vector2(16, 14)
	vitals_panel.size = Vector2(346, 116)
	vitals_panel.add_theme_stylebox_override("panel", _pixel_sb("res://assets/ui/frame.png", 8))
	vitals_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(vitals_panel)
	_register_safe_area_control(vitals_panel, ["left", "top"])

	# Ten small hearts form a readable health line without a second numeric bar.
	health_hearts.clear()
	for i in range(10):
		var heart_rect := TextureRect.new()
		heart_rect.position = Vector2(17 + i * 28, 15)
		heart_rect.size = Vector2(24, 21)
		heart_rect.texture = heart_full_tex
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_hearts.append(heart_rect)
		vitals_panel.add_child(heart_rect)
	_update_health_hearts()

	var vitals_divider := _make_divider(312)
	vitals_divider.position = Vector2(17, 43)
	vitals_panel.add_child(vitals_divider)

	# Defense is always visible; oxygen and temperature are concise live chips.
	var armor_icon := TextureRect.new()
	armor_icon.texture = _ui_tex("res://assets/ui/armor.png")
	armor_icon.position = Vector2(17, 54)
	armor_icon.size = Vector2(18, 18)
	armor_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	armor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	armor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals_panel.add_child(armor_icon)
	armor_chip_label = Label.new()
	armor_chip_label.position = Vector2(41, 54)
	armor_chip_label.size = Vector2(28, 18)
	armor_chip_label.add_theme_font_override("font", ui_pixel_font)
	armor_chip_label.add_theme_font_size_override("font_size", 10)
	armor_chip_label.add_theme_color_override("font_color", Color("e8edf2"))
	armor_chip_label.text = str(_total_defense())
	vitals_panel.add_child(armor_chip_label)
	var vitals_armor_caption := Label.new()
	vitals_armor_caption.text = "DEF"
	vitals_armor_caption.position = Vector2(68, 57)
	vitals_armor_caption.add_theme_font_override("font", ui_pixel_font)
	vitals_armor_caption.add_theme_font_size_override("font_size", 7)
	vitals_armor_caption.add_theme_color_override("font_color", Color("99a4b0"))
	vitals_panel.add_child(vitals_armor_caption)

	oxygen_panel = Control.new()
	oxygen_panel.position = Vector2(112, 51)
	oxygen_panel.size = Vector2(106, 24)
	oxygen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oxygen_panel.visible = false
	vitals_panel.add_child(oxygen_panel)
	var oxygen_icon := TextureRect.new()
	oxygen_icon.texture = _ui_tex("res://assets/ui/bubble.png")
	oxygen_icon.position = Vector2(0, 4)
	oxygen_icon.size = Vector2(14, 14)
	oxygen_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	oxygen_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	oxygen_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oxygen_panel.add_child(oxygen_icon)
	oxygen_bar = _make_compass_progress_bar(Color("4b97e0"))
	oxygen_bar.min_value = 0.0
	oxygen_bar.max_value = MAX_OXYGEN
	oxygen_bar.position = Vector2(19, 6)
	oxygen_bar.size = Vector2(57, 8)
	oxygen_panel.add_child(oxygen_bar)
	oxygen_value = Label.new()
	oxygen_value.position = Vector2(80, 3)
	oxygen_value.size = Vector2(28, 16)
	oxygen_value.add_theme_font_override("font", ui_pixel_font)
	oxygen_value.add_theme_font_size_override("font_size", 8)
	oxygen_value.add_theme_color_override("font_color", Color("9fd7ff"))
	oxygen_panel.add_child(oxygen_value)

	temperature_panel = Control.new()
	temperature_panel.position = Vector2(224, 51)
	temperature_panel.size = Vector2(105, 24)
	temperature_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals_panel.add_child(temperature_panel)
	var temperature_icon := TextureRect.new()
	temperature_icon.texture = _ui_tex("res://assets/ui/thermo.png")
	temperature_icon.position = Vector2(0, 3)
	temperature_icon.size = Vector2(14, 14)
	temperature_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	temperature_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	temperature_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temperature_panel.add_child(temperature_icon)
	temperature_bar = _make_compass_progress_bar(Color("f2a33a"))
	temperature_bar.min_value = MIN_BODY_TEMPERATURE
	temperature_bar.max_value = MAX_BODY_TEMPERATURE
	temperature_bar.position = Vector2(19, 6)
	temperature_bar.size = Vector2(55, 8)
	temperature_panel.add_child(temperature_bar)
	temperature_value = Label.new()
	temperature_value.position = Vector2(78, 3)
	temperature_value.size = Vector2(30, 16)
	temperature_value.add_theme_font_override("font", ui_pixel_font)
	temperature_value.add_theme_font_size_override("font_size", 8)
	temperature_value.add_theme_color_override("font_color", Color("ffc766"))
	temperature_panel.add_child(temperature_value)
	temperature_title = Label.new()
	temperature_title.visible = false
	temperature_panel.add_child(temperature_title)

	status_chips_root = HBoxContainer.new()
	status_chips_root.position = Vector2(17, 78)
	status_chips_root.size = Vector2(312, 20)
	status_chips_root.add_theme_constant_override("separation", 5)
	status_chips_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals_panel.add_child(status_chips_root)

	flight_charge_label = Label.new()
	flight_charge_label.position = Vector2(17, 98)
	flight_charge_label.size = Vector2(160, 13)
	flight_charge_label.add_theme_font_override("font", ui_pixel_font)
	flight_charge_label.add_theme_font_size_override("font_size", 7)
	flight_charge_label.add_theme_color_override("font_color", Color("9fd7ff"))
	flight_charge_label.visible = false
	vitals_panel.add_child(flight_charge_label)

	# Compatibility labels still receive updates, but are intentionally absent
	# from the permanent HUD in the minimal layout.
	hud_class_label = Label.new()
	hud_class_label.visible = false
	vitals_panel.add_child(hud_class_label)
	vitals_seed_label = Label.new()
	vitals_seed_label.visible = false
	vitals_panel.add_child(vitals_seed_label)

	# Legacy hidden widgets (kept for compatibility with update functions) --
	hud_label = Label.new()
	hud_label.visible = false
	canvas.add_child(hud_label)
	hud_health_bar = _make_compass_progress_bar(Color("d65455"))
	hud_health_bar.visible = false
	canvas.add_child(hud_health_bar)
	hud_armor_value = Label.new()
	hud_armor_value.visible = false
	canvas.add_child(hud_armor_value)
	hud_status_label = Label.new()
	hud_status_label.visible = false
	canvas.add_child(hud_status_label)

	# Day / biome / toast (top center) --------------------------------------
	day_time_label = Label.new()
	day_time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	day_time_label.anchor_left = 0.5
	day_time_label.anchor_right = 0.5
	day_time_label.offset_left = -90
	day_time_label.offset_top = 14
	day_time_label.offset_right = 90
	day_time_label.offset_bottom = 32
	day_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_time_label.add_theme_font_override("font", ui_pixel_font)
	day_time_label.add_theme_font_size_override("font_size", 10)
	day_time_label.add_theme_color_override("font_color", Color("f2a33a"))
	day_time_label.text = "DAY 14:22"
	canvas.add_child(day_time_label)

	day_icon_rect = TextureRect.new()
	day_icon_rect.set_anchors_preset(Control.PRESET_TOP_WIDE)
	day_icon_rect.anchor_left = 0.5
	day_icon_rect.anchor_right = 0.5
	day_icon_rect.offset_left = -84
	day_icon_rect.offset_top = 26
	day_icon_rect.offset_right = -70
	day_icon_rect.offset_bottom = 40
	day_icon_rect.visible = false
	day_icon_rect.texture = _ui_tex("res://assets/ui/sun.png")
	day_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	day_icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	day_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(day_icon_rect)

	minimap_biome_label = Label.new()
	minimap_biome_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	minimap_biome_label.anchor_left = 0.5
	minimap_biome_label.anchor_right = 0.5
	minimap_biome_label.offset_left = -200
	minimap_biome_label.offset_top = 34
	minimap_biome_label.offset_right = 200
	minimap_biome_label.offset_bottom = 52
	minimap_biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap_biome_label.add_theme_font_override("font", ui_pixel_font)
	minimap_biome_label.add_theme_font_size_override("font_size", 8)
	minimap_biome_label.add_theme_color_override("font_color", Color("99a4b0"))
	minimap_biome_label.text = "FOREST"
	canvas.add_child(minimap_biome_label)

	hud_toast_panel = PanelContainer.new()
	hud_toast_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_toast_panel.anchor_left = 0.5
	hud_toast_panel.anchor_right = 0.5
	hud_toast_panel.offset_left = -240
	hud_toast_panel.offset_top = 58
	hud_toast_panel.offset_right = 240
	hud_toast_panel.offset_bottom = 86
	hud_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_toast_panel.visible = false
	canvas.add_child(hud_toast_panel)
	var toast_style := _pixel_sb("res://assets/ui/frame_inner_accent.png", 8)
	toast_style.content_margin_left = 14
	toast_style.content_margin_top = 4
	toast_style.content_margin_right = 14
	toast_style.content_margin_bottom = 4
	hud_toast_panel.add_theme_stylebox_override("panel", toast_style)
	hud_toast_label = Label.new()
	hud_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_toast_label.add_theme_font_override("font", ui_pixel_font)
	hud_toast_label.add_theme_font_size_override("font_size", 8)
	hud_toast_label.add_theme_color_override("font_color", Color("ffc766"))
	hud_toast_label.text = last_message
	hud_toast_panel.add_child(hud_toast_label)

	# Minimap lens (top-right) ----------------------------------------------
	minimap_panel = _make_compass_map_frame()
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -184
	minimap_panel.offset_top = 16
	minimap_panel.offset_right = -20
	minimap_panel.offset_bottom = 180
	minimap_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	minimap_panel.z_index = 60
	minimap_panel.tooltip_text = "Open world map"
	minimap_panel.gui_input.connect(_on_minimap_gui_input)
	canvas.add_child(minimap_panel)
	_register_safe_area_control(minimap_panel, ["right", "top"])
	var minimap_root := Control.new()
	minimap_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_panel.add_child(minimap_root)
	minimap_rect = TextureRect.new()
	minimap_rect.position = Vector2(8, 8)
	minimap_rect.size = Vector2(148, 148)
	minimap_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	minimap_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(minimap_rect)
	lens_vignette_rect = TextureRect.new()
	lens_vignette_rect.position = Vector2(8, 8)
	lens_vignette_rect.size = Vector2(148, 148)
	lens_vignette_rect.texture = lens_vignette_texture
	lens_vignette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lens_vignette_rect.stretch_mode = TextureRect.STRETCH_SCALE
	lens_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(lens_vignette_rect)
	var lens_ring_rect := TextureRect.new()
	lens_ring_rect.position = Vector2(-6, -6)
	lens_ring_rect.size = Vector2(160, 160)
	lens_ring_rect.texture = _ui_tex("res://assets/ui/lens_ring.png")
	lens_ring_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lens_ring_rect.stretch_mode = TextureRect.STRETCH_SCALE
	lens_ring_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(lens_ring_rect)
	lens_dot_rect = TextureRect.new()
	lens_dot_rect.position = Vector2(73, 73)
	lens_dot_rect.size = Vector2(18, 18)
	lens_dot_rect.texture = _make_circle_texture(18, Color("ffe27a"))
	lens_dot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lens_dot_rect.stretch_mode = TextureRect.STRETCH_SCALE
	lens_dot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(lens_dot_rect)

	minimap_time_label = Label.new()
	minimap_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_time_label.offset_left = -184
	minimap_time_label.offset_top = 186
	minimap_time_label.offset_right = -20
	minimap_time_label.offset_bottom = 202
	minimap_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap_time_label.add_theme_font_size_override("font_size", 8)
	minimap_time_label.add_theme_color_override("font_color", Color("99a4b0"))
	minimap_time_label.text = "MAP · M"
	canvas.add_child(minimap_time_label)
	_register_safe_area_control(minimap_time_label, ["right", "top"])
	storm_progress_label = Label.new()
	storm_progress_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	storm_progress_label.offset_left = -184
	storm_progress_label.offset_top = 204
	storm_progress_label.offset_right = -20
	storm_progress_label.offset_bottom = 222
	storm_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	storm_progress_label.add_theme_font_override("font", ui_pixel_font)
	storm_progress_label.add_theme_font_size_override("font_size", 8)
	storm_progress_label.add_theme_color_override("font_color", Color("9fc4e8"))
	storm_progress_label.text = ""
	canvas.add_child(storm_progress_label)
	_register_safe_area_control(storm_progress_label, ["right", "top"])

	journal_access_button = _make_compass_action_button("JOURNAL")
	journal_access_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	journal_access_button.offset_left = -150
	journal_access_button.offset_top = 204
	journal_access_button.offset_right = -20
	journal_access_button.offset_bottom = 234
	journal_access_button.pressed.connect(_set_journal_open.bind(true))
	canvas.add_child(journal_access_button)
	_register_safe_area_control(journal_access_button, ["right", "top"])

	# Hotbar (bottom center) -------------------------------------------------
	var hotbar_root := Control.new()
	hotbar_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Touch targets: 60px canvas units land below Android's recommended
	# minimum on common phones, so mobile builds use larger slots. Desktop
	# keeps the original compact row.
	var hotbar_slot_px := 72.0 if mobile_ui_enabled else 60.0
	var hotbar_gap_px := 10.0 if mobile_ui_enabled else 8.0
	var hotbar_row_width := hotbar_slot_px * HOTBAR_SIZE + hotbar_gap_px * (HOTBAR_SIZE - 1) + 8.0
	hotbar_root.offset_left = -hotbar_row_width * 0.5
	hotbar_root.offset_top = -18.0 - hotbar_slot_px
	hotbar_root.offset_right = hotbar_row_width * 0.5
	hotbar_root.offset_bottom = -12
	hotbar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hotbar_root)
	_register_safe_area_control(hotbar_root, ["bottom"])
	# Slots float independently; the former 380x88 wooden tray is gone.
	var slot_positions: Array[Vector2] = []
	for i in range(HOTBAR_SIZE):
		slot_positions.append(Vector2(4.0 + i * (hotbar_slot_px + hotbar_gap_px), 4.0))
	for i in range(HOTBAR_SIZE):
		var slot := _make_slot_button()
		slot.position = slot_positions[i]
		slot.size = Vector2(hotbar_slot_px, hotbar_slot_px)
		slot.custom_minimum_size = Vector2(hotbar_slot_px, hotbar_slot_px)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		slot.gui_input.connect(_on_hotbar_slot_gui_input.bind(i))
		hotbar_buttons.append(slot)
		hotbar_root.add_child(slot)
		var arrow := Label.new()
		arrow.text = "•"
		arrow.position = slot_positions[i] + Vector2(hotbar_slot_px * 0.5 - 8.0, hotbar_slot_px - 10.0)
		arrow.size = Vector2(16, 12)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.add_theme_font_size_override("font_size", 9)
		arrow.add_theme_color_override("font_color", Color("f2a33a"))
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.visible = false
		hotbar_arrow_labels.append(arrow)
		hotbar_root.add_child(arrow)

	context_hint_panel = PanelContainer.new()
	context_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	context_hint_panel.offset_left = -170
	context_hint_panel.offset_top = -134
	context_hint_panel.offset_right = 170
	context_hint_panel.offset_bottom = -108
	context_hint_panel.visible = false
	context_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(context_hint_panel)
	_register_safe_area_control(context_hint_panel, ["bottom"])
	var context_style := _pixel_sb("res://assets/ui/frame_inner_accent.png", 8)
	context_style.content_margin_left = 14
	context_style.content_margin_top = 5
	context_style.content_margin_right = 14
	context_style.content_margin_bottom = 5
	context_hint_panel.add_theme_stylebox_override("panel", context_style)
	context_hint_label = Label.new()
	context_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	context_hint_label.add_theme_font_override("font", ui_pixel_font)
	context_hint_label.add_theme_font_size_override("font_size", 8)
	context_hint_label.add_theme_color_override("font_color", Color("f2a33a"))
	context_hint_panel.add_child(context_hint_label)

	# Full map ---------------------------------------------------------------
	full_map_panel = Control.new()
	full_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	full_map_panel.anchor_left = 0.06
	full_map_panel.anchor_top = 0.06
	full_map_panel.anchor_right = 0.94
	full_map_panel.anchor_bottom = 0.92
	full_map_panel.offset_left = 0
	full_map_panel.offset_top = 0
	full_map_panel.offset_right = 0
	full_map_panel.offset_bottom = 0
	full_map_panel.visible = false
	full_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	full_map_panel.z_index = 60
	canvas.add_child(full_map_panel)
	# Dim backdrop behind the map (no black panel square). Kept light so the
	# world stays visible behind the map.
	full_map_backdrop = ColorRect.new()
	full_map_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	full_map_backdrop.color = Color("030407", 0.30)
	full_map_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_map_backdrop.z_index = 58
	full_map_backdrop.visible = false
	canvas.add_child(full_map_backdrop)
	# Tap-outside catcher: closes the map when tapping anywhere outside it.
	map_close_catcher = Control.new()
	map_close_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_close_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	map_close_catcher.z_index = 59
	map_close_catcher.gui_input.connect(_on_map_close_catcher_input)
	map_close_catcher.visible = false
	canvas.add_child(map_close_catcher)
	var full_map_box := VBoxContainer.new()
	full_map_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	full_map_box.add_theme_constant_override("separation", 6)
	full_map_panel.add_child(full_map_box)
	var full_map_header := HBoxContainer.new()
	full_map_box.add_child(full_map_header)
	var full_map_title := Label.new()
	full_map_title.text = "WORLD MAP"
	full_map_title.add_theme_font_override("font", ui_pixel_font)
	full_map_title.add_theme_font_size_override("font_size", 15)
	full_map_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_map_header.add_child(full_map_title)
	# (No ✕ close button — tapping outside the map closes it instead.)
	map_wrap = Control.new()
	map_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_wrap.clip_contents = true
	map_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	full_map_box.add_child(map_wrap)
	full_map_rect = TextureRect.new()
	full_map_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	full_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	full_map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	full_map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_wrap.add_child(full_map_rect)
	map_fog_rect = TextureRect.new()
	map_fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_fog_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_fog_rect.stretch_mode = TextureRect.STRETCH_SCALE
	map_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_wrap.add_child(map_fog_rect)
	map_legend_label = RichTextLabel.new()
	map_legend_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	map_legend_label.offset_left = 14
	map_legend_label.offset_top = -32
	map_legend_label.offset_right = 860
	map_legend_label.offset_bottom = -6
	map_legend_label.bbcode_enabled = true
	map_legend_label.fit_content = true
	map_legend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_legend_label.add_theme_font_size_override("normal_font_size", 9)
	map_legend_label.text = "[color=#ffeb7a]●[/color] You   [color=#72d8ff]●[/color] Allies   [color=#9aef9f]■[/color] Forest   [color=#8fb3a8]■[/color] Marsh   [color=#c9b591]■[/color] Ash Desert   [color=#a79bb8]■[/color] Ruins   [color=#b8deed]■[/color] Frost   [color=#d172aa]■[/color] Mushrooms"
	map_wrap.add_child(map_legend_label)

	# Boss bar (top center, below toast) ------------------------------------
	boss_panel = _make_compass_clear_panel()
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -260
	boss_panel.offset_top = 108
	boss_panel.offset_right = 260
	boss_panel.offset_bottom = 148
	boss_panel.visible = false
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(boss_panel)
	var boss_style := _pixel_sb("res://assets/ui/boss_bar.png", 8)
	boss_style.content_margin_left = 12
	boss_style.content_margin_top = 8
	boss_style.content_margin_right = 12
	boss_style.content_margin_bottom = 8
	boss_panel.add_theme_stylebox_override("panel", boss_style)
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 4)
	boss_panel.add_child(boss_box)
	var boss_title_row := HBoxContainer.new()
	boss_title_row.add_theme_constant_override("separation", 6)
	boss_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_box.add_child(boss_title_row)
	var boss_skull := TextureRect.new()
	boss_skull.texture = _ui_tex("res://assets/ui/skull.png")
	boss_skull.custom_minimum_size = Vector2(16, 16)
	boss_skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_title_row.add_child(boss_skull)
	boss_label = Label.new()
	boss_label.add_theme_font_override("font", ui_pixel_font)
	boss_label.add_theme_font_size_override("font_size", 10)
	boss_label.add_theme_color_override("font_color", Color("ffd9c2"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title_row.add_child(boss_label)
	boss_hp_bar = _make_compass_progress_bar(Color("e05252"))
	boss_hp_bar.custom_minimum_size = Vector2(516, 12)
	boss_hp_bar.show_percentage = false
	boss_hp_bar.max_value = 100.0
	boss_box.add_child(boss_hp_bar)

	# Loot feed (bottom-right, chips with icons) -----------------------------
	var loot_feed := VBoxContainer.new()
	loot_feed.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	loot_feed.offset_left = -250
	loot_feed.offset_top = -230
	loot_feed.offset_right = -18
	loot_feed.offset_bottom = -14
	loot_feed.alignment = BoxContainer.ALIGNMENT_END
	loot_feed.add_theme_constant_override("separation", 7)
	loot_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(loot_feed)
	_register_safe_area_control(loot_feed, ["right", "bottom"])
	for i in range(5):
		var feed_chip := PanelContainer.new()
		loot_feed_chips.append(feed_chip)
		feed_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var feed_style := StyleBoxFlat.new()
		feed_style.bg_color = Color("0a0d13", 0.82)
		feed_style.border_color = Color("ff9d4d", 0.4)
		feed_style.set_border_width_all(1)
		feed_style.content_margin_left = 6
		feed_style.content_margin_top = 3
		feed_style.content_margin_right = 6
		feed_style.content_margin_bottom = 3
		feed_chip.add_theme_stylebox_override("panel", feed_style)
		loot_feed.add_child(feed_chip)
		var feed_row := HBoxContainer.new()
		feed_row.add_theme_constant_override("separation", 6)
		feed_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feed_chip.add_child(feed_row)
		var feed_icon := TextureRect.new()
		feed_icon.custom_minimum_size = Vector2(15, 15)
		feed_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		feed_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		feed_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loot_feed_icons.append(feed_icon)
		feed_row.add_child(feed_icon)
		var feed_label := Label.new()
		feed_label.add_theme_font_override("font", ui_pixel_font)
		feed_label.add_theme_font_size_override("font_size", 8)
		feed_label.add_theme_color_override("font_color", Color("ffe9c9"))
		feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		feed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loot_feed_labels.append(feed_label)
		feed_row.add_child(feed_label)

	# Inventory overlay ------------------------------------------------------
	inventory_backdrop = ColorRect.new()
	inventory_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_backdrop.color = Color("06080c", 0.68)
	inventory_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_backdrop.gui_input.connect(_on_inventory_backdrop_input)
	inventory_backdrop.visible = false
	inventory_backdrop.z_index = 50
	canvas.add_child(inventory_backdrop)

	# (Inventory header removed — no SURVIVOR'S KIT title, tabs, or close button.)

	# Character card (left) ---------------------------------------------------
	equipment_overlay = Control.new()
	equipment_overlay.set_anchors_preset(Control.PRESET_CENTER)
	equipment_overlay.anchor_left = 0.5
	equipment_overlay.anchor_top = 0.5
	equipment_overlay.anchor_right = 0.5
	equipment_overlay.anchor_bottom = 0.5
	equipment_overlay.offset_left = -540
	equipment_overlay.offset_top = -300
	equipment_overlay.offset_right = -300
	equipment_overlay.offset_bottom = 300
	equipment_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	equipment_overlay.visible = false
	equipment_overlay.z_index = 51
	canvas.add_child(equipment_overlay)
	var equipment_frame := _make_hud_panel(Vector2.ZERO, Vector2(240, 600))
	equipment_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment_overlay.add_child(equipment_frame)
	var loadout_title := Label.new()
	loadout_title.text = "LOADOUT"
	loadout_title.position = Vector2(18, 16)
	loadout_title.size = Vector2(204, 22)
	loadout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loadout_title.add_theme_font_override("font", ui_pixel_font)
	loadout_title.add_theme_font_size_override("font_size", 10)
	loadout_title.add_theme_color_override("font_color", Color("f2a33a"))
	equipment_overlay.add_child(loadout_title)

	hero_sprite_rect = TextureRect.new()
	hero_sprite_rect.position = Vector2(55, 46)
	hero_sprite_rect.size = Vector2(130, 150)
	hero_sprite_rect.custom_minimum_size = Vector2(130, 150)
	var hero_atlas := AtlasTexture.new()
	hero_atlas.atlas = player_texture
	hero_atlas.region = Rect2(0, 0, 48, 64)
	hero_sprite_rect.texture = hero_atlas
	hero_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipment_overlay.add_child(hero_sprite_rect)

	equipment_label = Label.new()
	equipment_label.visible = false
	equipment_overlay.add_child(equipment_label)
	equipment_environment_label = Label.new()
	equipment_environment_label.visible = false
	equipment_overlay.add_child(equipment_environment_label)

	var equipment_box := HBoxContainer.new()
	equipment_box.position = Vector2(28, 208)
	equipment_box.size = Vector2(184, 120)
	equipment_box.add_theme_constant_override("separation", 8)
	equipment_overlay.add_child(equipment_box)
	var weapon_col := VBoxContainer.new()
	weapon_col.add_theme_constant_override("separation", 4)
	equipment_box.add_child(weapon_col)
	var weapon_caption := Label.new()
	weapon_caption.text = "WEAPON"
	weapon_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_caption.add_theme_font_size_override("font_size", 8)
	weapon_caption.add_theme_color_override("font_color", Color("99a4b0"))
	weapon_col.add_child(weapon_caption)
	weapon_slot_button = _make_slot_button()
	weapon_slot_button.custom_minimum_size = Vector2(56, 56)
	weapon_slot_button.tooltip_text = "Weapon"
	weapon_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("weapon"))
	weapon_col.add_child(weapon_slot_button)
	var armor_col := VBoxContainer.new()
	armor_col.add_theme_constant_override("separation", 4)
	equipment_box.add_child(armor_col)
	var armor_caption := Label.new()
	armor_caption.text = "ARMOR"
	armor_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	armor_caption.add_theme_font_size_override("font_size", 8)
	armor_caption.add_theme_color_override("font_color", Color("99a4b0"))
	armor_col.add_child(armor_caption)
	armor_slot_button = _make_slot_button()
	armor_slot_button.custom_minimum_size = Vector2(56, 56)
	armor_slot_button.tooltip_text = "Armor"
	armor_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("armor"))
	armor_col.add_child(armor_slot_button)
	var accessory_col := VBoxContainer.new()
	accessory_col.add_theme_constant_override("separation", 4)
	equipment_box.add_child(accessory_col)
	var accessory_caption := Label.new()
	accessory_caption.text = "CHARM"
	accessory_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accessory_caption.add_theme_font_size_override("font_size", 8)
	accessory_caption.add_theme_color_override("font_color", Color("99a4b0"))
	accessory_col.add_child(accessory_caption)
	accessory_slot_button = _make_slot_button()
	accessory_slot_button.custom_minimum_size = Vector2(56, 56)
	accessory_slot_button.tooltip_text = "Charm"
	accessory_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("accessory"))
	accessory_col.add_child(accessory_slot_button)

	char_stats_label = Label.new()
	char_stats_label.position = Vector2(26, 344)
	char_stats_label.size = Vector2(188, 140)
	char_stats_label.add_theme_font_size_override("font_size", 10)
	char_stats_label.add_theme_color_override("font_color", Color("c3cbc4"))
	char_stats_label.text = ""
	equipment_overlay.add_child(char_stats_label)

	# Backpack panel (center) --------------------------------------------------
	inventory_panel = _make_compass_clear_panel()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.anchor_left = 0.5
	inventory_panel.anchor_top = 0.5
	inventory_panel.anchor_right = 0.5
	inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -280
	inventory_panel.offset_top = -300
	inventory_panel.offset_right = 540
	inventory_panel.offset_bottom = 300
	inventory_panel.custom_minimum_size = Vector2(820, 600)
	inventory_panel.visible = false
	inventory_panel.z_index = 51
	canvas.add_child(inventory_panel)
	var inventory_box := VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_box)
	var inventory_header := HBoxContainer.new()
	inventory_header.add_theme_constant_override("separation", 8)
	inventory_box.add_child(inventory_header)
	inventory_title_label = Label.new()
	inventory_title_label.text = "INVENTORY · 30 SLOTS"
	inventory_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_title_label.add_theme_font_override("font", ui_pixel_font)
	inventory_title_label.add_theme_font_size_override("font_size", 11)
	inventory_title_label.add_theme_color_override("font_color", Color("f2a33a"))
	inventory_header.add_child(inventory_title_label)
	var inventory_to_craft := _make_compass_action_button("CRAFTING")
	inventory_to_craft.custom_minimum_size = Vector2(132, 32)
	inventory_to_craft.pressed.connect(_open_inventory_screen.bind("crafting"))
	inventory_header.add_child(inventory_to_craft)
	var inventory_close := _make_compass_action_button("X")
	inventory_close.custom_minimum_size = Vector2(38, 32)
	inventory_close.pressed.connect(_close_inventory_screens)
	inventory_header.add_child(inventory_close)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 6
	inv_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inventory_box.add_child(inv_grid)
	for i in range(INVENTORY_GRID_SIZE):
		var inv_slot := _make_slot_button()
		inv_slot.custom_minimum_size = Vector2(88, 88)
		inv_slot.gui_input.connect(_on_inventory_slot_gui_input.bind(i))
		inv_slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		inventory_slot_buttons.append(inv_slot)
		inv_grid.add_child(inv_slot)
	selected_item_label = Label.new()
	selected_item_label.custom_minimum_size = Vector2(600, 44)
	selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_item_label.add_theme_font_size_override("font_size", 9)
	selected_item_label.add_theme_color_override("font_color", Color("99a4b0"))
	selected_item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_box.add_child(selected_item_label)
	var inventory_actions := HBoxContainer.new()
	inventory_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	inventory_actions.add_theme_constant_override("separation", 8)
	inventory_box.add_child(inventory_actions)
	assign_hotbar_button = _make_compass_action_button("TO HOTBAR")
	assign_hotbar_button.pressed.connect(_assign_selected_inventory_to_hotbar)
	inventory_actions.add_child(assign_hotbar_button)
	equip_inventory_button = _make_compass_action_button("EQUIP")
	equip_inventory_button.pressed.connect(_equip_selected_inventory_item)
	inventory_actions.add_child(equip_inventory_button)
	drop_inventory_button = _make_compass_action_button("DROP")
	drop_inventory_button.pressed.connect(_drop_selected_inventory_item)
	drop_inventory_button.visible = false
	inventory_actions.add_child(drop_inventory_button)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 9)
	message_label.add_theme_color_override("font_color", Color("99a4b0"))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.visible = false
	inventory_box.add_child(message_label)

	# Crafting is its own screen: category rail + recipe grid + focused detail
	# card. It no longer competes with inventory and equipment for width.
	crafting_panel = _make_compass_clear_panel()
	crafting_panel.set_anchors_preset(Control.PRESET_CENTER)
	crafting_panel.anchor_left = 0.5
	crafting_panel.anchor_top = 0.5
	crafting_panel.anchor_right = 0.5
	crafting_panel.anchor_bottom = 0.5
	crafting_panel.offset_left = -540
	crafting_panel.offset_top = -300
	crafting_panel.offset_right = 540
	crafting_panel.offset_bottom = 300
	crafting_panel.custom_minimum_size = Vector2(1080, 600)
	crafting_panel.visible = false
	crafting_panel.z_index = 51
	canvas.add_child(crafting_panel)
	var crafting_box := VBoxContainer.new()
	crafting_box.add_theme_constant_override("separation", 9)
	crafting_panel.add_child(crafting_box)

	var crafting_header := HBoxContainer.new()
	crafting_header.add_theme_constant_override("separation", 8)
	crafting_box.add_child(crafting_header)
	var recipe_title := Label.new()
	recipe_title.text = "CRAFTING"
	recipe_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recipe_title.add_theme_font_override("font", ui_pixel_font)
	recipe_title.add_theme_font_size_override("font_size", 11)
	recipe_title.add_theme_color_override("font_color", Color("f2a33a"))
	crafting_header.add_child(recipe_title)
	var crafting_to_inventory := _make_compass_action_button("INVENTORY")
	crafting_to_inventory.custom_minimum_size = Vector2(132, 32)
	crafting_to_inventory.pressed.connect(_open_inventory_screen.bind("inventory"))
	crafting_header.add_child(crafting_to_inventory)
	var crafting_close := _make_compass_action_button("X")
	crafting_close.custom_minimum_size = Vector2(38, 32)
	crafting_close.pressed.connect(_close_inventory_screens)
	crafting_header.add_child(crafting_close)

	var station_filter_box := HBoxContainer.new()
	station_filter_box.add_theme_constant_override("separation", 6)
	crafting_box.add_child(station_filter_box)
	for filter_data in [["all", "ALL"], ["hand", "HANDS"], ["workbench", "BENCH"], ["furnace", "FURNACE"], ["anvil", "ANVIL"]]:
		var filter_button := Button.new()
		filter_button.text = str(filter_data[1])
		filter_button.custom_minimum_size = Vector2(118, 30)
		filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_button.focus_mode = Control.FOCUS_NONE
		filter_button.add_theme_font_override("font", ui_pixel_font)
		filter_button.add_theme_font_size_override("font_size", 8)
		filter_button.set_meta("filter_id", str(filter_data[0]))
		filter_button.pressed.connect(_set_recipe_station_filter.bind(str(filter_data[0])))
		station_filter_buttons.append(filter_button)
		station_filter_box.add_child(filter_button)

	var crafting_body := HBoxContainer.new()
	crafting_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting_body.add_theme_constant_override("separation", 10)
	crafting_box.add_child(crafting_body)

	var recipes_panel := _make_inner_panel()
	recipes_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting_body.add_child(recipes_panel)
	var recipes_box := VBoxContainer.new()
	recipes_box.add_theme_constant_override("separation", 7)
	recipes_panel.add_child(recipes_box)
	var known_title := Label.new()
	known_title.text = "KNOWN RECIPES"
	known_title.add_theme_font_override("font", ui_pixel_font)
	known_title.add_theme_font_size_override("font_size", 8)
	known_title.add_theme_color_override("font_color", Color("99a4b0"))
	recipes_box.add_child(known_title)
	var recipe_scroll := ScrollContainer.new()
	recipe_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	recipes_box.add_child(recipe_scroll)
	var recipe_list := GridContainer.new()
	recipe_list.columns = 6
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("h_separation", 8)
	recipe_list.add_theme_constant_override("v_separation", 8)
	recipe_scroll.add_child(recipe_list)
	for i in range(recipes.size()):
		var recipe_button := _make_slot_button()
		recipe_button.custom_minimum_size = Vector2(82, 82)
		recipe_button.focus_mode = Control.FOCUS_NONE
		recipe_button.add_theme_font_size_override("font_size", 10)
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(i))
		recipe_buttons.append(recipe_button)
		recipe_list.add_child(recipe_button)

	var recipe_detail_panel := _make_inner_panel()
	recipe_detail_panel.custom_minimum_size = Vector2(330, 0)
	recipe_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting_body.add_child(recipe_detail_panel)
	var recipe_detail_box := VBoxContainer.new()
	recipe_detail_box.add_theme_constant_override("separation", 10)
	recipe_detail_panel.add_child(recipe_detail_box)
	var detail_title := Label.new()
	detail_title.text = "SELECTED RECIPE"
	detail_title.add_theme_font_override("font", ui_pixel_font)
	detail_title.add_theme_font_size_override("font_size", 8)
	detail_title.add_theme_color_override("font_color", Color("99a4b0"))
	recipe_detail_box.add_child(detail_title)
	crafting_label = Label.new()
	crafting_label.custom_minimum_size = Vector2(300, 300)
	crafting_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting_label.add_theme_font_size_override("font_size", 11)
	crafting_label.add_theme_color_override("font_color", Color("e8edf2"))
	crafting_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_detail_box.add_child(crafting_label)
	craft_button = _make_compass_action_button("CRAFT")
	craft_button.custom_minimum_size = Vector2(300, 42)
	craft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	craft_button.pressed.connect(_craft_selected_recipe)
	recipe_detail_box.add_child(craft_button)
	stations_label = Label.new()
	stations_label.visible = false
	recipe_detail_box.add_child(stations_label)
	controls_label = Label.new()
	controls_label.visible = false
	recipe_detail_box.add_child(controls_label)

	# Chest panel (replaces forge while a chest is open) -----------------------
	chest_panel = _make_compass_clear_panel()
	chest_panel.set_anchors_preset(Control.PRESET_CENTER)
	chest_panel.offset_left = -540
	chest_panel.offset_top = -300
	chest_panel.offset_right = -300
	chest_panel.offset_bottom = 300
	chest_panel.visible = false
	chest_panel.z_index = 52
	canvas.add_child(chest_panel)
	var chest_box := VBoxContainer.new()
	chest_box.add_theme_constant_override("separation", 8)
	chest_panel.add_child(chest_box)
	var chest_title := Label.new()
	chest_title.text = "ANCIENT CHEST"
	chest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_title.add_theme_font_override("font", ui_pixel_font)
	chest_title.add_theme_font_size_override("font_size", 9)
	chest_title.add_theme_color_override("font_color", Color("f2a33a"))
	chest_box.add_child(chest_title)
	var chest_grid := GridContainer.new()
	chest_grid.columns = 3
	chest_grid.add_theme_constant_override("h_separation", 8)
	chest_grid.add_theme_constant_override("v_separation", 8)
	chest_box.add_child(chest_grid)
	for i in range(15):
		var chest_slot := _make_slot_button()
		chest_slot.custom_minimum_size = Vector2(60, 60)
		chest_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		chest_slot.gui_input.connect(_on_chest_slot_gui_input.bind(i))
		chest_slot_buttons.append(chest_slot)
		chest_grid.add_child(chest_slot)

	# Dragged item preview -----------------------------------------------------
	held_item_panel = _make_hud_panel(Vector2(0, 0), Vector2(72, 40))
	held_item_panel.visible = false
	held_item_panel.z_index = 55
	canvas.add_child(held_item_panel)
	var held_row := HBoxContainer.new()
	held_row.add_theme_constant_override("separation", 4)
	held_item_panel.add_child(held_row)
	held_item_icon = TextureRect.new()
	held_item_icon.custom_minimum_size = Vector2(26, 26)
	held_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	held_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	held_row.add_child(held_item_icon)
	held_item_amount_label = Label.new()
	held_item_amount_label.add_theme_font_size_override("font_size", 13)
	held_row.add_child(held_item_amount_label)

	_apply_station_filter_styles()
	_update_day_icon()
	_setup_journal(canvas)
	_setup_path_dialog(canvas)
	_setup_mobile_controls(canvas)
	_setup_debug_console(canvas)
	_setup_main_menu(canvas)
	_setup_build_panel(canvas)


func _ui_tex(path: String) -> Texture2D:
	if ui_tex_cache.has(path):
		return ui_tex_cache[path]
	var tex := ResourceLoader.load(path) as Texture2D
	ui_tex_cache[path] = tex
	return tex


func _pixel_sb(path: String, margin: int) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _ui_tex(path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = margin
	sb.content_margin_top = margin
	sb.content_margin_right = margin
	sb.content_margin_bottom = margin
	return sb


func _apply_pixel_slot_style(button: Button, selected: bool) -> void:
	var normal := _pixel_sb("res://assets/ui/slot_selected.png" if selected else "res://assets/ui/slot.png", 5)
	normal.content_margin_left = 5
	normal.content_margin_top = 5
	normal.content_margin_right = 5
	normal.content_margin_bottom = 5
	button.add_theme_stylebox_override("normal", normal)
	var hover := _pixel_sb("res://assets/ui/slot_selected.png", 5)
	hover.content_margin_left = 5
	hover.content_margin_top = 5
	hover.content_margin_right = 5
	hover.content_margin_bottom = 5
	button.add_theme_stylebox_override("hover", hover)
	var pressed := _pixel_sb("res://assets/ui/slot_selected.png", 5)
	pressed.content_margin_left = 5
	pressed.content_margin_top = 5
	pressed.content_margin_right = 5
	pressed.content_margin_bottom = 5
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)


func _make_divider(width: int) -> Control:
	var div := Control.new()
	div.size = Vector2(width, 3)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := ColorRect.new()
	top.color = Color("2e3a4e")
	top.position = Vector2(0, 0)
	top.size = Vector2(width, 1)
	div.add_child(top)
	var accent := ColorRect.new()
	accent.color = Color("f2a33a")
	accent.position = Vector2(0, 1)
	accent.size = Vector2(18, 1)
	div.add_child(accent)
	var bottom := ColorRect.new()
	bottom.color = Color("0c0f15")
	bottom.position = Vector2(0, 2)
	bottom.size = Vector2(width, 1)
	div.add_child(bottom)
	return div


func _update_health_hearts() -> void:
	if health_hearts.is_empty():
		return
	var per_heart := float(MAX_HEALTH) / float(health_hearts.size())
	for i in range(health_hearts.size()):
		var heart_hp := clampf(health - float(i) * per_heart, 0.0, per_heart)
		var tex := heart_empty_tex
		if heart_hp >= per_heart - 0.5:
			tex = heart_full_tex
		elif heart_hp >= per_heart * 0.5:
			tex = heart_half_tex
		health_hearts[i].texture = tex


func _make_ring_texture(size: int, inner_ratio: float, color_a: Color, color_b: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var r_in := size * 0.5 * inner_ratio
	var r_out := size * 0.5 - 1.0
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d >= r_in and d <= r_out:
				var angle := atan2(y + 0.5 - center.y, x + 0.5 - center.x)
				var t := (angle + PI) / TAU
				image.set_pixel(x, y, color_a.lerp(color_b, t))
	return ImageTexture.create_from_image(image)


func _make_circle_texture(size: int, color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5 - 1.0
	for y in range(size):
		for x in range(size):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _make_lens_vignette_texture(size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5 - 1.0
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d > radius:
				continue  # fully transparent outside the circle — no black square
			var t := clampf((d - size * 0.38) / (size * 0.12), 0.0, 1.0)
			if t > 0.0:
				image.set_pixel(x, y, Color(0.02, 0.03, 0.05, t * t * 0.85))
	return ImageTexture.create_from_image(image)


func _status_icon_id(status: String) -> String:
	match status:
		"poison":
			return "status_poison"
		"burn":
			return "status_burn"
		"wet":
			return "status_wet"
		"root_bind":
			return "status_root_bind"
		"fragile":
			return "status_fragile"
		"armor_break":
			return "status_armor_break"
	return "status_slow"


func _status_chip_color(status: String) -> Color:
	match status:
		"burn", "armor_break":
			return Color("ffc09b")
		"poison", "root_bind":
			return Color("cfe9a6")
		"wet", "slow", "fragile":
			return Color("bdeaff")
	return Color("e8edf2")


func _rebuild_status_chips() -> void:
	if status_chips_root == null:
		return
	var text := _format_player_statuses().strip_edges()
	if text == status_chips_cache:
		return
	status_chips_cache = text
	for child in status_chips_root.get_children():
		child.queue_free()
	if player_statuses.is_empty():
		return
	for status in player_statuses.keys():
		var status_data: Dictionary = player_statuses[status]
		var remaining := ceili(float(status_data.get("time", 0.0)))
		var chip_panel := PanelContainer.new()
		var style := _pixel_sb("res://assets/ui/frame_inner.png", 6)
		style.content_margin_left = 7
		style.content_margin_top = 3
		style.content_margin_right = 7
		style.content_margin_bottom = 3
		chip_panel.add_theme_stylebox_override("panel", style)
		chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip_row := HBoxContainer.new()
		chip_row.add_theme_constant_override("separation", 5)
		chip_panel.add_child(chip_row)
		var chip_icon := TextureRect.new()
		var icon_id := _status_icon_id(str(status))
		chip_icon.texture = _ui_tex("res://assets/ui/%s.png" % icon_id)
		chip_icon.custom_minimum_size = Vector2(14, 14)
		chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip_row.add_child(chip_icon)
		var chip_label := Label.new()
		chip_label.text = "%s %d" % [str(status).capitalize(), remaining]
		chip_label.add_theme_font_override("font", ui_pixel_font)
		chip_label.add_theme_font_size_override("font_size", 8)
		chip_label.add_theme_color_override("font_color", _status_chip_color(str(status)))
		chip_row.add_child(chip_label)
		status_chips_root.add_child(chip_panel)


func _update_day_icon() -> void:
	if day_icon_rect == null or day_time_label == null:
		return
	day_time_label.text = _time_period_text().to_upper()
	# Sun/moon icon hidden — only the DAY text stays.


func _toast_message(message: String, duration: float = 4.0) -> void:
	if hud_toast_label != null:
		hud_toast_label.text = message
	if hud_toast_panel != null:
		hud_toast_panel.visible = true
		var tween := create_tween()
		tween.tween_interval(duration)
		tween.tween_callback(func() -> void:
			hud_toast_panel.visible = false
		)


func _update_hud_toast() -> void:
	if hud_toast_label == null:
		return
	if hud_toast_label.text != last_message:
		hud_toast_label.text = last_message


func _set_recipe_station_filter(filter_id: String) -> void:
	recipe_station_filter = filter_id
	_ensure_selected_recipe_known()
	_apply_station_filter_styles()
	_update_recipe_buttons()


func _apply_station_filter_styles() -> void:
	for button in station_filter_buttons:
		var active := str(button.get_meta("filter_id", "all")) == recipe_station_filter
		var base := _pixel_sb("res://assets/ui/button_hover.png" if active else "res://assets/ui/button.png", 5)
		base.content_margin_left = 8
		base.content_margin_top = 5
		base.content_margin_right = 8
		base.content_margin_bottom = 5
		button.add_theme_stylebox_override("normal", base)
		button.add_theme_stylebox_override("hover", base)
		button.add_theme_stylebox_override("pressed", base)
		button.add_theme_color_override("font_color", Color("ffd08a") if active else Color("99a4b0"))


func _update_map_fog() -> void:
	if map_fog_rect == null:
		return
	var image := Image.create(FULL_MAP_WIDTH, FULL_MAP_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.024, 0.031, 0.047, 1.0))
	var px := clampf(player_position.x / float(WORLD_WIDTH * TILE_SIZE), 0.0, 1.0) * float(FULL_MAP_WIDTH)
	var py := clampf(player_position.y / float(WORLD_HEIGHT * TILE_SIZE), 0.0, 1.0) * float(FULL_MAP_HEIGHT)
	var radius := float(FULL_MAP_WIDTH) * 0.16
	for y in range(FULL_MAP_HEIGHT):
		for x in range(FULL_MAP_WIDTH):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(px, py))
			var a := clampf(d / radius, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.024, 0.031, 0.047, a * a))
	map_fog_rect.texture = ImageTexture.create_from_image(image)


func _enemy_idle_texture(enemy_type: String) -> Texture2D:
	if not enemy_textures.has(enemy_type):
		return null
	var sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	if sets.has("idle"):
		return sets["idle"] as Texture2D
	return enemy_textures[enemy_type] as Texture2D


func _enemy_idle_region(enemy_type: String) -> Rect2:
	var texture := _enemy_idle_texture(enemy_type)
	if texture == null:
		return Rect2()
	var sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	if sets.has("idle"):
		var spec := _enemy_animation_spec(enemy_type, "idle")
		var frames := maxi(1, int(spec.get("frames", 1)))
		return Rect2(0, 0, float(texture.get_width()) / float(frames), float(texture.get_height()))
	return Rect2(0, 0, float(texture.get_width()) / 4.0, float(texture.get_height()) / 3.0)


func _setup_path_dialog(canvas: CanvasLayer) -> void:
	# Dialogue panel for the first NPC's path choice (science vs magic).
	path_dialog_panel = PanelContainer.new()
	path_dialog_panel.set_anchors_preset(Control.PRESET_CENTER)
	path_dialog_panel.offset_left = -360
	path_dialog_panel.offset_top = -160
	path_dialog_panel.offset_right = 360
	path_dialog_panel.offset_bottom = 160
	path_dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	path_dialog_panel.z_index = 120
	var style := _pixel_sb("res://assets/ui/frame.png", 10)
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	path_dialog_panel.add_theme_stylebox_override("panel", style)
	path_dialog_panel.visible = false
	canvas.add_child(path_dialog_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	path_dialog_panel.add_child(box)

	var title := Label.new()
	title.text = "THE SKY WANDERER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("ffc766"))
	box.add_child(title)

	var speech := Label.new()
	speech.text = "You have quelled the Leviathan, child of the sky.\n\nBefore you, the road divides. The stars whisper of MACHINES and flight to other worlds. The deep echoes of MANA and doors to other realms.\n\nChoose, and the world will reshape itself around your path."
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size = Vector2(660, 120)
	speech.add_theme_font_override("font", ui_pixel_font)
	speech.add_theme_font_size_override("font_size", 9)
	speech.add_theme_color_override("font_color", Color("e8edf2"))
	box.add_child(speech)

	var choice_row := HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("separation", 20)
	box.add_child(choice_row)

	var science_btn := _make_compass_action_button("SCIENCE — STARS & MACHINES")
	science_btn.custom_minimum_size = Vector2(300, 42)
	science_btn.pressed.connect(_choose_path.bind("science"))
	choice_row.add_child(science_btn)

	var magic_btn := _make_compass_action_button("MAGIC — MANA & REALMS")
	magic_btn.custom_minimum_size = Vector2(280, 42)
	magic_btn.pressed.connect(_choose_path.bind("magic"))
	choice_row.add_child(magic_btn)

	var hint := Label.new()
	hint.text = "This choice is permanent."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", ui_pixel_font)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color("99a4b0"))
	box.add_child(hint)


func _setup_journal(canvas: CanvasLayer) -> void:
	journal_backdrop = ColorRect.new()
	journal_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	journal_backdrop.color = Color("06080c", 0.68)
	journal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	journal_backdrop.visible = false
	journal_backdrop.z_index = 68
	canvas.add_child(journal_backdrop)

	journal_panel = _make_hud_panel(Vector2.ZERO, Vector2.ZERO)
	journal_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	journal_panel.anchor_left = 0.07
	journal_panel.anchor_top = 0.07
	journal_panel.anchor_right = 0.93
	journal_panel.anchor_bottom = 0.91
	journal_panel.offset_left = 0
	journal_panel.offset_top = 0
	journal_panel.offset_right = 0
	journal_panel.offset_bottom = 0
	journal_panel.visible = false
	journal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	journal_panel.z_index = 69
	canvas.add_child(journal_panel)

	var journal_root := VBoxContainer.new()
	journal_root.add_theme_constant_override("separation", 10)
	journal_panel.add_child(journal_root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	journal_root.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	header.add_child(title_box)
	var title := Label.new()
	title.text = "JOURNAL"
	title.add_theme_font_override("font", ui_pixel_font)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("f2a33a"))
	title_box.add_child(title)
	var title_sub := Label.new()
	title_sub.text = "FIELD JOURNAL · MEMORY OF THE WORLD"
	title_sub.add_theme_font_size_override("font_size", 9)
	title_sub.add_theme_color_override("font_color", Color("6b746e"))
	title_box.add_child(title_sub)
	journal_progress_label = Label.new()
	journal_progress_label.add_theme_font_size_override("font_size", 10)
	journal_progress_label.add_theme_color_override("font_color", Color("8fa790"))
	title_box.add_child(journal_progress_label)
	var close_button := _make_compass_action_button("X")
	close_button.custom_minimum_size = Vector2(38, 34)
	close_button.tooltip_text = "Close journal"
	close_button.pressed.connect(_set_journal_open.bind(false))
	header.add_child(close_button)

	var header_line := ColorRect.new()
	header_line.custom_minimum_size = Vector2(1, 1)
	header_line.color = Color("343e49", 0.85)
	header_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal_root.add_child(header_line)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	journal_root.add_child(tabs)
	for tab_name in ["Recipes", "Bestiary", "Materials", "Alchemy", "Story"]:
		var tab_button := _make_journal_tab_button(tab_name)
		tab_button.pressed.connect(_select_journal_tab.bind(tab_name))
		journal_tab_buttons[tab_name] = tab_button
		tabs.add_child(tab_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	journal_root.add_child(body)

	var index_panel := _make_inner_panel()
	index_panel.custom_minimum_size = Vector2(300, 420)
	body.add_child(index_panel)
	var index_box := VBoxContainer.new()
	index_box.add_theme_constant_override("separation", 6)
	index_panel.add_child(index_box)
	var index_title := Label.new()
	index_title.text = "INDEX"
	index_title.add_theme_font_size_override("font_size", 10)
	index_title.add_theme_color_override("font_color", Color("99a4b0"))
	index_box.add_child(index_title)
	var entry_scroll := ScrollContainer.new()
	entry_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	index_box.add_child(entry_scroll)
	journal_entry_list = VBoxContainer.new()
	journal_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_entry_list.add_theme_constant_override("separation", 4)
	entry_scroll.add_child(journal_entry_list)

	var detail_panel := _make_inner_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 8)
	detail_panel.add_child(detail_box)
	journal_detail_title = Label.new()
	journal_detail_title.text = "Select an entry"
	journal_detail_title.add_theme_font_size_override("font_size", 17)
	journal_detail_title.add_theme_color_override("font_color", Color("e8edf2"))
	detail_box.add_child(journal_detail_title)
	var detail_line := ColorRect.new()
	detail_line.custom_minimum_size = Vector2(1, 1)
	detail_line.color = Color("343e49", 0.8)
	detail_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_box.add_child(detail_line)
	journal_detail_sprite = TextureRect.new()
	journal_detail_sprite.custom_minimum_size = Vector2(0, 128)
	journal_detail_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	journal_detail_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# (journal sprite region removed — AtlasTexture below)
	journal_detail_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journal_detail_sprite.visible = false
	detail_box.add_child(journal_detail_sprite)
	journal_detail_text = RichTextLabel.new()
	journal_detail_text.bbcode_enabled = true
	journal_detail_text.fit_content = false
	journal_detail_text.scroll_active = true
	journal_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_detail_text.add_theme_font_size_override("normal_font_size", 13)
	journal_detail_text.add_theme_color_override("default_color", Color("cbd3dc"))
	detail_box.add_child(journal_detail_text)


func _make_inner_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _pixel_sb("res://assets/ui/frame_inner.png", 8)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_journal_tab_button(tab_name: String) -> Button:
	var button := Button.new()
	button.text = tab_name.to_upper()
	button.custom_minimum_size = Vector2(138, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 10)
	_apply_journal_tab_style(button, false)
	return button


func _apply_journal_tab_style(button: Button, selected: bool) -> void:
	var base := _pixel_sb("res://assets/ui/button_hover.png" if selected else "res://assets/ui/button.png", 5)
	base.content_margin_left = 10
	base.content_margin_top = 6
	base.content_margin_right = 10
	base.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", base)
	button.add_theme_stylebox_override("pressed", base)
	button.add_theme_color_override("font_color", Color("ffd08a") if selected else Color("a6b0bb"))


func _make_journal_entry_button(label_text: String, entry_id: String, known: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	button.tooltip_text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(270, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	if known and journal_active_tab in ["Recipes", "Materials"]:
		button.icon = _item_icon(entry_id)
		button.expand_icon = true
	var base := _pixel_sb("res://assets/ui/button_hover.png" if entry_id == journal_selected_entry else "res://assets/ui/button.png", 5)
	base.content_margin_left = 8
	base.content_margin_right = 8
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", base)
	button.add_theme_stylebox_override("pressed", base)
	button.add_theme_color_override("font_color", Color("e8edf2") if known else Color("606b76"))
	return button


func _set_journal_open(open: bool) -> void:
	journal_open = open
	if open:
		inventory_open = false
		_close_chest()
		_set_full_map_open(false)
		journal_unread_count = 0
		_refresh_journal()
	if journal_panel != null:
		journal_panel.visible = open
	if journal_backdrop != null:
		journal_backdrop.visible = open
	if mobile_controls != null:
		mobile_controls.visible = _mobile_controls_enabled() and not open


func _select_journal_tab(tab_name: String) -> void:
	journal_active_tab = tab_name
	journal_selected_entry = ""
	_refresh_journal()


func _select_journal_entry(entry_id: String) -> void:
	journal_selected_entry = entry_id
	_refresh_journal()


func _refresh_journal() -> void:
	if journal_entry_list == null:
		return
	for tab_name in journal_tab_buttons.keys():
		_apply_journal_tab_style(journal_tab_buttons[tab_name], str(tab_name) == journal_active_tab)
	for child in journal_entry_list.get_children():
		journal_entry_list.remove_child(child)
		child.queue_free()

	var entries := _journal_entries(journal_active_tab)
	if journal_selected_entry == "" and not entries.is_empty():
		journal_selected_entry = str(entries[0])
	for entry_variant in entries:
		var entry_id := str(entry_variant)
		var known := _journal_entry_is_known(journal_active_tab, entry_id)
		var entry_button := _make_journal_entry_button(_journal_entry_label(journal_active_tab, entry_id), entry_id, known)
		entry_button.pressed.connect(_select_journal_entry.bind(entry_id))
		journal_entry_list.add_child(entry_button)
	_update_journal_detail()
	_update_journal_progress()


func _journal_entries(tab_name: String) -> Array[String]:
	var entries: Array[String] = []
	if tab_name == "Recipes":
		for recipe in recipes:
			entries.append(str(recipe.get("id", recipe.get("result", ""))))
	elif tab_name == "Bestiary":
		for enemy_type in enemy_perception_profiles.keys():
			entries.append(str(enemy_type))
		entries.sort()
	elif tab_name == "Materials":
		for item_id in item_names.keys():
			var material_id := str(item_id)
			if _is_journal_material(material_id):
				entries.append(material_id)
		entries.sort()
	elif tab_name == "Alchemy":
		for result_id in alchemy_knowledge.keys():
			entries.append(str(result_id))
		entries.sort()
		if entries.is_empty():
			entries.append("__empty__")
	elif tab_name == "Story":
		entries.append("story_arc")
	return entries


func _journal_entry_is_known(tab_name: String, entry_id: String) -> bool:
	if tab_name == "Story":
		return true
	if tab_name == "Recipes":
		return bool(known_recipes.get(entry_id, false))
	if tab_name == "Bestiary":
		return int((bestiary_knowledge.get(entry_id, {}) as Dictionary).get("stage", 0)) > 0
	if tab_name == "Materials":
		return int((material_knowledge.get(entry_id, {}) as Dictionary).get("stage", 0)) > 0
	if tab_name == "Alchemy":
		return entry_id != "__empty__" and alchemy_knowledge.has(entry_id)
	return false


func _journal_entry_label(tab_name: String, entry_id: String) -> String:
	if tab_name == "Story":
		return "The Awakening Storm"
	if entry_id == "__empty__":
		return "No experiments recorded"
	if not _journal_entry_is_known(tab_name, entry_id):
		return "Unknown entry"
	if tab_name == "Recipes" or tab_name == "Materials" or tab_name == "Alchemy":
		return _item_display_name(entry_id)
	if tab_name == "Bestiary":
		return str(_enemy_template(entry_id).get("name", entry_id.capitalize()))
	return entry_id


func _update_journal_detail() -> void:
	if journal_detail_title == null or journal_detail_text == null:
		return
	var entry_id := journal_selected_entry
	if entry_id == "" or entry_id == "__empty__":
		journal_detail_title.text = "No recorded knowledge"
		journal_detail_text.text = "[color=#879086]Experiments and discoveries will be written here automatically.[/color]"
		return
	var known := _journal_entry_is_known(journal_active_tab, entry_id)
	if journal_detail_sprite != null:
		var preview_texture: Texture2D = null
		var preview_region := Rect2()
		if journal_active_tab == "Bestiary" and known:
			preview_texture = _enemy_idle_texture(entry_id)
			preview_region = _enemy_idle_region(entry_id)
		if preview_texture != null:
			journal_detail_sprite.visible = true
			if preview_region.size != Vector2.ZERO:
				var atlas := AtlasTexture.new()
				atlas.atlas = preview_texture
				atlas.region = preview_region
				journal_detail_sprite.texture = atlas
			else:
				journal_detail_sprite.texture = preview_texture
		else:
			journal_detail_sprite.visible = false
	if not known:
		journal_detail_title.text = "Unknown entry"
		journal_detail_text.text = "[color=#777f76]This knowledge has not been discovered yet.[/color]\n\nSearch ruins, observe creatures, collect unfamiliar materials, and conduct experiments."
		return
	journal_detail_title.text = _journal_entry_label(journal_active_tab, entry_id)
	match journal_active_tab:
		"Story":
			journal_detail_text.text = _storm_journal_text()
		"Recipes":
			journal_detail_text.text = _recipe_journal_text(entry_id)
		"Bestiary":
			journal_detail_text.text = _bestiary_journal_text(entry_id)
		"Materials":
			journal_detail_text.text = _material_journal_text(entry_id)
		"Alchemy":
			journal_detail_text.text = _alchemy_journal_text(entry_id)


func _update_journal_progress() -> void:
	if journal_progress_label == null:
		return
	var entries := _journal_entries(journal_active_tab)
	var known_count := 0
	for entry_id in entries:
		if _journal_entry_is_known(journal_active_tab, entry_id):
			known_count += 1
	var total := 0 if entries == ["__empty__"] else entries.size()
	journal_progress_label.text = "%s  |  %d / %d entries" % [journal_active_tab, known_count, total]


func _reset_knowledge() -> void:
	known_recipes.clear()
	bestiary_knowledge.clear()
	material_knowledge.clear()
	alchemy_knowledge.clear()
	wind_shard_picked = false
	storm_herald_defeated = false
	depth_warden_defeated = false
	sky_leviathan_spawned = false
	sky_leviathan_defeated = false
	path_choice = ""
	npc_wanderer_active = false
	npc_wanderer_pos = Vector2(-1.0, -1.0)
	observatory_pos = Vector2i(-1, -1)
	moon_altar_pos = Vector2i(-1, -1)
	path_dialog_open = false
	depth_sanctum_activated = false
	depth_warden_spawned = false
	storm_active = false
	storm_tornado_phase = ""
	for recipe in recipes:
		var recipe_id := str(recipe.get("id", recipe.get("result", "")))
		var station := str(recipe.get("station", "hand"))
		if station == "hand" or recipe_id in ["wooden_pickaxe", "ancient_chest", "furnace"]:
			known_recipes[recipe_id] = true
	for starting_material in ["dirt", "wood"]:
		material_knowledge[starting_material] = {
			"stage": 1,
			"found": int(inventory.get(starting_material, 0))
		}
	journal_unread_count = 0
	journal_observation_timer = 0.0


func _record_recipe_known(recipe_id: String) -> void:
	if recipe_id == "" or bool(known_recipes.get(recipe_id, false)):
		return
	known_recipes[recipe_id] = true
	_mark_journal_updated()


func _update_knowledge_observations(delta: float) -> void:
	journal_observation_timer += delta
	if journal_observation_timer < 0.45:
		return
	journal_observation_timer = 0.0
	for enemy in enemies:
		var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		if player_position.distance_to(enemy_pos) > 420.0:
			continue
		if _has_perception_line_of_sight(player_position, enemy_pos):
			_observe_enemy(str(enemy.get("type", "")))


func _observe_enemy(enemy_type: String) -> void:
	if enemy_type == "":
		return
	var record: Dictionary = bestiary_knowledge.get(enemy_type, {"stage": 0, "kills": 0})
	if int(record.get("stage", 0)) >= 1:
		return
	record["stage"] = 1
	bestiary_knowledge[enemy_type] = record
	_mark_journal_updated()


func _record_enemy_kill(enemy_type: String) -> void:
	if enemy_type == "":
		return
	var record: Dictionary = bestiary_knowledge.get(enemy_type, {"stage": 0, "kills": 0})
	var kills := int(record.get("kills", 0)) + 1
	var old_stage := int(record.get("stage", 0))
	record["kills"] = kills
	record["stage"] = 3 if kills >= 3 else 2
	bestiary_knowledge[enemy_type] = record
	if int(record["stage"]) > old_stage:
		_mark_journal_updated()


func _is_journal_material(item_id: String) -> bool:
	if not item_names.has(item_id):
		return false
	if tools.has(item_id) or gear_stats.has(item_id):
		return false
	return item_id not in [
		"workbench", "furnace", "anvil", "settlement_heart", "ancient_chest",
		"stone_altar", "drain_valve", "sapling", "torch"
	]


func _record_material_found(item_id: String, amount: int) -> void:
	if amount <= 0 or not _is_journal_material(item_id):
		return
	var record: Dictionary = material_knowledge.get(item_id, {"stage": 0, "found": 0})
	var old_stage := int(record.get("stage", 0))
	var found := int(record.get("found", 0)) + amount
	record["found"] = found
	record["stage"] = 3 if found >= 15 else (2 if found >= 5 else 1)
	material_knowledge[item_id] = record
	if int(record["stage"]) > old_stage:
		_mark_journal_updated()
	elif journal_open:
		_refresh_journal()


func _record_alchemy_result(result_id: String, ingredients: Dictionary) -> void:
	var record: Dictionary = alchemy_knowledge.get(result_id, {"attempts": 0, "ingredients": {}})
	record["attempts"] = int(record.get("attempts", 0)) + 1
	record["ingredients"] = ingredients.duplicate(true)
	alchemy_knowledge[result_id] = record
	_mark_journal_updated()


func _mark_journal_updated() -> void:
	journal_unread_count += 1
	if journal_open:
		_refresh_journal()


func _recipe_journal_text(recipe_id: String) -> String:
	for recipe in recipes:
		if str(recipe.get("id", "")) != recipe_id:
			continue
		var cost: Dictionary = recipe.get("cost", {})
		return "[color=#ad9a73]CRAFTING STATION[/color]\n%s\n\n[color=#ad9a73]REQUIRED MATERIALS[/color]\n%s\n\n[color=#819783]STATUS[/color]\nRecorded and understood." % [
			_station_display_name(str(recipe.get("station", "hand"))),
			_recipe_cost_text(recipe)
		]
	return "Recipe data is unavailable."


func _bestiary_journal_text(enemy_type: String) -> String:
	var record: Dictionary = bestiary_knowledge.get(enemy_type, {})
	var stage := int(record.get("stage", 0))
	var kills := int(record.get("kills", 0))
	var data := _enemy_template(enemy_type)
	var text := "[color=#ad9a73]HABITAT[/color]\n%s\n\n[color=#819783]RESEARCH[/color]\nStage %d of 4  |  Kills recorded: %d" % [
		_enemy_habitat(enemy_type),
		stage,
		kills
	]
	if stage >= 2:
		var approximate_hp := maxi(5, int(round(float(data.get("max_hp", 10)) / 5.0) * 5.0))
		text += "\n\n[color=#ad9a73]COMBAT OBSERVATION[/color]\nRough vitality: about %d\nKnown damage: %s" % [
			approximate_hp,
			str(data.get("damage_type", "physical")).capitalize()
		]
		var status := str(data.get("status_on_hit", ""))
		if status != "":
			text += "\nKnown effect: %s" % status.capitalize()
	if stage >= 3:
		var profile := _enemy_perception_profile(enemy_type)
		text += "\n\n[color=#ad9a73]BEHAVIOR AND SPOILS[/color]\nCommon drop: %s\nHearing: %s\nLight response: %s" % [
			_item_display_name(str(data.get("drop", "wild_ichor"))),
			_knowledge_rating(float(profile.get("hearing", 1.0))),
			_knowledge_rating(float(profile.get("light_sensitivity", 1.0)))
		]
	if stage < 4:
		text += "\n\n[color=#777f76]Study a trophy to reveal exact resistances and rare spoils.[/color]"
	return text


func _material_journal_text(item_id: String) -> String:
	var record: Dictionary = material_knowledge.get(item_id, {})
	var stage := int(record.get("stage", 0))
	var found := int(record.get("found", 0))
	var text := "[color=#819783]DISCOVERY[/color]\nRecognized material. Samples collected: %d\n\n[color=#ad9a73]APPEARANCE[/color]\nRecorded in the field journal." % found
	if stage >= 2:
		var uses := _recipes_using_material(item_id)
		text += "\n\n[color=#ad9a73]KNOWN USES[/color]\n%s" % (", ".join(uses) if not uses.is_empty() else "No practical use recorded yet.")
	if stage >= 3:
		text += "\n\n[color=#ad9a73]MEASURED PROPERTIES[/color]\nInventory count: %d\nRecipe connections: %d" % [
			int(inventory.get(item_id, 0)),
			_recipes_using_material(item_id).size()
		]
	else:
		text += "\n\n[color=#777f76]Collect more samples to reveal practical and measured properties.[/color]"
	return text


func _storm_journal_text() -> String:
	var best := mini(bestiary_knowledge.size(), STORM_BESTIARY_NEED)
	var rec := 0
	for rid in STORM_RECIPES_NEED:
		if known_recipes.has(rid):
			rec += 1
	var alc := mini(alchemy_knowledge.size(), STORM_ALCHEMY_NEED)
	var lines := "[color=#9fc4e8]THE AWAKENING STORM[/color]\n\n"
	if storm_herald_defeated:
		lines += "[color=#82d49a]The storm has been quelled. A shard of living wind remains.[/color]\n"
		if wind_shard_picked:
			lines += "\n[color=#e8c46a]CHAPTER II — THE CALL FROM BELOW[/color]\n"
			if depth_warden_defeated:
				lines += "[color=#82d49a]The Warden is defeated. A shard of living earth rests with you.[/color]\n"
			elif depth_warden_spawned:
				lines += "[color=#e8c46a]The Warden is loose in the sanctum. Face it![/color]\n"
			else:
				lines += "Deep beneath the roots, a sealed sanctum waits.\n"
				lines += "The wind left you two shards — one for [color=#9fc4e8]Wind Boots[/color],\n"
				lines += "and one to place upon the [color=#9fc4e8]Depth Altar[/color] to wake its guardian.\n"
			lines += "The wind called you here. The earth will answer.\n"
	elif sky_leviathan_defeated:
		lines += "[color=#82d49a]The Leviathan has fallen from the sky.\nIts scales and the Sky Shard rest with you.[/color]\n"
		lines += "\n[color=#e8c46a]CHAPTER III — THE SKY ISLANDS[/color]\n"
		lines += "The sky islands are yours to explore.\n"
		lines += "The Sky Shard hums — it wants to be taken somewhere new...\n"
	elif sky_leviathan_spawned:
		lines += "[color=#e8c46a]The Sky Leviathan circles the islands! Face it![/color]\n"
	elif storm_active:
		lines += "[color=#e8c46a]The sky darkens... follow the wind to the storm's heart.[/color]\n"
	else:
		lines += "Study the land to draw the storm:\n"
		lines += "[color=#d8c477]Bestiary[/color] %d/%d\n" % [best, STORM_BESTIARY_NEED]
		lines += "[color=#d8c477]Recipes[/color] %d/%d\n" % [rec, STORM_RECIPES_NEED.size()]
		lines += "[color=#d8c477]Alchemy[/color] %d/%d\n\n" % [alc, STORM_ALCHEMY_NEED]
		lines += "Craft an anvil, a copper pickaxe, an iron bar and a spark staff. Study six creatures and two alchemical results."
	return lines


func _alchemy_journal_text(result_id: String) -> String:
	var record: Dictionary = alchemy_knowledge.get(result_id, {})
	var ingredients: Dictionary = record.get("ingredients", {})
	var parts: Array[String] = []
	for item_id in ingredients.keys():
		parts.append("%s x%d" % [_item_display_name(str(item_id)), int(ingredients[item_id])])
	return "[color=#ad9a73]RECORDED RESULT[/color]\n%s\n\n[color=#ad9a73]INGREDIENTS[/color]\n%s\n\n[color=#819783]EXPERIMENTS[/color]\n%d successful preparation(s)." % [
		_item_display_name(result_id),
		", ".join(parts),
		int(record.get("attempts", 0))
	]


func _recipes_using_material(item_id: String) -> Array[String]:
	var uses: Array[String] = []
	for recipe in recipes:
		var cost: Dictionary = recipe.get("cost", {})
		if cost.has(item_id):
			uses.append(_item_display_name(str(recipe.get("result", ""))))
	return uses


func _enemy_habitat(enemy_type: String) -> String:
	if enemy_type in ["wild_slime", "mossling", "heartwood_boss"]:
		return "Forest surface and root-choked clearings"
	if enemy_type == "root_crawler":
		return "Ash desert drifts, ambushing from beneath the sand"
	if enemy_type in ["cave_worm", "bat", "cave_husk", "stone_beast"]:
		return "Deep caves and exposed stone chambers"
	if enemy_type in ["spore_bat", "mushroom_beetle"]:
		return "Mushroom halls"
	if enemy_type in ["ash_phantom", "ash_wisp", "ruin_drone", "ash_sentinel"]:
		return "Ash cities and abandoned ruins"
	if enemy_type == "depth_warden":
		return "A sealed sanctum deep beneath the roots"
	if enemy_type == "storm_herald":
		return "The heart of a storm"
	if enemy_type == "sky_herald":
		return "High peaks and the sky islands"
	if enemy_type == "leviathan":
		return "The sky above the islands"
	if enemy_type == "drowned_guard":
		return "Sunken ruins"
	if enemy_type in ["ember_rootling", "night_ember"]:
		return "Lava-root depths"
	if enemy_type == "glass_wraith":
		return "Glass abyss"
	return "Habitat not yet classified"


func _knowledge_rating(value: float) -> String:
	if value >= 1.45:
		return "Very high"
	if value >= 1.1:
		return "High"
	if value >= 0.75:
		return "Moderate"
	return "Low"


func _setup_debug_console(canvas: CanvasLayer) -> void:
	debug_console_panel = PanelContainer.new()
	debug_console_panel.name = "DebugConsole"
	if mobile_ui_enabled:
		# Mobile: full-width console anchored to top
		debug_console_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		debug_console_panel.offset_left = 8
		debug_console_panel.offset_top = 8
		debug_console_panel.offset_right = -8
		debug_console_panel.offset_bottom = 420
	else:
		debug_console_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		debug_console_panel.offset_left = 22
		debug_console_panel.offset_top = 18
		debug_console_panel.offset_right = 670
		debug_console_panel.offset_bottom = 352
	debug_console_panel.z_index = 200
	debug_console_panel.visible = false
	var panel_style := _pixel_sb("res://assets/ui/frame_inner.png", 8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	debug_console_panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(debug_console_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	debug_console_panel.add_child(layout)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	layout.add_child(title_row)

	var title := Label.new()
	if mobile_ui_enabled:
		title.text = "DEV CONSOLE"
	else:
		title.text = "DEV CONSOLE   F1 / `"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("9fd3c7"))
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(44, 32)
	close_btn.size = Vector2(44, 32)
	close_btn.add_theme_font_size_override("font_size", 16)
	var close_style := _pixel_sb("res://assets/ui/button.png", 5)
	close_style.content_margin_left = 8
	close_style.content_margin_top = 5
	close_style.content_margin_right = 8
	close_style.content_margin_bottom = 5
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_pressed := _pixel_sb("res://assets/ui/button_pressed.png", 5)
	close_pressed.content_margin_left = 8
	close_pressed.content_margin_top = 5
	close_pressed.content_margin_right = 8
	close_pressed.content_margin_bottom = 5
	close_btn.add_theme_stylebox_override("pressed", close_pressed)
	var close_hover := _pixel_sb("res://assets/ui/button_hover.png", 5)
	close_hover.content_margin_left = 8
	close_hover.content_margin_top = 5
	close_hover.content_margin_right = 8
	close_hover.content_margin_bottom = 5
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.pressed.connect(func(): _set_debug_console_open(false))
	title_row.add_child(close_btn)

	debug_console_output = RichTextLabel.new()
	debug_console_output.bbcode_enabled = true
	debug_console_output.fit_content = false
	debug_console_output.scroll_active = true
	if mobile_ui_enabled:
		debug_console_output.custom_minimum_size = Vector2(200, 260)
	else:
		debug_console_output.custom_minimum_size = Vector2(620, 242)
	debug_console_output.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_console_output.add_theme_font_size_override("normal_font_size", 12)
	layout.add_child(debug_console_output)

	debug_console_input = LineEdit.new()
	debug_console_input.placeholder_text = "help"
	debug_console_input.clear_button_enabled = true
	debug_console_input.caret_blink = true
	debug_console_input.add_theme_font_size_override("font_size", 13)
	debug_console_input.text_submitted.connect(_on_debug_console_command)
	debug_console_input.gui_input.connect(_on_debug_console_input)
	layout.add_child(debug_console_input)

	_console_print("Console ready. Type [color=#d8c477]help[/color] for commands.")


func _set_debug_console_open(open: bool) -> void:
	debug_console_open = open
	if debug_console_panel == null:
		return
	debug_console_panel.visible = open
	physical_move_left_held = false
	physical_move_right_held = false
	physical_noclip_up_held = false
	physical_noclip_down_held = false
	mouse_mine_held = false
	Input.action_release("mine")
	Input.action_release("attack")
	if open:
		inventory_open = false
		_set_full_map_open(false)
		debug_console_history_index = debug_console_history.size()
		debug_console_input.grab_focus()
		# Restore focus after the visibility change so typing can start instantly.
		debug_console_input.call_deferred("grab_focus")
		debug_console_input.caret_column = debug_console_input.text.length()
	else:
		debug_console_input.release_focus()
	_update_mobile_controls_visibility()


func _on_debug_console_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_UP:
		if not debug_console_history.is_empty():
			debug_console_history_index = maxi(0, debug_console_history_index - 1)
			debug_console_input.text = debug_console_history[debug_console_history_index]
			debug_console_input.caret_column = debug_console_input.text.length()
		debug_console_input.accept_event()
	elif key_event.keycode == KEY_DOWN:
		if not debug_console_history.is_empty():
			debug_console_history_index = mini(debug_console_history.size(), debug_console_history_index + 1)
			debug_console_input.text = "" if debug_console_history_index >= debug_console_history.size() else debug_console_history[debug_console_history_index]
			debug_console_input.caret_column = debug_console_input.text.length()
		debug_console_input.accept_event()
	elif key_event.keycode == KEY_ESCAPE:
		_set_debug_console_open(false)
		debug_console_input.accept_event()


func _on_debug_console_command(raw_command: String) -> void:
	var command_line := raw_command.strip_edges()
	debug_console_input.clear()
	if command_line == "":
		return
	debug_console_history.append(command_line)
	if debug_console_history.size() > 40:
		debug_console_history.pop_front()
	debug_console_history_index = debug_console_history.size()
	_console_print("[color=#82949d]> %s[/color]" % command_line)
	_execute_debug_command(command_line)
	# Keep the prompt active so commands can be entered one after another
	# without clicking the console again.
	debug_console_input.grab_focus()
	debug_console_input.caret_column = 0


func _console_print(message: String) -> void:
	if debug_console_output == null:
		return
	debug_console_output.append_text(message + "\n")
	debug_console_output.scroll_to_line(maxi(0, debug_console_output.get_line_count() - 1))


func _execute_debug_command(command_line: String) -> void:
	var parts := command_line.split(" ", false)
	if parts.is_empty():
		return
	var command := str(parts[0]).to_lower()
	if command in ["help", "помощь"]:
		_console_print("[color=#d8c477]give <item_id> [count][/color] - give an item")
		_console_print("[color=#d8c477]give_all [count][/color] - give every item")
		_console_print("[color=#d8c477]spawn <mob_id> [count][/color] - summon creatures")
		_console_print("[color=#d8c477]items [filter][/color] / [color=#d8c477]mobs[/color] - show IDs")
		_console_print("[color=#d8c477]noclip [on/off][/color] - collisions and flight; double Space toggles it")
		_console_print("[color=#d8c477]god [on/off][/color] - immortality")
		_console_print("[color=#d8c477]temp [value][/color] - inspect or set body temperature")
		_console_print("[color=#d8c477]perception [on/off][/color] - show vision, noise and AI states")
		_console_print("[color=#d8c477]noise [radius][/color] - emit a test noise at the player")
		_console_print("[color=#d8c477]weather [clear|rain|storm|blizzard|ashfall|fog][/color] - inspect or force atmospheric weather")
		_console_print("[color=#d8c477]learn all[/color] / [color=#d8c477]learn <recipe_id>[/color] - discover recipes")
		_console_print("[color=#d8c477]storm start[/color] - force the storm story arc to begin")
		_console_print("[color=#d8c477]chapter2[/color] - skip to Chapter II (2 wind shards + teleport to sanctum)")
		_console_print("[color=#d8c477]fastforward[/color] - skip to the NPC path choice (beat Leviathan, tp to wanderer)")
		_console_print("[color=#d8c477]creative[/color] - creative mode: god, flight, invisible, all knowledge")
		_console_print("[color=#d8c477]killall[/color], [color=#d8c477]clear[/color]")
		return
	if command in ["clear", "очистить"]:
		debug_console_output.clear()
		return
	if command in ["items", "предметы"]:
		var filter := str(parts[1]).to_lower() if parts.size() > 1 else ""
		var ids: Array[String] = []
		for item_id in item_names.keys():
			if filter == "" or str(item_id).contains(filter) or _item_display_name(str(item_id)).to_lower().contains(filter):
				ids.append(str(item_id))
		ids.sort()
		_console_print(", ".join(ids))
		return
	if command in ["mobs", "enemies", "мобы", "существа"]:
		var ids: Array[String] = []
		for enemy_id in enemy_sprite_specs.keys():
			ids.append(str(enemy_id))
		ids.sort()
		_console_print(", ".join(ids))
		return
	if command in ["give_all", "all_items", "все_предметы"]:
		var amount := clampi(int(parts[1]) if parts.size() > 1 and str(parts[1]).is_valid_int() else 99, 1, 9999)
		for item_id in item_names.keys():
			_add_item(str(item_id), amount)
		_console_print("[color=#82d49a]Added every item x%d.[/color]" % amount)
		return
	if command in ["give", "item", "предмет"]:
		if parts.size() < 2:
			_console_print("[color=#e68a78]Usage: give <item_id> [count][/color]")
			return
		var item_id := str(parts[1]).to_lower()
		if item_id in ["all", "все"]:
			var all_amount := clampi(int(parts[2]) if parts.size() > 2 and str(parts[2]).is_valid_int() else 99, 1, 9999)
			for all_item_id in item_names.keys():
				_add_item(str(all_item_id), all_amount)
			_console_print("[color=#82d49a]Added every item x%d.[/color]" % all_amount)
			return
		if not item_names.has(item_id):
			_console_print("[color=#e68a78]Unknown item: %s. Use items.[/color]" % item_id)
			return
		var amount := clampi(int(parts[2]) if parts.size() > 2 and str(parts[2]).is_valid_int() else 1, 1, 9999)
		_add_item(item_id, amount)
		_console_print("[color=#82d49a]Added %s x%d.[/color]" % [_item_display_name(item_id), amount])
		return
	if command in ["spawn", "summon", "призвать"]:
		if parts.size() < 2:
			_console_print("[color=#e68a78]Usage: spawn <mob_id> [count][/color]")
			return
		var enemy_id := str(parts[1]).to_lower()
		var count := clampi(int(parts[2]) if parts.size() > 2 and str(parts[2]).is_valid_int() else 1, 1, 20)
		if enemy_id in ["all", "все"]:
			for all_enemy_id in enemy_sprite_specs.keys():
				_spawn_debug_enemy(str(all_enemy_id), 1)
			_console_print("[color=#82d49a]Summoned every creature.[/color]")
			return
		if not enemy_sprite_specs.has(enemy_id):
			_console_print("[color=#e68a78]Unknown creature: %s. Use mobs.[/color]" % enemy_id)
			return
		_spawn_debug_enemy(enemy_id, count)
		_console_print("[color=#82d49a]Summoned %s x%d.[/color]" % [enemy_id, count])
		return
	if command in ["killall", "kill_all", "убить_всех"]:
		enemies.clear()
		enemy_projectiles.clear()
		enemy_impact_effects.clear()
		_console_print("[color=#82d49a]All creatures removed.[/color]")
		return
	if command in ["noclip", "ноклип"]:
		noclip_unlocked = true
		var next_value := _debug_toggle_value(parts, noclip_enabled)
		_set_noclip_enabled(next_value)
		return
	if command in ["god", "immortal", "бессмертие"]:
		god_mode_enabled = _debug_toggle_value(parts, god_mode_enabled)
		if god_mode_enabled:
			health = MAX_HEALTH
			player_statuses.clear()
			_console_print("[color=#82d49a]God mode enabled.[/color]")
		else:
			_console_print("[color=#d8c477]God mode disabled.[/color]")
		return
	if command in ["temp", "temperature"]:
		if parts.size() > 1:
			var requested_temperature := str(parts[1])
			if not requested_temperature.is_valid_float():
				_console_print("[color=#e68a78]Usage: temp [value][/color]")
				return
			body_temperature = clampf(float(requested_temperature), MIN_BODY_TEMPERATURE, MAX_BODY_TEMPERATURE)
			temperature_visual_state = ""
		_console_print("[color=#82d49a]Body %.1f C | ambient %.1f C | cold %d%% | heat %d%%[/color]" % [
			body_temperature,
			ambient_temperature,
			int(round(_temperature_protection("cold_protection") * 100.0)),
			int(round(_temperature_protection("heat_protection") * 100.0))
		])
		return
	if command in ["perception", "ai_debug", "perception_debug"]:
		perception_debug_enabled = _debug_toggle_value(parts, perception_debug_enabled)
		_console_print("[color=#82d49a]Perception debug %s.[/color]" % ("enabled" if perception_debug_enabled else "disabled"))
		return
	if command in ["noise", "make_noise"]:
		var radius := clampf(float(parts[1]) if parts.size() > 1 and str(parts[1]).is_valid_float() else 180.0, 20.0, 600.0)
		_emit_noise(player_position, radius, "debug", 1.0)
		_console_print("[color=#82d49a]Noise emitted: radius %.0f.[/color]" % radius)
		return
	if command in ["weather", "погода"]:
		if parts.size() < 2:
			_console_print("[color=#82d49a]Weather: %s, intensity %d%%, %.0fs remaining.[/color]" % [
				_weather_display_name(weather),
				int(round(weather_intensity * 100.0)),
				weather_timer
			])
			return
		if network_session != null and network_session.is_client() and network_session.joined:
			_console_print("[color=#e68a78]Weather is controlled by the server.[/color]")
			return
		var requested_weather := str(parts[1]).to_lower()
		if not _weather_kind_is_valid(requested_weather):
			_console_print("[color=#e68a78]Unknown weather: %s.[/color]" % requested_weather)
			return
		_start_weather(requested_weather, 240.0)
		weather_intensity = weather_target_intensity
		_console_print("[color=#82d49a]Weather set to %s.[/color]" % _weather_display_name(requested_weather))
		return
	if command in ["storm", "буря"]:
		if parts.size() < 2:
			_console_print("[color=#e68a78]Usage: storm start | storm stop[/color]")
			return
		var storm_cmd := str(parts[1]).to_lower()
		if storm_cmd in ["start", "старт", "force"]:
			storm_forced = true
			if not storm_herald_defeated and not storm_active:
				_start_storm()
			_console_print("[color=#82d49a]The storm begins![/color]")
		elif storm_cmd in ["stop", "стоп"]:
			storm_forced = false
			storm_research_timer = 0.0
			if storm_active and not _storm_boss_alive():
				storm_active = false
			_console_print("[color=#e8c46a]The storm calms.[/color]")
		return
	if command in ["creative", "креатив", "творческий"]:
		creative_mode = not creative_mode
		if creative_mode:
			god_mode_enabled = true
			noclip_enabled = true
			player_velocity = Vector2.ZERO
			landing_speed = 0.0
			# Full knowledge
			_learn_all_recipes()
			for enemy_type in enemy_perception_profiles.keys():
				var rec: Dictionary = bestiary_knowledge.get(enemy_type, {"stage": 0, "kills": 0})
				rec["stage"] = 3
				rec["kills"] = maxi(int(rec.get("kills", 0)), 1)
				bestiary_knowledge[enemy_type] = rec
			for item_id in item_names.keys():
				var mid := str(item_id)
				if _is_journal_material(mid):
					var mrec: Dictionary = material_knowledge.get(mid, {"stage": 0, "found": 0})
					mrec["stage"] = 2
					material_knowledge[mid] = mrec
			for recipe in recipes:
				var rid := str(recipe.get("id", recipe.get("result", "")))
				if rid in ["acid_flasks", "wild_badge"]:
					alchemy_knowledge[rid] = {"attempts": 1, "ingredients": recipe.get("cost", {})}
			# Unlimited key items
			inventory["blueprint"] = 99
			inventory["grappling_hook"] = 1
			_console_print("[color=#82d49a]CREATIVE MODE ON: god, flight, invisible to enemies, all knowledge. Use give_all for items.[/color]")
		else:
			god_mode_enabled = false
			noclip_enabled = false
			player_velocity = Vector2.ZERO
			_console_print("[color=#d8c477]Creative mode off.[/color]")
		return
	if command in ["chapter2", "глава2", "ch2"]:
		# Skip to Chapter II: mark Chapter I done, give 2 wind shards, tp to sanctum.
		storm_herald_defeated = true
		storm_active = false
		storm_tornado_phase = ""
		wind_shard_picked = true
		inventory["wind_shard"] = int(inventory.get("wind_shard", 0)) + 2
		if depth_sanctum_pos.x < 0:
			# Generate a sanctum if the world was created before Chapter II existed.
			_add_depth_sanctum()
		if depth_sanctum_pos.x >= 0:
			player_position = Vector2(depth_sanctum_pos.x * TILE_SIZE + TILE_SIZE * 0.5, (depth_sanctum_pos.y - 3) * TILE_SIZE)
		_console_print("[color=#82d49a]Chapter II ready: 2 Wind Shards given, teleported to the Depth Sanctum.[/color]")
		_toast_message("Chapter II — find the Depth Altar and place a Wind Shard.", 4.0)
		return
	if command in ["fastforward", "skip_to_npc", "ff", "быстро"]:
		# Skip straight to the first NPC / path choice moment:
		# mark all bosses up to and including the Leviathan as defeated,
		# ensure the sky islands exist, activate the wanderer, tp to it.
		storm_herald_defeated = true
		storm_active = false
		storm_tornado_phase = ""
		wind_shard_picked = true
		depth_warden_defeated = true
		depth_sanctum_activated = true
		depth_warden_spawned = false
		boss_defeated = true
		stone_beast_defeated = true
		sky_leviathan_defeated = true
		sky_leviathan_spawned = false
		if sky_island_positions.is_empty() or sky_arena_pos.x < 0:
			# Ensure islands exist (world may predate Chapter III).
			_add_sky_islands()
		_activate_wanderer_npc()
		# Give a few useful sky items so the player can get around.
		inventory["sky_shard"] = int(inventory.get("sky_shard", 0)) + 1
		inventory["sky_compass"] = int(inventory.get("sky_compass", 0)) + 1
		inventory["jetpack"] = int(inventory.get("jetpack", 0)) + 1
		if npc_wanderer_pos.x >= 0.0:
			player_position = npc_wanderer_pos + Vector2(0.0, 40.0)
		_console_print("[color=#82d49a]Fast-forward done: all bosses up to the Leviathan defeated, wanderer spawned. Follow the compass / talk to the Sky Wanderer on the central island.[/color]")
		_toast_message("Fast-forwarded to the Sky Wanderer. Talk to him to choose your path.", 5.0)
		_save_game()
		return
	if command in ["learn", "knowledge", "research"]:
		if parts.size() < 2:
			_console_print("[color=#e68a78]Usage: learn all | learn <recipe_id>[/color]")
			return
		var recipe_id := str(parts[1]).to_lower()
		if recipe_id == "all" or recipe_id == "journal" or recipe_id == "всё":
			var learned_count := _learn_all_recipes()
			# Also fill the bestiary, materials and alchemy knowledge.
			for enemy_type in enemy_perception_profiles.keys():
				var rec: Dictionary = bestiary_knowledge.get(enemy_type, {"stage": 0, "kills": 0})
				rec["stage"] = 3
				rec["kills"] = maxi(int(rec.get("kills", 0)), 1)
				bestiary_knowledge[enemy_type] = rec
			for item_id in item_names.keys():
				var mid := str(item_id)
				if _is_journal_material(mid):
					var mrec: Dictionary = material_knowledge.get(mid, {"stage": 0, "found": 0})
					mrec["stage"] = 2
					material_knowledge[mid] = mrec
			for recipe in recipes:
				var rid := str(recipe.get("id", recipe.get("result", "")))
				if rid in ["acid_flasks", "wild_badge"]:
					alchemy_knowledge[rid] = {"attempts": 1, "ingredients": recipe.get("cost", {})}
			_console_print("[color=#82d49a]Journal studied: %d recipe(s), bestiary, materials, alchemy.[/color]" % learned_count)
			return
		if not _recipe_id_exists(recipe_id):
			_console_print("[color=#e68a78]Unknown recipe: %s.[/color]" % recipe_id)
			return
		var was_known := bool(known_recipes.get(recipe_id, false))
		_record_recipe_known(recipe_id)
		_ensure_selected_recipe_known()
		_update_hud()
		_console_print("[color=#82d49a]%s recipe: %s.[/color]" % [
			"Already knew" if was_known else "Learned",
			_item_display_name(recipe_id)
		])
		return
	_console_print("[color=#e68a78]Unknown command: %s. Type help.[/color]" % command)


func _debug_toggle_value(parts: PackedStringArray, current: bool) -> bool:
	if parts.size() < 2:
		return not current
	var value := str(parts[1]).to_lower()
	if value in ["on", "1", "true", "вкл", "включить"]:
		return true
	if value in ["off", "0", "false", "выкл", "выключить"]:
		return false
	return not current


func _set_noclip_enabled(enabled: bool) -> void:
	noclip_enabled = enabled
	player_velocity = Vector2.ZERO
	landing_speed = 0.0
	if enabled:
		_console_print("[color=#82d49a]Noclip enabled. WASD/Arrows move, Space/W goes up, S goes down.[/color]")
	else:
		_console_print("[color=#d8c477]Noclip disabled.[/color]")


func _spawn_debug_enemy(enemy_id: String, count: int) -> void:
	var template := _enemy_template(enemy_id)
	var flying := bool(template.get("flying", false))
	var size: Vector2 = template.get("size", Vector2(16, 16))
	for index in range(count):
		var side := -1 if index % 2 == 0 else 1
		var distance := 52.0 + float(index / 2) * 22.0
		var spawn_pos := player_position + Vector2(float(side) * distance, -40.0 if flying else -8.0)
		if not flying:
			spawn_pos = _find_spawn_position_near_player(3 + index, 7 + index, false, size)
		_spawn_enemy(enemy_id, spawn_pos)


func _default_ui_layout() -> Dictionary:
	return {
		"move_joystick": {"anchor": "BL", "ox": 32.0, "oy": -224.0, "ow": 204.0, "oh": -52.0, "size": 1.0},
		"jump": {"anchor": "BR", "ox": -150.0, "oy": -224.0, "ow": -34.0, "oh": -108.0, "size": 1.0},
		"atk": {"anchor": "BR", "ox": -286.0, "oy": -224.0, "ow": -170.0, "oh": -108.0, "size": 1.0},
		"grapple": {"anchor": "BR", "ox": -138.0, "oy": -324.0, "ow": -54.0, "oh": -240.0, "size": 0.72},
	}


func _save_ui_layout() -> void:
	var data := {}
	data["version"] = UI_LAYOUT_VERSION
	data["layout"] = ui_layout
	var file := FileAccess.open(UI_LAYOUT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))


func _load_ui_layout() -> void:
	ui_layout_loaded = true
	ui_layout = _default_ui_layout()
	if not FileAccess.file_exists(UI_LAYOUT_PATH):
		return
	var file := FileAccess.open(UI_LAYOUT_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	# Old control sizes belonged to the previous heavy circular UI. Ignore that
	# layout once so existing installs receive the new ergonomic defaults.
	if int(data.get("version", 0)) != UI_LAYOUT_VERSION:
		return
	var saved_layout: Variant = data.get("layout", {})
	if typeof(saved_layout) == TYPE_DICTIONARY:
		for key in saved_layout.keys():
			if ui_layout.has(key):
				ui_layout[key] = saved_layout[key]


func _apply_ui_layout() -> void:
	var elems := {
		"move_joystick": mobile_joystick,
		"jump": jump_button,
		"atk": atk_button,
		"grapple": grapple_button,
	}
	for key in elems.keys():
		var elem: Control = elems[key]
		if elem == null:
			continue
		var def: Dictionary = ui_layout.get(key, {})
		if def.is_empty():
			continue
		_place_ui_elem(elem, def, key)


# --- Safe area handling ------------------------------------------------------
# Edge-anchored HUD controls keep their designed offsets; display cutouts and
# system bars only add extra padding on the affected edges. The registry keeps
# base offsets so insets can be re-applied idempotently after every change.

func _register_safe_area_control(control: Control, edges: Array) -> void:
	if control == null:
		return
	safe_area_registry.append({
		"control": control,
		"edges": edges.duplicate(),
		"base_left": control.offset_left,
		"base_top": control.offset_top,
		"base_right": control.offset_right,
		"base_bottom": control.offset_bottom,
	})


func _compute_safe_area_insets() -> Dictionary:
	var insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x < 1.0 or window_size.y < 1.0:
		return insets
	var safe_rect := Rect2(DisplayServer.get_display_safe_area())
	if safe_rect.size.x < 1.0 or safe_rect.size.y < 1.0:
		return insets
	# The safe area is reported in screen pixels while HUD offsets live in
	# canvas units (canvas_items stretch), so convert with the per-axis scale.
	var canvas_size := get_viewport_rect().size
	var scale_x := canvas_size.x / window_size.x
	var scale_y := canvas_size.y / window_size.y
	var window_pos := Vector2(DisplayServer.window_get_position())
	var left := maxf(0.0, safe_rect.position.x - window_pos.x) * scale_x
	var top := maxf(0.0, safe_rect.position.y - window_pos.y) * scale_y
	var right := maxf(0.0, (window_pos.x + window_size.x) - safe_rect.end.x) * scale_x
	var bottom := maxf(0.0, (window_pos.y + window_size.y) - safe_rect.end.y) * scale_y
	insets["left"] = minf(left, SAFE_AREA_MAX_INSET)
	insets["top"] = minf(top, SAFE_AREA_MAX_INSET)
	insets["right"] = minf(right, SAFE_AREA_MAX_INSET)
	insets["bottom"] = minf(bottom, SAFE_AREA_MAX_INSET)
	return insets


func _apply_safe_area_insets() -> void:
	safe_area_insets = _compute_safe_area_insets()
	_apply_current_safe_area()


func _apply_current_safe_area() -> void:
	safe_area_apply_count += 1
	var left := float(safe_area_insets["left"])
	var top := float(safe_area_insets["top"])
	var right := float(safe_area_insets["right"])
	var bottom := float(safe_area_insets["bottom"])
	for entry in safe_area_registry:
		var control: Control = entry.get("control")
		if control == null or not is_instance_valid(control):
			continue
		var edges: Array = entry.get("edges", [])
		var dx := 0.0
		var dy := 0.0
		if edges.has("left"):
			dx += left
		if edges.has("right"):
			dx -= right
		if edges.has("top"):
			dy += top
		if edges.has("bottom"):
			dy -= bottom
		control.offset_left = float(entry["base_left"]) + dx
		control.offset_right = float(entry["base_right"]) + dx
		control.offset_top = float(entry["base_top"]) + dy
		control.offset_bottom = float(entry["base_bottom"]) + dy
	# Custom-layout mobile controls receive insets inside _place_ui_elem.
	_apply_ui_layout()


func _on_window_size_changed() -> void:
	# Rotation, split-screen and IME changes all land here; re-deriving the
	# insets keeps the HUD inside the visible area without a restart.
	_apply_safe_area_insets()


func _place_ui_elem(elem: Control, def: Dictionary, key: String) -> void:
	var anchor := str(def.get("anchor", "BR"))
	if anchor == "BL":
		elem.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	elif anchor == "TR":
		elem.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	else:
		elem.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Keep saved layouts intact; cutout/system-bar insets only shift the
	# control towards the visible area on the edges its anchor touches.
	var inset_x := 0.0
	var inset_y := -float(safe_area_insets.get("bottom", 0.0))
	if anchor == "BL":
		inset_x = float(safe_area_insets.get("left", 0.0))
	elif anchor == "TR":
		inset_x = -float(safe_area_insets.get("right", 0.0))
		inset_y = float(safe_area_insets.get("top", 0.0))
	else:
		inset_x = -float(safe_area_insets.get("right", 0.0))
	elem.offset_left = float(def.get("ox", 0.0)) + inset_x
	elem.offset_top = float(def.get("oy", 0.0)) + inset_y
	elem.offset_right = float(def.get("ow", 0.0)) + inset_x
	elem.offset_bottom = float(def.get("oh", 0.0)) + inset_y
	var size_scale := float(def.get("size", 1.0))
	var cx := (elem.offset_left + elem.offset_right) * 0.5
	var cy := (elem.offset_top + elem.offset_bottom) * 0.5
	if key in ["jump", "atk", "grapple"] and elem.get_script() != null:
		var base_radius := 58.0
		var scaled_radius := base_radius * size_scale
		elem.set("radius", scaled_radius)
		elem.custom_minimum_size = Vector2(scaled_radius * 2.0, scaled_radius * 2.0)
		elem.offset_left = cx - scaled_radius
		elem.offset_top = cy - scaled_radius
		elem.offset_right = cx + scaled_radius
		elem.offset_bottom = cy + scaled_radius
		elem.queue_redraw()
	else:
		# The minimal joystick has a 172px touch area at 100% scale.
		var half_w := 86.0 * size_scale
		var half_h := 86.0 * size_scale
		elem.offset_left = cx - half_w
		elem.offset_top = cy - half_h
		elem.offset_right = cx + half_w
		elem.offset_bottom = cy + half_h
		elem.set("joy_scale", size_scale)
		elem.queue_redraw()


func _start_ui_editor() -> void:
	editing_ui = not editing_ui
	if editing_ui:
		_hide_settings()
		_build_editor_overlay()
		_toast_message("UI EDITOR: drag controls to move. Select + then tap +/- to resize. SAVE when done.", 5.0)
		mobile_controls.visible = true
	else:
		_remove_editor_overlay()
		_save_ui_layout()
		_apply_ui_layout()
		_toast_message("UI layout saved.", 2.0)


func _build_editor_overlay() -> void:
	if editor_overlay != null:
		return
	editor_overlay = Control.new()
	editor_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	editor_overlay.z_index = 99
	get_node("HUD").add_child(editor_overlay)
	# SAVE button (top-center)
	var save_btn := _make_compass_action_button("SAVE UI")
	save_btn.position = Vector2(0, 20)
	save_btn.size = Vector2(140, 36)
	save_btn.pressed.connect(_start_ui_editor)
	editor_overlay.add_child(save_btn)
	# + / - buttons (bottom-left of screen)
	var plus_btn := _make_compass_action_button("+")
	plus_btn.position = Vector2(40, 40)
	plus_btn.size = Vector2(60, 60)
	plus_btn.pressed.connect(_editor_overlay_resize.bind(0.1))
	editor_overlay.add_child(plus_btn)
	var minus_btn := _make_compass_action_button("-")
	minus_btn.position = Vector2(110, 40)
	minus_btn.size = Vector2(60, 60)
	minus_btn.pressed.connect(_editor_overlay_resize.bind(-0.1))
	editor_overlay.add_child(minus_btn)
	# hint
	var hint := Label.new()
	hint.text = "DRAG: MOVE   SELECT + TAP +/-: SIZE"
	hint.position = Vector2(0, 70)
	hint.size = Vector2(1280, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", ui_pixel_font)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color("99a4b0"))
	editor_overlay.add_child(hint)


func _editor_overlay_resize(delta_size: float) -> void:
	if editor_dragging == "":
		_toast_message("First drag/select a control, then +/-.", 2.0)
		return
	_editor_resize(editor_dragging, delta_size)


func _remove_editor_overlay() -> void:
	if editor_overlay != null:
		editor_overlay.queue_free()
		editor_overlay = null


func _reset_ui_layout() -> void:
	ui_layout = _default_ui_layout()
	_apply_ui_layout()
	_save_ui_layout()
	_toast_message("UI layout reset to default.", 2.0)


func _ui_editor_input(event: InputEvent) -> void:
	if not editing_ui:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if editor_dragging != "":
				if k.keycode == KEY_EQUAL or k.keycode == KEY_KP_ADD:
					_editor_resize(editor_dragging, 0.1)
				elif k.keycode == KEY_MINUS or k.keycode == KEY_KP_SUBTRACT:
					_editor_resize(editor_dragging, -0.1)
		return
	# Drag elements with touch/mouse; use drag position relative to screen.
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			editor_dragging = _editor_hit_test(t.position)
			if editor_dragging != "":
				editor_drag_offset = t.position - _editor_elem_center(editor_dragging)
		else:
			editor_dragging = ""
	elif event is InputEventScreenDrag and editor_dragging != "":
		var d := event as InputEventScreenDrag
		_move_editor_elem(editor_dragging, d.position - editor_drag_offset)
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				editor_dragging = _editor_hit_test(m.position)
				if editor_dragging != "":
					editor_drag_offset = m.position - _editor_elem_center(editor_dragging)
			else:
				editor_dragging = ""
	elif event is InputEventMouseMotion and editor_dragging != "":
		_move_editor_elem(editor_dragging, (event as InputEventMouseMotion).position - editor_drag_offset)


func _editor_elem(elem_id: String) -> Control:
	match elem_id:
		"move_joystick":
			return mobile_joystick
		"jump":
			return jump_button
		"atk":
			return atk_button
		"grapple":
			return grapple_button
	return null


func _editor_elem_center(elem_id: String) -> Vector2:
	var e := _editor_elem(elem_id)
	if e == null:
		return Vector2.ZERO
	var rect := e.get_global_rect()
	return rect.get_center()


func _editor_hit_test(screen_pos: Vector2) -> String:
	for elem_id in ["move_joystick", "jump", "atk", "grapple"]:
		var e := _editor_elem(elem_id)
		if e != null and e.get_global_rect().grow(30.0).has_point(screen_pos):
			return elem_id
	return ""


func _move_editor_elem(elem_id: String, screen_pos: Vector2) -> void:
	var e := _editor_elem(elem_id)
	if e == null:
		return
	var vr := get_viewport_rect()
	var size_x := e.size.x
	var size_y := e.size.y
	# Convert screen center to an anchored offset.
	var anchor := "BR"
	var def: Dictionary = ui_layout.get(elem_id, {})
	anchor = str(def.get("anchor", "BR"))
	var cx := screen_pos.x
	var cy := screen_pos.y
	if anchor == "BL":
		def["ox"] = cx - size_x * 0.5
		def["oy"] = cy - size_y * 0.5 - vr.size.y
		def["ow"] = cx + size_x * 0.5
		def["oh"] = cy + size_y * 0.5 - vr.size.y
	elif anchor == "TR":
		def["ox"] = cx - size_x * 0.5 - vr.size.x
		def["oy"] = cy - size_y * 0.5
		def["ow"] = cx + size_x * 0.5 - vr.size.x
		def["oh"] = cy + size_y * 0.5
	else:
		def["ox"] = cx - size_x * 0.5 - vr.size.x
		def["oy"] = cy - size_y * 0.5 - vr.size.y
		def["ow"] = cx + size_x * 0.5 - vr.size.x
		def["oh"] = cy + size_y * 0.5 - vr.size.y
	ui_layout[elem_id] = def
	_place_ui_elem(e, def, elem_id)


func _editor_resize(elem_id: String, delta_size: float) -> void:
	var def: Dictionary = ui_layout.get(elem_id, {})
	if def.is_empty():
		return
	var s := float(def.get("size", 1.0))
	s = clampf(s + delta_size, 0.5, 2.0)
	def["size"] = s
	ui_layout[elem_id] = def
	var e := _editor_elem(elem_id)
	if e != null:
		_place_ui_elem(e, def, elem_id)



func _setup_mobile_controls(canvas: CanvasLayer) -> void:
	mobile_controls = Control.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls.visible = mobile_ui_enabled
	mobile_controls.z_index = 40
	canvas.add_child(mobile_controls)

	mobile_gameplay_controls = Control.new()
	mobile_gameplay_controls.name = "MobileGameplayControls"
	mobile_gameplay_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_gameplay_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls.add_child(mobile_gameplay_controls)

	# Static movement joystick (bottom-left, always visible).
	mobile_joystick = Control.new()
	mobile_joystick.set_script(VIRTUAL_JOYSTICK_SCRIPT)
	mobile_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	mobile_joystick.offset_left = 32
	mobile_joystick.offset_top = -224
	mobile_joystick.offset_right = 204
	mobile_joystick.offset_bottom = -52
	mobile_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	mobile_joystick.static_mode = true
	mobile_gameplay_controls.add_child(mobile_joystick)

	# Round translucent action buttons (drawn with code): JUMP holds, ATK taps.
	atk_button = _make_action_button("atk", false)
	atk_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	atk_button.offset_left = -286
	atk_button.offset_top = -224
	atk_button.offset_right = -170
	atk_button.offset_bottom = -108
	atk_button.button_pressed.connect(_mobile_attack_button_pressed)
	mobile_gameplay_controls.add_child(atk_button)

	jump_button = _make_action_button("jump", true)
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.offset_left = -150
	jump_button.offset_top = -224
	jump_button.offset_right = -34
	jump_button.offset_bottom = -108
	jump_button.button_down.connect(_mobile_action_down.bind(&"jump"))
	jump_button.button_up.connect(_mobile_action_up.bind(&"jump"))
	mobile_gameplay_controls.add_child(jump_button)

	# Grapple is a tap button now (visible only with the accessory equipped).
	grapple_button = _make_action_button("grapple", false)
	grapple_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grapple_button.offset_left = -138
	grapple_button.offset_top = -324
	grapple_button.offset_right = -54
	grapple_button.offset_bottom = -240
	grapple_button.button_pressed.connect(_mobile_grapple_button_pressed)
	grapple_button.visible = false
	mobile_gameplay_controls.add_child(grapple_button)

	# Compact two-row utility rail sits between the center clock and minimap.
	# Inventory, crafting and journal each open their own screen.
	var top_group := Control.new()
	top_group.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_group.offset_left = -424
	top_group.offset_top = 12
	top_group.offset_right = -204
	top_group.offset_bottom = 88
	top_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls.add_child(top_group)
	_register_safe_area_control(top_group, ["right", "top"])
	_add_mobile_tap_button(top_group, "INV", Vector2(0, 0), _toggle_inventory_from_ui, "Inventory", Vector2(68, 34), false, {"frame": true})
	_add_mobile_tap_button(top_group, "CRAFT", Vector2(74, 0), _toggle_crafting_from_ui, "Crafting", Vector2(68, 34), false, {"frame": true})
	_add_mobile_tap_button(top_group, "JRN", Vector2(148, 0), _open_journal_from_ui, "Journal", Vector2(68, 34), false, {"frame": true})
	_add_mobile_tap_button(top_group, "BUILD", Vector2(0, 40), _toggle_build_panel, "Build", Vector2(68, 34), false, {"frame": true})
	_add_mobile_tap_button(top_group, "PAUSE", Vector2(74, 40), _toggle_pause, "Pause", Vector2(68, 34), false, {"frame": true})
	_add_mobile_tap_button(top_group, "DEV", Vector2(148, 40), _toggle_console_from_ui, "Console", Vector2(68, 34), false, {"frame": true})

	# Long-press tooltip bubble for touch slots (hotbar/inventory). Reuses the
	# pixel frame style so it matches the existing tooltip look.
	touch_tooltip_panel = PanelContainer.new()
	touch_tooltip_panel.visible = false
	touch_tooltip_panel.z_index = 90
	touch_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var touch_tooltip_style := _pixel_sb("res://assets/ui/frame_inner_accent.png", 8)
	touch_tooltip_style.content_margin_left = 12
	touch_tooltip_style.content_margin_right = 12
	touch_tooltip_style.content_margin_top = 8
	touch_tooltip_style.content_margin_bottom = 8
	touch_tooltip_panel.add_theme_stylebox_override("panel", touch_tooltip_style)
	touch_tooltip_label = Label.new()
	touch_tooltip_label.add_theme_font_override("font", ui_pixel_font)
	touch_tooltip_label.add_theme_font_size_override("font_size", 8)
	touch_tooltip_label.add_theme_color_override("font_color", Color("e8edf2"))
	touch_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	touch_tooltip_label.custom_minimum_size = Vector2(240, 0)
	touch_tooltip_panel.add_child(touch_tooltip_label)
	canvas.add_child(touch_tooltip_panel)

	# Apply saved layout (positions/sizes).
	if not ui_layout_loaded:
		_load_ui_layout()
	_apply_ui_layout()


# --- Touch long-press tooltips ----------------------------------------------

func _begin_slot_longpress(kind: String, index: int, pointer: int, screen_pos: Vector2) -> void:
	slot_longpress_kind = kind
	slot_longpress_index = index
	slot_longpress_pointer = pointer
	slot_longpress_timer = 0.0
	slot_longpress_origin = screen_pos
	slot_longpress_fired = false


func _cancel_slot_longpress() -> void:
	slot_longpress_kind = ""
	slot_longpress_index = -1
	slot_longpress_pointer = -1
	slot_longpress_timer = 0.0
	slot_longpress_fired = false
	_hide_touch_tooltip()


func _update_slot_longpress(delta: float) -> void:
	if slot_longpress_kind == "" or slot_longpress_fired:
		return
	slot_longpress_timer += delta
	if slot_longpress_timer < SLOT_LONG_PRESS_TIME:
		return
	slot_longpress_fired = true
	var item_id := ""
	var amount := 0
	if slot_longpress_kind == "hotbar":
		if slot_longpress_index >= 0 and slot_longpress_index < hotbar.size():
			item_id = str(hotbar[slot_longpress_index])
			amount = int(inventory.get(item_id, 0))
	elif slot_longpress_kind == "inventory":
		var items := _inventory_item_ids()
		if slot_longpress_index >= 0 and slot_longpress_index < items.size():
			item_id = str(items[slot_longpress_index])
			amount = int(inventory.get(item_id, 0))
	if item_id == "" or amount <= 0:
		return
	_show_touch_tooltip(_item_tooltip_text(item_id, amount), slot_longpress_origin)


func _slot_longpress_pointer_moved(pointer: int, screen_pos: Vector2) -> void:
	if slot_longpress_kind == "" or pointer != slot_longpress_pointer:
		return
	if screen_pos.distance_to(slot_longpress_origin) > SLOT_LONG_PRESS_SLOP:
		_cancel_slot_longpress()


func _slot_longpress_pointer_released(pointer: int) -> void:
	if slot_longpress_kind == "" or pointer != slot_longpress_pointer:
		return
	_cancel_slot_longpress()


func _show_touch_tooltip(text: String, screen_pos: Vector2) -> void:
	if touch_tooltip_panel == null or touch_tooltip_label == null or text == "":
		return
	touch_tooltip_label.text = text
	touch_tooltip_panel.visible = true
	touch_tooltip_panel.reset_size()
	var view_size := get_viewport_rect().size
	var panel_size := touch_tooltip_panel.get_combined_minimum_size()
	var pos := screen_pos + Vector2(-panel_size.x * 0.5, -panel_size.y - 34.0)
	pos.x = clampf(pos.x, 8.0 + float(safe_area_insets.get("left", 0.0)), view_size.x - panel_size.x - 8.0 - float(safe_area_insets.get("right", 0.0)))
	pos.y = clampf(pos.y, 8.0 + float(safe_area_insets.get("top", 0.0)), view_size.y - panel_size.y - 8.0)
	touch_tooltip_panel.position = pos


func _hide_touch_tooltip() -> void:
	if touch_tooltip_panel != null:
		touch_tooltip_panel.visible = false


func _add_mobile_hold_button(parent: Control, text: String, position: Vector2, action: StringName, tooltip: String, size := Vector2(68, 68), circular := false, textures := {}) -> void:
	var button := _make_mobile_button(text, position, size, tooltip, circular, textures)
	button.button_down.connect(_mobile_action_down.bind(action))
	button.button_up.connect(_mobile_action_up.bind(action))
	button.mouse_exited.connect(_mobile_action_up.bind(action))
	parent.add_child(button)


func _add_mobile_tap_button(parent: Control, text: String, position: Vector2, callback: Callable, tooltip: String, size := Vector2(68, 58), circular := false, textures := {}) -> void:
	var button := _make_mobile_button(text, position, size, tooltip, circular, textures)
	button.pressed.connect(callback)
	parent.add_child(button)


func _make_action_button(kind: String, hold: bool) -> Control:
	var button := Control.new()
	button.set_script(ACTION_BUTTON_SCRIPT)
	button.kind = kind
	button.hold = hold
	button.radius = 58.0
	button.label_text = ""
	button.label_font = ui_pixel_font
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button


func _make_mobile_button(text: String, position: Vector2, size: Vector2, tooltip: String, circular := false, textures := {}) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.custom_minimum_size = size
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override("font_size", 15)
	if textures.has("normal") and textures.has("pressed"):
		# Pixel-art circular buttons (JUMP / ATK): icon baked into the texture.
		var normal := StyleBoxTexture.new()
		normal.texture = _ui_tex("res://assets/ui/%s" % str(textures["normal"]))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal)
		button.add_theme_stylebox_override("focus", normal)
		var pressed := StyleBoxTexture.new()
		pressed.texture = _ui_tex("res://assets/ui/%s" % str(textures["pressed"]))
		button.add_theme_stylebox_override("pressed", pressed)
	elif textures.has("frame"):
		# Pixel 9-slice rectangular buttons (INV / DEV).
		button.add_theme_font_override("font", ui_pixel_font)
		button.add_theme_font_size_override("font_size", 9)
		var normal := _pixel_sb("res://assets/ui/button.png", 6)
		var hover := _pixel_sb("res://assets/ui/button_hover.png", 6)
		var pressed := _pixel_sb("res://assets/ui/button_pressed.png", 6)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", normal)
	else:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("10141b", 0.78)
		normal.border_color = Color("ffb84d", 0.8)
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(int(minf(size.x, size.y) * 0.5) if circular else 8)
		button.add_theme_stylebox_override("normal", normal)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("ff9d4d", 0.9)
		pressed.border_color = Color("ffd08a")
		button.add_theme_stylebox_override("pressed", pressed)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("1e2530", 0.85)
		button.add_theme_stylebox_override("hover", hover)
	return button


func _mobile_action_down(action: StringName) -> void:
	Input.action_press(action)


func _mobile_action_up(action: StringName) -> void:
	Input.action_release(action)


func _release_mobile_actions() -> void:
	mobile_world_touch_index = -1
	_hide_touch_tooltip()
	for action in [&"move_left", &"move_right", &"jump", &"mine", &"place", &"attack"]:
		Input.action_release(action)


func _toggle_console_from_ui() -> void:
	if full_map_open:
		_set_full_map_open(false)
	if inventory_open:
		inventory_open = false
		_close_chest()
	_set_debug_console_open(not debug_console_open)


func _open_inventory_screen(screen_name: String) -> void:
	if full_map_open:
		_set_full_map_open(false)
	if journal_open:
		_set_journal_open(false)
	inventory_screen = "crafting" if screen_name == "crafting" else "inventory"
	inventory_open = true
	if inventory_screen == "crafting":
		_close_chest()
	_update_mobile_controls_visibility()


func _close_inventory_screens() -> void:
	inventory_open = false
	_close_chest()
	_cancel_slot_longpress()
	_update_mobile_controls_visibility()


func _toggle_inventory_from_ui() -> void:
	if inventory_open and inventory_screen == "inventory":
		_close_inventory_screens()
	else:
		_open_inventory_screen("inventory")


func _toggle_crafting_from_ui() -> void:
	if inventory_open and inventory_screen == "crafting":
		_close_inventory_screens()
	else:
		_open_inventory_screen("crafting")


func _open_journal_from_ui() -> void:
	_close_inventory_screens()
	_set_journal_open(true)


func _toggle_map_from_ui() -> void:
	_set_full_map_open(not full_map_open)


func _on_inventory_backdrop_input(event: InputEvent) -> void:
	if inventory_open:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
				_close_inventory_screens()
				get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				_close_inventory_screens()
				get_viewport().set_input_as_handled()


func _on_map_close_catcher_input(event: InputEvent) -> void:
	if full_map_open:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
				_set_full_map_open(false)
				get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				_set_full_map_open(false)
				get_viewport().set_input_as_handled()


func _on_minimap_gui_input(event: InputEvent) -> void:
	var local_pos := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
			return
		local_pos = mouse.position
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			return
		local_pos = touch.position
	else:
		return
	# Same circular rule as the touch handlers: only the lens itself.
	if minimap_panel != null:
		var center := minimap_panel.size * 0.5
		if center.distance_to(local_pos) > minimap_panel.size.x * 0.5 + 12.0:
			return
	_toggle_map_from_ui()
	minimap_panel.accept_event()


func _mobile_grapple_button_pressed() -> void:
	_throw_grapple(player_position + Vector2(float(facing) * GRAPPLE_RANGE, 0.0))


func _mobile_attack_button_pressed() -> void:
	# Auto-aim: attack the nearest enemy within ~150 px, otherwise swing forward.
	var best: Dictionary = {}
	var best_dist := 150.0 * 150.0
	for enemy in enemies:
		if not _enemy_can_be_hit(enemy):
			continue
		var d := (Vector2(enemy.get("pos", Vector2.ZERO)) - player_position).length_squared()
		if d < best_dist:
			best_dist = d
			best = enemy
	if not best.is_empty():
		_try_player_attack_at(Vector2(best.get("pos", player_position)))
	else:
		_try_player_attack_at(player_position + Vector2(float(facing) * 100.0, 0.0))


func _mobile_controls_enabled() -> bool:
	return mobile_ui_enabled


func _set_full_map_open(open: bool) -> void:
	full_map_open = open
	if full_map_panel != null:
		full_map_panel.visible = open
	if full_map_backdrop != null:
		full_map_backdrop.visible = open
	if map_close_catcher != null:
		map_close_catcher.visible = open
	if open:
		inventory_open = false
		_close_chest()
		_release_mobile_actions()
		_refresh_map_textures()
	_update_mobile_controls_visibility()


func _update_mobile_controls_visibility() -> void:
	var settings_open := settings_panel != null and settings_panel.visible
	if mobile_controls != null:
		mobile_controls.visible = mobile_ui_enabled and not full_map_open and not journal_open and not debug_console_open and not settings_open
	if mobile_gameplay_controls != null:
		mobile_gameplay_controls.visible = mobile_ui_enabled and not full_map_open and not inventory_open and not journal_open and not debug_console_open and not settings_open
		if not mobile_gameplay_controls.visible:
			_release_mobile_actions()
	if grapple_button != null:
		grapple_button.visible = mobile_ui_enabled and not full_map_open and not inventory_open and not journal_open and not debug_console_open and not settings_open and equipped_accessory == "grappling_hook"


func _setup_audio() -> void:
	sound_players.clear()
	var sounds := {
		"swing": {"freq": 315.0, "duration": 0.045, "volume": -15.0},
		"hit": {"freq": 180.0, "duration": 0.08, "volume": -10.0},
		"heavy_hit": {"freq": 92.0, "duration": 0.13, "volume": -7.5},
		"block": {"freq": 245.0, "duration": 0.07, "volume": -11.0},
		"pickup": {"freq": 820.0, "duration": 0.10, "volume": -12.0},
		"hurt": {"freq": 110.0, "duration": 0.16, "volume": -9.0},
		"mine": {"freq": 260.0, "duration": 0.06, "volume": -14.0},
		"shoot": {"freq": 520.0, "duration": 0.09, "volume": -12.0},
		"boss": {"freq": 74.0, "duration": 0.45, "volume": -8.0},
		"forest_event": {"freq": 640.0, "duration": 0.22, "volume": -14.0},
		"cave_event": {"freq": 210.0, "duration": 0.24, "volume": -13.0},
		"mushroom_event": {"freq": 420.0, "duration": 0.28, "volume": -13.0},
		"ash_event": {"freq": 96.0, "duration": 0.36, "volume": -11.0},
		"water_event": {"freq": 330.0, "duration": 0.30, "volume": -14.0},
		"lava_event": {"freq": 130.0, "duration": 0.32, "volume": -11.0},
		"glass_event": {"freq": 920.0, "duration": 0.24, "volume": -15.0}
	}
	for sound_name in sounds.keys():
		var data: Dictionary = sounds[sound_name]
		var player := AudioStreamPlayer.new()
		player.name = "Sound_%s" % sound_name
		player.stream = _make_tone(float(data["freq"]), float(data["duration"]))
		player.volume_db = float(data["volume"])
		add_child(player)
		sound_players[str(sound_name)] = player
	_apply_master_volume()


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(float(mix_rate) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var fade := 1.0 - float(i) / float(maxi(1, sample_count))
		var wave := sin(t * frequency * TAU) * fade
		var sample := int(clampf(wave, -1.0, 1.0) * 18000.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_sound(sound_name: String) -> void:
	if not sound_players.has(sound_name):
		return
	var player: AudioStreamPlayer = sound_players[sound_name]
	player.stop()
	player.play()


func _make_hud_panel(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.offset_left = position.x
	panel.offset_top = position.y
	panel.offset_right = position.x + size.x
	panel.offset_bottom = position.y + size.y
	var style := _pixel_sb("res://assets/ui/frame.png", 8)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_compass_clear_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _pixel_sb("res://assets/ui/frame.png", 8)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_compass_map_frame() -> Control:
	# Frameless: the minimap is a circular lens, no square panel behind it.
	var panel := Control.new()
	return panel


func _make_compass_progress_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("0a0d13", 0.95)
	background.border_color = Color("ffffff", 0.10)
	background.set_border_width_all(1)
	background.content_margin_left = 2
	background.content_margin_top = 2
	background.content_margin_right = 2
	background.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_border_width_all(1)
	fill.border_color = fill_color.lightened(0.35)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _apply_compass_hotbar_slot_style(button: Button, selected: bool) -> void:
	_apply_pixel_slot_style(button, selected)


func _make_compass_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(106, 32)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", ui_pixel_font)
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color("e8edf2"))
	button.add_theme_color_override("font_hover_color", Color("ffc766"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("68727d"))
	var normal := _pixel_sb("res://assets/ui/button.png", 6)
	normal.content_margin_left = 8
	normal.content_margin_top = 7
	normal.content_margin_right = 8
	normal.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", normal)
	var hover := _pixel_sb("res://assets/ui/button_hover.png", 6)
	hover.content_margin_left = 8
	hover.content_margin_top = 7
	hover.content_margin_right = 8
	hover.content_margin_bottom = 7
	button.add_theme_stylebox_override("hover", hover)
	var pressed := _pixel_sb("res://assets/ui/button_pressed.png", 6)
	pressed.content_margin_left = 8
	pressed.content_margin_top = 7
	pressed.content_margin_right = 8
	pressed.content_margin_bottom = 7
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	return button


func _apply_compass_inventory_slot_style(button: Button, selected: bool, equipment := false) -> void:
	_apply_pixel_slot_style(button, selected)


func _make_slot_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 10)
	_apply_slot_style(button, false)
	return button


func _apply_slot_style(button: Button, selected: bool) -> void:
	_apply_pixel_slot_style(button, selected)


func _setup_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_ensure_key_action("regen_world", [KEY_R])
	_ensure_key_action("save_world", [KEY_F5])
	_ensure_key_action("load_world", [KEY_F9])
	_ensure_key_action("toggle_inventory", [KEY_TAB, KEY_I])
	_ensure_key_action("toggle_map", [KEY_M])
	_ensure_key_action("toggle_journal", [KEY_J])
	_ensure_key_action("recipe_prev", [KEY_Z])
	_ensure_key_action("recipe_next", [KEY_X])
	_ensure_key_action("craft_item", [KEY_C])
	_ensure_key_action("equip_item", [KEY_E])
	_ensure_key_action("attack", [KEY_F])
	_ensure_key_action("grapple", [KEY_G])
	_ensure_key_action("toggle_build", [KEY_B])
	_ensure_key_action("hotbar_1", [KEY_1])
	_ensure_key_action("hotbar_2", [KEY_2])
	_ensure_key_action("hotbar_3", [KEY_3])
	_ensure_key_action("hotbar_4", [KEY_4])
	_ensure_key_action("hotbar_5", [KEY_5])
	_ensure_mouse_action("mine", MOUSE_BUTTON_LEFT)
	_ensure_mouse_action("place", MOUSE_BUTTON_RIGHT)
	_ensure_mouse_action("zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_ensure_mouse_action("zoom_out", MOUSE_BUTTON_WHEEL_DOWN)


func _ensure_key_action(action: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var exists := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.keycode == keycode:
				exists = true
				break
		if exists:
			continue
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action, key_event)


func _ensure_mouse_action(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button:
			return
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = button
	InputMap.action_add_event(action, mouse_event)


func _generate_world() -> void:
	world_generation_in_progress = true
	if liquid_sim != null:
		liquid_sim.clear()
	seed = int(Time.get_unix_time_from_system()) % 1000000000
	rng.seed = seed
	_reset_weather_state()
	_reset_inventory()
	network_player_profiles.clear()
	network_open_chests.clear()
	network_open_tiles.clear()
	network_mine_ready_msec.clear()
	health = MAX_HEALTH
	oxygen = MAX_OXYGEN
	body_temperature = NORMAL_BODY_TEMPERATURE
	ambient_temperature = 20.0
	temperature_sample_timer = 0.0
	temperature_damage_tick = 0.0
	temperature_visual_state = ""
	drowning_tick = 0.0
	lava_tick = 0.0
	liquid_flow_timer = 0.0
	liquid_flow_phase = 0
	sapling_growth_timer = 0.0
	enemies.clear()
	dying_enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	enemy_impact_effects.clear()
	perception_noise_events.clear()
	dropped_items.clear()
	next_network_loot_id = 1
	network_pending_loot.clear()
	damage_numbers.clear()
	hit_particles.clear()
	combat_impacts.clear()
	combat_hit_stop_timer = 0.0
	camera_shake_strength = 0.0
	camera_shake_time = 0.0
	camera_shake_duration = 0.0
	camera_shake_phase = 0.0
	player_hurt_flash = 0.0
	loot_notifications.clear()
	attack_anim_time = 0.0
	attack_anim_kind = ""
	held_item_id = ""
	held_item_amount = 0
	world_time = 28.0
	defeated_enemies = 0
	flight_charge = FLIGHT_CHARGE_MAX
	path_choice = ""
	npc_wanderer_active = false
	npc_wanderer_pos = Vector2(-1.0, -1.0)
	observatory_pos = Vector2i(-1, -1)
	moon_altar_pos = Vector2i(-1, -1)
	path_dialog_open = false
	enemy_spawn_timer = 45.0
	boss_spawned = false
	boss_defeated = false
	stone_broken_count = 0
	stone_beast_spawned = false
	stone_beast_defeated = false
	mushroom_path_opened = false
	last_biome = ""
	player_statuses.clear()
	mining_progress = 0.0
	mining_target = Vector2i(-999, -999)
	world.clear()
	surface_heights.clear()
	surface_biomes.clear()
	chest_loot.clear()
	sapling_positions.clear()
	tree_tile_owners.clear()
	next_tree_id = 1
	_reset_knowledge()
	biome_check_timer = 0.0
	hud_update_timer = 0.0

	var height_noise := FastNoiseLite.new()
	height_noise.seed = seed
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = 0.018
	height_noise.fractal_octaves = 4

	var cave_noise := FastNoiseLite.new()
	cave_noise.seed = seed + 1009
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cave_noise.frequency = 0.055
	cave_noise.fractal_octaves = 3

	var ore_noise := FastNoiseLite.new()
	ore_noise.seed = seed + 2027
	ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ore_noise.frequency = 0.105
	ore_noise.fractal_octaves = 2

	for x in range(WORLD_WIDTH):
		var h := int(44 + height_noise.get_noise_1d(float(x)) * 12.0 + sin(float(x) * 0.035) * 5.0)
		h = clampi(h, 24, 66)
		surface_heights.append(h)
	_build_surface_biome_map()

	for y in range(WORLD_HEIGHT):
		var row: Array[int] = []
		for x in range(WORLD_WIDTH):
			row.append(_pick_base_tile(x, y, cave_noise, ore_noise))
		world.append(row)

	_carve_spawn_area()
	_add_cave_networks()
	_add_biomes()
	_add_ash_pockets()
	_add_cave_structures()
	_add_landmark_structures()
	_add_depth_sanctum()
	_add_cave_decorations()
	_add_trees()
	_add_roots()
	_add_ruins()
	_add_sky_islands()
	_stabilize_generated_chests()
	world_generation_in_progress = false
	_invalidate_world_tile_caches()
	if liquid_sim != null:
		liquid_sim.rebuild(world)
	_spawn_player()
	_reset_exploration()
	_reveal_player_surroundings()
	cached_biome = _compute_current_biome()
	_update_minimap(999.0)


func _reset_inventory() -> void:
	inventory.clear()
	inventory["wooden_pickaxe"] = 1
	inventory["builder_hammer"] = 1
	inventory["wooden_sword"] = 1
	inventory["dirt"] = 24
	inventory["wood"] = 12
	current_tool = "wooden_pickaxe"
	hotbar = ["wooden_pickaxe", "dirt", "stone", "wood", "workbench"]
	selected_slot = 0
	selected_block = Tile.DIRT
	selected_recipe_index = 0
	equipped_weapon = ""
	equipped_armor = ""
	equipped_accessory = ""
	selected_inventory_item_id = ""
	last_message = "Gather wood and stone, then craft a workbench."


func _build_surface_biome_map() -> void:
	surface_biomes.clear()
	topsoil_noise = FastNoiseLite.new()
	topsoil_noise.seed = seed + 2791
	topsoil_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	topsoil_noise.frequency = 0.085
	topsoil_noise.fractal_octaves = 2
	_setup_transition_noise()
	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = seed + 6143
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_noise.frequency = 0.012
	biome_noise.fractal_octaves = 2
	var layout_rng := RandomNumberGenerator.new()
	layout_rng.seed = seed + 9127
	# Wide bands make each biome a real region instead of a tiny strip. The band
	# count is rolled first, then widths jitter around the average and get
	# nudged one tile at a time until they cover the world exactly. This keeps
	# every band inside the min/max range, including the last one.
	var band_count := layout_rng.randi_range(7, 9)
	var average_width := int(WORLD_WIDTH / band_count)
	var widths: Array[int] = []
	var width_sum := 0
	for i in range(band_count):
		var width := clampi(
			layout_rng.randi_range(average_width - 40, average_width + 40),
			SURFACE_BAND_MIN_WIDTH,
			SURFACE_BAND_MAX_WIDTH
		)
		widths.append(width)
		width_sum += width
	var adjust_index := 0
	while width_sum != WORLD_WIDTH:
		if width_sum < WORLD_WIDTH and widths[adjust_index] < SURFACE_BAND_MAX_WIDTH:
			widths[adjust_index] += 1
			width_sum += 1
		elif width_sum > WORLD_WIDTH and widths[adjust_index] > SURFACE_BAND_MIN_WIDTH:
			widths[adjust_index] -= 1
			width_sum -= 1
		adjust_index = (adjust_index + 1) % band_count
	var band_ends: Array[int] = []
	var covered := 0
	for width in widths:
		covered += width
		band_ends.append(covered)
	var spawn_x := int(WORLD_WIDTH / 2)
	var spawn_band := band_ends.size() - 1
	for i in range(band_ends.size()):
		var band_start := 0 if i == 0 else band_ends[i - 1]
		if spawn_x >= band_start and spawn_x < band_ends[i]:
			spawn_band = i
			break
	# Assign biomes from a shuffled cycle that exhausts every type before
	# repeating, never placing the same type twice in a row.
	var band_biomes: Array[String] = []
	var available: Array[String] = []
	var previous := ""
	for i in range(band_ends.size()):
		if i == spawn_band:
			band_biomes.append("forest")
			previous = "forest"
			continue
		if available.is_empty():
			available = SURFACE_BAND_BIOMES.duplicate()
		var options: Array[String] = []
		for candidate in available:
			if candidate == previous:
				continue
			# Never place natural forest directly before the pinned spawn band,
			# so two forest regions cannot merge into one mega-biome.
			if i + 1 == spawn_band and candidate == "forest":
				continue
			options.append(candidate)
		if options.is_empty():
			available = SURFACE_BAND_BIOMES.duplicate()
			for candidate in available:
				if candidate == previous:
					continue
				if i + 1 == spawn_band and candidate == "forest":
					continue
				options.append(candidate)
		var biome: String = options[layout_rng.randi_range(0, options.size() - 1)]
		available.erase(biome)
		band_biomes.append(biome)
		previous = biome
	var band_index := 0
	for x in range(WORLD_WIDTH):
		# Noise nudges band borders so transitions weave instead of forming a flat
		# vertical line. The band index only moves forward, which keeps one-column
		# biome pockets from appearing along the border.
		var border_wobble := int(round(biome_noise.get_noise_1d(float(x)) * 18.0))
		while band_index < band_ends.size() - 1 and x >= band_ends[band_index] + border_wobble:
			band_index += 1
		var column_biome: String = band_biomes[band_index]
		# The spawn corridor is always forest, independent of the world seed.
		if abs(x - spawn_x) <= 42:
			column_biome = "forest"
		surface_biomes.append(column_biome)
	_rebuild_border_metadata()


func _setup_transition_noise() -> void:
	# Broad coherent pockets prevent the blend from looking like single-pixel
	# dithering, while a lower-frequency field bends the seam with depth.
	transition_noise = FastNoiseLite.new()
	transition_noise.seed = seed + 5511
	transition_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	transition_noise.frequency = 0.14
	transition_noise.fractal_octaves = 3
	transition_noise.fractal_gain = 0.62
	border_meander_noise = FastNoiseLite.new()
	border_meander_noise.seed = seed + 7723
	border_meander_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	border_meander_noise.frequency = 0.035
	border_meander_noise.fractal_octaves = 2


func _rebuild_border_metadata() -> void:
	border_distances.clear()
	border_neighbors.clear()
	var width := surface_biomes.size()
	if width == 0:
		return
	for i in range(width):
		border_distances.append(width)
		border_neighbors.append("")
	for seam in range(1, width):
		if surface_biomes[seam] == surface_biomes[seam - 1]:
			continue
		var left_biome: String = surface_biomes[seam - 1]
		var right_biome: String = surface_biomes[seam]
		for offset in range(SURFACE_BORDER_BLEND):
			var left_x := seam - 1 - offset
			if left_x >= 0 and offset < border_distances[left_x]:
				border_distances[left_x] = offset
				border_neighbors[left_x] = right_biome
			var right_x := seam + offset
			if right_x < width and offset < border_distances[right_x]:
				border_distances[right_x] = offset
				border_neighbors[right_x] = left_biome


func _blended_biome_at(x: int, y: int, biome: String) -> String:
	if border_distances.size() != surface_biomes.size() or transition_noise == null:
		return biome
	if x < 0 or x >= border_distances.size():
		return biome
	var distance: int = border_distances[x]
	if distance >= SURFACE_BORDER_BLEND:
		return biome
	var neighbor: String = border_neighbors[x]
	if neighbor.is_empty() or neighbor == biome:
		return biome
	var drift := 0.0
	if border_meander_noise != null:
		drift = border_meander_noise.get_noise_2d(float(x) * 0.35, float(y)) * SURFACE_BORDER_MEANDER
	var effective_distance := float(distance) - drift
	if effective_distance >= float(SURFACE_BORDER_BLEND):
		return biome
	var takes_neighbor := effective_distance < 0.0
	if not takes_neighbor:
		var own_chance := 0.5 + 0.5 * (effective_distance / float(SURFACE_BORDER_BLEND))
		var pocket := transition_noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
		takes_neighbor = pocket > own_chance
	return neighbor if takes_neighbor else biome


func _visual_biome_at(x: int, y: int) -> String:
	# Rendering uses the exact same deterministic blend as world generation, so
	# palette tint cannot redraw a hard vertical line over interlocked blocks.
	return _blended_biome_at(x, y, _surface_biome_at_column(x))


func _topsoil_depth_at_column(x: int, biome: String) -> int:
	var noise_value := 0.0
	if topsoil_noise != null:
		noise_value = topsoil_noise.get_noise_1d(float(x))
	# Every biome gets its own topsoil depth profile, from the thin frozen crust
	# of the wasteland to the deep drifts of the ash desert.
	match biome:
		"ash_desert":
			return maxi(4, 8 + int(round(noise_value * 4.0)))
		"marsh":
			return maxi(2, 5 + int(round(noise_value * 3.0)))
		"frost_wasteland":
			return maxi(2, 4 + int(round(noise_value * 3.0)))
		"ash_ruins":
			return maxi(2, 4 + int(round(noise_value * 3.0)))
		_:
			return maxi(2, 5 + int(round(noise_value * 3.0)))


func _scaled_count(base: int) -> int:
	# Generation pass densities are tuned for the classic 560-column world; keep
	# them constant when the world grows so wider worlds stay just as full.
	return maxi(1, int(round(float(base) * float(WORLD_WIDTH) / 560.0)))


func _is_biome_topsoil_tile(tile: int) -> bool:
	return tile == Tile.ASH_SAND or tile == Tile.FROZEN_DIRT or tile == Tile.MUD or tile == Tile.RUBBLE or tile == Tile.SKY_GRASS


func _surface_biome_at_column(x: int) -> String:
	if surface_biomes.size() == WORLD_WIDTH:
		return surface_biomes[clampi(x, 0, WORLD_WIDTH - 1)]
	return "forest"


func _surface_biome_at_player() -> String:
	var tile_x := floori(player_position.x / TILE_SIZE)
	return _surface_biome_at_column(tile_x)


func _pick_base_tile(x: int, y: int, cave_noise: FastNoiseLite, ore_noise: FastNoiseLite) -> int:
	var surface_y: int = surface_heights[x]
	if y < surface_y:
		return Tile.AIR
	var biome := _blended_biome_at(x, y, _surface_biome_at_column(x))
	if y == surface_y:
		# The visible ground block belongs to the biome, not just its tint.
		if biome == "frost_wasteland":
			return Tile.SNOW_BLOCK
		if biome == "ash_desert":
			return Tile.ASH_SAND
		return Tile.GRASS

	var depth := y - surface_y
	var cave_value := cave_noise.get_noise_2d(float(x), float(y))
	if depth > 8 and cave_value > 0.34:
		return Tile.AIR

	# Topsoil is biome-specific all the way down, not only the first row: the
	# desert is real ash sand, the marsh is wet mud, the wasteland is frozen
	# dirt and the ruins sit on rubble.
	if depth <= _topsoil_depth_at_column(x, biome):
		match biome:
			"frost_wasteland":
				return Tile.FROZEN_DIRT
			"marsh":
				return Tile.MUD
			"ash_desert":
				return Tile.ASH_SAND
			"ash_ruins":
				return Tile.RUBBLE
		return Tile.DIRT

	var ore_value := ore_noise.get_noise_2d(float(x), float(y))
	if depth > 14 and ore_value > 0.58:
		return Tile.COPPER
	if depth > 28 and ore_value < -0.60:
		return Tile.IRON
	if depth > 44 and cave_value < -0.48:
		return Tile.ASH

	return Tile.STONE


func _add_cave_networks() -> void:
	var room_centers: Array[Vector2i] = []
	for i in range(_scaled_count(44)):
		var x := rng.randi_range(18, WORLD_WIDTH - 19)
		var surface_y: int = surface_heights[x]
		var y := rng.randi_range(surface_y + 14, WORLD_HEIGHT - 18)
		var radius_x := rng.randi_range(5, 13)
		var radius_y := rng.randi_range(3, 8)
		var center := Vector2i(x, y)
		room_centers.append(center)
		_carve_cave_blob(center, radius_x, radius_y)
	room_centers.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x
	)
	for i in range(room_centers.size() - 1):
		if rng.randf() < 0.88:
			_carve_tunnel(room_centers[i], room_centers[i + 1], rng.randi_range(2, 3))
	# Occasional cross-links create loops instead of one long cave chain.
	for i in range(room_centers.size() - 2):
		if rng.randf() < 0.28:
			_carve_tunnel(room_centers[i], room_centers[i + 2], 2)


func _add_biomes() -> void:
	_add_forest_floor_details()
	_add_marsh_ponds()
	_add_mushroom_halls()
	_add_ash_cities()
	_add_sunken_ruins()
	_add_lava_roots()
	_add_glass_abyss()


func _add_forest_floor_details() -> void:
	for x in range(6, WORLD_WIDTH - 6):
		var ground_y: int = surface_heights[x]
		if _get_tile(x, ground_y) == Tile.GRASS and rng.randf() < 0.22:
			_set_tile(x, ground_y, Tile.MOSS)
		if rng.randf() < 0.035:
			_add_forest_cache(Vector2i(x, ground_y - 1))


func _add_forest_cache(pos: Vector2i) -> void:
	for x in range(pos.x - 2, pos.x + 3):
		if _in_bounds(x, pos.y + 1) and _get_tile(x, pos.y + 1) != Tile.AIR:
			_set_tile(x, pos.y + 1, Tile.MOSS)


func _add_marsh_ponds() -> void:
	# Surface ponds make the marsh read differently from the other surface
	# biomes and give the finite water sim something to do above ground.
	var pond_centers: Array[int] = []
	for attempt in range(_scaled_count(30)):
		if pond_centers.size() >= _scaled_count(3):
			break
		var x := rng.randi_range(18, WORLD_WIDTH - 19)
		if _surface_biome_at_column(x) != "marsh":
			continue
		var too_close := false
		for other in pond_centers:
			if abs(x - other) < 26:
				too_close = true
				break
		if too_close:
			continue
		pond_centers.append(x)
		_carve_marsh_pond(x)


func _carve_marsh_pond(center_x: int) -> void:
	var half_width := rng.randi_range(4, 8)
	var depth := rng.randi_range(3, 5)
	for dx in range(-half_width, half_width + 1):
		var x := center_x + dx
		if not _in_bounds(x, 0):
			continue
		var surface_y: int = surface_heights[x]
		var rim_taper := int(round(absf(float(dx)) / float(maxi(1, half_width)) * 2.0))
		var dig_depth := maxi(1, depth - rim_taper)
		for y in range(surface_y, surface_y + dig_depth):
			_set_tile(x, y, Tile.AIR)
		# Keep the water level below the pond rim so the pool stays contained;
		# the shallowest shore columns become open mud instead of water.
		if dig_depth >= 2:
			for y in range(surface_y + 1, surface_y + dig_depth):
				_set_tile(x, y, Tile.WATER)
	# A moss rim frames every pond and keeps the marsh palette on the surface.
	for rim_x in [center_x - half_width - 1, center_x + half_width + 1]:
		if not _in_bounds(rim_x, 0):
			continue
		var rim_y: int = surface_heights[rim_x]
		if _get_tile(rim_x, rim_y) == Tile.GRASS:
			_set_tile(rim_x, rim_y, Tile.MOSS)


func _add_mushroom_halls() -> void:
	for i in range(_scaled_count(8)):
		var x := rng.randi_range(48, WORLD_WIDTH - 49)
		var y := rng.randi_range(surface_heights[x] + 42, WORLD_HEIGHT - 48)
		var center := Vector2i(x, y)
		_carve_cave_blob(center, rng.randi_range(10, 20), rng.randi_range(5, 10))
		_paint_biome_patch(center, rng.randi_range(13, 22), rng.randi_range(7, 12), Tile.MUSHROOM_SOIL, Tile.STONE)
		for cap in range(rng.randi_range(9, 18)):
			var px := center.x + rng.randi_range(-18, 18)
			var py := center.y + rng.randi_range(-7, 9)
			if _in_bounds(px, py) and _get_tile(px, py) == Tile.AIR and _get_tile(px, py + 1) != Tile.AIR:
				_set_tile(px, py, Tile.GLOW_MUSHROOM)
		_try_place_cave_chest(center + Vector2i(rng.randi_range(-5, 5), rng.randi_range(-1, 2)), "mushroom")


func _add_ash_cities() -> void:
	for i in range(_scaled_count(5)):
		var w := rng.randi_range(20, 34)
		var h := rng.randi_range(8, 14)
		var left := rng.randi_range(35, WORLD_WIDTH - w - 35)
		var top := rng.randi_range(72, WORLD_HEIGHT - 68)
		for y in range(top, top + h):
			for x in range(left, left + w):
				var border := x == left or x == left + w - 1 or y == top or y == top + h - 1
				var column := (x - left) % 7 == 0 and y > top + 2
				if border or column:
					_set_tile(x, y, Tile.ASH_BRICK)
				else:
					_set_tile(x, y, Tile.AIR)
		for tower in range(rng.randi_range(2, 4)):
			var tx := left + rng.randi_range(3, w - 4)
			for y in range(top - rng.randi_range(3, 7), top + 1):
				_set_tile(tx, y, Tile.ASH_BRICK)
		_try_place_structure_chest(Vector2i(left + rng.randi_range(3, w - 4), top + h - 2), "ash_city")


func _add_sunken_ruins() -> void:
	for i in range(_scaled_count(6)):
		var center := Vector2i(rng.randi_range(28, WORLD_WIDTH - 29), rng.randi_range(88, WORLD_HEIGHT - 46))
		var radius_x := rng.randi_range(8, 16)
		var radius_y := rng.randi_range(4, 8)
		_carve_cave_blob(center, radius_x, radius_y)
		_paint_biome_patch(center, radius_x + 3, radius_y + 2, Tile.SUNKEN_STONE, Tile.STONE)
		_fill_liquid_pool(center, radius_x - 1, radius_y, center.y, Tile.WATER)
		for col in range(rng.randi_range(3, 6)):
			var x := center.x + rng.randi_range(-12, 12)
			for y in range(center.y - rng.randi_range(2, 5), center.y + rng.randi_range(2, 5)):
				if rng.randf() > 0.18:
					_set_tile(x, y, Tile.SUNKEN_STONE)
		_try_place_structure_chest(center + Vector2i(rng.randi_range(-4, 4), rng.randi_range(0, 3)), "sunken")


func _add_lava_roots() -> void:
	for i in range(_scaled_count(34)):
		var x := rng.randi_range(18, WORLD_WIDTH - 19)
		var y := rng.randi_range(WORLD_HEIGHT - 72, WORLD_HEIGHT - 16)
		var length := rng.randi_range(14, 42)
		for step in range(length):
			if not _in_bounds(x, y):
				break
			if _get_tile(x, y) != Tile.AIR:
				_set_tile(x, y, Tile.LAVA_ROOT)
			if rng.randf() < 0.18:
				_set_tile(x + rng.randi_range(-1, 1), y, Tile.ASH)
			x += rng.randi_range(-1, 1)
			y += rng.randi_range(-1, 1)
	for i in range(_scaled_count(5)):
		var pos := Vector2i(rng.randi_range(35, WORLD_WIDTH - 36), rng.randi_range(WORLD_HEIGHT - 58, WORLD_HEIGHT - 18))
		var radius_x := rng.randi_range(7, 13)
		var radius_y := rng.randi_range(3, 6)
		_carve_cave_blob(pos, radius_x, radius_y)
		_fill_liquid_pool(pos, radius_x - 1, radius_y, pos.y + 1, Tile.LAVA)
		_try_place_cave_chest(pos, "lava_root")


func _add_glass_abyss() -> void:
	for i in range(_scaled_count(7)):
		var center := Vector2i(rng.randi_range(28, WORLD_WIDTH - 29), rng.randi_range(WORLD_HEIGHT - 46, WORLD_HEIGHT - 12))
		_carve_cave_blob(center, rng.randi_range(12, 24), rng.randi_range(5, 11))
		_paint_biome_patch(center, rng.randi_range(15, 27), rng.randi_range(7, 13), Tile.GLASS_STONE, Tile.STONE)
		for crystal in range(rng.randi_range(8, 18)):
			var x := center.x + rng.randi_range(-20, 20)
			var y := center.y + rng.randi_range(-8, 10)
			if _in_bounds(x, y) and _get_tile(x, y) != Tile.AIR and rng.randf() < 0.55:
				_set_tile(x, y, Tile.ABYSS_CRYSTAL)
		_try_place_cave_chest(center + Vector2i(rng.randi_range(-5, 5), rng.randi_range(-1, 3)), "glass")


func _paint_biome_patch(center: Vector2i, radius_x: int, radius_y: int, tile: int, replace_tile: int) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			if not _in_bounds(x, y):
				continue
			var dx := float(x - center.x) / float(maxi(1, radius_x))
			var dy := float(y - center.y) / float(maxi(1, radius_y))
			if dx * dx + dy * dy > 1.0 + rng.randf_range(-0.18, 0.18):
				continue
			var current := _get_tile(x, y)
			if current == replace_tile or current == Tile.DIRT or current == Tile.ASH or current == Tile.RUIN:
				_set_tile(x, y, tile)
			elif _is_biome_topsoil_tile(current):
				_set_tile(x, y, tile)


func _fill_liquid_pool(center: Vector2i, radius_x: int, radius_y: int, surface_y: int, liquid_tile: int) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			if not _in_bounds(x, y) or y < surface_y:
				continue
			var dx := float(x - center.x) / float(maxi(1, radius_x))
			var dy := float(y - center.y) / float(maxi(1, radius_y))
			if dx * dx + dy * dy <= 1.0 and _get_tile(x, y) == Tile.AIR:
				_set_tile(x, y, liquid_tile)


func _carve_cave_blob(center: Vector2i, radius_x: int, radius_y: int) -> void:
	for y in range(center.y - radius_y - 1, center.y + radius_y + 2):
		for x in range(center.x - radius_x - 1, center.x + radius_x + 2):
			if not _in_bounds(x, y):
				continue
			var dx := float(x - center.x) / float(maxi(1, radius_x))
			var dy := float(y - center.y) / float(maxi(1, radius_y))
			var ragged := rng.randf_range(-0.20, 0.28)
			if dx * dx + dy * dy <= 1.0 + ragged:
				_set_tile(x, y, Tile.AIR)
	for drip in range(rng.randi_range(2, 5)):
		var start_x := center.x + rng.randi_range(-radius_x, radius_x)
		var length := rng.randi_range(3, 9)
		for step in range(length):
			_set_tile(start_x + rng.randi_range(-1, 1), center.y + radius_y + step, Tile.AIR)


func _carve_tunnel(a: Vector2i, b: Vector2i, radius: int) -> void:
	var current := a
	var guard := 0
	while current.distance_to(b) > 2.0 and guard < 260:
		guard += 1
		if rng.randf() < 0.62:
			current.x += signi(b.x - current.x)
		else:
			current.y += signi(b.y - current.y)
		current.y += rng.randi_range(-1, 1) if rng.randf() < 0.24 else 0
		for yy in range(current.y - radius, current.y + radius + 1):
			for xx in range(current.x - radius, current.x + radius + 1):
				if Vector2(xx - current.x, yy - current.y).length() <= float(radius) + rng.randf_range(-0.2, 0.8):
					_set_tile(xx, yy, Tile.AIR)


func _add_depth_sanctum() -> void:
	# A single deep sanctum per world, hidden in the lower caves.
	var center := _find_cave_floor_position()
	if center.x < 0:
		return
	# Make it deep: scan for the lowest available floor.
	for attempt in range(40):
		var x := rng.randi_range(16, WORLD_WIDTH - 17)
		var surface_y: int = surface_heights[x]
		var y := rng.randi_range(surface_y + 40, WORLD_HEIGHT - 16)
		for scan_y in range(y, mini(WORLD_HEIGHT - 4, y + 20)):
			if _get_tile(x, scan_y) == Tile.AIR and _get_tile(x, scan_y + 1) != Tile.AIR:
				center = Vector2i(x, scan_y)
				break
	# Carve a small chamber around the altar.
	var cx := center.x
	var cy := center.y
	for yy in range(-4, 5):
		for xx in range(-5, 6):
			var tx := cx + xx
			var ty := cy + yy
			if _in_bounds(tx, ty) and _get_tile(tx, ty) == Tile.AIR and yy >= -3:
				continue
			if _in_bounds(tx, ty) and (absf(xx) < 5 and yy < 3):
				_set_tile(tx, ty, Tile.AIR)
	# Floor
	for xx in range(-5, 6):
		if _in_bounds(cx + xx, cy + 2):
			_set_tile(cx + xx, cy + 2, Tile.DEPTH_STONE)
	# Walls of depth stone
	for yy in range(-3, 3):
		if _in_bounds(cx - 5, cy + yy):
			_set_tile(cx - 5, cy + yy, Tile.DEPTH_STONE)
		if _in_bounds(cx + 5, cy + yy):
			_set_tile(cx + 5, cy + yy, Tile.DEPTH_STONE)
	# The altar in the middle
	if _in_bounds(cx, cy):
		_set_tile(cx, cy, Tile.DEPTH_ALTAR)
	depth_sanctum_pos = Vector2i(cx, cy)
	# A hint appears in the journal once the player has the wind shard.
	# (Sanctum exists in the world from the start; activation requires the shard.)


func _on_depth_altar_interact() -> void:
	if depth_warden_defeated:
		last_message = "The altar is silent. The depths are at peace."
		return
	if int(inventory.get("wind_shard", 0)) <= 0:
		last_message = "The altar hums... it hungers for a shard of living wind."
		return
	if depth_warden_spawned:
		last_message = "The Warden already stirs."
		return
	inventory["wind_shard"] = int(inventory.get("wind_shard", 0)) - 1
	depth_sanctum_activated = true
	depth_warden_spawned = true
	_spawn_depth_warden()
	last_message = "The wind shard is consumed. THE DEPTH WARDEN AWAKENS!"
	_play_sound("boss")


func _on_sky_obelisk_interact() -> void:
	if sky_leviathan_defeated:
		last_message = "The obelisk hums faintly. The sky is at peace."
		return
	if sky_leviathan_spawned:
		last_message = "The Leviathan already circles above."
		return
	if int(inventory.get("sky_fragment", 0)) < SKY_FRAGMENTS_NEEDED:
		last_message = "The obelisk needs %d Sky Fragments (you have %d)." % [SKY_FRAGMENTS_NEEDED, int(inventory.get("sky_fragment", 0))]
		return
	inventory["sky_fragment"] = int(inventory.get("sky_fragment", 0)) - SKY_FRAGMENTS_NEEDED
	sky_leviathan_spawned = true
	_spawn_sky_leviathan()
	last_message = "The shards are consumed. THE SKY LEVIATHAN AWAKENS!"
	_play_sound("boss")


func _spawn_sky_leviathan() -> void:
	var pos := sky_arena_pos
	if pos.x < 0:
		pos = Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	# Spawn above the arena, high in the sky.
	_spawn_enemy("leviathan", Vector2(pos.x * TILE_SIZE + TILE_SIZE * 0.5, (pos.y - 26) * TILE_SIZE))


func _spawn_depth_warden() -> void:
	var pos := depth_sanctum_pos
	if pos.x < 0:
		pos = Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	_spawn_enemy("depth_warden", Vector2(pos.x * TILE_SIZE + TILE_SIZE * 0.5, pos.y * TILE_SIZE - 40.0))


func _add_cave_structures() -> void:
	for i in range(_scaled_count(11)):
		var center := _find_cave_floor_position()
		if center.x < 0:
			continue
		if rng.randf() < 0.55:
			_add_ruin_room(center)
		else:
			_add_root_shrine(center)


func _find_cave_floor_position() -> Vector2i:
	for attempt in range(80):
		var x := rng.randi_range(16, WORLD_WIDTH - 17)
		var surface_y: int = surface_heights[x]
		var y := rng.randi_range(surface_y + 18, WORLD_HEIGHT - 14)
		for scan_y in range(y, mini(WORLD_HEIGHT - 4, y + 16)):
			if _get_tile(x, scan_y) == Tile.AIR and _get_tile(x, scan_y + 1) != Tile.AIR:
				return Vector2i(x, scan_y)
	return Vector2i(-1, -1)


func _add_cave_decorations() -> void:
	# A small number of physical cave props create readable silhouettes without
	# closing off the generated cave network.
	for i in range(_scaled_count(160)):
		var x := rng.randi_range(10, WORLD_WIDTH - 11)
		var y := rng.randi_range(surface_heights[x] + 12, WORLD_HEIGHT - 12)
		if _get_tile(x, y) != Tile.AIR:
			continue
		var above := _get_tile(x, y - 1)
		var below := _get_tile(x, y + 1)
		if above != Tile.AIR and rng.randf() < 0.42:
			var length := rng.randi_range(1, 3)
			for step in range(length):
				if _get_tile(x, y + step) == Tile.AIR:
					_set_tile(x, y + step, Tile.STONE)
		elif below != Tile.AIR and rng.randf() < 0.34:
			var length := rng.randi_range(1, 2)
			for step in range(length):
				if _get_tile(x, y - step) == Tile.AIR:
					_set_tile(x, y - step, Tile.STONE)
		elif below == Tile.MUSHROOM_SOIL or below == Tile.MOSS:
			_set_tile(x, y, Tile.GLOW_MUSHROOM)
		elif rng.randf() < 0.22 and below != Tile.AIR:
			_set_tile(x, y, Tile.ROOT)


func _add_ruin_room(center: Vector2i) -> void:
	var w := rng.randi_range(7, 12)
	var h := rng.randi_range(4, 6)
	var left := clampi(center.x - int(w / 2), 2, WORLD_WIDTH - w - 2)
	var top := clampi(center.y - h + 1, 2, WORLD_HEIGHT - h - 2)
	for y in range(top, top + h):
		for x in range(left, left + w):
			var border := x == left or x == left + w - 1 or y == top or y == top + h - 1
			if border:
				_set_tile(x, y, Tile.RUIN)
			else:
				_set_tile(x, y, Tile.AIR)
	var door_x := left + int(w / 2)
	_set_tile(door_x, top + h - 1, Tile.AIR)
	_set_tile(door_x, top + h - 2, Tile.AIR)
	_try_place_structure_chest(Vector2i(left + rng.randi_range(2, w - 3), top + h - 2), "ruin")
	if rng.randf() < 0.45:
		_set_tile(left + rng.randi_range(2, w - 3), top + h - 2, Tile.STONE_ALTAR)


func _add_root_shrine(center: Vector2i) -> void:
	var w := rng.randi_range(6, 10)
	var left := clampi(center.x - int(w / 2), 2, WORLD_WIDTH - w - 2)
	var floor_y := clampi(center.y, 4, WORLD_HEIGHT - 4)
	for x in range(left, left + w):
		_set_tile(x, floor_y + 1, Tile.ROOT)
		if rng.randf() < 0.45:
			_set_tile(x, floor_y, Tile.AIR)
	for pillar_x in [left + 1, left + w - 2]:
		for y in range(floor_y - rng.randi_range(2, 4), floor_y + 1):
			_set_tile(pillar_x, y, Tile.ROOT)
	_try_place_structure_chest(Vector2i(left + rng.randi_range(2, w - 3), floor_y), "root")
	if rng.randf() < 0.35:
		_set_tile(left + int(w / 2), floor_y, Tile.STONE_ALTAR)


func _add_landmark_structures() -> void:
	# Large landmarks give the cave network destinations instead of only random
	# rooms. They use existing tiles so art can be upgraded independently later.
	var placed: Array[Vector2i] = []
	var placed_count := 0
	var attempts := 0
	while placed_count < _scaled_count(16) and attempts < _scaled_count(180):
		attempts += 1
		var center := _find_cave_floor_position()
		if center.x < 0 or not _landmark_area_is_clear(center, 9, 8):
			continue
		var too_close := false
		for other in placed:
			if center.distance_to(other) < 32.0:
				too_close = true
				break
		if too_close:
			continue

		var kind := placed_count % 5 if placed_count < 5 else rng.randi_range(0, 4)
		match kind:
			0:
				_add_abandoned_mine(center)
			1:
				_add_flooded_cistern(center)
			2:
				_add_lava_forge(center)
			3:
				_add_crystal_vault(center)
			4:
				_add_root_sanctum(center)
		placed.append(center)
		placed_count += 1


func _landmark_area_is_clear(center: Vector2i, half_width: int, height: int) -> bool:
	if center.x - half_width < 3 or center.x + half_width >= WORLD_WIDTH - 3:
		return false
	if center.y - height < 8 or center.y + 2 >= WORLD_HEIGHT:
		return false
	for y in range(center.y - height, center.y + 2):
		for x in range(center.x - half_width, center.x + half_width + 1):
			var tile := _get_tile(x, y)
			if tile == Tile.CHEST or tile == Tile.STONE_ALTAR or tile == Tile.WORKBENCH or tile == Tile.FURNACE or tile == Tile.ANVIL or tile == Tile.TURRET or tile == Tile.HEART:
				return false
			if tile == Tile.WATER or tile == Tile.LAVA or tile == Tile.BUBBLE_VENT or tile == Tile.DRAIN_VALVE:
				return false
	return true


func _prepare_landmark(center: Vector2i, half_width: int, height: int) -> Dictionary:
	var floor_y := center.y + 1
	var left := center.x - half_width
	var right := center.x + half_width
	var top := floor_y - height
	for y in range(top, floor_y):
		for x in range(left, right + 1):
			_set_tile(x, y, Tile.AIR)
	for x in range(left, right + 1):
		if _get_tile(x, floor_y) == Tile.AIR:
			_set_tile(x, floor_y, Tile.STONE)
	return {"left": left, "right": right, "top": top, "floor": floor_y}


func _carve_landmark_entrance(left: int, right: int, floor_y: int) -> void:
	var direction := -1 if rng.randf() < 0.5 else 1
	var wall_x := left if direction < 0 else right
	for step in range(5):
		var x := wall_x + direction * step
		_set_tile(x, floor_y - 3, Tile.AIR)
		_set_tile(x, floor_y - 2, Tile.AIR)
	# Some landmarks receive a second exit and become useful cave shortcuts.
	if rng.randf() < 0.38:
		direction *= -1
		wall_x = left if direction < 0 else right
		for step in range(3):
			var x := wall_x + direction * step
			_set_tile(x, floor_y - 3, Tile.AIR)
			_set_tile(x, floor_y - 2, Tile.AIR)


func _add_abandoned_mine(center: Vector2i) -> void:
	var room := _prepare_landmark(center, 7, 7)
	var left := int(room["left"])
	var right := int(room["right"])
	var top := int(room["top"])
	var floor_y := int(room["floor"])
	for x in range(left, right + 1):
		_set_tile(x, top, Tile.WOOD)
	for support_x in [left, left + 4, right]:
		for y in range(top, floor_y):
			_set_tile(support_x, y, Tile.WOOD)
		var torch_x: int = int(support_x) + 1 if int(support_x) < right else int(support_x) - 1
		if _get_tile(torch_x, top + 2) == Tile.AIR:
			_set_tile(torch_x, top + 2, Tile.TORCH)
	if rng.randf() < 0.55:
		_set_tile(center.x - 3, floor_y - 1, Tile.STONE)
		_set_tile(center.x - 2, floor_y - 1, Tile.STONE)
	_try_place_structure_chest(Vector2i(center.x + rng.randi_range(-2, 2), floor_y - 1), "ruin")


func _add_flooded_cistern(center: Vector2i) -> void:
	var room := _prepare_landmark(center, 8, 7)
	var left := int(room["left"])
	var right := int(room["right"])
	var top := int(room["top"])
	var floor_y := int(room["floor"])
	for x in range(left, right + 1):
		_set_tile(x, top, Tile.SUNKEN_STONE)
	for y in range(top, floor_y):
		_set_tile(left, y, Tile.SUNKEN_STONE)
		_set_tile(right, y, Tile.SUNKEN_STONE)
	for x in range(left + 2, right - 1):
		_set_tile(x, floor_y - 2, Tile.WATER)
		_set_tile(x, floor_y - 1, Tile.WATER)
	_set_tile(left + 2, floor_y, Tile.BUBBLE_VENT)
	_set_tile(right - 2, floor_y, Tile.DRAIN_VALVE)
	for x in range(left + 2, left + 5):
		_set_tile(x, floor_y - 2, Tile.SUNKEN_STONE)
	_try_place_structure_chest(Vector2i(left + 3, floor_y - 3), "sunken")
	_carve_landmark_entrance(left, right, floor_y)


func _add_lava_forge(center: Vector2i) -> void:
	var room := _prepare_landmark(center, 8, 7)
	var left := int(room["left"])
	var right := int(room["right"])
	var top := int(room["top"])
	var floor_y := int(room["floor"])
	for x in range(left, right + 1):
		_set_tile(x, top, Tile.ASH_BRICK)
	for y in range(top, floor_y):
		_set_tile(left, y, Tile.ASH_BRICK)
		_set_tile(right, y, Tile.ASH_BRICK)
	for x in range(center.x - 4, center.x + 5):
		_set_tile(x, floor_y, Tile.ASH_BRICK)
		_set_tile(x, floor_y - 1, Tile.LAVA)
	_set_tile(left + 2, floor_y - 1, Tile.STONE_ALTAR)
	_set_tile(right - 2, floor_y - 1, Tile.LAVA_ROOT)
	_try_place_structure_chest(Vector2i(left + 2, floor_y - 2), "lava_root")
	_carve_landmark_entrance(left, right, floor_y)


func _add_crystal_vault(center: Vector2i) -> void:
	var room := _prepare_landmark(center, 8, 8)
	var left := int(room["left"])
	var right := int(room["right"])
	var top := int(room["top"])
	var floor_y := int(room["floor"])
	for x in range(left, right + 1):
		_set_tile(x, top, Tile.GLASS_STONE)
		if x % 2 == 0:
			_set_tile(x, floor_y, Tile.GLASS_STONE)
	for y in range(top, floor_y):
		_set_tile(left, y, Tile.GLASS_STONE)
		_set_tile(right, y, Tile.GLASS_STONE)
	for x in range(left + 2, right - 1, 2):
		_set_tile(x, top + 1, Tile.ABYSS_CRYSTAL)
		if rng.randf() < 0.7:
			_set_tile(x, floor_y - 1, Tile.ABYSS_CRYSTAL)
	_try_place_structure_chest(Vector2i(center.x, floor_y - 1), "glass")
	_carve_landmark_entrance(left, right, floor_y)


func _add_root_sanctum(center: Vector2i) -> void:
	var room := _prepare_landmark(center, 7, 7)
	var left := int(room["left"])
	var right := int(room["right"])
	var top := int(room["top"])
	var floor_y := int(room["floor"])
	for x in range(left + 1, right):
		if x % 2 == 0:
			_set_tile(x, top, Tile.ROOT)
	for pillar_x in [left + 1, right - 1]:
		for y in range(top, floor_y):
			_set_tile(pillar_x, y, Tile.ROOT)
	for x in range(left + 2, right - 1):
		_set_tile(x, floor_y, Tile.MOSS)
	_set_tile(center.x, floor_y - 1, Tile.STONE_ALTAR)
	for mushroom_x in [left + 3, right - 3]:
		_set_tile(mushroom_x, floor_y - 1, Tile.GLOW_MUSHROOM)
	_try_place_structure_chest(Vector2i(left + 3, floor_y - 1), "root")


func _try_place_structure_chest(pos: Vector2i, loot_kind: String) -> bool:
	if rng.randf() >= STRUCTURE_CHEST_CHANCE:
		return false
	return _place_chest(pos, _make_chest_loot(loot_kind))


func _try_place_cave_chest(pos: Vector2i, loot_kind: String) -> bool:
	if rng.randf() >= CAVE_CHEST_CHANCE:
		return false
	return _place_chest(pos, _make_chest_loot(loot_kind))


func _place_chest(pos: Vector2i, loot: Dictionary) -> bool:
	var grounded_pos := _find_grounded_chest_position(pos)
	if grounded_pos.x < 0:
		return false
	_set_tile(grounded_pos.x, grounded_pos.y, Tile.CHEST)
	chest_loot[_tile_key(grounded_pos)] = loot
	return true


func _find_grounded_chest_position(pos: Vector2i) -> Vector2i:
	for drop in range(CHEST_GROUND_SEARCH_DEPTH + 1):
		for distance in range(CHEST_GROUND_SEARCH_RADIUS + 1):
			var offsets := [0] if distance == 0 else [-distance, distance]
			for offset in offsets:
				var candidate := Vector2i(pos.x + offset, pos.y + drop)
				if not _in_bounds(candidate.x, candidate.y) or not _in_bounds(candidate.x, candidate.y + 1):
					continue
				if _get_tile(candidate.x, candidate.y) == Tile.AIR and _is_solid(candidate.x, candidate.y + 1):
					return candidate
	return Vector2i(-1, -1)


func _add_sky_islands() -> void:
	# Chapter III: a band of floating islands very high above the surface
	# (y = SKY_ZONE_TOP..SKY_ZONE_BOTTOM). They are unreachable without
	# jetpack/wings, generated once per world and saved with the world array.
	sky_island_positions.clear()
	sky_arena_pos = Vector2i(-1, -1)
	var attempts := 0
	var placed := 0
	var target := _scaled_count(9)
	while placed < target and attempts < _scaled_count(60):
		attempts += 1
		var x := rng.randi_range(30, WORLD_WIDTH - 31)
		var y := rng.randi_range(SKY_ZONE_TOP + 1, SKY_ZONE_BOTTOM - 1)
		var too_close := false
		for other in sky_island_positions:
			if absf(float(x) - float(other.x)) < 42.0 and absf(float(y) - float(other.y)) < 10.0:
				too_close = true
				break
		if too_close:
			continue
		var radius_x := rng.randi_range(3, 8)
		var radius_y := rng.randi_range(2, 5)
		_carve_sky_island(Vector2i(x, y), radius_x, radius_y)
		sky_island_positions.append(Vector2i(x, y))
		placed += 1
	# The biggest island becomes the Leviathan arena anchor (obelisk later).
	var biggest := Vector2i(-1, -1)
	var biggest_r := 0
	for center in sky_island_positions:
		var r: int = int(_get_tile(center.x, center.y) != Tile.AIR)
		for yy in range(center.y - 6, center.y + 7):
			for xx in range(center.x - 9, center.x + 10):
				if _in_bounds(xx, yy) and _get_tile(xx, yy) == Tile.CLOUDSTONE:
					r += 1
		if r > biggest_r:
			biggest_r = r
			biggest = center
	if biggest.x >= 0:
		sky_arena_pos = biggest
		_add_sky_obelisk(biggest)
	# Sky shrines: small cloud platforms with a chest holding a guaranteed
	# Sky Fragments (needed to summon the Leviathan) plus sky resources.
	var shrine_count := 0
	var shrine_target := maxi(3, _scaled_count(3))
	for center in sky_island_positions:
		if shrine_count >= shrine_target:
			break
		if rng.randf() < 0.6:
			continue
		if _add_sky_shrine(center):
			shrine_count += 1


func _add_sky_obelisk(center: Vector2i) -> void:
	# The Leviathan summoning obelisk on the biggest island: a cloudstone
	# tower with the obelisk crystal on top. Only placed once per world.
	var top_y := center.y
	while _in_bounds(center.x, top_y - 1) and _get_tile(center.x, top_y - 1) != Tile.AIR:
		top_y -= 1
	var base_y := top_y - 1
	if not _in_bounds(center.x, base_y):
		return
	# Pillar of cloudstone up from the island surface.
	var pillar_top := base_y - 4
	for y in range(pillar_top, base_y):
		if _in_bounds(center.x, y) and _get_tile(center.x, y) == Tile.AIR:
			_set_tile(center.x, y, Tile.CLOUDSTONE)
	# The obelisk cap (interactable).
	if _in_bounds(center.x, pillar_top - 1):
		_set_tile(center.x, pillar_top - 1, Tile.SKY_OBELISK)
	# Two crystal pylons beside the tower.
	for sx in [center.x - 3, center.x + 3]:
		if _in_bounds(sx, base_y) and _get_tile(sx, base_y) == Tile.SKY_GRASS:
			_set_tile(sx, base_y - 1, Tile.SKY_CRYSTAL)


func _carve_sky_island(center: Vector2i, radius_x: int, radius_y: int) -> void:
	for y in range(center.y - radius_y, center.y + radius_y + 1):
		for x in range(center.x - radius_x, center.x + radius_x + 1):
			var dx := float(x - center.x) / float(maxi(1, radius_x))
			var dy := float(y - center.y) / float(maxi(1, radius_y))
			if dx * dx + dy * dy > 1.0:
				continue
			# Slight edge noise keeps islands cloud-shaped, not perfect ovals.
			if rng.randf() < 0.12 and (absf(dx) > 0.55 or absf(dy) > 0.55):
				continue
			if not _in_bounds(x, y):
				continue
			if y == center.y - radius_y:
				_set_tile(x, y, Tile.SKY_GRASS)
			else:
				_set_tile(x, y, Tile.CLOUDSTONE)
				if rng.randf() < 0.06 and y > center.y - radius_y + 1:
					_set_tile(x, y, Tile.SKY_CRYSTAL)
	# Tiny grass bump on top for texture (like a cloud crown).
	for x in range(center.x - 1, center.x + 2):
		if _in_bounds(x, center.y - radius_y - 1) and rng.randf() < 0.5:
			_set_tile(x, center.y - radius_y - 1, Tile.SKY_GRASS)


func _add_sky_shrine(center: Vector2i) -> bool:
	# Find the top of the island at its center column.
	var top_y := center.y
	while _in_bounds(center.x, top_y - 1) and _get_tile(center.x, top_y - 1) != Tile.AIR:
		top_y -= 1
	var surface_y := top_y - 1
	# Build a small cloudstone pillar with a chest on top.
	var px := center.x
	if not _in_bounds(px, surface_y) or not _in_bounds(px, surface_y + 2):
		return false
	_set_tile(px, surface_y, Tile.CLOUDSTONE)
	_set_tile(px, surface_y - 1, Tile.CLOUDSTONE)
	if not _place_chest(Vector2i(px, surface_y - 2), _make_chest_loot("sky")):
		return false
	# Two crystal sentinels beside the shrine.
	for sx in [px - 2, px + 2]:
		if _in_bounds(sx, surface_y) and _get_tile(sx, surface_y) == Tile.SKY_GRASS:
			_set_tile(sx, surface_y - 1, Tile.SKY_CRYSTAL)
	return true


func _stabilize_generated_chests() -> void:
	var chest_positions: Array[Vector2i] = []
	for y in range(WORLD_HEIGHT - 1):
		for x in range(WORLD_WIDTH):
			if _get_tile(x, y) == Tile.CHEST:
				chest_positions.append(Vector2i(x, y))
	for chest_pos in chest_positions:
		if _is_solid(chest_pos.x, chest_pos.y + 1):
			continue
		var old_key := _tile_key(chest_pos)
		var loot: Dictionary = chest_loot.get(old_key, {})
		chest_loot.erase(old_key)
		_set_tile(chest_pos.x, chest_pos.y, Tile.AIR)
		var grounded_pos := _find_grounded_chest_position(chest_pos)
		if grounded_pos.x < 0:
			continue
		_set_tile(grounded_pos.x, grounded_pos.y, Tile.CHEST)
		chest_loot[_tile_key(grounded_pos)] = loot


func _make_chest_loot(kind: String) -> Dictionary:
	var loot := {}
	loot["torch"] = rng.randi_range(3, 7)
	loot["wood"] = rng.randi_range(4, 10)
	if kind == "forest":
		loot["moss_fiber"] = rng.randi_range(5, 12)
		if rng.randf() < 0.24:
			loot["wild_badge"] = 1
	elif kind == "mushroom":
		loot["mushroom_spore"] = rng.randi_range(4, 9)
		loot["glowcap"] = rng.randi_range(2, 6)
		if rng.randf() < 0.26:
			loot["root_ring"] = 1
	elif kind == "ash_city":
		loot["ash_city_brick"] = rng.randi_range(8, 18)
		loot["ash_relic"] = rng.randi_range(1, 2)
		if rng.randf() < 0.24:
			loot["ash_sickle"] = 1
	elif kind == "sunken":
		loot["sunken_stone"] = rng.randi_range(8, 16)
		loot["drowned_pearl"] = 1
		if rng.randf() < 0.22:
			loot["hand_cannon"] = 1
	elif kind == "lava_root":
		loot["ember_root"] = rng.randi_range(5, 11)
		loot["night_ember"] = rng.randi_range(2, 5)
		if rng.randf() < 0.26:
			loot["fire_arrows"] = rng.randi_range(15, 30)
	elif kind == "glass":
		loot["glass_shard"] = rng.randi_range(5, 12)
		loot["abyss_crystal"] = rng.randi_range(2, 5)
		if rng.randf() < 0.20:
			loot["abyss_lens"] = 1
	elif kind == "sky":
		loot["sky_crystal"] = rng.randi_range(2, 5)
		loot["star_dust"] = rng.randi_range(4, 9)
		loot["sky_feather"] = rng.randi_range(1, 2)
		# Shrines guarantee one Sky Fragment (summon pieces for the Leviathan).
		if rng.randf() < 0.95:
			loot["sky_fragment"] = 1
		if rng.randf() < 0.30:
			loot["zephyr_feather"] = rng.randi_range(1, 2)
	elif kind == "ruin":
		loot["ruin_brick"] = rng.randi_range(4, 10)
		if rng.randf() < 0.58:
			loot["spark_shard"] = rng.randi_range(1, 2)
		if rng.randf() < 0.25:
			loot["hand_cannon"] = 1
	else:
		loot["root"] = rng.randi_range(5, 12)
		if rng.randf() < 0.62:
			loot["root_core"] = 1
		if rng.randf() < 0.22:
			loot["root_spirit_rod"] = 1
	if rng.randf() < 0.45:
		loot["copper_bar"] = rng.randi_range(2, 5)
	if rng.randf() < 0.25:
		loot["iron_bar"] = rng.randi_range(1, 3)
	return loot


func _tile_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _unlock_stone_beast_progression() -> void:
	if mushroom_path_opened:
		return
	mushroom_path_opened = true
	for i in range(_scaled_count(32)):
		var x := rng.randi_range(18, WORLD_WIDTH - 19)
		var y := rng.randi_range(surface_heights[x] + 34, WORLD_HEIGHT - 10)
		for yy in range(y - 2, y + 3):
			for xx in range(x - 3, x + 4):
				if _in_bounds(xx, yy) and _get_tile(xx, yy) == Tile.STONE and rng.randf() < 0.42:
					_set_tile(xx, yy, Tile.STONEBLOOD)
	for i in range(_scaled_count(5)):
		var center := _find_cave_floor_position()
		if center.x >= 0:
			_carve_cave_blob(center + Vector2i(rng.randi_range(-5, 5), rng.randi_range(2, 8)), rng.randi_range(7, 12), rng.randi_range(4, 7))
			for x in range(center.x - 5, center.x + 6):
				if _in_bounds(x, center.y + 1) and rng.randf() < 0.55:
					_set_tile(x, center.y + 1, Tile.ROOT)


func _carve_spawn_area() -> void:
	var center := int(WORLD_WIDTH / 2)
	for x in range(center - 8, center + 9):
		if not _in_bounds(x, 0):
			continue
		var ground_y: int = surface_heights[x]
		for y in range(ground_y - 8, ground_y):
			_set_tile(x, y, Tile.AIR)
		_set_tile(x, ground_y, Tile.GRASS)


func _add_ash_pockets() -> void:
	for i in range(_scaled_count(9)):
		var center_x := rng.randi_range(25, WORLD_WIDTH - 26)
		var center_y := rng.randi_range(72, WORLD_HEIGHT - 14)
		var radius := rng.randi_range(6, 13)
		for y in range(center_y - radius, center_y + radius + 1):
			for x in range(center_x - radius, center_x + radius + 1):
				if not _in_bounds(x, y):
					continue
				var dist := Vector2(x - center_x, y - center_y).length()
				if dist < float(radius) * rng.randf_range(0.65, 1.1) and _get_tile(x, y) == Tile.STONE:
					_set_tile(x, y, Tile.ASH)


func _add_trees() -> void:
	var last_tree_x := -MIN_TREE_SPACING
	for x in range(8, WORLD_WIDTH - 8):
		if x - last_tree_x < MIN_TREE_SPACING:
			continue
		if rng.randf() > 0.055:
			continue
		var ground_y: int = surface_heights[x]
		var ground_tile := _get_tile(x, ground_y)
		if ground_tile != Tile.GRASS and ground_tile != Tile.ASH_SAND:
			continue
		last_tree_x = x
		var tree_id := _allocate_tree_id()
		var is_tall := rng.randf() < 0.12
		# Only bleached dead trunks survive on the ash desert drifts.
		var is_dead := ground_tile == Tile.ASH_SAND or (not is_tall and rng.randf() < 0.14)
		if ground_tile == Tile.ASH_SAND:
			is_tall = false
		var height := rng.randi_range(9, 12) if is_tall else (rng.randi_range(7, 9) if is_dead else rng.randi_range(6, 9))
		for y in range(ground_y - height, ground_y):
			_set_tree_tile(x, y, Tile.WOOD, tree_id)
			if is_tall and y > ground_y - 3:
				_set_tile(x - 1, y, Tile.ROOT)
				_set_tile(x + 1, y, Tile.ROOT)

		var branch_count := rng.randi_range(2, 4) if is_tall else rng.randi_range(1, 2)
		var branch_ends: Array[Vector2i] = []
		for branch_index in range(branch_count):
			var dir := -1 if branch_index % 2 == 0 else 1
			if rng.randf() < 0.35:
				dir *= -1
			var min_from_top := 3 if is_tall else 2
			var max_from_ground := height - 3
			var branch_y := ground_y - rng.randi_range(min_from_top, max_from_ground)
			var length := rng.randi_range(3, 5) if is_tall else rng.randi_range(2, 3)
			var rise := rng.randi_range(1, 2) if is_tall else rng.randi_range(0, 1)
			branch_ends.append(_add_tree_branch(Vector2i(x, branch_y), dir, length, rise, tree_id))

		var crown_center := Vector2i(x, ground_y - height)
		if is_dead:
			for root_offset in range(-2, 3):
				if root_offset != 0 and _get_tile(x + root_offset, ground_y - 1) == Tile.AIR:
					_set_tile(x + root_offset, ground_y - 1, Tile.ROOT)
		else:
			_add_leaf_cluster(crown_center, rng.randi_range(4, 5) if is_tall else rng.randi_range(3, 4), rng.randi_range(3, 4) if is_tall else rng.randi_range(2, 3), tree_id)
			_add_leaf_cluster(crown_center + Vector2i(-3, 1), rng.randi_range(2, 3), rng.randi_range(2, 3), tree_id)
			_add_leaf_cluster(crown_center + Vector2i(3, 1), rng.randi_range(2, 3), rng.randi_range(2, 3), tree_id)
			if is_tall:
				_add_leaf_cluster(crown_center + Vector2i(0, -2), rng.randi_range(3, 4), 2, tree_id)
			for branch_end in branch_ends:
				_add_leaf_cluster(branch_end + Vector2i(0, -1), rng.randi_range(2, 3), rng.randi_range(2, 3), tree_id)


func _allocate_tree_id() -> int:
	var tree_id := next_tree_id
	next_tree_id += 1
	return tree_id


func _set_tree_tile(x: int, y: int, tile: int, tree_id: int) -> void:
	if not _in_bounds(x, y):
		return
	var key := "%d,%d" % [x, y]
	var current := _get_tile(x, y)
	if current != Tile.AIR and int(tree_tile_owners.get(key, -1)) != tree_id:
		return
	_set_tile(x, y, tile)
	tree_tile_owners[key] = tree_id


func _add_tree_branch(start: Vector2i, dir: int, length: int, rise: int, tree_id: int) -> Vector2i:
	var end := start
	for i in range(1, length + 1):
		var branch_x := start.x + dir * i
		var branch_y := start.y - int(round(float(i) / float(maxi(1, length)) * float(rise)))
		end = Vector2i(branch_x, branch_y)
		_set_tree_tile(branch_x, branch_y, Tile.WOOD, tree_id)
		if i > 2 and i % 3 == 0 and rng.randf() < 0.7:
			_set_tree_tile(branch_x, branch_y - 1, Tile.WOOD, tree_id)
		if i > 3 and rng.randf() < 0.28:
			var offshoot_dir := -dir if rng.randf() < 0.45 else dir
			_set_tree_tile(branch_x + offshoot_dir, branch_y - 1, Tile.WOOD, tree_id)
	return end


func _add_leaf_cluster(center: Vector2i, radius_x: int, radius_y: int, tree_id: int) -> void:
	for yy in range(center.y - radius_y, center.y + radius_y + 1):
		for xx in range(center.x - radius_x, center.x + radius_x + 1):
			if not _in_bounds(xx, yy):
				continue
			var dx := float(xx - center.x) / float(maxi(1, radius_x))
			var dy := float(yy - center.y) / float(maxi(1, radius_y))
			var edge_noise := rng.randf_range(-0.28, 0.22)
			if dx * dx + dy * dy <= 1.0 + edge_noise and _get_tile(xx, yy) == Tile.AIR:
				_set_tree_tile(xx, yy, Tile.LEAVES, tree_id)


func _update_saplings(delta: float) -> void:
	sapling_growth_timer += delta
	if sapling_growth_timer < 4.0:
		return
	sapling_growth_timer = 0.0
	var grown := 0
	for key in sapling_positions.keys():
		var pos: Vector2i = sapling_positions[key]
		if _get_tile(pos.x, pos.y) != Tile.SAPLING:
			sapling_positions.erase(key)
			continue
		if rng.randf() > 0.18:
			continue
		if _can_grow_sapling(pos):
			_grow_sapling(pos)
			grown += 1
			if grown >= 3:
				return


func _can_grow_sapling(pos: Vector2i) -> bool:
	var below := _get_tile(pos.x, pos.y + 1)
	if below != Tile.GRASS and below != Tile.DIRT and below != Tile.MOSS and below != Tile.MUD:
		return false
	for y in range(pos.y - 10, pos.y + 1):
		for x in range(pos.x - 4, pos.x + 5):
			if not _in_bounds(x, y):
				return false
			var tile := _get_tile(x, y)
			if tile != Tile.AIR and tile != Tile.SAPLING and tile != Tile.LEAVES:
				return false
	return true


func _grow_sapling(pos: Vector2i) -> void:
	var tree_id := _allocate_tree_id()
	var height := rng.randi_range(6, 8)
	_set_tile(pos.x, pos.y, Tile.AIR)
	for y in range(pos.y - height + 1, pos.y + 1):
		_set_tree_tile(pos.x, y, Tile.WOOD, tree_id)
	var crown := Vector2i(pos.x, pos.y - height + 1)
	_add_leaf_cluster(crown, rng.randi_range(3, 4), rng.randi_range(2, 3), tree_id)
	_add_leaf_cluster(crown + Vector2i(-2, 1), 2, 2, tree_id)
	_add_leaf_cluster(crown + Vector2i(2, 1), 2, 2, tree_id)
	for branch_index in range(rng.randi_range(1, 2)):
		var dir := -1 if branch_index % 2 == 0 else 1
		var branch_y := pos.y - rng.randi_range(3, height - 2)
		var branch_end := _add_tree_branch(Vector2i(pos.x, branch_y), dir, rng.randi_range(2, 3), rng.randi_range(0, 1), tree_id)
		_add_leaf_cluster(branch_end, 2, 2, tree_id)


func _add_roots() -> void:
	for i in range(_scaled_count(42)):
		var x := rng.randi_range(10, WORLD_WIDTH - 11)
		var y: int = surface_heights[x] + rng.randi_range(5, 32)
		var length := rng.randi_range(10, 30)
		for step in range(length):
			if not _in_bounds(x, y):
				break
			if _get_tile(x, y) != Tile.AIR:
				_set_tile(x, y, Tile.ROOT)
			x += rng.randi_range(-1, 1)
			y += rng.randi_range(0, 1)


func _add_ruins() -> void:
	for i in range(_scaled_count(7)):
		var w := rng.randi_range(5, 11)
		var h := rng.randi_range(4, 7)
		var x0 := rng.randi_range(20, WORLD_WIDTH - w - 20)
		var y0 := surface_heights[x0] + rng.randi_range(18, 58)
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + w):
				if not _in_bounds(x, y):
					continue
				var is_wall := x == x0 or x == x0 + w - 1 or y == y0 or y == y0 + h - 1
				if is_wall and rng.randf() > 0.15:
					_set_tile(x, y, Tile.RUIN)
				elif not is_wall:
					_set_tile(x, y, Tile.AIR)
		_try_place_structure_chest(Vector2i(x0 + rng.randi_range(1, w - 2), y0 + h - 2), "ruin")


func _spawn_player() -> void:
	var spawn_x := int(WORLD_WIDTH / 2)
	var spawn_y: int = surface_heights[spawn_x] - 3
	player_position = Vector2(spawn_x * TILE_SIZE, spawn_y * TILE_SIZE)
	player_velocity = Vector2.ZERO
	player_on_floor = false
	landing_speed = 0.0
	_update_camera()


func _reset_exploration() -> void:
	explored_tiles.resize(WORLD_WIDTH * WORLD_HEIGHT)
	explored_tiles.fill(0)
	last_explored_tile = Vector2i(-999, -999)
	world_map_dirty = true


func _reveal_player_surroundings() -> void:
	if explored_tiles.size() != WORLD_WIDTH * WORLD_HEIGHT:
		_reset_exploration()
	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	if center == last_explored_tile:
		return
	last_explored_tile = center
	var changed := false
	const REVEAL_RADIUS_X := 13
	const REVEAL_RADIUS_Y := 8
	for y in range(center.y - REVEAL_RADIUS_Y, center.y + REVEAL_RADIUS_Y + 1):
		for x in range(center.x - REVEAL_RADIUS_X, center.x + REVEAL_RADIUS_X + 1):
			if not _in_bounds(x, y):
				continue
			var nx := float(x - center.x) / float(REVEAL_RADIUS_X)
			var ny := float(y - center.y) / float(REVEAL_RADIUS_Y)
			if nx * nx + ny * ny > 1.0:
				continue
			var index := y * WORLD_WIDTH + x
			if explored_tiles[index] == 0:
				explored_tiles[index] = 1
				changed = true
	if changed:
		world_map_dirty = true


func _is_tile_explored(x: int, y: int) -> bool:
	if not _in_bounds(x, y) or explored_tiles.size() != WORLD_WIDTH * WORLD_HEIGHT:
		return false
	return explored_tiles[y * WORLD_WIDTH + x] != 0


func _storm_research_ready() -> bool:
	if storm_herald_defeated or storm_active:
		return false
	if bestiary_knowledge.size() < STORM_BESTIARY_NEED:
		return false
	for rid in STORM_RECIPES_NEED:
		if not known_recipes.has(rid):
			return false
	if alchemy_knowledge.size() < STORM_ALCHEMY_NEED:
		return false
	return true


func _storm_research_count() -> int:
	var n := 0
	n += mini(bestiary_knowledge.size(), STORM_BESTIARY_NEED)
	for rid in STORM_RECIPES_NEED:
		if known_recipes.has(rid):
			n += 1
	n += mini(alchemy_knowledge.size(), STORM_ALCHEMY_NEED)
	return n


func _storm_research_total() -> int:
	return STORM_BESTIARY_NEED + STORM_RECIPES_NEED.size() + STORM_ALCHEMY_NEED


func _is_player_underground() -> bool:
	var tile_pos := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var surface_y: int = surface_heights[clampi(tile_pos.x, 0, surface_heights.size() - 1)]
	return tile_pos.y - surface_y > 10


func _update_storm_arc(delta: float) -> void:
	if storm_herald_defeated:
		return
	if not storm_active:
		# The story begins after ~15 minutes of surface play (unless forced).
		# Time spent underground (caves) does NOT count — the player is busy
		# exploring down there and shouldn't be interrupted.
		if storm_forced:
			_start_storm()
			return
		if _is_player_underground():
			return
		storm_research_timer += delta
		# Quiet until 8 minutes so the player can learn the game; then the
		# warnings escalate quickly toward the storm at ~15 minutes.
		if storm_research_timer >= 480.0 and not storm_warning_1:
			storm_warning_1 = true
			last_message = "The wind has changed. Something is stirring far beneath the land."
			_toast_message(last_message, 4.0)
		elif storm_research_timer >= 660.0 and not storm_warning_2:
			storm_warning_2 = true
			last_message = "Distant thunder rolls across a clear sky. The horizon darkens."
			_toast_message(last_message, 4.0)
		elif storm_research_timer >= 840.0 and not storm_warning_3:
			storm_warning_3 = true
			last_message = "The storm is nearly here — the wind pulls toward its heart."
			_toast_message(last_message, 5.0)
		elif storm_research_timer >= 900.0:
			_start_storm()
		return
	# Tornado lifecycle
	storm_tornado_timer += delta
	if storm_tornado_phase == "forming" and storm_tornado_timer >= 3.0:
		storm_tornado_phase = "active"
		storm_tornado_timer = 0.0
		last_message = "The storm's heart is here. Step into the wind to face it!"


func _start_storm() -> void:
	storm_active = true
	storm_tornado_phase = "forming"
	storm_tornado_timer = 0.0
	# Place the tornado on the surface in the player's biome, 60-100 tiles away.
	var px := int(player_position.x / TILE_SIZE)
	var side := 1 if rng.randf() < 0.5 else -1
	var tx := clampi(px + side * rng.randi_range(60, 100), 2, WORLD_WIDTH - 3)
	var ty := int(surface_heights[tx]) - 3
	storm_tornado_pos = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)
	storm_wind_dir = (storm_tornado_pos - player_position).normalized()
	last_message = "The sky darkens. A storm gathers — follow the wind to its heart."
	_play_sound("boss")


func _storm_boss_alive() -> bool:
	for enemy in enemies:
		if str(enemy.get("type", "")) == "storm_herald":
			return true
	return false


func _trigger_storm_boss() -> void:
	if storm_herald_defeated or _storm_boss_alive():
		return
	storm_tornado_phase = "sucking"
	_spawn_enemy("storm_herald", storm_tornado_pos + Vector2(0, -50.0))
	_play_sound("boss")
	last_message = "The Storm Herald tears free of the tornado!"


func _update_player(delta: float) -> void:
	if noclip_enabled:
		var horizontal := float(int(Input.is_action_pressed("move_right") or physical_move_right_held) - int(Input.is_action_pressed("move_left") or physical_move_left_held))
		var vertical := float(int(physical_noclip_down_held) - int(physical_noclip_up_held))
		if mobile_joystick != null:
			var joy_axis: Vector2 = mobile_joystick.get("axis")
			if joy_axis.length() > 0.05:
				horizontal = joy_axis.x
				vertical = joy_axis.y
		var direction := Vector2(horizontal, vertical).normalized()
		var noclip_speed := 430.0 if Input.is_key_pressed(KEY_SHIFT) else 270.0
		player_velocity = direction * noclip_speed
		player_position += player_velocity * delta
		player_position.x = clampf(player_position.x, PLAYER_SIZE.x * 0.5, WORLD_WIDTH * TILE_SIZE - PLAYER_SIZE.x * 0.5)
		player_position.y = clampf(player_position.y, PLAYER_SIZE.y * 0.5, WORLD_HEIGHT * TILE_SIZE - PLAYER_SIZE.y * 0.5)
		if absf(horizontal) > 0.01:
			facing = 1 if horizontal > 0.0 else -1
		player_on_floor = false
		landing_speed = 0.0
		_reveal_player_surroundings()
		return
	var was_on_floor := player_on_floor
	player_on_floor = _is_on_floor()
	var direction := 0.0
	if not full_map_open and not player_statuses.has("root_bind"):
		var move_left := Input.is_action_pressed("move_left") or physical_move_left_held
		var move_right := Input.is_action_pressed("move_right") or physical_move_right_held
		direction = float(int(move_right) - int(move_left))
	var in_water := _player_overlaps_tile(Tile.WATER)
	var in_lava := _player_overlaps_tile(Tile.LAVA)
	var in_liquid := in_water or in_lava
	var on_ladder := _player_overlaps_tile(Tile.LADDER) or _player_overlaps_tile(Tile.ROPE)
	if absf(direction) > 0.01:
		facing = 1 if direction > 0.0 else -1
	var liquid_speed := 0.62 if in_water else (0.43 if in_lava else 1.0)
	if on_ladder:
		# Climbing: no gravity, stick to the ladder, move up/down manually.
		var climb_speed := 120.0
		var up := (Input.is_action_pressed("jump") or physical_noclip_up_held)
		var down := physical_noclip_down_held
		if mobile_joystick != null:
			var joy_axis: Vector2 = mobile_joystick.get("axis")
			if joy_axis.y < -0.3:
				up = true
			elif joy_axis.y > 0.3:
				down = true
		player_velocity.y = 0.0
		if up:
			player_velocity.y = -climb_speed
		elif down:
			player_velocity.y = climb_speed
		landing_speed = 0.0
	# Terraria-style acceleration: speed builds up to the target quickly,
	# and braking is very fast (a fraction of a second).
	var target_speed := direction * MOVE_SPEED * _player_speed_multiplier() * liquid_speed
	var accel := 620.0
	var decel := 1700.0
	if direction == 0.0:
		player_velocity.x = move_toward(player_velocity.x, 0.0, decel * delta)
	else:
		player_velocity.x = move_toward(player_velocity.x, target_speed, accel * delta)
	# Storm wind: always pushes the player TOWARD the tornado (direction
	# recomputed every frame), strengthening as the player gets closer.
	# Multiplier: x1 far away, x1.5 at ~30 tiles, x3 at ~10 tiles.
	if storm_active:
		var to_tornado := storm_tornado_pos - player_position
		var wind_dist := to_tornado.length()
		if wind_dist > 1.0:
			var wind_dir := to_tornado / wind_dist
			var close_units := wind_dist / TILE_SIZE
			var wind_mult := 1.0
			if close_units < 60.0:
				wind_mult = lerpf(1.0, 1.5, clampf((60.0 - close_units) / 30.0, 0.0, 1.0))
			if close_units < 30.0:
				wind_mult = lerpf(1.5, 3.0, clampf((30.0 - close_units) / 20.0, 0.0, 1.0))
			var wind_strength := 3.5 * wind_mult
			player_velocity.x += wind_dir.x * wind_strength
			player_velocity.y += wind_dir.y * wind_strength
		# Tornado pull: when close to the heart it sucks the player in.
		if storm_tornado_phase == "active" or storm_tornado_phase == "sucking":
			if wind_dist < 160.0:
				var pull_strength := (1.0 - wind_dist / 160.0) * 60.0
				player_position += (storm_tornado_pos - player_position).normalized() * pull_strength * delta
				if wind_dist < 40.0 and storm_tornado_phase == "active":
					_trigger_storm_boss()
	# --- Flight (jetpack / Wind Wings) ---
	var flying := false
	var want_fly := (Input.is_action_pressed("jump") or physical_noclip_up_held)
	if mobile_joystick != null:
		var joy_axis: Vector2 = mobile_joystick.get("axis")
		if joy_axis.y < -0.3:
			want_fly = true
	var flight_accessory := _equipped_accessory_has("flight")
	var cloudwing := equipped_accessory == "cloudwing_amulet"
	if (flight_accessory or cloudwing) and want_fly and not player_on_floor and not in_liquid and not on_ladder:
		if flight_charge > 0.0:
			flying = true
	if flying:
		# Hover thrust: lift must outpace gravity (1700 px/s) to actually climb.
		# The Cloudwing Amulet adds a stronger ascent.
		var lift_target := -340.0 if cloudwing else -300.0
		var lift_accel := 3000.0 if cloudwing else 2600.0
		player_velocity.y = move_toward(player_velocity.y, lift_target, lift_accel * delta)
		if absf(direction) > 0.01:
			player_velocity.x = move_toward(player_velocity.x, target_speed, 700.0 * delta)
		else:
			player_velocity.x = move_toward(player_velocity.x, 0.0, 500.0 * delta)
		flight_charge = maxf(0.0, flight_charge - FLIGHT_CHARGE_COST * delta)
		if flight_charge <= 0.0:
			last_message = "Flight charge exhausted. Refuel with star dust."
			_toast_message(last_message, 2.5)
		landing_speed = 0.0
	if in_liquid:
		var gravity_scale := 0.20 if in_water else 0.12
		player_velocity.y += GRAVITY * gravity_scale * delta
		if not full_map_open and not player_statuses.has("root_bind") and Input.is_action_pressed("jump"):
			player_velocity.y -= (650.0 if in_water else 430.0) * delta
		player_velocity.y = clampf(player_velocity.y, -190.0 if in_water else -125.0, 175.0 if in_water else 105.0)
		landing_speed = 0.0
	else:
		player_velocity.y += GRAVITY * delta
		landing_speed = maxf(landing_speed, player_velocity.y)

	if not full_map_open and not player_statuses.has("root_bind") and Input.is_action_just_pressed("jump") and player_on_floor and not in_liquid:
		player_velocity.y = JUMP_SPEED
		player_on_floor = false
		landing_speed = 0.0
		_emit_noise(player_position, 62.0, "jump", 0.65)

	_move_player(Vector2(player_velocity.x * delta, 0.0))
	_move_player(Vector2(0.0, player_velocity.y * delta))
	player_on_floor = _is_on_floor()
	if player_on_floor and not flying:
		flight_charge = minf(FLIGHT_CHARGE_MAX, flight_charge + 8.0 * delta)
	elif flying and equipped_accessory == "cloudwing_amulet":
		# The Cloudwing Amulet is tied to the sky islands: while flying it
		# slowly regenerates charge, letting the player glide between islands.
		flight_charge = minf(FLIGHT_CHARGE_MAX, flight_charge + 3.5 * delta)
	_reveal_player_surroundings()
	if player_on_floor and not was_on_floor:
		if landing_speed > 185.0:
			_emit_noise(player_position, clampf(58.0 + (landing_speed - 185.0) * 0.35, 58.0, 175.0), "landing", 0.85)
		_apply_fall_damage(landing_speed)
		landing_speed = 0.0
	_update_player_footstep_noise(delta, in_liquid)
	_update_liquid_hazards(delta, in_water, in_lava)


func _update_player_footstep_noise(delta: float, in_liquid: bool) -> void:
	player_footstep_noise_timer = maxf(0.0, player_footstep_noise_timer - delta)
	if not player_on_floor or absf(player_velocity.x) < MOVE_SPEED * 0.45:
		return
	if player_footstep_noise_timer > 0.0:
		return
	var radius := 54.0 if in_liquid else 78.0
	var strength := 0.55 if in_liquid else 0.72
	_emit_noise(player_position, radius, "footstep", strength)
	player_footstep_noise_timer = 0.48 if in_liquid else 0.38


func _liquid_fill_ratio(x: int, y: int) -> float:
	if liquid_sim == null:
		return 1.0
	var ratio := liquid_sim.get_fill_ratio(x, y)
	return ratio if ratio > 0.0 else 1.0


func _player_overlaps_tile(tile: int) -> bool:
	var rect := Rect2(player_position - PLAYER_SIZE * 0.45, PLAYER_SIZE * 0.90)
	var min_x := floori(rect.position.x / TILE_SIZE)
	var max_x := floori((rect.end.x - 1.0) / TILE_SIZE)
	var min_y := floori(rect.position.y / TILE_SIZE)
	var max_y := floori((rect.end.y - 1.0) / TILE_SIZE)
	var liquid := tile == Tile.WATER or tile == Tile.LAVA
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _get_tile(x, y) != tile:
				continue
			if not liquid:
				return true
			var fill_top := float(y + 1) * TILE_SIZE - float(TILE_SIZE) * _liquid_fill_ratio(x, y)
			if rect.end.y > fill_top:
				return true
	return false


func _player_head_submerged() -> bool:
	var head_y := player_position.y - PLAYER_SIZE.y * 0.38
	var head_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(head_y / TILE_SIZE))
	if _get_tile(head_tile.x, head_tile.y) != Tile.WATER:
		return false
	var fill_top := float(head_tile.y + 1) * TILE_SIZE - float(TILE_SIZE) * _liquid_fill_ratio(head_tile.x, head_tile.y)
	return head_y > fill_top


func _equipped_accessory_has(property_name: String) -> bool:
	if equipped_accessory == "" or not gear_stats.has(equipped_accessory):
		return false
	return bool((gear_stats[equipped_accessory] as Dictionary).get(property_name, false))


func _temperature_protection(property_name: String) -> float:
	var total := 0.0
	for item_id in [equipped_armor, equipped_accessory]:
		if gear_stats.has(item_id):
			total += float((gear_stats[item_id] as Dictionary).get(property_name, 0.0))
	return clampf(total, 0.0, 0.85)


func _update_liquid_hazards(delta: float, in_water: bool, in_lava: bool) -> void:
	var can_breathe := _equipped_accessory_has("water_breathing")
	if in_water and _player_head_submerged() and not can_breathe:
		oxygen = maxf(0.0, oxygen - 17.0 * delta)
	else:
		oxygen = minf(MAX_OXYGEN, oxygen + 34.0 * delta)
	if oxygen <= 0.0:
		drowning_tick -= delta
		if drowning_tick <= 0.0:
			drowning_tick = 1.0
			_damage_player(7)
			last_message = "You are drowning."
	else:
		drowning_tick = 0.0

	if in_lava:
		lava_tick -= delta
		if lava_tick <= 0.0:
			lava_tick = 0.65
			if _equipped_accessory_has("heat_resistance"):
				_damage_player(2)
			else:
				_damage_player(10)
				_apply_player_status("burn")
				last_message = "The lava is burning you."
	else:
		lava_tick = 0.0


func _update_temperature(delta: float) -> void:
	temperature_sample_timer -= delta
	if temperature_sample_timer <= 0.0:
		temperature_sample_timer = 0.25
		ambient_temperature = _sample_ambient_temperature()
	var target_temperature := _temperature_target_for_environment(ambient_temperature)
	var target_distance := absf(target_temperature - body_temperature)
	var adjustment_rate := 0.28 + minf(6.0, target_distance) * 0.08
	if is_equal_approx(target_temperature, NORMAL_BODY_TEMPERATURE):
		adjustment_rate = 0.55
	body_temperature = move_toward(body_temperature, target_temperature, adjustment_rate * delta)
	body_temperature = clampf(body_temperature, MIN_BODY_TEMPERATURE, MAX_BODY_TEMPERATURE)
	_update_temperature_consequences(delta)


func _sample_ambient_temperature() -> float:
	if _player_overlaps_tile(Tile.LAVA):
		return 72.0
	var biome := _current_biome()
	var daylight := clampf((_daylight_factor() - 0.38) / 0.62, 0.0, 1.0)
	var environment := 13.0
	if biome == "forest":
		environment = lerpf(5.0, 23.0, daylight)
	elif biome == "mushroom_halls":
		environment = 18.0
	elif biome == "ash_city":
		environment = 30.0
	elif biome == "sunken_ruins":
		environment = 7.0
	elif biome == "lava_roots":
		environment = 34.0
	elif biome == "glass_abyss":
		environment = -12.0
	else:
		var tile_pos := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
		var surface_y := int(surface_heights[clampi(tile_pos.x, 0, surface_heights.size() - 1)]) if not surface_heights.is_empty() else tile_pos.y
		var depth := maxi(0, tile_pos.y - surface_y)
		environment = clampf(14.0 - float(depth) * 0.045, 6.0, 14.0)
	return environment + _local_heat_bonus(8) + _weather_temperature_shift()


func _local_heat_bonus(radius: int) -> float:
	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var strongest_bonus := 0.0
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var tile := _get_tile(x, y)
			var source_heat := 0.0
			if tile == Tile.LAVA:
				source_heat = 38.0
			elif tile == Tile.LAVA_ROOT:
				source_heat = 14.0
			elif tile == Tile.FURNACE:
				source_heat = 10.0
			elif tile == Tile.TORCH:
				source_heat = 6.0
			if source_heat <= 0.0:
				continue
			var distance := Vector2(center).distance_to(Vector2(x, y))
			if distance > float(radius):
				continue
			var influence := 1.0 - distance / float(radius + 1)
			strongest_bonus = maxf(strongest_bonus, source_heat * influence)
	return strongest_bonus


func _temperature_target_for_environment(environment: float, cold_protection := -1.0, heat_protection := -1.0) -> float:
	var cold_resistance := _temperature_protection("cold_protection") if cold_protection < 0.0 else clampf(cold_protection, 0.0, 0.85)
	var heat_resistance := _temperature_protection("heat_protection") if heat_protection < 0.0 else clampf(heat_protection, 0.0, 0.85)
	var target := NORMAL_BODY_TEMPERATURE
	if environment < 14.0:
		var cold_deviation := minf(9.0, (14.0 - environment) * 0.32)
		target -= cold_deviation * (1.0 - cold_resistance)
	elif environment > 28.0:
		var heat_deviation := minf(9.0, (environment - 28.0) * 0.22)
		target += heat_deviation * (1.0 - heat_resistance)
	return clampf(target, MIN_BODY_TEMPERATURE, MAX_BODY_TEMPERATURE)


func _update_temperature_consequences(delta: float) -> void:
	var dangerous_cold := body_temperature <= 31.0
	var dangerous_heat := body_temperature >= 43.0
	if not dangerous_cold and not dangerous_heat:
		temperature_damage_tick = 0.0
		return
	temperature_damage_tick -= delta
	if temperature_damage_tick > 0.0:
		return
	temperature_damage_tick = 1.25
	_damage_player(4 if dangerous_cold else 5)
	last_message = "Your body temperature is dangerously low." if dangerous_cold else "Your body temperature is dangerously high."


func _temperature_action_multiplier() -> float:
	if body_temperature <= 31.0 or body_temperature >= 43.0:
		return 0.72
	if body_temperature < 34.0 or body_temperature > 40.0:
		return 0.86
	return 1.0


func _update_liquid_physics(delta: float) -> void:
	# Lightweight local cellular flow. Only liquid near the player is simulated,
	# so caves can fill and drain without scanning the whole world at once.
	liquid_flow_timer += delta
	if liquid_flow_timer < 0.12:
		return
	liquid_flow_timer = 0.0
	liquid_flow_phase = 1 - liquid_flow_phase
	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var min_x := clampi(center.x - 48, 1, WORLD_WIDTH - 2)
	var max_x := clampi(center.x + 48, 1, WORLD_WIDTH - 2)
	var min_y := clampi(center.y - 34, 1, WORLD_HEIGHT - 2)
	var max_y := clampi(center.y + 34, 1, WORLD_HEIGHT - 2)
	var candidates: Array[Vector2i] = []
	for y in range(max_y, min_y - 1, -1):
		for x in range(min_x, max_x + 1):
			var tile := _get_tile(x, y)
			if tile != Tile.WATER and tile != Tile.LAVA:
				continue
			# Alternating checkerboard passes prevent a directional drift.
			if (x + y + liquid_flow_phase) % 2 != 0:
				continue
			candidates.append(Vector2i(x, y))
			if candidates.size() >= 850:
				break
		if candidates.size() >= 850:
			break
	for pos in candidates:
		var liquid := _get_tile(pos.x, pos.y)
		if liquid == Tile.WATER or liquid == Tile.LAVA:
			_try_flow_liquid(pos, liquid)


func _try_flow_liquid(pos: Vector2i, liquid: int) -> void:
	var below := pos + Vector2i(0, 1)
	var below_tile := _get_tile(below.x, below.y)
	if _resolve_liquid_contact(pos, below, liquid, below_tile):
		return
	if below_tile == Tile.AIR:
		_set_tile(below.x, below.y, liquid)
		_set_tile(pos.x, pos.y, Tile.AIR)
		return
	var first_dir := -1 if liquid_flow_phase == 0 else 1
	for dir in [first_dir, -first_dir]:
		var side := pos + Vector2i(dir, 0)
		var side_tile := _get_tile(side.x, side.y)
		if _resolve_liquid_contact(pos, side, liquid, side_tile):
			return
		if side_tile != Tile.AIR:
			continue
		# A liquid can spread sideways only when it has support below.
		var side_below := _get_tile(side.x, side.y + 1)
		if side_below != Tile.AIR:
			_set_tile(side.x, side.y, liquid)
			_set_tile(pos.x, pos.y, Tile.AIR)
			return


func _resolve_liquid_contact(source: Vector2i, target: Vector2i, liquid: int, target_tile: int) -> bool:
	if (liquid == Tile.WATER and target_tile == Tile.LAVA) or (liquid == Tile.LAVA and target_tile == Tile.WATER):
		_set_tile(source.x, source.y, Tile.STONE)
		_set_tile(target.x, target.y, Tile.STONE)
		_spawn_hit_particles(Vector2(target) * TILE_SIZE + Vector2(8, 8), Color("d8ddd5"), 4)
		return true
	return false


func _apply_fall_damage(speed: float) -> void:
	if speed <= FALL_DAMAGE_SPEED:
		return
	var damage := maxi(0, int((speed - FALL_DAMAGE_SPEED) / 28.0) - _total_defense())
	if damage <= 0:
		return
	_damage_player(damage)


func _damage_player(amount: int, impact_direction := Vector2.ZERO, damage_type := "physical") -> bool:
	if god_mode_enabled:
		health = MAX_HEALTH
		return false
	if amount <= 0 or player_hurt_timer > 0.0:
		return false
	health = maxi(0, health - amount)
	player_hurt_timer = PLAYER_HURT_COOLDOWN
	player_regen_timer = REGEN_DELAY
	player_hurt_flash = 0.20
	var heavy := amount >= 14
	var direction: Vector2 = impact_direction
	if direction.length_squared() < 0.01:
		direction = Vector2(0.0, -1.0)
	_spawn_damage_number(player_position + Vector2(0, -22), amount, Color("ff7777"), heavy)
	_spawn_combat_impact(player_position, direction, str(damage_type), heavy, true)
	_add_camera_trauma(7.0 if heavy else 5.0, 0.24 if heavy else 0.18)
	_trigger_hit_stop(0.060 if heavy else 0.045)
	_play_sound("hurt")
	last_message = "Ouch! Took %d damage." % amount
	if health <= 0:
		_respawn_player()
	return true


func _incoming_damage(amount: int, damage_type: String) -> int:
	var defense := _total_defense()
	if player_statuses.has("armor_break"):
		defense = maxi(0, defense - 3)
	if damage_type == "poison":
		defense = int(floor(float(defense) * 0.55))
	elif damage_type == "fire" or damage_type == "arcane":
		defense = int(floor(float(defense) * 0.72))
	var final_damage := maxi(1, amount - defense)
	# Soft floor: armor can never reduce a hit below ~35% of its raw value, so
	# the best end-game armor can't trivialize the deepest biomes.
	final_damage = maxi(final_damage, maxi(1, int(ceil(float(amount) * 0.35))))
	if damage_type == "physical" and player_statuses.has("fragile"):
		final_damage = int(ceil(float(final_damage) * 1.20))
	return final_damage


func _apply_player_status(status: String) -> void:
	var duration := 3.0
	if status == "poison":
		duration = 5.0
	elif status == "burn":
		duration = 4.0
	elif status == "slow":
		duration = 2.5
	elif status == "root_bind":
		duration = 0.8
	elif status == "fragile":
		duration = 4.0
	elif status == "wet":
		duration = 4.0
		player_statuses.erase("burn")
	elif status == "armor_break":
		duration = 5.0
	# Reapplying an effect refreshes its duration instead of stacking strength.
	player_statuses[status] = {"time": duration, "tick": 0.0}


func _player_speed_multiplier() -> float:
	if player_statuses.has("root_bind"):
		return 0.0
	var multiplier := 1.0
	if player_statuses.has("slow"):
		multiplier *= 0.55
	if player_statuses.has("wet"):
		multiplier *= 0.80
	# Wind Boots accessory: +10% movement speed.
	if equipped_accessory != "" and gear_stats.has(equipped_accessory):
		multiplier += float((gear_stats[equipped_accessory] as Dictionary).get("speed_bonus", 0.0))
	return multiplier * _temperature_action_multiplier()


func _respawn_player() -> void:
	if network_session != null and network_session.is_client() and network_session.joined and not network_applying_respawn:
		network_session.request_game_action("respawn", {"reported_health": health})
		return
	if bed_spawn_pos.x >= 0.0 and bed_spawn_pos.y >= 0.0:
		var bx := int(bed_spawn_pos.x / TILE_SIZE)
		var by := int(bed_spawn_pos.y / TILE_SIZE)
		if _in_bounds(bx, by) and _get_tile(bx, by) == Tile.BED:
			player_position = bed_spawn_pos + Vector2(0, -24)
	health = MAX_HEALTH
	oxygen = MAX_OXYGEN
	body_temperature = NORMAL_BODY_TEMPERATURE
	ambient_temperature = 20.0
	temperature_sample_timer = 0.0
	temperature_damage_tick = 0.0
	temperature_visual_state = ""
	drowning_tick = 0.0
	lava_tick = 0.0
	# Keep shared projectiles and loot alive when the listen-server owner dies;
	# other players may still be interacting with them.
	var preserve_shared_entities: bool = network_session != null and bool(network_session.is_server()) and bool(network_session.is_active())
	if not preserve_shared_entities:
		projectiles.clear()
		enemy_projectiles.clear()
		enemy_impact_effects.clear()
		perception_noise_events.clear()
		dropped_items.clear()
		next_network_loot_id = 1
	network_pending_loot.clear()
	damage_numbers.clear()
	hit_particles.clear()
	combat_impacts.clear()
	combat_hit_stop_timer = 0.0
	camera_shake_strength = 0.0
	camera_shake_time = 0.0
	camera_shake_duration = 0.0
	camera_shake_phase = 0.0
	player_hurt_flash = 0.0
	attack_anim_time = 0.0
	attack_anim_kind = ""
	held_item_id = ""
	held_item_amount = 0
	_spawn_player()


func _weather_kind_is_valid(kind: String) -> bool:
	return kind == WEATHER_CLEAR or kind in WEATHER_TYPES


func _reset_weather_state() -> void:
	weather_state_rng.seed = seed ^ 0x57454154
	weather_visual_rng.seed = seed ^ 0x56495355
	weather = WEATHER_CLEAR
	weather_timer = weather_state_rng.randf_range(45.0, 120.0)
	weather_intensity = 0.0
	weather_target_intensity = 0.0
	weather_lightning_timer = 0.0
	weather_lightning_flash = 0.0
	weather_effect_timer = 0.0
	weather_particles.clear()


func _restore_weather_state(data: Dictionary) -> void:
	weather_state_rng.seed = seed ^ 0x57454154
	weather_visual_rng.seed = seed ^ 0x56495355
	var restored_kind := str(data.get("weather", WEATHER_CLEAR))
	weather = restored_kind if _weather_kind_is_valid(restored_kind) else WEATHER_CLEAR
	weather_timer = maxf(0.1, float(data.get("weather_timer", 90.0)))
	var default_intensity := 0.0 if weather == WEATHER_CLEAR else 1.0
	weather_intensity = clampf(float(data.get("weather_intensity", default_intensity)), 0.0, 1.0)
	weather_target_intensity = clampf(float(data.get("weather_target_intensity", default_intensity)), 0.0, 1.0)
	weather_lightning_timer = maxf(0.0, float(data.get("weather_lightning_timer", 0.0)))
	weather_lightning_flash = 0.0
	weather_effect_timer = 0.0
	if data.has("weather_rng_state"):
		weather_state_rng.state = int(data.get("weather_rng_state", weather_state_rng.state))
	weather_particles.clear()


func _apply_weather_snapshot(snapshot: Dictionary) -> void:
	# Missing fields remain safe for older or partially populated entity payloads.
	if not snapshot.has("weather"):
		return
	var restored_kind := str(snapshot.get("weather", WEATHER_CLEAR))
	var next_weather := restored_kind if _weather_kind_is_valid(restored_kind) else WEATHER_CLEAR
	if weather != next_weather:
		weather_particles.clear()
	weather = next_weather
	weather_timer = maxf(0.0, float(snapshot.get("weather_timer", weather_timer)))
	weather_intensity = clampf(float(snapshot.get("weather_intensity", weather_intensity)), 0.0, 1.0)
	weather_target_intensity = clampf(float(snapshot.get("weather_target_intensity", weather_target_intensity)), 0.0, 1.0)
	weather_lightning_flash = maxf(
		weather_lightning_flash,
		clampf(float(snapshot.get("weather_lightning_flash", 0.0)), 0.0, 0.35)
	)


func _depth_below_surface_at(world_pos: Vector2) -> int:
	if surface_heights.is_empty():
		return 0
	var tile_x := clampi(floori(world_pos.x / TILE_SIZE), 0, surface_heights.size() - 1)
	var tile_y := floori(world_pos.y / TILE_SIZE)
	return maxi(0, tile_y - int(surface_heights[tile_x]))


func _player_depth_below_surface() -> int:
	return _depth_below_surface_at(player_position)


func _weather_exposure_at(world_pos: Vector2) -> float:
	# Weather fades below the surface and disappears in deep caves.
	var depth := _depth_below_surface_at(world_pos)
	if depth <= WEATHER_DEPTH_FADE_START:
		return 1.0
	if depth >= WEATHER_DEPTH_SILENT:
		return 0.0
	var span := float(WEATHER_DEPTH_SILENT - WEATHER_DEPTH_FADE_START)
	return clampf(1.0 - float(depth - WEATHER_DEPTH_FADE_START) / span, 0.0, 1.0)


func _weather_exposure() -> float:
	return _weather_exposure_at(player_position)


func _weather_strength_at(world_pos: Vector2) -> float:
	if weather == WEATHER_CLEAR:
		return 0.0
	return weather_intensity * _weather_exposure_at(world_pos)


func _weather_strength() -> float:
	return _weather_strength_at(player_position)


func _enemy_is_exposed_to_weather(enemy_pos: Vector2) -> bool:
	return _weather_exposure_at(enemy_pos) > 0.65


func _weather_temperature_shift() -> float:
	var strength := _weather_strength()
	if strength <= 0.0:
		return 0.0
	var tile_x := clampi(floori(player_position.x / TILE_SIZE), 0, WORLD_WIDTH - 1)
	var biome := _surface_biome_at_column(tile_x)
	var shift := 0.0
	match weather:
		WEATHER_RAIN:
			shift = -6.0
		WEATHER_STORM:
			shift = -9.0
		WEATHER_BLIZZARD:
			shift = -22.0
		WEATHER_ASHFALL:
			shift = 16.0
		WEATHER_FOG:
			shift = -3.0
	if biome == "frost_wasteland" and shift < 0.0:
		shift *= 1.5
	elif biome == "ash_desert" and shift > 0.0:
		shift *= 1.35
	return shift * strength


func _weather_visibility_penalty_at(world_pos: Vector2) -> float:
	var strength := _weather_strength_at(world_pos)
	if strength <= 0.0:
		return 0.0
	var penalty := 0.0
	match weather:
		WEATHER_BLIZZARD:
			penalty = 0.72
		WEATHER_ASHFALL:
			penalty = 0.60
		WEATHER_FOG:
			penalty = 0.66
		WEATHER_STORM:
			penalty = 0.34
		WEATHER_RAIN:
			penalty = 0.22
	return penalty * strength


func _weather_noise_mask_at(world_pos: Vector2) -> float:
	var strength := _weather_strength_at(world_pos)
	if strength <= 0.0:
		return 1.0
	match weather:
		WEATHER_STORM:
			return 1.0 - 0.55 * strength
		WEATHER_RAIN:
			return 1.0 - 0.35 * strength
		WEATHER_BLIZZARD:
			return 1.0 - 0.45 * strength
		WEATHER_FOG:
			return 1.0 + 0.30 * strength
	return 1.0


func _weather_display_name(kind: String) -> String:
	match kind:
		WEATHER_RAIN:
			return "Rain"
		WEATHER_STORM:
			return "Thunderstorm"
		WEATHER_BLIZZARD:
			return "Blizzard"
		WEATHER_ASHFALL:
			return "Ashfall"
		WEATHER_FOG:
			return "Fog"
	return "Clear"


func _pick_next_weather() -> String:
	# The state is global, while the host's current surface biome biases what
	# arrives next. Dedicated servers track their first connected player here.
	var biome := _surface_biome_at_player()
	var weights := {
		WEATHER_RAIN: 30.0,
		WEATHER_STORM: 14.0,
		WEATHER_BLIZZARD: 10.0,
		WEATHER_ASHFALL: 10.0,
		WEATHER_FOG: 20.0
	}
	match biome:
		"frost_wasteland":
			weights[WEATHER_BLIZZARD] = 46.0
			weights[WEATHER_RAIN] = 8.0
		"ash_desert":
			weights[WEATHER_ASHFALL] = 46.0
			weights[WEATHER_RAIN] = 6.0
			weights[WEATHER_BLIZZARD] = 2.0
		"marsh":
			weights[WEATHER_FOG] = 40.0
			weights[WEATHER_RAIN] = 38.0
		"ash_ruins":
			weights[WEATHER_FOG] = 30.0
			weights[WEATHER_ASHFALL] = 24.0
	var total := 0.0
	for kind in weights:
		total += float(weights[kind])
	var roll := weather_state_rng.randf() * total
	for kind in weights:
		roll -= float(weights[kind])
		if roll <= 0.0:
			return str(kind)
	return WEATHER_RAIN


func _start_weather(kind: String, duration: float) -> void:
	if not _weather_kind_is_valid(kind):
		return
	weather = kind
	weather_timer = maxf(0.1, duration)
	weather_target_intensity = 0.0 if kind == WEATHER_CLEAR else 1.0
	weather_effect_timer = 0.0
	weather_particles.clear()
	if kind == WEATHER_STORM:
		weather_lightning_timer = weather_state_rng.randf_range(
			WEATHER_LIGHTNING_MIN_INTERVAL,
			WEATHER_LIGHTNING_MAX_INTERVAL
		)
	else:
		weather_lightning_timer = 0.0
	if kind != WEATHER_CLEAR and _weather_exposure() > 0.35:
		last_message = "%s rolls in." % _weather_display_name(kind)


func _update_weather(delta: float, authoritative: bool, render_visuals: bool) -> void:
	if authoritative:
		weather_timer -= delta
		if weather_timer <= 0.0:
			if weather == WEATHER_CLEAR:
				_start_weather(_pick_next_weather(), weather_state_rng.randf_range(55.0, 130.0))
			else:
				_start_weather(WEATHER_CLEAR, weather_state_rng.randf_range(90.0, 220.0))
	weather_intensity = move_toward(weather_intensity, weather_target_intensity, 0.35 * delta)
	if weather == WEATHER_CLEAR and weather_intensity <= 0.01:
		weather_particles.clear()
	weather_lightning_flash = maxf(0.0, weather_lightning_flash - delta * 3.2)
	if authoritative:
		if weather == WEATHER_STORM and weather_intensity >= 0.4:
			weather_lightning_timer -= delta
			if weather_lightning_timer <= 0.0:
				weather_lightning_flash = 0.35
				weather_lightning_timer = weather_state_rng.randf_range(
					WEATHER_LIGHTNING_MIN_INTERVAL,
					WEATHER_LIGHTNING_MAX_INTERVAL
				)
		else:
			weather_lightning_timer = 0.0
	if render_visuals:
		_update_weather_particles(delta)
	else:
		weather_particles.clear()


func _update_weather_player_effects(delta: float) -> void:
	var strength := _weather_strength()
	if strength < 0.25:
		weather_effect_timer = 0.0
		return
	weather_effect_timer -= delta
	if weather_effect_timer > 0.0:
		return
	weather_effect_timer = 2.0
	match weather:
		WEATHER_RAIN, WEATHER_STORM:
			_apply_player_status("wet")
		WEATHER_BLIZZARD:
			if _temperature_protection("cold_protection") < 0.35:
				_apply_player_status("slow")


func _update_weather_particles(delta: float) -> void:
	var strength := _weather_strength()
	if strength <= 0.02 or camera == null:
		weather_particles.clear()
		return
	var view := get_viewport_rect().size / camera.zoom
	var centre := camera.get_screen_center_position()
	var left := centre.x - view.x * 0.5
	var top := centre.y - view.y * 0.5
	var performance_scale := 0.58 if mobile_ui_enabled else 1.0
	var wanted := 0
	var fall := Vector2.ZERO
	match weather:
		WEATHER_RAIN:
			wanted = int(150.0 * strength * performance_scale)
			fall = Vector2(-70.0, 620.0)
		WEATHER_STORM:
			wanted = int(210.0 * strength * performance_scale)
			fall = Vector2(-160.0, 760.0)
		WEATHER_BLIZZARD:
			wanted = int(190.0 * strength * performance_scale)
			fall = Vector2(-190.0, 190.0)
		WEATHER_ASHFALL:
			wanted = int(160.0 * strength * performance_scale)
			fall = Vector2(150.0, 130.0)
		WEATHER_FOG:
			wanted = 0
	while weather_particles.size() > wanted:
		weather_particles.pop_back()
	while weather_particles.size() < wanted:
		weather_particles.append({
			"pos": Vector2(
				left + weather_visual_rng.randf() * view.x,
				top + weather_visual_rng.randf() * view.y
			),
			"speed": weather_visual_rng.randf_range(0.75, 1.3)
		})
	for particle in weather_particles:
		var pos: Vector2 = particle.get("pos", centre)
		pos += fall * float(particle.get("speed", 1.0)) * delta
		if pos.y > top + view.y:
			pos.y = top - 8.0
			pos.x = left + weather_visual_rng.randf() * view.x
		if pos.x < left - 12.0:
			pos.x = left + view.x
		elif pos.x > left + view.x + 12.0:
			pos.x = left
		particle["pos"] = pos


func _draw_weather() -> void:
	var strength := _weather_strength()
	if strength <= 0.02 or camera == null:
		return
	var view := get_viewport_rect().size / camera.zoom
	var centre := camera.get_screen_center_position()
	var screen := Rect2(centre - view * 0.5, view)
	var tint := Color(0.05, 0.07, 0.10, 0.30 * strength)
	match weather:
		WEATHER_BLIZZARD:
			tint = Color(0.62, 0.72, 0.80, 0.34 * strength)
		WEATHER_ASHFALL:
			tint = Color(0.32, 0.20, 0.13, 0.40 * strength)
		WEATHER_FOG:
			tint = Color(0.55, 0.58, 0.55, 0.42 * strength)
	draw_rect(screen, tint)
	for particle in weather_particles:
		var pos: Vector2 = particle.get("pos", centre)
		match weather:
			WEATHER_RAIN, WEATHER_STORM:
				var streak_length := 9.0 if weather == WEATHER_RAIN else 13.0
				draw_line(pos, pos + Vector2(-1.6, streak_length), Color("9fc4d8", 0.55), 1.0)
			WEATHER_BLIZZARD:
				draw_rect(Rect2(pos, Vector2(2, 2)), Color("eaf4ff", 0.80))
			WEATHER_ASHFALL:
				draw_rect(Rect2(pos, Vector2(2, 2)), Color("caa77d", 0.62))
	if weather_lightning_flash > 0.0:
		draw_rect(
			screen,
			Color(0.92, 0.95, 1.0, clampf(weather_lightning_flash, 0.0, 0.55))
		)


func _update_day_night(delta: float) -> void:
	world_time = fposmod(world_time + delta, FULL_DAY_DURATION)


func _is_night() -> bool:
	return world_time >= DAY_DURATION


func _daylight_factor() -> float:
	if _is_night():
		return 0.38
	if world_time < 90.0:
		return lerpf(0.38, 1.0, world_time / 90.0)
	if world_time > DAY_DURATION - 120.0:
		return lerpf(1.0, 0.38, (world_time - (DAY_DURATION - 120.0)) / 120.0)
	return 1.0


func _time_period_text() -> String:
	if _is_night():
		var remaining := int(ceil(FULL_DAY_DURATION - world_time))
		return "Night %02d:%02d" % [remaining / 60, remaining % 60]
	var day_remaining := int(ceil(DAY_DURATION - world_time))
	return "Day %02d:%02d" % [day_remaining / 60, day_remaining % 60]


func _update_regen(delta: float) -> void:
	if in_main_menu or game_paused or not world_loaded:
		return
	if health >= MAX_HEALTH:
		player_regen_timer = 0.0
		return
	if player_regen_timer <= 0.0:
		return
	player_regen_timer -= delta
	if player_regen_timer <= 0.0:
		player_regen_timer = REGEN_INTERVAL
		health = mini(MAX_HEALTH, health + 1)


func _update_network_client_combat(delta: float) -> void:
	# Enemies/projectiles are simulated by the host. The client keeps only
	# immediate local feedback and status timers responsive between snapshots.
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	player_hurt_timer = maxf(0.0, player_hurt_timer - delta)
	player_hurt_flash = maxf(0.0, player_hurt_flash - delta)
	_update_noise_events(delta)
	_collect_visible_light_sources()
	_update_status_effects(delta)


func _update_combat(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	player_hurt_timer = maxf(0.0, player_hurt_timer - delta)
	player_hurt_flash = maxf(0.0, player_hurt_flash - delta)
	_update_noise_events(delta)
	_collect_visible_light_sources()
	enemy_spawn_timer -= delta
	if enemy_spawn_timer <= 0.0:
		enemy_spawn_timer = _enemy_spawn_interval()
		_try_spawn_enemy()
	if defeated_enemies >= 10 and not boss_spawned and not boss_defeated:
		_spawn_enemy("heartwood_boss", _find_spawn_position_near_player(18, 26))
		boss_spawned = true
		_play_sound("boss")
		last_message = "The old root heart has awakened."
	_update_enemy_ai(delta)
	_update_enemy_deaths(delta)
	_update_projectiles(delta)
	_update_enemy_projectiles(delta)
	_update_enemy_impact_effects(delta)
	_update_engineer_turret(delta)
	_update_status_effects(delta)


func _bosses_defeated() -> int:
	# Bosses are counted from saved flags, so old worlds get the right pacing
	# automatically. This is the global difficulty clock for mob scaling.
	var count := 0
	if boss_defeated:
		count += 1
	if stone_beast_defeated:
		count += 1
	if storm_herald_defeated:
		count += 1
	if depth_warden_defeated:
		count += 1
	if sky_leviathan_defeated:
		count += 1
	return count


func _max_enemies() -> int:
	# Fresh world: at most 7 creatures near the player. Each defeated boss
	# raises the cap by 3 (7 -> 10 -> 13 -> 16 -> 18 global ceiling).
	return mini(MAX_ENEMIES, 7 + 3 * _bosses_defeated())


func _enemy_spawn_interval() -> float:
	# Fresh world spawns rarely (6s between attempts) so reaching the cap takes
	# a long time; every boss defeated speeds spawning up (min 2.4s).
	return maxf(2.4, 6.0 - 1.2 * float(_bosses_defeated()))


func _enemy_scale(enemy_type: String) -> Dictionary:
	var bosses := _bosses_defeated()
	var is_boss := enemy_type in ["heartwood_boss", "stone_beast", "storm_herald", "depth_warden", "leviathan"]
	var hp_scale := 1.0 + (0.10 if is_boss else 0.20) * float(bosses)
	var dmg_scale := 1.0 + (0.05 if is_boss else 0.08) * float(bosses)
	return {
		"hp": minf(hp_scale, 2.0),
		"damage": minf(dmg_scale, 1.5),
	}


func _try_spawn_enemy() -> void:
	if network_session == null or not network_session.is_server() or network_session.players.is_empty():
		_try_spawn_enemy_for_current_player()
		return
	var original_position := player_position
	var selected_position := player_position
	var selected_nearby := INF
	for state_variant in network_session.players.values():
		var state: Dictionary = state_variant
		var candidate: Vector2 = state.get("pos", player_position)
		var nearby := 0
		for enemy in enemies:
			if (enemy.get("pos", Vector2.ZERO) as Vector2).distance_to(candidate) < 45.0 * TILE_SIZE:
				nearby += 1
		if nearby < selected_nearby:
			selected_nearby = nearby
			selected_position = candidate
	player_position = selected_position
	_try_spawn_enemy_for_current_player()
	player_position = original_position


func _try_spawn_enemy_for_current_player() -> void:
	# Global ceiling: never more than MAX_ENEMIES in the whole world.
	if enemies.size() >= MAX_ENEMIES:
		return
	# Nearby cap: only a limited number of creatures may be close to the
	# player (7 in a fresh world; every defeated boss raises it by 3).
	var nearby_enemies := 0
	for enemy in enemies:
		if Vector2(enemy.get("pos", Vector2.ZERO)).distance_to(player_position) < 45.0 * TILE_SIZE:
			nearby_enemies += 1
	if nearby_enemies >= _max_enemies():
		return
	# Grace period: a brand-new world starts at world_time 28 and gets roughly
	# 45 seconds of peace before the first hostile appears (the spawn timer
	# also starts at 45s, this is a second safety net).
	if world_time < 75.0:
		return
	# Sky Herald: rare scout that appears only after the 2nd boss is dead.
	# It roosts on highland peaks (reachable without wings) and later on the
	# sky islands, and drops Zephyr Feathers for the Wind Wings recipe.
	if depth_warden_defeated and rng.randf() < 0.12:
		var highland_pos := _find_highland_spawn_position()
		if highland_pos.x >= 0.0:
			_spawn_enemy("sky_herald", highland_pos)
			return
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var surface_y := surface_heights[clampi(player_tile.x, 0, surface_heights.size() - 1)]
	var depth := player_tile.y - surface_y
	var in_cave := depth > 10
	var near_ruins := _has_tile_near_player(Tile.RUIN, 13)
	var biome := _current_biome()
	var surface_biome := _surface_biome_at_column(player_tile.x)

	# --- Spawn chance per situation (Terraria-like pacing) ---
	# The forest surface is a safe zone during the day: nothing hostile spawns
	# there until night falls or the player digs underground.
	var spawn_chance := 0.0
	if biome == "sky_islands":
		# The sky is always a bit lively regardless of the surface biome below.
		spawn_chance = 0.45
	elif in_cave:
		spawn_chance = 0.50
	elif _is_night():
		spawn_chance = 0.60
	elif surface_biome == "forest":
		spawn_chance = 0.0
	elif surface_biome == "ash_ruins":
		spawn_chance = 0.30
	else:
		# Marsh / ash desert / frost wasteland: resident surface wildlife.
		spawn_chance = 0.28
	if near_ruins:
		spawn_chance += 0.15
	# Progress pushes spawn frequency up, so later game worlds feel busier.
	spawn_chance *= minf(1.6, 1.0 + 0.15 * float(_bosses_defeated()))
	if rng.randf() > spawn_chance:
		return

	# --- Which enemy (decision table mirrors the field journal habitats) ---
	var enemy_type := "wild_slime"
	if biome == "sky_islands":
		# Above the clouds: bats roam; the Sky Herald appears after Chapter II.
		if depth_warden_defeated and rng.randf() < 0.35:
			enemy_type = "sky_herald"
		else:
			enemy_type = "bat"
	elif biome == "glass_abyss":
		enemy_type = "glass_wraith"
	elif biome == "lava_roots":
		enemy_type = "ember_rootling" if rng.randf() < 0.6 else "night_ember"
	elif biome == "sunken_ruins":
		enemy_type = "drowned_guard"
	elif biome == "ash_city":
		var city_roll := rng.randf()
		if city_roll < 0.45:
			enemy_type = "ash_sentinel"
		elif city_roll < 0.78:
			enemy_type = "ruin_drone"
		else:
			enemy_type = "ash_wisp"
	elif biome == "mushroom_halls":
		enemy_type = "mushroom_beetle" if rng.randf() < 0.65 else "spore_bat"
	elif in_cave:
		# Generic underground: only true cave dwellers, never surface mobs.
		if biome == "frost_caves":
			enemy_type = "cave_husk" if rng.randf() < 0.5 else "bat"
		elif mushroom_path_opened and depth > 24 and rng.randf() < 0.30:
			enemy_type = "mushroom_beetle"
		else:
			var cave_roll := rng.randf()
			if cave_roll < 0.34:
				enemy_type = "cave_worm"
			elif cave_roll < 0.64:
				enemy_type = "bat"
			else:
				enemy_type = "cave_husk"
	elif near_ruins and rng.randf() < 0.55:
		enemy_type = "ruin_drone"
	elif _is_night():
		# Night surface: bats and slimes roam everywhere.
		enemy_type = "bat" if rng.randf() < 0.5 else "wild_slime"
	elif surface_biome == "marsh":
		enemy_type = "mossling" if rng.randf() < 0.62 else "wild_slime"
	elif surface_biome == "ash_desert":
		# The sand mantis is the desert's ambush predator; desert slimes fill
		# the rest of the drifts (palette applied at spawn).
		enemy_type = "root_crawler" if rng.randf() < 0.45 else "wild_slime"
	elif surface_biome == "frost_wasteland":
		enemy_type = "wild_slime" if rng.randf() < 0.52 else "bat"  # frost palette
	elif surface_biome == "ash_ruins":
		var ruins_roll := rng.randf()
		if ruins_roll < 0.45:
			enemy_type = "ash_phantom"
		elif ruins_roll < 0.75:
			enemy_type = "ruin_drone"
		else:
			enemy_type = "ash_wisp"
	else:
		enemy_type = "wild_slime"
	var spawn_data := _enemy_template(enemy_type)
	var pos := _find_spawn_position_near_player(18, 30, bool(spawn_data.get("flying", false)), spawn_data.get("size", Vector2(16, 16)))
	_spawn_enemy(enemy_type, pos)


func _compute_current_biome() -> String:
	var tile_pos := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var surface_y: int = surface_heights[clampi(tile_pos.x, 0, surface_heights.size() - 1)]
	var depth := tile_pos.y - surface_y
	if tile_pos.y <= SKY_ZONE_BOTTOM and _has_tile_near_player(Tile.CLOUDSTONE, 16):
		return "sky_islands"
	if _has_tile_near_player(Tile.ABYSS_CRYSTAL, 14) or tile_pos.y > WORLD_HEIGHT - 44:
		return "glass_abyss"
	if _has_tile_near_player(Tile.LAVA_ROOT, 13):
		return "lava_roots"
	if _has_tile_near_player(Tile.SUNKEN_STONE, 13):
		return "sunken_ruins"
	if _has_tile_near_player(Tile.ASH_BRICK, 14):
		return "ash_city"
	if _has_tile_near_player(Tile.GLOW_MUSHROOM, 14) or _has_tile_near_player(Tile.MUSHROOM_SOIL, 14):
		return "mushroom_halls"
	if depth <= 10:
		return _surface_biome_at_column(tile_pos.x)
	# Frost caves are a distinct underground climate, but remain tied to the
	# frost surface above them instead of being scattered world-wide.
	if _surface_biome_at_column(tile_pos.x) == "frost_wasteland":
		return "frost_caves"
	return "caves"


func _current_biome() -> String:
	return cached_biome


func _update_biome_cache(delta: float) -> void:
	biome_check_timer += delta
	if biome_check_timer < 0.25:
		return
	biome_check_timer = 0.0
	cached_biome = _compute_current_biome()


func _update_biome_audio() -> void:
	var biome := cached_biome
	if biome == last_biome:
		return
	last_biome = biome
	var sound_name := "cave_event"
	if biome == "forest":
		sound_name = "forest_event"
	elif biome == "mushroom_halls":
		sound_name = "mushroom_event"
	elif biome == "ash_city":
		sound_name = "ash_event"
	elif biome == "sunken_ruins":
		sound_name = "water_event"
	elif biome == "lava_roots":
		sound_name = "lava_event"
	elif biome == "glass_abyss":
		sound_name = "glass_event"
	_play_sound(sound_name)
	# (Biome-entry toast removed — the strip at the top center looked bad.)


func _has_tile_near_player(tile: int, radius: int) -> bool:
	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if _in_bounds(x, y) and _get_tile(x, y) == tile:
				return true
	return false


func _find_highland_spawn_position() -> Vector2:
	# Find the highest surface peak near the player (minimal surface height in
	# a ring of columns around them) and place the Sky Herald on top of it.
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var best_x := -1
	var best_y := 999999
	for attempt in range(24):
		var x := clampi(player_tile.x + rng.randi_range(20, 42) * (-1 if rng.randf() < 0.5 else 1), 4, WORLD_WIDTH - 5)
		var sy: int = surface_heights[x] if x < surface_heights.size() else 60
		if sy < best_y:
			best_y = sy
			best_x = x
	if best_x < 0:
		return Vector2(-1.0, -1.0)
	# Place the herald a little above the peak; it flies, so it hovers.
	var pos := Vector2(best_x * TILE_SIZE + TILE_SIZE * 0.5, (best_y - 4) * TILE_SIZE)
	var size := Vector2(16, 20)
	var rect := Rect2(pos - size * 0.5, size)
	if _rect_collides(rect):
		return Vector2(-1.0, -1.0)
	return pos


func _find_spawn_position_near_player(min_tiles: int, max_tiles: int, flying := false, spawn_size := Vector2(16, 16)) -> Vector2:
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	for attempt in range(30):
		var dir := -1 if rng.randf() < 0.5 else 1
		var x := clampi(player_tile.x + dir * rng.randi_range(min_tiles, max_tiles), 4, WORLD_WIDTH - 5)
		if flying:
			var flying_y := clampi(player_tile.y + rng.randi_range(-8, 7), 4, WORLD_HEIGHT - 6)
			var flying_rect := Rect2(Vector2(x * TILE_SIZE + 8.0, flying_y * TILE_SIZE + 8.0) - spawn_size * 0.5, spawn_size)
			if not _rect_collides(flying_rect):
				return flying_rect.get_center()
			continue
		# Search for a real floor around the player's current depth. Ground enemies
		# no longer spawn in mid-air above the surface.
		for offset in range(0, 54):
			var sign_dir := -1 if offset % 2 == 0 else 1
			var y := player_tile.y + sign_dir * int(ceil(float(offset) * 0.5))
			if y < 2 or y >= WORLD_HEIGHT - 3:
				continue
			if _get_tile(x, y) != Tile.AIR or not _is_solid(x, y + 1):
				continue
			var ground_pos := Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, (y + 1) * TILE_SIZE - spawn_size.y * 0.5)
			var ground_rect := Rect2(ground_pos - spawn_size * 0.5, spawn_size)
			if not _rect_collides(ground_rect):
				return ground_pos
	return player_position + Vector2(TILE_SIZE * min_tiles, -TILE_SIZE * 4)


func _find_bat_roost_position(origin: Vector2, size: Vector2) -> Vector2:
	var origin_tile := Vector2i(floori(origin.x / TILE_SIZE), floori(origin.y / TILE_SIZE))
	for upward in range(0, 11):
		var ceiling_y := origin_tile.y - upward
		if ceiling_y < 1:
			break
		for x_offset in [0, -1, 1, -2, 2]:
			var ceiling_x := origin_tile.x + int(x_offset)
			if ceiling_x < 1 or ceiling_x >= WORLD_WIDTH - 1:
				continue
			if not _is_solid(ceiling_x, ceiling_y):
				continue
			var candidate := Vector2(
				ceiling_x * TILE_SIZE + TILE_SIZE * 0.5,
				(ceiling_y + 1) * TILE_SIZE + size.y * 0.5 + 1.0
			)
			if _enemy_position_valid(candidate, size):
				return candidate
	return Vector2(-1.0, -1.0)


func _enemy_surface_visual_variant(enemy_type: String, pos: Vector2) -> String:
	if enemy_type != "wild_slime" and enemy_type != "bat":
		return enemy_type
	var tile_x := clampi(floori(pos.x / TILE_SIZE), 0, WORLD_WIDTH - 1)
	var surface_y := surface_heights[tile_x] if tile_x < surface_heights.size() else 0
	# Cave creatures keep their normal visual. Variants are surface climates only.
	if pos.y > float((surface_y + 10) * TILE_SIZE):
		return enemy_type
	var surface_biome := _surface_biome_at_column(tile_x)
	if surface_biome == "frost_wasteland":
		return "frost_wild_slime" if enemy_type == "wild_slime" else "frost_bat"
	if surface_biome == "ash_desert" and enemy_type == "wild_slime":
		return "desert_wild_slime"
	return enemy_type


func _enemy_visual_type(enemy: Dictionary) -> String:
	var enemy_type := str(enemy.get("type", "wild_slime"))
	var variant := str(enemy.get("visual_variant", enemy_type))
	return variant if enemy_textures.has(variant) else enemy_type


func _spawn_enemy(enemy_type: String, pos: Vector2) -> void:
	var data := _enemy_template(enemy_type)
	# Progress scaling: defeated bosses make every new creature tougher, so the
	# player must keep crafting better gear. Bosses scale gently (+10% hp per
	# boss), regular mobs more (+20%) — capped so they never become sponges.
	var scale := _enemy_scale(enemy_type)
	var scaled_hp := int(round(float(data.get("hp", 10)) * float(scale["hp"])))
	data["hp"] = scaled_hp
	data["max_hp"] = scaled_hp
	data["damage"] = int(round(float(data.get("damage", 1)) * float(scale["damage"])))
	data["perception_id"] = next_enemy_perception_id
	next_enemy_perception_id += 1
	data["type"] = enemy_type
	data["visual_variant"] = _enemy_surface_visual_variant(enemy_type, pos)
	data["pos"] = pos
	data["vel"] = Vector2.ZERO
	data["hit_timer"] = 0.0
	data["stun_timer"] = 0.0
	data["attack_windup"] = 0.0
	data["attack_flash"] = 0.0
	data["attack_cooldown"] = rng.randf_range(0.25, 0.8)
	data["facing"] = -1 if rng.randf() < 0.5 else 1
	data["anim_offset"] = rng.randf() * 10.0
	data["anim_state"] = "idle"
	data["anim_time"] = 0.0
	data["home_pos"] = pos
	data["perception_state"] = PERCEPTION_CALM
	data["suspicion"] = 0.0
	data["last_known_pos"] = pos
	data["investigate_pos"] = pos
	data["search_target"] = pos
	data["memory_timer"] = 0.0
	data["search_timer"] = 0.0
	data["search_step_timer"] = 0.0
	data["last_noise_id"] = 0
	data["can_see_player"] = false
	data["alert_cooldown"] = 0.0
	data["idle_look_timer"] = rng.randf_range(1.2, 3.5)
	data["last_safe_pos"] = pos
	data["stuck_time"] = 0.0
	data["jump_cooldown"] = rng.randf_range(0.15, 0.45)
	data["hop_timer"] = rng.randf_range(0.35, 0.75) if enemy_type == "wild_slime" else 0.0
	data["avoid_timer"] = 0.0
	data["avoid_direction"] = 0
	data["burrow_hidden"] = false
	data["burrow_origin"] = pos
	data["burrow_target"] = pos
	data["burrow_dust_started"] = false
	data["roll_active"] = false
	data["roll_direction"] = int(data["facing"])
	data["roll_dust_started"] = false
	data["roll_time"] = 0.0
	data["roosting"] = false
	data["wake_timer"] = 0.0
	data["dive_phase"] = ""
	data["dive_timer"] = 0.0
	data["dive_direction"] = Vector2.ZERO
	data["dive_hit"] = false
	data["alert_timer"] = 0.0
	data["trail_timer"] = rng.randf_range(0.05, 0.35)
	if enemy_type == "bat":
		var roost_pos := _find_bat_roost_position(pos, data.get("size", Vector2(22, 14)))
		if roost_pos.x >= 0.0:
			data["pos"] = roost_pos
			data["home_pos"] = roost_pos
			data["last_safe_pos"] = roost_pos
			data["roosting"] = true
			data["anim_state"] = "hang_idle"
	# Bats can be moved to a cave roost after their initial spawn point was
	# chosen, so resolve the surface palette one more time at the final position.
	data["visual_variant"] = _enemy_surface_visual_variant(enemy_type, data["pos"])
	if enemy_type == "heartwood_boss":
		data["spawn_timer"] = 0.85
		data["phase_two"] = false
		data["phase_timer"] = 0.0
		data["anim_state"] = "spawn"
		data["perception_state"] = PERCEPTION_COMBAT
		data["last_known_pos"] = player_position
		data["memory_timer"] = float(_enemy_perception_profile(enemy_type).get("memory_time", 10.0))
	enemies.append(data)


func _enemy_template(enemy_type: String) -> Dictionary:
	if enemy_type == "mossling":
		return {"name": "Mossling", "hp": 20, "max_hp": 20, "damage": 6, "damage_type": "physical", "speed": 72.0, "flying": false, "size": Vector2(18, 12), "color": Color("5c9a63"), "drop": "moss_fiber"}
	if enemy_type == "cave_worm":
		return {"name": "Cave Worm", "hp": 46, "max_hp": 46, "damage": 11, "damage_type": "physical", "speed": 82.0, "flying": false, "size": Vector2(34, 12), "hitbox_size": Vector2(62, 24), "hitbox_offset": Vector2(0, -6), "color": Color("9b6b4d"), "drop": "wild_ichor", "status_on_hit": "slow"}
	if enemy_type == "bat":
		return {"name": "Bat", "hp": 16, "max_hp": 16, "damage": 6, "damage_type": "physical", "speed": 128.0, "flying": true, "size": Vector2(22, 14), "hitbox_size": Vector2(42, 28), "color": Color("4f5165"), "drop": "wild_ichor"}
	if enemy_type == "spore_bat":
		return {"name": "Spore Bat", "hp": 22, "max_hp": 22, "damage": 8, "damage_type": "poison", "speed": 118.0, "flying": true, "size": Vector2(21, 14), "hitbox_size": Vector2(42, 24), "color": Color("79c98b"), "drop": "glowcap", "status_on_hit": "poison"}
	if enemy_type == "ash_phantom":
		return {"name": "Ash Phantom", "hp": 32, "max_hp": 32, "damage": 10, "damage_type": "fire", "speed": 88.0, "flying": true, "size": Vector2(18, 24), "color": Color("a88cff"), "drop": "memory_shard", "status_on_hit": "burn"}
	if enemy_type == "mushroom_beetle":
		return {"name": "Mushroom Beetle", "hp": 34, "max_hp": 34, "damage": 9, "damage_type": "poison", "speed": 54.0, "flying": false, "size": Vector2(20, 14), "hitbox_size": Vector2(56, 28), "hitbox_offset": Vector2(0, -4), "color": Color("65b47d"), "drop": "mushroom_spore", "status_on_hit": "poison"}
	if enemy_type == "root_crawler":
		return {"name": "Sand Mantis", "hp": 30, "max_hp": 30, "damage": 8, "damage_type": "physical", "speed": 62.0, "flying": false, "size": Vector2(22, 12), "hitbox_size": Vector2(58, 22), "hitbox_offset": Vector2(0, -4), "color": Color("b2925c"), "drop": "root", "status_on_hit": "slow"}
	if enemy_type == "ruin_drone":
		return {"name": "Ruin Drone", "hp": 36, "max_hp": 36, "damage": 12, "damage_type": "arcane", "speed": 95.0, "flying": true, "size": Vector2(16, 16), "color": Color("8fa9c9"), "drop": "spark_shard"}
	if enemy_type == "ash_sentinel":
		return {"name": "Ash Sentinel", "hp": 48, "max_hp": 48, "damage": 14, "damage_type": "fire", "speed": 56.0, "flying": false, "size": Vector2(20, 28), "color": Color("7b707e"), "drop": "ash_relic", "status_on_hit": "burn"}
	if enemy_type == "drowned_guard":
		return {"name": "Drowned Guard", "hp": 44, "max_hp": 44, "damage": 12, "damage_type": "physical", "speed": 50.0, "flying": false, "size": Vector2(20, 24), "color": Color("4e8a94"), "drop": "drowned_pearl", "status_on_hit": "slow"}
	if enemy_type == "ember_rootling":
		return {"name": "Ember Rootling", "hp": 52, "max_hp": 52, "damage": 15, "damage_type": "fire", "speed": 64.0, "flying": false, "size": Vector2(24, 18), "color": Color("c15b38"), "drop": "ember_root", "status_on_hit": "burn"}
	if enemy_type == "glass_wraith":
		return {"name": "Glass Wraith", "hp": 58, "max_hp": 58, "damage": 16, "damage_type": "arcane", "speed": 92.0, "flying": true, "size": Vector2(18, 28), "color": Color("b8f4ff"), "drop": "abyss_crystal", "status_on_hit": "slow"}
	if enemy_type == "stone_beast":
		return {"name": "Stone Beast", "hp": 420, "max_hp": 420, "damage": 22, "damage_type": "physical", "speed": 40.0, "flying": false, "size": Vector2(56, 42), "color": Color("7f7368"), "drop": "beast_core"}
	if enemy_type == "night_ember":
		return {"name": "Night Ember", "hp": 28, "max_hp": 28, "damage": 12, "damage_type": "fire", "speed": 92.0, "flying": true, "size": Vector2(15, 15), "color": Color("ee6f46"), "drop": "night_ember", "status_on_hit": "burn"}
	if enemy_type == "cave_husk":
		return {"name": "Cave Husk", "hp": 38, "max_hp": 38, "damage": 10, "damage_type": "physical", "speed": 58.0, "flying": false, "size": Vector2(18, 22), "hitbox_size": Vector2(72, 42), "hitbox_offset": Vector2(0, -10), "color": Color("8f8796"), "drop": "wild_ichor"}
	if enemy_type == "ash_wisp":
		return {"name": "Ash Wisp", "hp": 22, "max_hp": 22, "damage": 8, "damage_type": "arcane", "speed": 76.0, "flying": true, "size": Vector2(14, 14), "color": Color("b79cff"), "drop": "spark_shard"}
	if enemy_type == "heartwood_boss":
		return {"name": "Heartwood Core", "hp": 260, "max_hp": 260, "damage": 18, "damage_type": "physical", "speed": 46.0, "flying": false, "size": Vector2(42, 48), "color": Color("8b5a36"), "drop": "heartwood_core"}
	if enemy_type == "depth_warden":
		return {"name": "Depth Warden", "hp": 320, "max_hp": 320, "damage": 20, "damage_type": "physical", "speed": 52.0, "flying": false, "size": Vector2(44, 56), "hitbox_size": Vector2(72, 60), "hitbox_offset": Vector2(0, -10), "color": Color("7a5a8a"), "drop": "earth_shard", "status_on_hit": "slow"}
	if enemy_type == "storm_herald":
		return {"name": "Storm Herald", "hp": 180, "max_hp": 180, "damage": 16, "damage_type": "arcane", "speed": 120.0, "flying": true, "size": Vector2(28, 34), "hitbox_size": Vector2(56, 48), "color": Color("9fc4e8"), "drop": "wind_shard", "status_on_hit": "slow"}
	if enemy_type == "sky_herald":
		return {"name": "Sky Herald", "hp": 26, "max_hp": 26, "damage": 8, "damage_type": "arcane", "speed": 96.0, "flying": true, "size": Vector2(16, 20), "hitbox_size": Vector2(40, 30), "color": Color("ffd98a"), "drop": "zephyr_feather"}
	if enemy_type == "leviathan":
		return {"name": "Sky Leviathan", "hp": 340, "max_hp": 340, "damage": 19, "damage_type": "arcane", "speed": 118.0, "flying": true, "size": Vector2(44, 52), "hitbox_size": Vector2(120, 70), "hitbox_offset": Vector2(0, -10), "color": Color("aed6ff"), "drop": "leviathan_scale"}
	return {"name": "Wild Slime", "hp": 18, "max_hp": 18, "damage": 7, "damage_type": "physical", "speed": 64.0, "flying": false, "size": Vector2(16, 13), "color": Color("5fbf7b"), "drop": "wild_ichor"}


func _enemy_perception_profile(enemy_type: String) -> Dictionary:
	var profile := {
		"vision_range": 165.0,
		"vision_angle": 120.0,
		"hearing": 1.0,
		"light_sensitivity": 0.75,
		"suspicion_rate": 1.35,
		"suspicion_decay": 0.38,
		"memory_time": 5.0,
		"search_time": 6.0,
		"alert_radius": 150.0,
		"instant_range": 30.0
	}
	var overrides: Dictionary = enemy_perception_profiles.get(enemy_type, {})
	for key in overrides.keys():
		profile[key] = overrides[key]
	return profile


func _enemy_movement_profile(enemy_type: String) -> Dictionary:
	var profile := {
		"locomotion": "walk",
		"acceleration": 6.0,
		"air_control": 0.12,
		"ground_snap": 6.0,
		"stuck_turn_time": 0.62,
		"avoid_time": 0.72,
		"navigation_jump": true,
		"jump_speed": -285.0,
		"jump_interval": 1.10
	}
	if enemy_type in ["bat", "spore_bat", "ash_phantom", "ash_wisp", "ruin_drone", "glass_wraith", "night_ember", "leviathan", "sky_herald"]:
		profile["locomotion"] = "hover"
		profile["ground_snap"] = 0.0
		profile["navigation_jump"] = false
		return profile
	if enemy_type == "wild_slime":
		profile["locomotion"] = "hop"
		profile["acceleration"] = 5.0
		profile["air_control"] = 0.42
		profile["ground_snap"] = 0.0
		profile["navigation_jump"] = false
		profile["hop_speed"] = -285.0
		profile["hop_interval"] = 0.72
	elif enemy_type in ["root_crawler", "cave_worm"]:
		profile["locomotion"] = "crawl"
		profile["acceleration"] = 8.5
		profile["air_control"] = 0.05
		profile["ground_snap"] = 8.0
		profile["stuck_turn_time"] = 0.50
	elif enemy_type in ["mossling", "mushroom_beetle", "ember_rootling"]:
		profile["locomotion"] = "scuttle"
		profile["acceleration"] = 7.5
		profile["ground_snap"] = 7.0
	elif enemy_type in ["cave_husk", "ash_sentinel", "drowned_guard"]:
		profile["locomotion"] = "heavy_walk"
		profile["acceleration"] = 3.8
		profile["air_control"] = 0.02
		profile["ground_snap"] = 5.0
		profile["jump_speed"] = -305.0
		profile["stuck_turn_time"] = 0.78
	elif enemy_type in ["stone_beast", "heartwood_boss"]:
		profile["locomotion"] = "heavy_walk"
		profile["acceleration"] = 2.6
		profile["air_control"] = 0.0
		profile["ground_snap"] = 4.0
		profile["navigation_jump"] = false
		profile["stuck_turn_time"] = 0.90
	return profile


func _emit_noise(pos: Vector2, radius: float, kind: String, strength := 1.0) -> void:
	if radius <= 0.0:
		return
	var effective_radius := radius
	if kind in ["footstep", "jump", "landing"]:
		effective_radius *= _weather_noise_mask_at(pos)
	perception_noise_events.append({
		"id": next_noise_event_id,
		"pos": pos,
		"radius": effective_radius,
		"kind": kind,
		"strength": clampf(strength, 0.05, 2.0),
		"life": NOISE_EVENT_LIFETIME,
		"max_life": NOISE_EVENT_LIFETIME
	})
	next_noise_event_id += 1
	while perception_noise_events.size() > 32:
		perception_noise_events.pop_front()


func _update_noise_events(delta: float) -> void:
	for i in range(perception_noise_events.size() - 1, -1, -1):
		var event: Dictionary = perception_noise_events[i]
		event["life"] = float(event.get("life", 0.0)) - delta
		if float(event["life"]) <= 0.0:
			perception_noise_events.remove_at(i)
		else:
			perception_noise_events[i] = event


func _player_visibility_light() -> float:
	var tile_x := clampi(floori(player_position.x / TILE_SIZE), 0, WORLD_WIDTH - 1)
	var tile_y := clampi(floori(player_position.y / TILE_SIZE), 0, WORLD_HEIGHT - 1)
	var environment_light := _light_at_tile(tile_x, tile_y, true)
	if _selected_item() == "torch" and int(inventory.get("torch", 0)) > 0:
		environment_light = maxf(environment_light, 1.0)
	return clampf(environment_light, 0.02, 1.0)


func _has_perception_line_of_sight(from_pos: Vector2, to_pos: Vector2) -> bool:
	var delta_pos := to_pos - from_pos
	var distance := delta_pos.length()
	if distance <= 1.0:
		return true
	var steps := maxi(2, ceili(distance / (TILE_SIZE * 0.35)))
	for step in range(1, steps):
		var sample := from_pos.lerp(to_pos, float(step) / float(steps))
		var tile_x := floori(sample.x / TILE_SIZE)
		var tile_y := floori(sample.y / TILE_SIZE)
		if _is_solid(tile_x, tile_y):
			return false
	return true


func _enemy_can_see_player(enemy: Dictionary, pos: Vector2, profile: Dictionary, target_player_position := Vector2.ZERO) -> bool:
	if creative_mode:
		return false
	if target_player_position == Vector2.ZERO:
		target_player_position = player_position
	var to_player := target_player_position - pos
	var distance := to_player.length()
	var light := _player_visibility_light()
	var light_sensitivity := clampf(float(profile.get("light_sensitivity", 0.75)), 0.0, 1.0)
	var illuminated_range_factor := lerpf(0.38, 1.12, light)
	var range_factor := lerpf(1.0, illuminated_range_factor, light_sensitivity)
	var effective_range := float(profile.get("vision_range", 165.0)) * range_factor * ENEMY_VISION_RANGE_MULTIPLIER
	if _enemy_is_exposed_to_weather(pos):
		var weather_penalty := _weather_visibility_penalty_at(target_player_position)
		effective_range *= clampf(1.0 - weather_penalty * 0.8, 0.25, 1.0)
	enemy["debug_vision_range"] = effective_range
	enemy["debug_player_light"] = light
	if distance > effective_range:
		return false
	if distance > float(profile.get("instant_range", 30.0)):
		var facing_direction := Vector2(float(int(enemy.get("facing", 1))), 0.0)
		var direction := to_player.normalized()
		var half_angle := deg_to_rad(float(profile.get("vision_angle", 120.0)) * 0.5)
		if facing_direction.dot(direction) < cos(half_angle):
			return false
	var eye_height := maxf(3.0, float((enemy.get("size", Vector2(16, 16)) as Vector2).y) * 0.28)
	var eye_pos := pos + Vector2(0.0, -eye_height)
	var player_chest := target_player_position + Vector2(0.0, -PLAYER_SIZE.y * 0.16)
	return _has_perception_line_of_sight(eye_pos, player_chest)


func _strongest_heard_noise(enemy: Dictionary, pos: Vector2, profile: Dictionary) -> Dictionary:
	var last_noise_id := int(enemy.get("last_noise_id", 0))
	var newest_noise_id := last_noise_id
	var best_event: Dictionary = {}
	var best_score := 0.0
	var hearing := maxf(0.0, float(profile.get("hearing", 1.0)))
	for noise in perception_noise_events:
		var event: Dictionary = noise
		var event_id := int(event.get("id", 0))
		if event_id <= last_noise_id:
			continue
		newest_noise_id = maxi(newest_noise_id, event_id)
		var noise_pos: Vector2 = event.get("pos", pos)
		var effective_radius := float(event.get("radius", 0.0)) * hearing * ENEMY_HEARING_RADIUS_MULTIPLIER
		var distance := pos.distance_to(noise_pos)
		if effective_radius <= 0.0 or distance > effective_radius:
			continue
		var occlusion := 1.0 if _has_perception_line_of_sight(pos, noise_pos) else 0.52
		var score := float(event.get("strength", 1.0)) * (1.0 - distance / effective_radius) * occlusion
		if score > best_score:
			best_score = score
			best_event = event
			best_event["heard_score"] = score
	enemy["last_noise_id"] = newest_noise_id
	return best_event


func _enemy_alert_group(enemy_type: String) -> String:
	if enemy_type in ["wild_slime", "mossling", "root_crawler", "heartwood_boss"]:
		return "roots"
	if enemy_type in ["cave_worm", "bat", "cave_husk", "stone_beast"]:
		return "cave"
	if enemy_type in ["spore_bat", "mushroom_beetle"]:
		return "fungal"
	if enemy_type in ["ash_phantom", "ash_wisp", "ash_sentinel"]:
		return "ash"
	if enemy_type in ["ruin_drone", "drowned_guard"]:
		return "ruins"
	if enemy_type in ["ember_rootling", "night_ember"]:
		return "ember"
	if enemy_type == "glass_wraith":
		return "abyss"
	return enemy_type


func _broadcast_enemy_alert(source_enemy: Dictionary, target_pos: Vector2) -> void:
	var source_pos: Vector2 = source_enemy.get("pos", target_pos)
	var source_id := int(source_enemy.get("perception_id", -1))
	var source_group := _enemy_alert_group(str(source_enemy.get("type", "")))
	var profile := _enemy_perception_profile(str(source_enemy.get("type", "")))
	var radius := float(profile.get("alert_radius", 150.0))
	for ally in enemies:
		var ally_data: Dictionary = ally
		if int(ally_data.get("perception_id", -2)) == source_id:
			continue
		if _enemy_alert_group(str(ally_data.get("type", ""))) != source_group:
			continue
		var ally_pos: Vector2 = ally_data.get("pos", source_pos)
		if ally_pos.distance_to(source_pos) > radius:
			continue
		if not _has_perception_line_of_sight(source_pos, ally_pos) and ally_pos.distance_to(source_pos) > radius * 0.55:
			continue
		if str(ally_data.get("perception_state", PERCEPTION_CALM)) == PERCEPTION_COMBAT:
			continue
		ally_data["perception_state"] = PERCEPTION_INVESTIGATE
		ally_data["suspicion"] = maxf(float(ally_data.get("suspicion", 0.0)), 0.72)
		ally_data["investigate_pos"] = target_pos
		ally_data["last_known_pos"] = target_pos
		ally_data["search_timer"] = float(_enemy_perception_profile(str(ally_data.get("type", ""))).get("search_time", 6.0))


func _force_enemy_combat(enemy: Dictionary, target_pos: Vector2, broadcast := true) -> void:
	var was_in_combat := str(enemy.get("perception_state", PERCEPTION_CALM)) == PERCEPTION_COMBAT
	var profile := _enemy_perception_profile(str(enemy.get("type", "")))
	enemy["perception_state"] = PERCEPTION_COMBAT
	enemy["suspicion"] = 1.0
	enemy["last_known_pos"] = target_pos
	enemy["investigate_pos"] = target_pos
	enemy["memory_timer"] = float(profile.get("memory_time", 5.0))
	if broadcast and not was_in_combat and float(enemy.get("alert_cooldown", 0.0)) <= 0.0:
		enemy["alert_cooldown"] = 1.0
		_broadcast_enemy_alert(enemy, target_pos)


func _update_enemy_perception(enemy: Dictionary, pos: Vector2, delta: float) -> Dictionary:
	var enemy_type := str(enemy.get("type", ""))
	var profile := _enemy_perception_profile(enemy_type)
	var target_info := _network_nearest_player_target(pos)
	var target_player_position: Vector2 = target_info.get("pos", player_position)
	var target_peer_id := int(target_info.get("peer_id", 1))
	enemy["network_target_peer"] = target_peer_id
	var previous_state := str(enemy.get("perception_state", PERCEPTION_CALM))
	var state := previous_state
	var suspicion := clampf(float(enemy.get("suspicion", 0.0)), 0.0, 1.0)
	var memory_timer := maxf(0.0, float(enemy.get("memory_timer", 0.0)))
	var search_timer := maxf(0.0, float(enemy.get("search_timer", 0.0)))
	var alert_cooldown := maxf(0.0, float(enemy.get("alert_cooldown", 0.0)) - delta)
	if state == PERCEPTION_CALM:
		var idle_look_timer := float(enemy.get("idle_look_timer", 1.0)) - delta
		if idle_look_timer <= 0.0:
			enemy["facing"] = -int(enemy.get("facing", 1))
			idle_look_timer = rng.randf_range(1.4, 3.8)
		enemy["idle_look_timer"] = idle_look_timer
	var can_see_player := _enemy_can_see_player(enemy, pos, profile, target_player_position)
	var player_distance := pos.distance_to(target_player_position)
	var heard_noise := _strongest_heard_noise(enemy, pos, profile)

	if can_see_player:
		enemy["last_known_pos"] = target_player_position
		enemy["investigate_pos"] = target_player_position
		memory_timer = float(profile.get("memory_time", 5.0))
		var distance_factor := clampf(1.25 - player_distance / maxf(1.0, float(enemy.get("debug_vision_range", 165.0))), 0.35, 1.25)
		suspicion = clampf(suspicion + delta * float(profile.get("suspicion_rate", 1.35)) * distance_factor, 0.0, 1.0)
		if previous_state == PERCEPTION_COMBAT or player_distance <= float(profile.get("instant_range", 30.0)) or suspicion >= 1.0:
			state = PERCEPTION_COMBAT
		else:
			state = PERCEPTION_SUSPICIOUS
	else:
		if state == PERCEPTION_COMBAT:
			memory_timer = maxf(0.0, memory_timer - delta)
			if memory_timer <= 0.0:
				state = PERCEPTION_SEARCH
				search_timer = float(profile.get("search_time", 6.0))
				enemy["search_step_timer"] = 0.0
		elif state == PERCEPTION_SUSPICIOUS:
			suspicion = maxf(0.0, suspicion - delta * float(profile.get("suspicion_decay", 0.38)))
			if suspicion <= 0.0:
				state = PERCEPTION_RETURN

	if not heard_noise.is_empty():
		var noise_pos: Vector2 = heard_noise.get("pos", pos)
		var heard_score := float(heard_noise.get("heard_score", 0.0))
		if state == PERCEPTION_COMBAT and not can_see_player:
			enemy["last_known_pos"] = noise_pos
			memory_timer = float(profile.get("memory_time", 5.0))
		elif state != PERCEPTION_COMBAT and heard_score >= 0.08:
			state = PERCEPTION_INVESTIGATE
			enemy["investigate_pos"] = noise_pos
			enemy["last_known_pos"] = noise_pos
			suspicion = maxf(suspicion, clampf(heard_score, 0.25, 0.88))
			search_timer = float(profile.get("search_time", 6.0))

	var target_pos: Vector2 = enemy.get("home_pos", pos)
	var has_move_target := false
	if state == PERCEPTION_COMBAT:
		target_pos = target_player_position if can_see_player else enemy.get("last_known_pos", target_player_position)
		has_move_target = true
	elif state == PERCEPTION_INVESTIGATE:
		target_pos = enemy.get("investigate_pos", pos)
		has_move_target = true
		if pos.distance_to(target_pos) <= 18.0:
			state = PERCEPTION_SEARCH
			search_timer = maxf(search_timer, float(profile.get("search_time", 6.0)))
			enemy["search_step_timer"] = 0.0
	elif state == PERCEPTION_SEARCH:
		search_timer = maxf(0.0, search_timer - delta)
		var search_step_timer := float(enemy.get("search_step_timer", 0.0)) - delta
		if search_step_timer <= 0.0 or pos.distance_to(enemy.get("search_target", pos)) <= 14.0:
			var spread := 54.0 if bool(enemy.get("flying", false)) else 42.0
			var vertical_spread := 34.0 if bool(enemy.get("flying", false)) else 0.0
			var search_origin: Vector2 = enemy.get("last_known_pos", pos)
			enemy["search_target"] = search_origin + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-vertical_spread, vertical_spread))
			search_step_timer = rng.randf_range(0.8, 1.5)
		enemy["search_step_timer"] = search_step_timer
		target_pos = enemy.get("search_target", enemy.get("last_known_pos", pos))
		has_move_target = true
		if search_timer <= 0.0:
			state = PERCEPTION_RETURN
	elif state == PERCEPTION_RETURN:
		target_pos = enemy.get("home_pos", pos)
		has_move_target = true
		if pos.distance_to(target_pos) <= 16.0:
			state = PERCEPTION_CALM
			suspicion = 0.0
			has_move_target = false
	elif state == PERCEPTION_SUSPICIOUS:
		target_pos = target_player_position

	if state == PERCEPTION_COMBAT and previous_state != PERCEPTION_COMBAT and alert_cooldown <= 0.0:
		alert_cooldown = 1.0
		if not _enemy_animation_spec(enemy_type, "alert").is_empty():
			enemy["alert_timer"] = _enemy_animation_duration(enemy_type, "alert", 0.45)
			enemy["anim_state"] = "alert"
			enemy["anim_time"] = 0.0
		_broadcast_enemy_alert(enemy, enemy.get("last_known_pos", target_player_position))

	enemy["perception_state"] = state
	enemy["suspicion"] = suspicion
	enemy["memory_timer"] = memory_timer
	enemy["search_timer"] = search_timer
	enemy["alert_cooldown"] = alert_cooldown
	enemy["can_see_player"] = can_see_player
	return {
		"state": state,
		"target_pos": target_pos,
		"has_move_target": has_move_target,
		"can_attack_player": state == PERCEPTION_COMBAT and can_see_player,
		"player_distance": player_distance,
		"target_player_position": target_player_position,
		"target_peer_id": target_peer_id
	}


func _update_enemy_ai(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var enemy: Dictionary = enemies[i]
		var enemy_type := str(enemy.get("type", ""))
		var spawn_timer := maxf(0.0, float(enemy.get("spawn_timer", 0.0)) - delta)
		enemy["spawn_timer"] = spawn_timer
		if spawn_timer > 0.0:
			enemy["anim_state"] = "spawn"
			enemies[i] = enemy
			continue
		var hp_ratio := float(enemy.get("hp", 1)) / float(maxi(1, int(enemy.get("max_hp", 1))))
		if enemy_type == "heartwood_boss" and not bool(enemy.get("phase_two", false)) and hp_ratio <= 0.50:
			enemy["phase_two"] = true
			enemy["phase_timer"] = 0.90
			_spawn_hit_particles(enemy["pos"] as Vector2, Color("9ce36d"), 12)
		var phase_timer := maxf(0.0, float(enemy.get("phase_timer", 0.0)) - delta)
		enemy["phase_timer"] = phase_timer
		if phase_timer > 0.0:
			enemy["anim_state"] = "phase_2"
			enemies[i] = enemy
			continue
		enemy["hit_timer"] = maxf(0.0, float(enemy.get("hit_timer", 0.0)) - delta)
		enemy["stun_timer"] = maxf(0.0, float(enemy.get("stun_timer", 0.0)) - delta)
		enemy["attack_cooldown"] = maxf(0.0, float(enemy.get("attack_cooldown", 0.0)) - delta)
		enemy["guard_time"] = maxf(0.0, float(enemy.get("guard_time", 0.0)) - delta)
		enemy["attack_flash"] = maxf(0.0, float(enemy.get("attack_flash", 0.0)) - delta)
		enemy["roll_time"] = maxf(0.0, float(enemy.get("roll_time", 0.0)) - delta)
		enemy["dive_timer"] = maxf(0.0, float(enemy.get("dive_timer", 0.0)) - delta)
		enemy["alert_timer"] = maxf(0.0, float(enemy.get("alert_timer", 0.0)) - delta)
		enemy["trail_timer"] = maxf(0.0, float(enemy.get("trail_timer", 0.0)) - delta)
		enemy["jump_cooldown"] = maxf(0.0, float(enemy.get("jump_cooldown", 0.0)) - delta)
		enemy["hop_timer"] = maxf(0.0, float(enemy.get("hop_timer", 0.0)) - delta)
		enemy["avoid_timer"] = maxf(0.0, float(enemy.get("avoid_timer", 0.0)) - delta)
		var pos: Vector2 = enemy["pos"]
		var old_pos := pos
		var vel: Vector2 = enemy["vel"]
		var size: Vector2 = enemy["size"]
		var last_safe_pos: Vector2 = enemy.get("last_safe_pos", pos)
		var burrow_hidden_at_frame_start := bool(enemy.get("burrow_hidden", false))
		if not burrow_hidden_at_frame_start and not _enemy_position_valid(pos, size):
			pos = _recover_enemy_position(pos, size, last_safe_pos)
			old_pos = pos
			vel = Vector2.ZERO
		var perception := _update_enemy_perception(enemy, pos, delta)
		var target_player_position: Vector2 = perception.get("target_player_position", player_position)
		var target_position: Vector2 = perception.get("target_pos", pos)
		var has_move_target := bool(perception.get("has_move_target", false))
		var can_attack_player := bool(perception.get("can_attack_player", false))
		var player_distance := float(perception.get("player_distance", pos.distance_to(target_player_position)))
		if enemy_type == "spore_bat" and float(enemy.get("trail_timer", 0.0)) <= 0.0:
			_spawn_enemy_impact(pos + Vector2(float(-int(enemy.get("facing", 1))) * 5.0, 4.0), "spore_bat", "spore_trail", 1, false, 0.44)
			enemy["trail_timer"] = 0.48
		if enemy_type == "bat":
			var wake_timer := float(enemy.get("wake_timer", 0.0))
			if bool(enemy.get("roosting", false)):
				var perception_state := str(perception.get("state", PERCEPTION_CALM))
				if perception_state != PERCEPTION_CALM or player_distance <= 118.0:
					enemy["roosting"] = false
					wake_timer = _enemy_animation_duration("bat", "wake_up", 0.40)
					enemy["wake_timer"] = wake_timer
					enemy["anim_state"] = "wake_up"
					enemy["anim_time"] = 0.0
				else:
					enemy["vel"] = Vector2.ZERO
					enemy["anim_state"] = "hang_idle"
					enemy["anim_time"] = float(enemy.get("anim_time", 0.0)) + delta
					enemies[i] = enemy
					continue
			if wake_timer > 0.0:
				wake_timer = maxf(0.0, wake_timer - delta)
				enemy["wake_timer"] = wake_timer
				enemy["vel"] = Vector2.ZERO
				if str(enemy.get("anim_state", "")) != "wake_up":
					enemy["anim_state"] = "wake_up"
					enemy["anim_time"] = 0.0
				else:
					enemy["anim_time"] = float(enemy.get("anim_time", 0.0)) + delta
				enemies[i] = enemy
				continue
		var to_player := target_position - pos
		var distance := to_player.length()
		var facing := int(enemy.get("facing", 1))
		if has_move_target or str(perception.get("state", PERCEPTION_CALM)) == PERCEPTION_SUSPICIOUS:
			facing = 1 if to_player.x >= 0.0 else -1
		if absf(to_player.x) > 2.0 and (has_move_target or str(perception.get("state", PERCEPTION_CALM)) == PERCEPTION_SUSPICIOUS):
			enemy["facing"] = facing
		var speed := float(enemy.get("speed", 50.0))
		var movement_profile := _enemy_movement_profile(enemy_type)
		if enemy_type == "heartwood_boss" and bool(enemy.get("phase_two", false)):
			speed *= 1.25
		var statuses: Dictionary = enemy.get("statuses", {})
		if statuses.has("slow"):
			speed *= 0.55
		var flying := bool(enemy.get("flying", false))
		var attack_range := _enemy_attack_range(enemy_type, size, flying)
		var windup_duration := 0.42 if flying else 0.32
		if enemy_type == "stone_beast":
			attack_range = 46.0
			windup_duration = 0.60
		elif enemy_type == "heartwood_boss":
			attack_range = 118.0
			windup_duration = 0.50
		var attack_windup := float(enemy.get("attack_windup", 0.0))
		var stunned := float(enemy.get("stun_timer", 0.0)) > 0.0
		var alerting := float(enemy.get("alert_timer", 0.0)) > 0.0
		var move_intent := 0
		var desired_flying_velocity := Vector2.ZERO
		var vertical_attack_tolerance := maxf(28.0, size.y * 1.25)
		var can_begin_attack := can_attack_player and player_distance <= attack_range
		if not flying and _enemy_attack_kind(enemy_type, int(enemy.get("attack_index", 1))) in ["melee", "dash", "roll", "slam", "whip"]:
			can_begin_attack = can_begin_attack and absf(target_player_position.y - pos.y) <= vertical_attack_tolerance

		if alerting:
			vel = vel.move_toward(Vector2.ZERO, speed * 7.0 * delta)
		elif stunned:
			enemy["roll_active"] = false
			enemy["roll_time"] = 0.0
			vel.x = move_toward(vel.x, 0.0, speed * 3.0 * delta)
		elif attack_windup > 0.0:
			attack_windup = maxf(0.0, attack_windup - delta)
			var active_attack_index := int(enemy.get("attack_index", 1))
			if enemy_type in ["root_crawler", "cave_worm"] and active_attack_index == 3:
				pos = _update_enemy_burrow_windup(enemy, pos, attack_windup)
			if enemy_type == "cave_worm" and active_attack_index == 2:
				_update_cave_worm_roll_windup(enemy, pos, attack_windup)
			if not bool(enemy.get("roll_active", false)):
				vel.x = move_toward(vel.x, 0.0, speed * 7.0 * delta)
			if attack_windup <= 0.0:
				var attack_state := "attack_%d" % int(enemy.get("attack_index", 1))
				var has_authored_attack := not _enemy_animation_spec(enemy_type, attack_state).is_empty()
				enemy["attack_flash"] = _enemy_attack_recovery(enemy_type, int(enemy.get("attack_index", 1))) if has_authored_attack else 0.16
				enemy["attack_cooldown"] = 1.10 if flying else 0.95
				if enemy_type == "heartwood_boss" and bool(enemy.get("phase_two", false)):
					enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) * 0.72
				vel += _execute_enemy_attack(enemy, pos, facing, player_distance, attack_range, target_player_position)
		else:
			if float(enemy.get("attack_cooldown", 0.0)) <= 0.0 and can_begin_attack:
				var next_attack := _choose_enemy_attack_index(enemy)
				enemy["attack_index"] = next_attack
				attack_windup = _enemy_attack_windup(str(enemy.get("type", "")), next_attack, windup_duration)
				enemy["attack_total"] = attack_windup
				vel.x = 0.0
				if enemy_type in ["root_crawler", "cave_worm"] and next_attack == 3:
					_prepare_enemy_burrow(enemy, pos, size)
				if enemy_type == "cave_worm" and next_attack == 2:
					_prepare_cave_worm_roll(enemy)
			else:
				if flying and has_move_target:
					var hover_offset := attack_range * 0.72 if can_attack_player else 0.0
					if enemy_type == "bat" and can_attack_player:
						hover_offset = 58.0
					elif enemy_type == "spore_bat" and can_attack_player:
						hover_offset = 40.0
					var hover_target := target_position + Vector2(float(-facing) * hover_offset, sin(float(Time.get_ticks_msec()) / 260.0 + float(enemy.get("anim_offset", 0.0))) * 12.0)
					var desired := hover_target - pos
					desired_flying_velocity = desired.normalized() * speed if desired.length() > 3.0 else Vector2.ZERO
				else:
					var stopping_distance := attack_range * 0.72 if can_attack_player else 12.0
					move_intent = facing if has_move_target and distance > stopping_distance else 0

		var bat_dive_phase := str(enemy.get("dive_phase", ""))
		var bat_diving := enemy_type == "bat" and bat_dive_phase != ""
		var cave_worm_rolling := enemy_type == "cave_worm" and bool(enemy.get("roll_active", false)) and (attack_windup > 0.0 or float(enemy.get("roll_time", 0.0)) > 0.0)
		if not flying and not stunned and not alerting and attack_windup <= 0.0 and not cave_worm_rolling:
			var avoid_direction := int(enemy.get("avoid_direction", 0))
			if float(enemy.get("avoid_timer", 0.0)) > 0.0 and avoid_direction != 0:
				move_intent = avoid_direction
			var movement_on_floor := _enemy_on_floor(pos, size)
			var desired_x := float(move_intent) * speed
			var movement_control := 1.0 if movement_on_floor else float(movement_profile.get("air_control", 0.12))
			var acceleration := float(movement_profile.get("acceleration", 6.0))
			vel.x = move_toward(vel.x, desired_x, speed * acceleration * movement_control * delta)
		if cave_worm_rolling and not stunned:
			vel.x = float(int(enemy.get("roll_direction", enemy.get("facing", 1)))) * 245.0
		elif enemy_type == "cave_worm" and bool(enemy.get("roll_active", false)):
			enemy["roll_active"] = false

		var burrow_hidden := bool(enemy.get("burrow_hidden", false))
		if burrow_hidden:
			vel = Vector2.ZERO
		elif not flying:
			var on_floor := _enemy_on_floor(pos, size)
			if on_floor and vel.y > 0.0:
				vel.y = 0.0
			if enemy_type == "wild_slime" and not stunned and attack_windup <= 0.0 and move_intent != 0 and on_floor and float(enemy.get("hop_timer", 0.0)) <= 0.0:
				vel.y = float(movement_profile.get("hop_speed", -285.0))
				vel.x = float(move_intent) * speed * 1.12
				enemy["hop_timer"] = float(movement_profile.get("hop_interval", 0.72))
			elif not stunned and not alerting and attack_windup <= 0.0 and move_intent != 0 and on_floor and bool(movement_profile.get("navigation_jump", true)) and float(enemy.get("jump_cooldown", 0.0)) <= 0.0:
				var blocked_ahead := _enemy_wall_ahead(pos, size, move_intent)
				if blocked_ahead and not _enemy_can_step_up(pos, size, move_intent):
					vel.y = float(movement_profile.get("jump_speed", -285.0))
					enemy["jump_cooldown"] = float(movement_profile.get("jump_interval", 1.10))
			vel.y += GRAVITY * delta
			pos = _move_enemy(pos, vel * delta, size)
			if on_floor and vel.y >= 0.0 and str(movement_profile.get("locomotion", "walk")) != "hop":
				pos = _enemy_snap_to_ground(pos, size, float(movement_profile.get("ground_snap", 6.0)))
			if _enemy_on_floor(pos, size) and vel.y > 0.0:
				vel.y = 0.0
			var expected_motion := move_intent != 0 and attack_windup <= 0.0 and not stunned
			var made_progress := absf(old_pos.x - pos.x) > maxf(0.25, speed * delta * 0.12)
			var stuck_time := float(enemy.get("stuck_time", 0.0))
			stuck_time = maxf(0.0, stuck_time - delta * 2.0) if not expected_motion or made_progress else stuck_time + delta
			if stuck_time > float(movement_profile.get("stuck_turn_time", 0.62)) and _enemy_on_floor(pos, size):
				enemy["avoid_direction"] = -facing
				enemy["avoid_timer"] = float(movement_profile.get("avoid_time", 0.72))
				stuck_time = 0.0
			enemy["stuck_time"] = stuck_time
		else:
			if bat_diving:
				var dive_direction: Vector2 = enemy.get("dive_direction", Vector2(float(facing), 0.65))
				if dive_direction.length_squared() < 0.01:
					dive_direction = Vector2(float(facing), 0.65).normalized()
				if bat_dive_phase == "loop":
					vel = dive_direction * 285.0
					var dive_start_pos := pos
					pos = _move_flying_enemy(pos, vel * delta, size)
					var player_rect := Rect2(target_player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
					var dive_rect := Rect2(pos - Vector2(18.0, 16.0), Vector2(36.0, 32.0))
					if not bool(enemy.get("dive_hit", false)) and dive_rect.intersects(player_rect):
						_enemy_hit_player(enemy, facing)
						enemy["dive_hit"] = true
					var dive_blocked := dive_start_pos.distance_to(pos) < maxf(0.1, vel.length() * delta * 0.20)
					if float(enemy.get("dive_timer", 0.0)) <= 0.0 or dive_blocked:
						bat_dive_phase = "recover"
						enemy["dive_phase"] = bat_dive_phase
						enemy["dive_timer"] = _enemy_animation_duration("bat", "dive_recover", 0.50)
						vel = Vector2(-dive_direction.x * 55.0, -145.0)
				else:
					var recover_velocity := Vector2(-dive_direction.x * 42.0, -105.0)
					vel = vel.move_toward(recover_velocity, speed * 6.0 * delta)
					pos = _move_flying_enemy(pos, vel * delta, size)
					if float(enemy.get("dive_timer", 0.0)) <= 0.0:
						enemy["dive_phase"] = ""
						enemy["dive_hit"] = false
						vel *= 0.35
			elif not stunned and not alerting and attack_windup <= 0.0:
				desired_flying_velocity += _enemy_flying_avoidance(pos, size, desired_flying_velocity, target_player_position) * speed
				vel = vel.move_toward(desired_flying_velocity.limit_length(speed), speed * 4.5 * delta)
			else:
				vel = vel.move_toward(Vector2.ZERO, speed * 5.0 * delta)
			if not bat_diving:
				pos = _move_flying_enemy(pos, vel * delta, size)
			var flying_progress := old_pos.distance_to(pos)
			if desired_flying_velocity.length_squared() > 25.0 and flying_progress < 0.2:
				var flying_stuck := float(enemy.get("stuck_time", 0.0)) + delta
				if flying_stuck > 0.35:
					vel.y += (-1.0 if target_position.y <= pos.y else 1.0) * speed * 0.85
					vel.x *= -0.45
					flying_stuck = 0.0
				enemy["stuck_time"] = flying_stuck
			else:
				enemy["stuck_time"] = maxf(0.0, float(enemy.get("stuck_time", 0.0)) - delta * 2.0)

		if not burrow_hidden and not _enemy_position_valid(pos, size):
			pos = _recover_enemy_position(pos, size, last_safe_pos)
			vel = Vector2.ZERO
		elif not burrow_hidden and (flying or _enemy_on_floor(pos, size)):
			enemy["last_safe_pos"] = pos
		enemy["attack_windup"] = attack_windup
		var next_anim_state := "idle"
		var current_attack_state := "attack_%d" % int(enemy.get("attack_index", 1))
		var playing_authored_attack := not _enemy_animation_spec(enemy_type, current_attack_state).is_empty() and (attack_windup > 0.0 or float(enemy.get("attack_flash", 0.0)) > 0.0)
		if enemy_type == "bat" and str(enemy.get("dive_phase", "")) == "loop":
			next_anim_state = "dive_loop"
		elif enemy_type == "bat" and str(enemy.get("dive_phase", "")) == "recover":
			next_anim_state = "dive_recover"
		elif playing_authored_attack:
			next_anim_state = "attack_%d" % int(enemy.get("attack_index", 1))
		elif float(enemy.get("hit_timer", 0.0)) > 0.0:
			next_anim_state = "hurt"
		elif stunned and not _enemy_animation_spec(enemy_type, "stunned").is_empty():
			next_anim_state = "stunned"
		elif alerting and not _enemy_animation_spec(enemy_type, "alert").is_empty():
			next_anim_state = "alert"
		elif attack_windup > 0.0 or float(enemy.get("attack_flash", 0.0)) > 0.0:
			next_anim_state = "attack_%d" % int(enemy.get("attack_index", 1))
		elif vel.length_squared() > 100.0:
			next_anim_state = "move"
		if next_anim_state != str(enemy.get("anim_state", "idle")):
			enemy["anim_state"] = next_anim_state
			enemy["anim_time"] = 0.0
		else:
			enemy["anim_time"] = float(enemy.get("anim_time", 0.0)) + delta
		enemy["pos"] = pos
		enemy["vel"] = vel
		if int(enemy.get("hp", 1)) <= 0:
			_kill_enemy(i)


func _prepare_enemy_burrow(enemy: Dictionary, pos: Vector2, size: Vector2) -> void:
	var target := _find_spawn_position_near_player(2, 3, false, size)
	if not _enemy_position_valid(target, size):
		target = pos
	enemy["burrow_origin"] = pos
	enemy["burrow_target"] = target
	enemy["burrow_hidden"] = false
	enemy["burrow_dust_started"] = false


func _prepare_root_crawler_burrow(enemy: Dictionary, pos: Vector2, size: Vector2) -> void:
	_prepare_enemy_burrow(enemy, pos, size)


func _update_enemy_burrow_windup(enemy: Dictionary, pos: Vector2, remaining: float) -> Vector2:
	var enemy_type := str(enemy.get("type", "root_crawler"))
	var total := maxf(0.01, float(enemy.get("attack_total", 1.0)))
	var elapsed := maxf(0.0, total - remaining)
	var hide_time := _enemy_animation_event_time(enemy_type, "attack_3", "burrow_start_frames", total * 0.43)
	if elapsed < hide_time:
		return pos
	var origin: Vector2 = enemy.get("burrow_origin", pos)
	var target: Vector2 = enemy.get("burrow_target", pos)
	if not bool(enemy.get("burrow_dust_started", false)):
		var size: Vector2 = enemy.get("size", Vector2(22, 12))
		var effect_scale := 0.56 if enemy_type == "cave_worm" else 0.48
		_spawn_enemy_impact(origin + Vector2(0.0, size.y * 0.5), enemy_type, "burrow_dust", int(enemy.get("facing", 1)), true, effect_scale)
		enemy["burrow_dust_started"] = true
	enemy["burrow_hidden"] = true
	var travel_ratio := clampf((elapsed - hide_time) / maxf(0.01, total - hide_time), 0.0, 1.0)
	return origin.lerp(target, smoothstep(0.0, 1.0, travel_ratio))


func _update_root_crawler_burrow_windup(enemy: Dictionary, pos: Vector2, remaining: float) -> Vector2:
	return _update_enemy_burrow_windup(enemy, pos, remaining)


func _prepare_cave_worm_roll(enemy: Dictionary) -> void:
	enemy["roll_active"] = false
	enemy["roll_direction"] = int(enemy.get("facing", 1))
	enemy["roll_dust_started"] = false
	enemy["roll_time"] = 0.0


func _update_cave_worm_roll_windup(enemy: Dictionary, pos: Vector2, remaining: float) -> void:
	var total := maxf(0.01, float(enemy.get("attack_total", 10.0 / 14.0)))
	var elapsed := maxf(0.0, total - remaining)
	var roll_start_time := _enemy_animation_event_time("cave_worm", "attack_2", "roll_start_frames", total * 0.90)
	if elapsed < roll_start_time:
		return
	if not bool(enemy.get("roll_dust_started", false)):
		var size: Vector2 = enemy.get("size", Vector2(34, 12))
		_spawn_enemy_impact(pos + Vector2(0.0, size.y * 0.5), "cave_worm", "roll_dust", int(enemy.get("roll_direction", enemy.get("facing", 1))), true, 0.56)
		enemy["roll_dust_started"] = true
	enemy["roll_active"] = true


func _enemy_attack_range(enemy_type: String, size: Vector2, flying: bool) -> float:
	if enemy_type == "bat":
		return 145.0
	if enemy_type == "spore_bat":
		return 92.0
	if enemy_type in ["ash_wisp", "ruin_drone", "glass_wraith", "night_ember", "ash_phantom"]:
		return 150.0
	if enemy_type in ["ash_sentinel", "drowned_guard", "ember_rootling", "cave_husk", "mushroom_beetle"]:
		return 92.0
	if enemy_type == "root_crawler":
		return 44.0
	if enemy_type == "heartwood_boss":
		return 118.0
	return maxf(24.0, size.x * (1.45 if flying else 1.05))


func _enemy_wall_ahead(pos: Vector2, size: Vector2, direction: int) -> bool:
	var probe_x := pos.x + float(direction) * (size.x * 0.5 + 3.0)
	var probe := Rect2(Vector2(probe_x - 1.5, pos.y - size.y * 0.5 + 3.0), Vector2(3.0, maxf(4.0, size.y - 6.0)))
	return _rect_collides(probe)


func _enemy_flying_avoidance(pos: Vector2, size: Vector2, desired_velocity: Vector2, target_player_position: Vector2) -> Vector2:
	if desired_velocity.length_squared() < 1.0:
		return Vector2.ZERO
	var direction := desired_velocity.normalized()
	var forward_pos := pos + direction * (size.length() * 0.45 + 8.0)
	if not _rect_collides(Rect2(forward_pos - size * 0.45, size * 0.9)):
		return Vector2.ZERO
	var perpendicular := Vector2(-direction.y, direction.x)
	var left_clear := not _rect_collides(Rect2(pos + perpendicular * 14.0 - size * 0.45, size * 0.9))
	var right_clear := not _rect_collides(Rect2(pos - perpendicular * 14.0 - size * 0.45, size * 0.9))
	if left_clear and not right_clear:
		return perpendicular
	if right_clear and not left_clear:
		return -perpendicular
	return Vector2(0.0, -1.0 if target_player_position.y <= pos.y else 1.0)

func _update_enemy_deaths(delta: float) -> void:
	for i in range(dying_enemies.size() - 1, -1, -1):
		var corpse: Dictionary = dying_enemies[i]
		var flying_corpse_type := str(corpse.get("type", ""))
		if flying_corpse_type in ["bat", "spore_bat"]:
			var death_phase := str(corpse.get("death_phase", "fall"))
			corpse["death_anim_time"] = float(corpse.get("death_anim_time", 0.0)) + delta
			if death_phase == "fall":
				var corpse_pos: Vector2 = corpse.get("pos", Vector2.ZERO)
				var corpse_size: Vector2 = corpse.get("size", Vector2(22, 14))
				var corpse_velocity: Vector2 = corpse.get("death_velocity", Vector2.ZERO)
				corpse_velocity.y = minf(390.0, corpse_velocity.y + GRAVITY * 0.72 * delta)
				corpse_velocity.x = move_toward(corpse_velocity.x, 0.0, 55.0 * delta)
				var previous_pos := corpse_pos
				corpse_pos = _move_enemy(corpse_pos, corpse_velocity * delta, corpse_size)
				corpse["pos"] = corpse_pos
				corpse["death_velocity"] = corpse_velocity
				var stopped_falling := corpse_pos.distance_to(previous_pos) < maxf(0.08, corpse_velocity.length() * delta * 0.18)
				if _enemy_on_floor(corpse_pos, corpse_size) or (corpse_velocity.y > 20.0 and stopped_falling):
					corpse["death_phase"] = "impact"
					corpse["death_velocity"] = Vector2.ZERO
					if flying_corpse_type == "bat":
						corpse["death_anim_time"] = 0.0
						corpse["death_time"] = _enemy_animation_duration("bat", "death_impact", 0.50)
						_spawn_hit_particles(corpse_pos + Vector2(0.0, corpse_size.y * 0.5), Color("8d8499"), 5)
					else:
						corpse["death_anim_time"] = _enemy_animation_duration("spore_bat", "death", 0.84)
						corpse["death_time"] = _enemy_animation_duration("spore_bat", "death_impact", 0.60)
						_spawn_enemy_impact(corpse_pos + Vector2(0.0, corpse_size.y * 0.5), "spore_bat", "death_impact", int(corpse.get("facing", 1)), false, 0.44)
						_spawn_hit_particles(corpse_pos + Vector2(0.0, corpse_size.y * 0.5), Color("62c6a8"), 6)
				elif float(corpse["death_anim_time"]) >= 4.0:
					dying_enemies.remove_at(i)
					continue
			else:
				corpse["death_time"] = float(corpse.get("death_time", 0.0)) - delta
				if float(corpse["death_time"]) <= 0.0:
					dying_enemies.remove_at(i)
					continue
			dying_enemies[i] = corpse
			continue
		corpse["death_time"] = float(corpse.get("death_time", 0.0)) - delta
		var corpse_type := str(corpse.get("type", ""))
		if corpse_type == "cave_husk" and not bool(corpse.get("death_vfx_spawned", false)):
			var death_elapsed := float(corpse.get("death_total", 0.0)) - float(corpse.get("death_time", 0.0))
			if death_elapsed >= 6.0 / 5.9:
				_spawn_enemy_impact(corpse.get("pos", Vector2.ZERO), "cave_husk", "death_vfx", int(corpse.get("facing", 1)), true, 0.50)
				corpse["death_vfx_spawned"] = true
		elif corpse_type == "ruin_drone" and not bool(corpse.get("death_vfx_spawned", false)):
			var drone_death_elapsed := float(corpse.get("death_total", 0.0)) - float(corpse.get("death_time", 0.0))
			if drone_death_elapsed >= 7.0 / 11.0:
				_spawn_enemy_impact(corpse.get("pos", Vector2.ZERO), "ruin_drone", "death_vfx", int(corpse.get("facing", 1)), true, 0.50)
				corpse["death_vfx_spawned"] = true
		elif corpse_type == "stone_beast" and not bool(corpse.get("death_vfx_spawned", false)):
			var beast_death_elapsed := float(corpse.get("death_total", 0.0)) - float(corpse.get("death_time", 0.0))
			if beast_death_elapsed >= 10.0 / 8.0:
				var beast_size: Vector2 = corpse.get("size", Vector2(42, 30))
				var beast_ground := (corpse.get("pos", Vector2.ZERO) as Vector2) + Vector2(0.0, beast_size.y * 0.5)
				_spawn_enemy_impact(beast_ground, "stone_beast", "death_dust", int(corpse.get("facing", 1)), true, 0.72)
				corpse["death_vfx_spawned"] = true
		if float(corpse["death_time"]) <= 0.0:
			dying_enemies.remove_at(i)
		else:
			dying_enemies[i] = corpse


func _enemy_attack_count(enemy_type: String) -> int:
	if enemy_type == "stone_beast" or enemy_type == "heartwood_boss":
		return 6
	if enemy_type in ["ash_sentinel", "drowned_guard", "glass_wraith"]:
		return 4
	if enemy_type in ["root_crawler", "cave_worm", "bat", "cave_husk", "mushroom_beetle", "ash_phantom", "ruin_drone", "ember_rootling", "night_ember"]:
		return 3
	if enemy_type in ["wild_slime", "mossling", "spore_bat", "ash_wisp"]:
		return 2
	return 1


func _choose_enemy_attack_index(enemy: Dictionary) -> int:
	var count := _enemy_attack_count(str(enemy.get("type", "")))
	var previous := int(enemy.get("attack_index", 0))
	if str(enemy.get("type", "")) == "bat":
		var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		if pos.distance_to(player_position) <= 44.0 and previous != 1:
			return 1
		return 3 if previous == 2 else 2
	if str(enemy.get("type", "")) == "spore_bat":
		var spore_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		if spore_pos.distance_to(player_position) <= 44.0 and previous != 1:
			return 1
		return 2
	return previous % count + 1


func _enemy_attack_windup(enemy_type: String, attack_index: int, default_time: float) -> float:
	var state := "attack_%d" % attack_index
	var animation_spec := _enemy_animation_spec(enemy_type, state)
	if not animation_spec.is_empty():
		var event_key := _enemy_animation_attack_event_key(animation_spec)
		return _enemy_animation_event_time(enemy_type, state, event_key, default_time)
	if enemy_type == "mossling" and attack_index == 2:
		return 0.60
	if enemy_type == "root_crawler" and attack_index == 3:
		return 0.75
	if enemy_type == "cave_worm" and attack_index == 3:
		return 0.90
	if enemy_type == "bat" and attack_index == 2:
		return 0.50
	if enemy_type == "cave_husk" and attack_index == 3:
		return 0.65
	if enemy_type == "spore_bat" and attack_index == 2:
		return 0.55
	if enemy_type == "mushroom_beetle" and attack_index == 2:
		return 0.70
	if enemy_type == "ash_phantom" and attack_index == 1:
		return 0.55
	if enemy_type == "ash_wisp" and attack_index == 2:
		return 0.80
	if enemy_type == "ash_sentinel" and attack_index == 4:
		return 0.55
	if enemy_type == "ruin_drone" and attack_index == 2:
		return 0.80
	if enemy_type == "drowned_guard" and attack_index == 2:
		return 0.55
	if enemy_type == "drowned_guard" and attack_index == 3:
		return 0.60
	if enemy_type == "ember_rootling" and attack_index == 3:
		return 0.70
	if enemy_type == "night_ember" and attack_index == 3:
		return 1.20
	if enemy_type == "glass_wraith" and attack_index in [3, 4]:
		return 0.80
	if enemy_type == "stone_beast" and attack_index in [3, 4, 5]:
		return 0.75
	if enemy_type == "stone_beast" and attack_index == 6:
		return 0.60
	if enemy_type == "heartwood_boss" and attack_index in [2, 4, 5, 6]:
		return 0.75
	return default_time


func _enemy_attack_kind(enemy_type: String, attack_index := 1) -> String:
	if enemy_type == "wild_slime":
		return "dash" if attack_index == 1 else "burst"
	if enemy_type == "mossling":
		return "melee" if attack_index == 1 else "dash"
	if enemy_type == "root_crawler":
		return "melee" if attack_index == 1 else ("whip" if attack_index == 2 else "burrow")
	if enemy_type == "cave_worm":
		return "melee" if attack_index == 1 else ("roll" if attack_index == 2 else "burrow")
	if enemy_type == "bat":
		return "bite" if attack_index == 1 else ("pulse" if attack_index == 2 else "dive")
	if enemy_type == "cave_husk":
		return "reach" if attack_index == 1 else ("rock_throw" if attack_index == 2 else "slam")
	if enemy_type == "spore_bat":
		return "bite" if attack_index == 1 else "spore_burst"
	if enemy_type == "mushroom_beetle":
		return "bite" if attack_index == 1 else ("dash" if attack_index == 2 else "projectile")
	if enemy_type == "ash_phantom":
		return "claw" if attack_index == 1 else ("phase_dash" if attack_index == 2 else "projectile")
	if enemy_type == "ash_wisp":
		return "projectile" if attack_index == 1 else "burst"
	if enemy_type == "ash_sentinel":
		return "melee" if attack_index == 1 else ("slam" if attack_index == 2 else ("projectile" if attack_index == 3 else "guard"))
	if enemy_type == "ruin_drone":
		return "projectile" if attack_index == 1 else ("laser" if attack_index == 2 else "pulse")
	if enemy_type == "drowned_guard":
		return "melee" if attack_index == 1 else ("harpoon" if attack_index == 2 else ("wave" if attack_index == 3 else "guard"))
	if enemy_type == "ember_rootling":
		return "melee" if attack_index == 1 else ("projectile" if attack_index == 2 else "rootburst")
	if enemy_type == "night_ember":
		return "dash" if attack_index == 1 else ("triple" if attack_index == 2 else "burst")
	if enemy_type == "glass_wraith":
		return "shardfan" if attack_index == 1 else ("teleport_slash" if attack_index == 2 else ("laser" if attack_index == 3 else "cage"))
	if enemy_type == "stone_beast":
		return ["melee", "dash", "shockwave", "rockfall", "spikes", "guard"][attack_index - 1]
	if enemy_type == "heartwood_boss":
		return ["melee", "rootburst", "seed", "summon", "flowers", "heal"][attack_index - 1]
	return "melee"


func _execute_enemy_attack(enemy: Dictionary, pos: Vector2, facing: int, distance: float, attack_range: float, target_player_position := Vector2.ZERO) -> Vector2:
	if target_player_position == Vector2.ZERO:
		target_player_position = player_position
	var enemy_type := str(enemy.get("type", ""))
	var attack_index := int(enemy.get("attack_index", 1))
	var kind := _enemy_attack_kind(enemy_type, attack_index)
	var raw_damage := int(enemy.get("damage", 1))
	if kind == "bite":
		if distance <= 44.0:
			_enemy_hit_player(enemy, facing)
		return Vector2.ZERO
	if kind == "claw":
		var claw_pos := pos + Vector2(float(facing) * 22.0, -4.0)
		_spawn_enemy_impact(claw_pos, "ash_phantom", "slash_vfx", facing, false, 0.50)
		if distance <= 48.0:
			_enemy_hit_player(enemy, facing, "burn")
		return Vector2.ZERO
	if kind == "phase_dash":
		_spawn_enemy_impact(pos - Vector2(float(facing) * 12.0, 0.0), "ash_phantom", "dash_vfx", facing, false, 0.50)
		if distance <= 72.0:
			_enemy_hit_player(enemy, facing, "burn")
		var phase_direction := (target_player_position - pos).normalized()
		if phase_direction.length_squared() < 0.01:
			phase_direction = Vector2(float(facing), 0.0)
		_emit_noise(pos, 120.0, "phantom_dash", 0.85)
		return phase_direction * 230.0
	if kind == "dive":
		var dive_direction := (target_player_position + Vector2(0.0, 10.0) - pos).normalized()
		if dive_direction.length_squared() < 0.01:
			dive_direction = Vector2(float(facing), 0.65).normalized()
		enemy["dive_phase"] = "loop"
		enemy["dive_timer"] = 0.42
		enemy["dive_direction"] = dive_direction
		enemy["dive_hit"] = false
		enemy["attack_flash"] = 0.42 + _enemy_animation_duration("bat", "dive_recover", 0.50)
		_emit_noise(pos, 105.0, "bat_dive", 0.75)
		return Vector2.ZERO
	if kind == "spore_burst":
		_spawn_enemy_impact(pos, "spore_bat", "spore_cloud", facing, false, 0.44)
		if distance <= 52.0:
			_enemy_hit_player(enemy, facing, "poison")
		_emit_noise(pos, 135.0, "spore_burst", 0.90)
		return Vector2.ZERO
	if kind == "burst":
		var burst_color := Color("9ce36d")
		var burst_type := "poison"
		var burst_status := "poison"
		var burst_count := 6
		if enemy_type == "ash_phantom" or enemy_type == "ash_wisp" or enemy_type == "night_ember":
			burst_color = Color("ff8a45")
			burst_type = "fire"
			burst_status = "burn"
		elif enemy_type == "spore_bat":
			burst_count = 5
		for burst_index in range(burst_count):
			var burst_dir := Vector2.RIGHT.rotated(float(burst_index) * TAU / float(burst_count))
			var applied_status := burst_status
			if enemy_type == "wild_slime" and rng.randf() >= 0.25:
				applied_status = ""
			var special := "wild_ichor" if enemy_type == "wild_slime" else ""
			_spawn_enemy_projectile(pos + burst_dir * 8.0, burst_dir * 150.0, raw_damage, burst_color, burst_type, applied_status, special)
		if enemy_type == "ash_wisp":
			_spawn_enemy_impact(pos, "ash_wisp", "burst_vfx", facing, true, 0.44)
		elif enemy_type == "night_ember":
			_spawn_enemy_impact(pos, "night_ember", "burst_vfx", facing, true, 0.44)
		return Vector2.ZERO
	if kind == "whip":
		var whip_impact_pos := pos + Vector2(float(facing) * 34.0, 5.0)
		_spawn_enemy_impact(whip_impact_pos, "root_crawler", "whip_impact", facing, true, 0.48)
		if distance <= 52.0:
			_enemy_hit_player(enemy, facing, "root_bind")
		return Vector2.ZERO
	if kind == "burrow":
		enemy["burrow_hidden"] = false
		enemy["burrow_dust_started"] = false
		enemy["pos"] = pos
		var burrower_size: Vector2 = enemy.get("size", Vector2(22, 12))
		var emerge_facing := 1 if target_player_position.x >= pos.x else -1
		enemy["facing"] = emerge_facing
		var effect_scale := 0.56 if enemy_type == "cave_worm" else 0.52
		_spawn_enemy_impact(pos + Vector2(0.0, burrower_size.y * 0.5), enemy_type, "burrow_dust", emerge_facing, true, effect_scale)
		if pos.distance_to(target_player_position) <= 72.0:
			_enemy_hit_player(enemy, emerge_facing, "root_bind" if enemy_type == "root_crawler" else "slow")
		return Vector2.ZERO
	if kind == "pulse":
		var pulse_range := 82.0 if enemy_type == "bat" else 68.0
		if enemy_type == "ruin_drone":
			_spawn_enemy_impact(pos, "ruin_drone", "pulse_vfx", facing, true, 0.50)
		if distance <= pulse_range:
			_enemy_hit_player(enemy, facing)
			player_velocity += Vector2(float(facing) * 150.0, -25.0)
		if enemy_type == "bat":
			_emit_noise(pos, 205.0, "sonic_pulse", 1.20)
			_play_sound("shoot")
		return Vector2.ZERO
	if kind == "slam":
		if enemy_type == "cave_husk":
			_spawn_enemy_impact(pos, "cave_husk", "slam_vfx", facing, true, 0.50)
		elif enemy_type == "ash_sentinel":
			var sentinel_ground: Vector2 = pos + Vector2(0.0, float((enemy.get("size", Vector2(24, 28)) as Vector2).y) * 0.5)
			_spawn_enemy_impact(sentinel_ground, "ash_sentinel", "ground_cracks", facing, true, 0.50)
			_spawn_enemy_impact(sentinel_ground, "ash_sentinel", "slam_vfx", facing, true, 0.50)
		if distance <= 42.0:
			_enemy_hit_player(enemy, facing, "armor_break")
		return Vector2.ZERO
	if kind == "reach":
		var reach_center := pos + Vector2(float(facing) * 38.0, -8.0)
		var reach_rect := Rect2(reach_center - Vector2(36.0, 19.0), Vector2(72.0, 38.0))
		var player_rect := Rect2(target_player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
		if reach_rect.intersects(player_rect):
			_enemy_hit_player(enemy, facing)
		return Vector2.ZERO
	if kind == "rock_throw":
		var throw_spec := _enemy_animation_spec("cave_husk", "attack_2")
		var spawn_data: Array = throw_spec.get("projectile_spawn", [112, 46])
		var spawn_local := Vector2(float(spawn_data[0]) - 80.0, float(spawn_data[1]) - 89.0) * _enemy_sprite_scale("cave_husk")
		spawn_local.x *= float(facing)
		var rock_spawn := pos + spawn_local
		var rock_direction := (target_player_position - rock_spawn).normalized()
		if rock_direction.length_squared() < 0.01:
			rock_direction = Vector2(float(facing), -0.12).normalized()
		var rock_velocity := rock_direction * 205.0
		rock_velocity.y = minf(rock_velocity.y - 38.0, -55.0)
		_spawn_enemy_projectile(rock_spawn, rock_velocity, raw_damage, Color("9b8a6f"), "physical", "slow", "cave_husk_rock")
		_emit_noise(rock_spawn, 125.0, "rock_throw", 0.85)
		return Vector2.ZERO
	if kind == "guard":
		enemy["guard_time"] = 1.35
		return Vector2.ZERO
	if kind == "harpoon":
		var harpoon_spec := _enemy_animation_spec("drowned_guard", "attack_2")
		var harpoon_spawn_data: Array = harpoon_spec.get("projectile_spawn", [118, 52])
		var harpoon_anchor := _enemy_animation_anchor("drowned_guard", Vector2(160, 128))
		var harpoon_local := (Vector2(float(harpoon_spawn_data[0]), float(harpoon_spawn_data[1])) - harpoon_anchor) * _enemy_sprite_scale("drowned_guard")
		harpoon_local.x *= float(facing)
		var harpoon_pos := pos + harpoon_local
		var harpoon_dir := (target_player_position - harpoon_pos).normalized()
		if harpoon_dir.length_squared() < 0.01:
			harpoon_dir = Vector2(float(facing), 0.0)
		_spawn_enemy_projectile(harpoon_pos, harpoon_dir * 130.0, raw_damage, Color("86c8d0"), "physical", "slow", "drowned_harpoon")
		return Vector2.ZERO
	if kind == "wave":
		var wave_dir := Vector2(float(facing), 0)
		var guard_size: Vector2 = enemy.get("size", Vector2(24, 28))
		var wave_pos := pos + Vector2(float(facing) * 18.0, guard_size.y * 0.5)
		_spawn_enemy_projectile(wave_pos, wave_dir * 70.0, raw_damage, Color("62b8ca"), "physical", "wet", "drowned_wave")
		return Vector2.ZERO
	if kind == "rootburst":
		if enemy_type == "ember_rootling":
			var root_target_ground := target_player_position + Vector2(0.0, PLAYER_SIZE.y * 0.5)
			_spawn_enemy_impact(root_target_ground, "ember_rootling", "root_burst_vfx", facing, true, 0.50)
		if distance <= 64.0:
			_enemy_hit_player(enemy, facing, "root_bind" if enemy_type == "heartwood_boss" else "burn")
			if enemy_type != "heartwood_boss":
				_apply_player_status("root_bind")
		return Vector2.ZERO
	if kind == "triple":
		var triple_spec := _enemy_animation_spec("night_ember", "attack_2")
		var triple_spawn_data: Array = triple_spec.get("projectile_spawn", [73, 48])
		var triple_anchor := _enemy_animation_anchor("night_ember", Vector2(96, 96))
		var triple_local := (Vector2(float(triple_spawn_data[0]), float(triple_spawn_data[1])) - triple_anchor) * _enemy_sprite_scale("night_ember")
		triple_local.x *= float(facing)
		var triple_pos := pos + triple_local
		var triple_fan: Array = triple_spec.get("projectile_fan_degrees", [-30, 0, 30])
		for triple_angle in triple_fan:
			var flame_dir := Vector2(float(facing), 0).rotated(deg_to_rad(float(triple_angle)) * float(facing))
			_spawn_enemy_projectile(triple_pos, flame_dir * 150.0, raw_damage, Color("ff8a45"), "fire", "burn", "night_fire")
		return Vector2.ZERO
	if kind == "seed":
		var seed_dir := (target_player_position - pos).normalized()
		_spawn_enemy_projectile(pos + seed_dir * 14.0, seed_dir * 175.0, raw_damage, Color("c790d3"), "physical", "slow", "seed")
		return Vector2.ZERO
	if kind == "summon":
		var mossling_spawn_size: Vector2 = _enemy_template("mossling").get("size", Vector2(22, 16))
		for summon_index in range(2):
			var summon_pos := _find_spawn_position_near_player(7 + summon_index * 2, 10 + summon_index * 2, false, mossling_spawn_size)
			_spawn_enemy("mossling", summon_pos)
		return Vector2.ZERO
	if kind == "flowers":
		for flower_index in range(5):
			var flower_dir := Vector2.RIGHT.rotated(float(flower_index) * TAU / 5.0)
			_spawn_enemy_projectile(pos + flower_dir * 10.0, flower_dir * 115.0, raw_damage, Color("9ce36d"), "poison", "poison", "flower")
		return Vector2.ZERO
	if kind == "heal":
		var maximum_hp := int(enemy.get("max_hp", 1))
		enemy["hp"] = mini(maximum_hp, int(enemy.get("hp", 1)) + int(ceil(float(maximum_hp) * 0.12)))
		_spawn_hit_particles(pos, Color("8fdb82"), 9)
		return Vector2.ZERO
	if kind == "shardfan":
		var shard_spec := _enemy_animation_spec("glass_wraith", "attack_1")
		var shard_spawn_data: Array = shard_spec.get("projectile_spawn", [96, 76])
		var shard_anchor := _enemy_animation_anchor("glass_wraith", Vector2(144, 160))
		var shard_local := (Vector2(float(shard_spawn_data[0]), float(shard_spawn_data[1])) - shard_anchor) * _enemy_sprite_scale("glass_wraith")
		shard_local.x *= float(facing)
		var shard_pos := pos + shard_local
		var fan_degrees: Array = shard_spec.get("projectile_fan_degrees", [-52, -26, 0, 26, 52])
		for fan_degrees_value in fan_degrees:
			var shard_dir := Vector2(float(facing), 0).rotated(deg_to_rad(float(fan_degrees_value)) * float(facing))
			_spawn_enemy_projectile(shard_pos, shard_dir * 145.0, raw_damage, Color("b8f4ff"), "physical", "fragile", "glass_shard")
		return Vector2.ZERO
	if kind == "teleport_slash":
		var arrival_pos := target_player_position - Vector2(float(facing) * 22.0, 0.0)
		_spawn_enemy_impact(pos, "glass_wraith", "teleport_vfx", facing, true, 0.50)
		_spawn_enemy_impact(arrival_pos, "glass_wraith", "teleport_vfx", -facing, true, 0.50)
		_spawn_enemy_impact(arrival_pos, "glass_wraith", "slash_vfx", facing, true, 0.50)
		if distance <= 68.0:
			_enemy_hit_player(enemy, facing, "fragile")
		return Vector2(float(facing) * 230.0, -35.0)
	if kind == "cage":
		_spawn_enemy_impact(target_player_position, "glass_wraith", "cage_vfx", facing, true, 0.50)
		if distance <= 88.0:
			_enemy_hit_player(enemy, facing, "root_bind")
		return Vector2.ZERO
	if kind == "shockwave":
		if enemy_type == "stone_beast":
			var beast_ground := pos + Vector2(0.0, float((enemy.get("size", Vector2(42, 30)) as Vector2).y) * 0.5)
			_spawn_enemy_impact(beast_ground, "stone_beast", "shockwave_vfx", facing, true, 0.72)
		if distance <= 80.0:
			_enemy_hit_player(enemy, facing, "slow")
		return Vector2.ZERO
	if kind == "rockfall":
		for offset in [-32.0, 0.0, 32.0]:
			var rock_target := target_player_position + Vector2(offset, -70.0)
			_spawn_enemy_projectile(rock_target, Vector2(0, 130.0), raw_damage, Color("a9a49a"), "physical", "slow", "stone_falling_rock")
		return Vector2.ZERO
	if kind == "spikes":
		if enemy_type == "stone_beast":
			var spikes_ground := target_player_position + Vector2(0.0, PLAYER_SIZE.y * 0.5)
			_spawn_enemy_impact(spikes_ground, "stone_beast", "spikes_vfx", facing, true, 0.72)
		if distance <= 96.0:
			_enemy_hit_player(enemy, facing, "slow")
		return Vector2.ZERO
	if kind == "projectile" or kind == "laser":
		if enemy_type == "glass_wraith" and kind == "laser":
			var beam_origin := pos + Vector2(float(facing) * 18.0, -2.0)
			_spawn_enemy_impact(beam_origin, "glass_wraith", "laser_beam", facing, true, 0.50)
			if distance <= 160.0:
				_enemy_hit_player(enemy, facing, "fragile")
			return Vector2.ZERO
		if enemy_type == "ruin_drone" and kind == "laser":
			var drone_beam_origin := pos + Vector2(float(facing) * 17.0, 0.0)
			_spawn_enemy_impact(drone_beam_origin, "ruin_drone", "laser_beam", facing, true, 0.50)
			if distance <= 160.0:
				_enemy_hit_player(enemy, facing, "slow")
			return Vector2.ZERO
		var direction := (target_player_position - pos).normalized()
		if direction.length() < 0.1:
			direction = Vector2(float(facing), 0)
		var color := Color("9fd6e7")
		var status := str(enemy.get("status_on_hit", ""))
		var speed := 180.0
		if enemy_type == "ember_rootling" or enemy_type == "night_ember":
			color = Color("ff8a45")
			status = "burn"
		elif enemy_type == "ash_wisp" or enemy_type == "ash_sentinel":
			color = Color("b79cff")
		elif enemy_type == "ash_phantom":
			color = Color("ff9c68")
			status = "burn"
		elif enemy_type == "mushroom_beetle":
			color = Color("9ce36d")
			status = "poison"
		elif enemy_type == "spore_bat":
			color = Color("9ce36d")
			status = "poison"
		elif enemy_type == "glass_wraith":
			color = Color("aef7ff")
			status = "slow"
		elif enemy_type == "ruin_drone":
			color = Color("ffe09a")
			status = ""
		elif enemy_type == "heartwood_boss":
			color = Color("d96a94")
			speed = 220.0
		if kind == "laser":
			color = Color("b8f4ff")
			speed = 310.0
			raw_damage = int(ceil(float(raw_damage) * 1.6))
		var projectile_pos := pos + direction * 12.0
		var projectile_special := ""
		if enemy_type == "mushroom_beetle":
			var beetle_spec := _enemy_animation_spec("mushroom_beetle", "attack_3")
			var beetle_spawn: Array = beetle_spec.get("projectile_spawn", [120, 70])
			var beetle_anchor := _enemy_animation_anchor("mushroom_beetle", Vector2(128, 96))
			var beetle_local := (Vector2(float(beetle_spawn[0]), float(beetle_spawn[1])) - beetle_anchor) * _enemy_sprite_scale("mushroom_beetle")
			beetle_local.x *= float(facing)
			projectile_pos = pos + beetle_local
			projectile_special = "mushroom_poison"
			speed = 145.0
		elif enemy_type == "ash_phantom":
			var phantom_spec := _enemy_animation_spec("ash_phantom", "attack_3")
			var phantom_spawn: Array = phantom_spec.get("projectile_spawn", [108, 42])
			var phantom_anchor := _enemy_animation_anchor("ash_phantom", Vector2(128, 128))
			var phantom_local := (Vector2(float(phantom_spawn[0]), float(phantom_spawn[1])) - phantom_anchor) * _enemy_sprite_scale("ash_phantom")
			phantom_local.x *= float(facing)
			projectile_pos = pos + phantom_local
			projectile_special = "ash_phantom_ember"
			speed = 190.0
		elif enemy_type == "ash_wisp":
			var wisp_spec := _enemy_animation_spec("ash_wisp", "attack_1")
			var wisp_spawn: Array = wisp_spec.get("projectile_spawn", [72, 48])
			var wisp_anchor := _enemy_animation_anchor("ash_wisp", Vector2(96, 96))
			var wisp_local := (Vector2(float(wisp_spawn[0]), float(wisp_spawn[1])) - wisp_anchor) * _enemy_sprite_scale("ash_wisp")
			wisp_local.x *= float(facing)
			projectile_pos = pos + wisp_local
			projectile_special = "ash_wisp_ember"
			speed = 120.0
		elif enemy_type == "ash_sentinel":
			var sentinel_spec := _enemy_animation_spec("ash_sentinel", "attack_3")
			var sentinel_spawn: Array = sentinel_spec.get("projectile_spawn", [115, 49])
			var sentinel_anchor := _enemy_animation_anchor("ash_sentinel", Vector2(160, 128))
			var sentinel_local := (Vector2(float(sentinel_spawn[0]), float(sentinel_spawn[1])) - sentinel_anchor) * _enemy_sprite_scale("ash_sentinel")
			sentinel_local.x *= float(facing)
			projectile_pos = pos + sentinel_local
			projectile_special = "sentinel_ash"
			speed = 95.0
		elif enemy_type == "ember_rootling":
			var rootling_spec := _enemy_animation_spec("ember_rootling", "attack_2")
			var rootling_spawn: Array = rootling_spec.get("projectile_spawn", [106, 47])
			var rootling_anchor := _enemy_animation_anchor("ember_rootling", Vector2(144, 112))
			var rootling_local := (Vector2(float(rootling_spawn[0]), float(rootling_spawn[1])) - rootling_anchor) * _enemy_sprite_scale("ember_rootling")
			rootling_local.x *= float(facing)
			projectile_pos = pos + rootling_local
			projectile_special = "ember_seed"
			speed = 105.0
		elif enemy_type == "ruin_drone":
			var drone_spec := _enemy_animation_spec("ruin_drone", "attack_1")
			var drone_spawn: Array = drone_spec.get("projectile_spawn", [98, 64])
			var drone_anchor := _enemy_animation_anchor("ruin_drone", Vector2(128, 128))
			var drone_local := (Vector2(float(drone_spawn[0]), float(drone_spawn[1])) - drone_anchor) * _enemy_sprite_scale("ruin_drone")
			drone_local.x *= float(facing)
			projectile_pos = pos + drone_local
			projectile_special = "ruin_bolt"
			speed = 120.0
		_spawn_enemy_projectile(projectile_pos, direction * speed, raw_damage, color, str(enemy.get("damage_type", "physical")), status, projectile_special)
		_play_sound("shoot")
		return Vector2.ZERO
	if kind == "roll":
		var roll_facing := facing
		if enemy_type == "cave_worm":
			roll_facing = int(enemy.get("roll_direction", facing))
			enemy["facing"] = roll_facing
			enemy["roll_active"] = true
			enemy["roll_time"] = _enemy_attack_recovery(enemy_type, attack_index)
			if not bool(enemy.get("roll_dust_started", false)):
				var worm_size: Vector2 = enemy.get("size", Vector2(34, 12))
				_spawn_enemy_impact(pos + Vector2(0.0, worm_size.y * 0.5), "cave_worm", "roll_dust", roll_facing, true, 0.56)
				enemy["roll_dust_started"] = true
		if distance <= attack_range + 28.0:
			_enemy_hit_player(enemy, roll_facing, "slow")
		if enemy_type == "cave_worm":
			return Vector2.ZERO
		return Vector2(float(facing) * 245.0, -25.0)
	if kind == "dash":
		if enemy_type == "mushroom_beetle":
			var beetle_size: Vector2 = enemy.get("size", Vector2(20, 14))
			_spawn_enemy_impact(pos + Vector2(0.0, beetle_size.y * 0.5), "mushroom_beetle", "dust_vfx", facing, false, 0.50)
			_emit_noise(pos, 105.0, "beetle_charge", 0.75)
		elif enemy_type == "night_ember":
			_spawn_enemy_impact(pos - Vector2(float(facing) * 12.0, 0.0), "night_ember", "flame_trail", facing, true, 0.44)
		elif enemy_type == "stone_beast":
			var charge_ground := pos + Vector2(0.0, float((enemy.get("size", Vector2(42, 30)) as Vector2).y) * 0.5)
			_spawn_enemy_impact(charge_ground, "stone_beast", "dust_trail", facing, true, 0.72)
		if distance <= attack_range + 20.0:
			_enemy_hit_player(enemy, facing)
		var dash_speed := 250.0 if enemy_type == "stone_beast" else 175.0
		var vertical_impulse := float(_enemy_movement_profile(enemy_type).get("hop_speed", 0.0)) if enemy_type == "wild_slime" else 0.0
		return Vector2(float(facing) * dash_speed, vertical_impulse)
	if enemy_type == "mossling" and attack_index == 1:
		var mossling_size: Vector2 = enemy.get("size", Vector2(18, 12))
		var impact_pos := pos + Vector2(float(facing) * 20.0, mossling_size.y * 0.5)
		_spawn_enemy_impact(impact_pos, "mossling", "root_impact", facing, true, 0.50)
	if enemy_type == "cave_worm" and attack_index == 1:
		var bite_impact_pos := pos + Vector2(float(facing) * 34.0, -5.0)
		_spawn_enemy_impact(bite_impact_pos, "cave_worm", "bite_impact", facing, true, 0.56)
	if distance <= attack_range + 14.0:
		_enemy_hit_player(enemy, facing)
	return Vector2.ZERO


func _enemy_hit_player(enemy: Dictionary, facing: int, forced_status := "") -> void:
	var damage_type := str(enemy.get("damage_type", "physical"))
	var raw_damage := int(enemy.get("damage", 1))
	var impact_direction := Vector2(float(facing), -0.25).normalized()
	var applied_status := forced_status if forced_status != "" else str(enemy.get("status_on_hit", ""))
	var target_peer := int(enemy.get("network_target_peer", 1))
	if network_session != null and network_session.is_server() and (network_session.is_dedicated() or target_peer != 1):
		network_session.damage_player_from_enemy(target_peer, raw_damage, impact_direction, damage_type, applied_status)
		return
	var damage := _incoming_damage(raw_damage, damage_type)
	# I-frames now reject knockback/status together with damage; previously a
	# blocked hit could still throw and poison the player.
	if not _damage_player(damage, impact_direction, damage_type):
		return
	player_velocity += Vector2(float(facing) * 115.0, -80.0)
	if applied_status != "":
		_apply_player_status(applied_status)


func _spawn_enemy_projectile(pos: Vector2, vel: Vector2, damage: int, color: Color, damage_type: String, status: String, special := "") -> void:
	enemy_projectiles.append({
		"pos": pos,
		"vel": vel,
		"damage": damage,
		"color": color,
		"life": 2.3,
		"anim_time": 0.0,
		"damage_type": damage_type,
		"status": status,
		"special": special
	})


func _enemy_on_floor(pos: Vector2, size: Vector2) -> bool:
	var foot_rect := Rect2(Vector2(pos.x - size.x * 0.4, pos.y + size.y * 0.5), Vector2(size.x * 0.8, 2.5))
	return _rect_collides(foot_rect)


func _move_enemy(pos: Vector2, motion: Vector2, size: Vector2) -> Vector2:
	if motion.x != 0.0:
		var horizontal_steps := maxi(1, ceili(absf(motion.x)))
		var horizontal_motion := motion.x / float(horizontal_steps)
		for _step in range(horizontal_steps):
			var x_pos := pos + Vector2(horizontal_motion, 0.0)
			if not _rect_collides(Rect2(x_pos - size * 0.5, size)):
				pos = x_pos
				continue
			if _enemy_on_floor(pos, size):
				var step_pos := _enemy_step_position(pos, horizontal_motion, size)
				if step_pos != pos:
					pos = step_pos
					continue
			break
	if motion.y != 0.0:
		var vertical_steps := maxi(1, ceili(absf(motion.y)))
		var vertical_motion := motion.y / float(vertical_steps)
		for _step in range(vertical_steps):
			var y_pos := pos + Vector2(0.0, vertical_motion)
			if _rect_collides(Rect2(y_pos - size * 0.5, size)):
				break
			pos = y_pos
	return pos


func _enemy_snap_to_ground(pos: Vector2, size: Vector2, maximum_distance: float) -> Vector2:
	if maximum_distance <= 0.0 or _rect_collides(Rect2(pos - size * 0.5, size)):
		return pos
	var last_valid := pos
	for step in range(1, ceili(maximum_distance) + 1):
		var candidate := pos + Vector2(0.0, float(step))
		if _rect_collides(Rect2(candidate - size * 0.5, size)):
			return last_valid
		last_valid = candidate
	if _enemy_on_floor(last_valid, size):
		return last_valid
	return pos


func _enemy_can_step_up(pos: Vector2, size: Vector2, direction: int) -> bool:
	return _enemy_step_position(pos, float(direction) * 2.0, size) != pos


func _enemy_step_has_support(pos: Vector2, size: Vector2, direction: int) -> bool:
	var leading_foot_x := pos.x + float(direction) * maxf(1.0, size.x * 0.5 - 1.0)
	var foot_y := pos.y + size.y * 0.5
	return _rect_collides(Rect2(Vector2(leading_foot_x - 2.0, foot_y), Vector2(4.0, 3.0)))


func _enemy_step_position(pos: Vector2, horizontal_motion: float, size: Vector2) -> Vector2:
	var direction := 1 if horizontal_motion > 0.0 else -1
	for step_height in range(1, TILE_SIZE + 2):
		var candidate := pos + Vector2(horizontal_motion, -float(step_height))
		if _rect_collides(Rect2(candidate - size * 0.5, size)):
			continue
		if _enemy_step_has_support(candidate, size, direction):
			return candidate
	return pos


func _enemy_position_valid(pos: Vector2, size: Vector2) -> bool:
	var half := size * 0.5
	if pos.x - half.x < 0.0 or pos.x + half.x >= WORLD_WIDTH * TILE_SIZE:
		return false
	if pos.y - half.y < 0.0 or pos.y + half.y >= WORLD_HEIGHT * TILE_SIZE:
		return false
	return not _rect_collides(Rect2(pos - half, size))


func _enemy_can_be_hit(enemy: Dictionary) -> bool:
	return not bool(enemy.get("burrow_hidden", false))


func _enemy_hitbox_rect(enemy: Dictionary) -> Rect2:
	var physics_size: Vector2 = enemy.get("size", Vector2(16, 16))
	var hitbox_size: Vector2 = enemy.get("hitbox_size", physics_size)
	var hitbox_offset: Vector2 = enemy.get("hitbox_offset", Vector2.ZERO)
	if str(enemy.get("type", "")) == "cave_worm" and str(enemy.get("anim_state", "idle")) == "attack_2":
		hitbox_size = Vector2(36, 36)
		hitbox_offset = Vector2(0, -12)
	var hitbox_center: Vector2 = enemy.get("pos", Vector2.ZERO)
	hitbox_center += hitbox_offset
	return Rect2(hitbox_center - hitbox_size * 0.5, hitbox_size)


func _closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func _recover_enemy_position(pos: Vector2, size: Vector2, last_safe_pos: Vector2) -> Vector2:
	if _enemy_position_valid(last_safe_pos, size):
		return last_safe_pos
	for origin in [pos, last_safe_pos]:
		for radius in range(1, TILE_SIZE * 4 + 1):
			for x_direction in [0, -1, 1]:
				var candidate: Vector2 = origin + Vector2(float(x_direction * mini(radius, TILE_SIZE * 2)), -float(radius))
				if _enemy_position_valid(candidate, size):
					return candidate
	var fallback := Vector2(
		clampf(pos.x, size.x * 0.5 + 1.0, WORLD_WIDTH * TILE_SIZE - size.x * 0.5 - 1.0),
		clampf(pos.y, size.y * 0.5 + 1.0, WORLD_HEIGHT * TILE_SIZE - size.y * 0.5 - 1.0)
	)
	return fallback


func _move_flying_enemy(pos: Vector2, motion: Vector2, size: Vector2) -> Vector2:
	var steps := maxi(1, ceili(motion.length() / 6.0))
	var step_motion := motion / float(steps)
	for _step in range(steps):
		var next_pos := pos + step_motion
		if not _rect_collides(Rect2(next_pos - size * 0.5, size)):
			pos = next_pos
			continue
		var x_pos := pos + Vector2(step_motion.x, 0.0)
		if not _rect_collides(Rect2(x_pos - size * 0.5, size)):
			pos = x_pos
		var y_pos := pos + Vector2(0.0, step_motion.y)
		if not _rect_collides(Rect2(y_pos - size * 0.5, size)):
			pos = y_pos
	return pos


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[i]
		var pos: Vector2 = projectile["pos"]
		var vel: Vector2 = projectile["vel"]
		var kind := str(projectile.get("kind", "bolt"))
		if kind == "spirit":
			var target_index := _nearest_enemy_index(pos, 180.0)
			if target_index >= 0:
				var target: Dictionary = enemies[target_index]
				var target_pos: Vector2 = target["pos"]
				vel = vel.lerp((target_pos - pos).normalized() * 230.0, 0.12)
		if kind == "acid":
			vel.y += 520.0 * delta
		pos += vel * delta
		projectile["pos"] = pos
		projectile["vel"] = vel
		projectile["life"] = float(projectile.get("life", 1.0)) - delta
		var remove: bool = float(projectile["life"]) <= 0.0
		if _get_tile(floori(pos.x / TILE_SIZE), floori(pos.y / TILE_SIZE)) != Tile.AIR:
			remove = true
		for enemy_index in range(enemies.size() - 1, -1, -1):
			var enemy: Dictionary = enemies[enemy_index]
			if not _enemy_can_be_hit(enemy):
				continue
			var enemy_rect := _enemy_hitbox_rect(enemy)
			if enemy_rect.has_point(pos):
				_damage_enemy(enemy_index, int(projectile.get("damage", 1)), Vector2(signf(vel.x), -0.3), str(projectile.get("damage_type", "physical")), str(projectile.get("status", "")))
				remove = true
				if kind == "acid":
					_damage_enemies_in_radius(pos, 28.0, int(projectile.get("damage", 1)) / 2)
				break
		if not remove and network_session != null and network_session.is_server() and network_session.pvp_enabled:
			var owner_peer := int(projectile.get("owner_peer", 1))
			for target_variant in network_session.players.keys():
				var target_peer := int(target_variant)
				if target_peer == owner_peer:
					continue
				var target_state: Dictionary = network_session.players[target_peer]
				var target_pos: Vector2 = target_state.get("pos", Vector2.ZERO)
				if Rect2(target_pos - PLAYER_SIZE * 0.5, PLAYER_SIZE).grow(2.0).has_point(pos):
					network_session.damage_player_from_pvp(owner_peer, target_peer, int(projectile.get("damage", 1)), vel.normalized(), str(projectile.get("damage_type", "physical")))
					remove = true
					break
		if remove:
			if kind == "cannon":
				_emit_noise(pos, 245.0, "explosion", 1.35)
			elif kind == "acid":
				_emit_noise(pos, 92.0, "acid_impact", 0.75)
			projectiles.remove_at(i)


func _network_projectile_hit_peer(pos: Vector2) -> int:
	if network_session != null and network_session.is_server():
		for peer_variant in network_session.players.keys():
			var peer_id := int(peer_variant)
			var state: Dictionary = network_session.players[peer_id]
			var target_pos: Vector2 = state.get("pos", Vector2.ZERO)
			if Rect2(target_pos - PLAYER_SIZE * 0.5, PLAYER_SIZE).grow(3.0).has_point(pos):
				return peer_id
		return -1
	return 1 if Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE).grow(3.0).has_point(pos) else -1


func _update_enemy_projectiles(delta: float) -> void:
	for i in range(enemy_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = enemy_projectiles[i]
		var pos: Vector2 = projectile["pos"]
		var velocity: Vector2 = projectile["vel"]
		var projectile_special := str(projectile.get("special", ""))
		if projectile_special == "cave_husk_rock":
			velocity.y += 310.0 * delta
			projectile["vel"] = velocity
		pos += velocity * delta
		projectile["pos"] = pos
		projectile["anim_time"] = float(projectile.get("anim_time", 0.0)) + delta
		projectile["life"] = float(projectile.get("life", 0.0)) - delta
		var remove := float(projectile["life"]) <= 0.0
		var tile := _get_tile(floori(pos.x / TILE_SIZE), floori(pos.y / TILE_SIZE))
		if tile != Tile.AIR and tile != Tile.WATER and tile != Tile.LAVA:
			remove = true
		var hit_peer := _network_projectile_hit_peer(pos)
		if hit_peer >= 0:
			var direction := (projectile["vel"] as Vector2).normalized()
			var projectile_damage_type := str(projectile.get("damage_type", "physical"))
			var projectile_status := str(projectile.get("status", ""))
			var raw_damage := int(projectile.get("damage", 1))
			if network_session != null and network_session.is_server() and (network_session.is_dedicated() or hit_peer != 1):
				network_session.damage_player_from_enemy(hit_peer, raw_damage, direction, projectile_damage_type, projectile_status)
			else:
				var applied_hit := _damage_player(_incoming_damage(raw_damage, projectile_damage_type), direction, projectile_damage_type)
				if applied_hit:
					if projectile_special in ["harpoon", "drowned_harpoon"]:
						player_velocity += -direction * 180.0 + Vector2(0, -35.0)
					else:
						player_velocity += direction * 95.0 + Vector2(0, -45.0)
					if projectile_status != "":
						_apply_player_status(projectile_status)
			_spawn_hit_particles(pos, projectile.get("color", Color.WHITE), 4)
			remove = true
		if remove:
			if projectile_special == "wild_ichor":
				_spawn_enemy_impact(pos, "wild_slime", "ichor_impact", 1, false, 0.34)
			elif projectile_special == "cave_husk_rock":
				var impact_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "cave_husk", "rock_impact", impact_facing, false, 0.50)
				_emit_noise(pos, 150.0, "rock_impact", 1.0)
			elif projectile_special == "mushroom_poison":
				var poison_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "mushroom_beetle", "poison_impact", poison_facing, false, 0.50)
			elif projectile_special == "ash_phantom_ember":
				var ember_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "ash_phantom", "ember_impact", ember_facing, false, 0.50)
			elif projectile_special == "ash_wisp_ember":
				var wisp_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "ash_wisp", "ember_impact", wisp_facing, true, 0.44)
			elif projectile_special == "sentinel_ash":
				var sentinel_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "ash_sentinel", "projectile_impact", sentinel_facing, true, 0.50)
			elif projectile_special == "drowned_harpoon":
				var harpoon_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "drowned_guard", "harpoon_impact", harpoon_facing, true, 0.50)
			elif projectile_special == "drowned_wave":
				var wave_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "drowned_guard", "wave_impact", wave_facing, true, 0.50)
			elif projectile_special == "ember_seed":
				var seed_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "ember_rootling", "seed_impact", seed_facing, true, 0.50)
			elif projectile_special == "glass_shard":
				var shard_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "glass_wraith", "shard_impact", shard_facing, true, 0.50)
			elif projectile_special == "night_fire":
				var fire_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "night_ember", "fire_impact", fire_facing, true, 0.44)
			elif projectile_special == "ruin_bolt":
				var bolt_facing := 1 if velocity.x >= 0.0 else -1
				_spawn_enemy_impact(pos, "ruin_drone", "bolt_impact", bolt_facing, true, 0.50)
			elif projectile_special == "stone_falling_rock":
				_spawn_enemy_impact(pos, "stone_beast", "rock_impact", 1, true, 0.72)
				_emit_noise(pos, 175.0, "stone_rock_impact", 1.10)
			enemy_projectiles.remove_at(i)
		else:
			enemy_projectiles[i] = projectile


func _spawn_enemy_impact(pos: Vector2, enemy_type: String, effect_state: String, effect_facing := 1, use_pack_anchor := false, effect_scale := 0.34) -> void:
	enemy_impact_effects.append({
		"pos": pos,
		"enemy_type": enemy_type,
		"state": effect_state,
		"facing": effect_facing,
		"use_pack_anchor": use_pack_anchor,
		"scale": effect_scale,
		"time": 0.0,
		"duration": _enemy_animation_duration(enemy_type, effect_state, 0.45)
	})


func _update_enemy_impact_effects(delta: float) -> void:
	for i in range(enemy_impact_effects.size() - 1, -1, -1):
		var effect: Dictionary = enemy_impact_effects[i]
		effect["time"] = float(effect.get("time", 0.0)) + delta
		if float(effect["time"]) >= float(effect.get("duration", 0.45)):
			enemy_impact_effects.remove_at(i)
		else:
			enemy_impact_effects[i] = effect


func _update_engineer_turret(delta: float) -> void:
	if equipped_weapon != "small_turret":
		return
	if attack_cooldown > 0.0:
		return
	var target_index := _nearest_enemy_index(player_position, 220.0)
	if target_index < 0:
		return
	var enemy: Dictionary = enemies[target_index]
	var target_pos: Vector2 = enemy["pos"]
	var dir := (target_pos - player_position).normalized()
	var muzzle_pos := player_position + dir * 14.0
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_projectile(muzzle_pos, dir * 310.0, _total_damage(), "turret", Color("aeefff"), 1.0, "arcane", "")
	else:
		_spawn_projectile(muzzle_pos, dir * 310.0, _total_damage(), "turret", Color("aeefff"), 1.0, "arcane", "")
	_start_attack_animation("turret", dir, Color("aeefff"), 0.18)
	_play_sound("shoot")
	_emit_noise(player_position, 175.0, "turret_shot", 0.95)
	attack_cooldown = 0.7


func _update_status_effects(delta: float) -> void:
	if god_mode_enabled:
		health = MAX_HEALTH
		player_statuses.clear()
	for status in player_statuses.keys():
		var data: Dictionary = player_statuses[status]
		data["time"] = float(data.get("time", 0.0)) - delta
		data["tick"] = float(data.get("tick", 0.0)) - delta
		if float(data["tick"]) <= 0.0:
			data["tick"] = 1.0
			if status == "poison":
				health = maxi(0, health - 2)
				_spawn_damage_number(player_position + Vector2(0, -28), 2, Color("89e36b"))
			elif status == "burn":
				health = maxi(0, health - 3)
				_spawn_damage_number(player_position + Vector2(0, -28), 3, Color("ff8a3c"))
			if health <= 0:
				_respawn_player()
				return
		player_statuses[status] = data
		if float(data["time"]) <= 0.0:
			player_statuses.erase(status)
			if status == "root_bind":
				_apply_player_status("slow")
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var statuses: Dictionary = enemy.get("statuses", {})
		for status in statuses.keys():
			var data: Dictionary = statuses[status]
			data["time"] = float(data.get("time", 0.0)) - delta
			data["tick"] = float(data.get("tick", 0.0)) - delta
			if float(data["tick"]) <= 0.0:
				data["tick"] = 1.0
				var tick_damage := 2 if status == "poison" else 3
				enemy["hp"] = int(enemy.get("hp", 1)) - tick_damage
				_spawn_damage_number((enemy["pos"] as Vector2) + Vector2(0, -18), tick_damage, Color("89e36b") if status == "poison" else Color("ff8a3c"))
			statuses[status] = data
			if float(data["time"]) <= 0.0:
				statuses.erase(status)
		enemy["statuses"] = statuses
		if int(enemy.get("hp", 1)) <= 0:
			_kill_enemy(i)


func _try_player_attack() -> void:
	_try_player_attack_at(Vector2.ZERO, false)


func _try_player_attack_at(target: Vector2, use_target := true) -> void:
	if inventory_open or full_map_open or attack_cooldown > 0.0:
		return
	# Consumable in hand: use it instead of attacking (only when it can heal).
	var held := _selected_item()
	if network_session != null and network_session.is_client() and network_session.joined:
		if (held == "star_dust" and flight_charge < FLIGHT_CHARGE_MAX - 0.5) or (consumables.has(held) and health < MAX_HEALTH):
			network_session.request_game_action("consume", {"item_id": held})
			attack_cooldown = 0.5
			return
	if held == "star_dust" and flight_charge < FLIGHT_CHARGE_MAX - 0.5:
		flight_charge = minf(FLIGHT_CHARGE_MAX, flight_charge + 50.0)
		inventory["star_dust"] = int(inventory.get("star_dust", 0)) - 1
		if int(inventory.get("star_dust", 0)) <= 0:
			inventory.erase("star_dust")
			_sanitize_hotbar()
		attack_cooldown = 0.5
		_play_sound("pickup")
		last_message = "Star dust fuels your flight (%d%% charge)." % int(round(flight_charge))
		return
	if consumables.has(held) and health < MAX_HEALTH:
		var effect: Dictionary = consumables[held]
		health = mini(MAX_HEALTH, health + int(effect.get("heal", 0)))
		inventory[held] = int(inventory.get(held, 0)) - 1
		if int(inventory.get(held, 0)) <= 0:
			inventory.erase(held)
			_sanitize_hotbar()
		attack_cooldown = 0.5
		_play_sound("pickup")
		last_message = "Used %s (+%d HP)." % [_item_display_name(held), int(effect.get("heal", 0))]
		return
	mobile_attack_target = target
	mobile_attack_target_valid = use_target
	if use_target and absf(target.x - player_position.x) > 4.0:
		facing = 1 if target.x > player_position.x else -1
	var weapon := equipped_weapon
	if weapon == "":
		_melee_attack(20.0, 5, 0.34)
	elif weapon.contains("sword") or weapon.contains("sickle"):
		_melee_attack(34.0, _total_damage(), 0.38)
	elif weapon.contains("spear") or weapon == "sky_lance":
		_melee_attack(52.0, _total_damage() + 4, 0.46)
	elif weapon.contains("bow"):
		_fire_projectile_weapon(330.0, _total_damage(), "arrow", Color("d5a15a"), 0.55)
	elif weapon == "hand_cannon":
		_fire_projectile_weapon(430.0, _total_damage() + 5, "cannon", Color("ffe1a1"), 0.95)
	elif weapon == "spark_staff":
		_fire_projectile_weapon(260.0, _total_damage() + 4, "spark", Color("b79cff"), 0.62)
	elif weapon == "root_spirit_rod":
		_fire_projectile_weapon(210.0, _total_damage(), "spirit", Color("80d989"), 0.85)
	elif weapon == "acid_flasks":
		_fire_projectile_weapon(210.0, _total_damage(), "acid", Color("94e86f"), 0.72)
	elif weapon == "small_turret":
		_update_engineer_turret(0.0)
	else:
		_melee_attack(28.0, _total_damage(), 0.45)
	mobile_attack_target_valid = false


func _throw_grapple(target: Vector2) -> void:
	if grapple_cooldown > 0.0:
		return
	if grapple_attached:
		# Release the hook.
		grapple_attached = false
		grapple_hook_pos = Vector2(-1.0, -1.0)
		grapple_cooldown = 0.35
		return
	# Aim toward the target (cursor / joystick direction), capped at range.
	var dir := target - player_position
	if dir.length() < 4.0:
		dir = Vector2(float(facing), 0.0)
	dir = dir.normalized()
	var hook_pos := player_position + dir * GRAPPLE_RANGE
	# Walk from the player outward and find the first solid tile.
	var steps := 12
	var found := false
	for i in range(1, steps + 1):
		var check := player_position + dir * (GRAPPLE_RANGE * float(i) / float(steps))
		var tx := floori(check.x / TILE_SIZE)
		var ty := floori(check.y / TILE_SIZE)
		if _in_bounds(tx, ty) and _is_solid(tx, ty):
			grapple_hook_pos = Vector2(tx * TILE_SIZE + TILE_SIZE * 0.5, ty * TILE_SIZE + TILE_SIZE * 0.5)
			grapple_attached_to = Vector2i(tx, ty)
			grapple_attached = true
			found = true
			break
	if found:
		_play_sound("hit")
		grapple_cooldown = 0.0
	else:
		grapple_cooldown = 0.3
	_start_attack_animation("slash", dir, Color("d5c9a8"), 0.2)


func _update_grapple(delta: float) -> void:
	grapple_cooldown = maxf(0.0, grapple_cooldown - delta)
	if not grapple_attached:
		return
	# If the anchor block was destroyed, drop.
	if not _in_bounds(grapple_attached_to.x, grapple_attached_to.y) or not _is_solid(grapple_attached_to.x, grapple_attached_to.y):
		grapple_attached = false
		grapple_hook_pos = Vector2(-1.0, -1.0)
		return
	# Pull the player toward the hook.
	var to_hook := grapple_hook_pos - player_position
	var dist := to_hook.length()
	if dist < 14.0:
		grapple_attached = false
		grapple_hook_pos = Vector2(-1.0, -1.0)
		return
	var pull := to_hook.normalized() * minf(GRAPPLE_SPEED * delta, dist)
	_move_player(pull)
	player_velocity.y = 0.0



func _draw_sky_compass() -> void:
	# The Sky Compass points to the nearest sky island, or — after the path
	# choice — to the structure of the chosen path (observatory / moon altar).
	if not _equipped_accessory_has("sky_compass"):
		return
	# Path structure takes priority over islands.
	var path_target := Vector2(-1.0, -1.0)
	if path_choice == "science" and observatory_pos.x >= 0:
		path_target = Vector2(observatory_pos.x * TILE_SIZE + TILE_SIZE * 0.5, observatory_pos.y * TILE_SIZE)
	elif path_choice == "magic" and moon_altar_pos.x >= 0:
		path_target = Vector2(moon_altar_pos.x * TILE_SIZE + TILE_SIZE * 0.5, moon_altar_pos.y * TILE_SIZE)
	if path_target.x >= 0.0:
		if path_target.distance_to(player_position) < 8.0 * TILE_SIZE:
			return
		var dir := (path_target - player_position).normalized()
		_draw_compass_arrow(dir, Color("ffe9a8"))
		return
	if sky_island_positions.is_empty() or sky_arena_pos.x < 0:
		return
	var nearest := Vector2.ZERO
	var best_dist := INF
	for center in sky_island_positions:
		var island_center := Vector2(center.x * TILE_SIZE + TILE_SIZE * 0.5, center.y * TILE_SIZE + TILE_SIZE * 0.5)
		var d := island_center.distance_to(player_position)
		if d < best_dist:
			best_dist = d
			nearest = island_center
	# Already on an island (or very close): hide the arrow.
	if best_dist < 10.0 * TILE_SIZE:
		return
	_draw_compass_arrow((nearest - player_position).normalized(), Color(1.0, 0.9, 0.55, 0.92))


func _draw_compass_arrow(dir: Vector2, color: Color) -> void:
	var view := get_viewport_rect()
	var screen_center := view.size * 0.5
	var radius := minf(view.size.x, view.size.y) * 0.42
	var arrow_pos := screen_center + dir * radius
	arrow_pos.x = clampf(arrow_pos.x, 30.0, view.size.x - 30.0)
	arrow_pos.y = clampf(arrow_pos.y, 30.0, view.size.y - 30.0)
	var angle := dir.angle()
	# Golden arrow (rotated to point at the island).
	draw_set_transform(arrow_pos, angle, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 0), Vector2(5, -7), Vector2(2, 0), Vector2(5, 7)
	]), color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 0), Vector2(5, -7), Vector2(2, 0), Vector2(5, 7)
	]), color.darkened(0.1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)



func _draw_sky_islands_on_map(image: Image) -> void:
	# With the Sky Compass equipped, the full map reveals the sky islands as
	# gold dots (they are far above the explored world otherwise).
	if not _equipped_accessory_has("sky_compass"):
		return
	for center in sky_island_positions:
		var mx := clampi(int(center.x / float(WORLD_WIDTH) * float(image.get_width())), 0, image.get_width() - 1)
		var my := clampi(int(center.y / float(WORLD_HEIGHT) * float(image.get_height())), 0, image.get_height() - 1)
		for yy in range(my - 1, my + 2):
			for xx in range(mx - 1, mx + 2):
				if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
					image.set_pixel(xx, yy, Color("ffd97a"))


func _activate_wanderer_npc() -> void:
	# The first NPC appears on the central sky island after the Leviathan dies.
	if npc_wanderer_active or path_choice != "":
		return
	if sky_arena_pos.x < 0:
		return
	npc_wanderer_pos = Vector2(sky_arena_pos.x * TILE_SIZE + TILE_SIZE * 0.5, (sky_arena_pos.y - 8) * TILE_SIZE)
	npc_wanderer_active = true
	last_message = "A hooded wanderer stands on the island, waiting for you."
	_toast_message(last_message, 4.0)


func _draw_wanderer_npc() -> void:
	if not npc_wanderer_active:
		return
	var pos := npc_wanderer_pos
	# A simple robed figure: hood, cloak, staff. Bobs gently.
	var bob := sin(Time.get_ticks_msec() * 0.003) * 1.5
	var p := pos + Vector2(0, bob)
	var cloak := Color("5a5f78")
	var cloak_dark := Color("3a3e52")
	var hood := Color("6a6f8a")
	var staff := Color("8a6a42")
	# staff
	draw_rect(Rect2(p + Vector2(8, -26), Vector2(2, 30)), staff)
	draw_circle(p + Vector2(9, -28), 3.0, Color("ffe9a8"))
	# cloak body
	draw_rect(Rect2(p + Vector2(-7, -18), Vector2(14, 22)), cloak_dark)
	draw_rect(Rect2(p + Vector2(-6, -18), Vector2(12, 20)), cloak)
	# hood/head
	draw_rect(Rect2(p + Vector2(-4, -26), Vector2(9, 9)), hood)
	draw_rect(Rect2(p + Vector2(-4, -26), Vector2(9, 3)), Color("4a4e66"))
	# face shadow inside hood
	draw_rect(Rect2(p + Vector2(-3, -22), Vector2(7, 4)), Color("2a2c3a"))
	# glowing eyes
	draw_rect(Rect2(p + Vector2(-2, -22), Vector2(2, 2)), Color("aee6ff"))
	draw_rect(Rect2(p + Vector2(1, -22), Vector2(2, 2)), Color("aee6ff"))
	# name tag
	if ui_font != null:
		draw_string(ui_font, p + Vector2(-40, 8), "SKY WANDERER", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 8, Color("cfe4ff", 0.9))
	# interaction hint
	if player_position.distance_to(pos) < 90.0:
		if ui_font != null:
			draw_string(ui_font, p + Vector2(-40, 22), "TAP TO TALK", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 8, Color("ffe9a8", 0.95))


func _npc_in_interact_range() -> bool:
	if not npc_wanderer_active:
		return false
	return player_position.distance_to(npc_wanderer_pos) < 90.0


func _open_path_dialog() -> void:
	if path_dialog_open or not npc_wanderer_active:
		return
	path_dialog_open = true
	if path_dialog_panel != null:
		path_dialog_panel.visible = true


func _close_path_dialog() -> void:
	path_dialog_open = false
	if path_dialog_panel != null:
		path_dialog_panel.visible = false


func _choose_path(choice: String) -> void:
	if path_choice != "":
		_close_path_dialog()
		return
	path_choice = choice
	_close_path_dialog()
	npc_wanderer_active = false
	if choice == "science":
		_spawn_observatory()
		last_message = "The wanderer nods. The path of SCIENCE opens — follow the compass to the observatory."
	elif choice == "magic":
		_spawn_moon_altar()
		last_message = "The wanderer nods. The path of MAGIC opens — follow the compass to the moon altar."
	_toast_message(last_message, 5.0)
	_save_game()


func _spawn_observatory() -> void:
	# Find the highest surface peak in the whole world and build a stone
	# observatory tower there (science path structure).
	var best_x := -1
	var best_y := 999999
	for x in range(4, WORLD_WIDTH - 4):
		var sy: int = surface_heights[x] if x < surface_heights.size() else 60
		if sy < best_y:
			best_y = sy
			best_x = x
	if best_x < 0:
		return
	observatory_pos = Vector2i(best_x, best_y - 3)
	var cx := best_x
	var base_y := best_y
	# Tower: 3-wide stone column up from the peak.
	for y in range(base_y - 9, base_y):
		for xx in range(cx - 1, cx + 2):
			if _in_bounds(xx, y) and _get_tile(xx, y) == Tile.AIR:
				_set_tile(xx, y, Tile.STONE)
	# Dome on top (small).
	for xx in range(cx - 2, cx + 3):
		if _in_bounds(xx, base_y - 10) and _get_tile(xx, base_y - 10) == Tile.AIR:
			_set_tile(xx, base_y - 10, Tile.RUIN)
	# A glowing beacon mark (visual only via details) — a torch-like top.
	if _in_bounds(cx, base_y - 11):
		_set_tile(cx, base_y - 11, Tile.TORCH)
	world_map_dirty = true


func _spawn_moon_altar() -> void:
	# Magic path structure: a moon altar in the depths (near the glass abyss /
	# deepest part of the world for now, or a clearing). Use depth stone.
	var x := int(WORLD_WIDTH * 0.5)
	var y := WORLD_HEIGHT - 30
	# Search a cave floor.
	for attempt in range(60):
		var cx2 := rng.randi_range(30, WORLD_WIDTH - 31)
		var cy2 := rng.randi_range(WORLD_HEIGHT - 60, WORLD_HEIGHT - 20)
		if _get_tile(cx2, cy2) == Tile.AIR and _is_solid(cx2, cy2 + 1):
			x = cx2
			y = cy2
			break
	moon_altar_pos = Vector2i(x, y)
	# A small platform + altar.
	for xx in range(x - 2, x + 3):
		if _in_bounds(xx, y + 1):
			_set_tile(xx, y + 1, Tile.DEPTH_STONE)
	if _in_bounds(x, y):
		_set_tile(x, y, Tile.DEPTH_STONE)
	if _in_bounds(x, y - 1):
		_set_tile(x, y - 1, Tile.STONE_ALTAR)
	# Glowing crystals around.
	for sx in [x - 3, x + 3]:
		if _in_bounds(sx, y) and _get_tile(sx, y) == Tile.AIR:
			_set_tile(sx, y, Tile.ABYSS_CRYSTAL)
	world_map_dirty = true


func _draw_grapple() -> void:
	if not grapple_attached:
		return
	var from := player_position + Vector2(0.0, -PLAYER_SIZE.y * 0.5)
	var to := grapple_hook_pos
	draw_line(from, to, Color(0.75, 0.65, 0.45, 0.9), 2.0)
	draw_circle(grapple_hook_pos, 4.0, Color(0.85, 0.75, 0.55, 1.0))


func _melee_attack(range_px: float, damage: int, cooldown: float) -> void:
	var center := player_position + Vector2(float(facing) * range_px * 0.6, 0.0)
	var attack_rect := Rect2(center - Vector2(range_px * 0.5, 18.0), Vector2(range_px, 36.0))
	var hit := false
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if not _enemy_can_be_hit(enemy):
			continue
		var enemy_rect := _enemy_hitbox_rect(enemy)
		if attack_rect.intersects(enemy_rect):
			_damage_enemy(i, damage, Vector2(facing, -0.2), _weapon_damage_type(equipped_weapon), _weapon_status(equipped_weapon))
			hit = true
	if network_session != null and network_session.is_active() and network_session.joined:
		network_session.request_pvp_melee(range_px, damage, facing, _weapon_damage_type(equipped_weapon))
	var weapon := equipped_weapon
	var anim_kind := "spear" if weapon.contains("spear") else "slash"
	_start_attack_animation(anim_kind, Vector2(facing, 0), Color("f0d27a"), cooldown)
	_play_sound("swing")
	_emit_noise(player_position, 58.0 if weapon == "" else 72.0, "melee", 0.55)
	attack_cooldown = cooldown


func _fire_projectile_weapon(speed: float, damage: int, kind: String, color: Color, cooldown: float) -> void:
	var aim_position := mobile_attack_target if mobile_attack_target_valid else get_global_mouse_position()
	var aim_dir := aim_position - player_position
	if aim_dir.length() < 8.0:
		aim_dir = Vector2(facing, 0)
	var dir := aim_dir.normalized()
	var muzzle_pos := player_position + dir * 14.0
	var damage_type := _projectile_damage_type(kind)
	var projectile_status := _projectile_status(kind)
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_projectile(muzzle_pos, dir * speed, damage, kind, color, 1.5, damage_type, projectile_status)
	else:
		_spawn_projectile(muzzle_pos, dir * speed, damage, kind, color, 1.5, damage_type, projectile_status)
	if kind == "cannon":
		player_velocity -= dir * 42.0
		_add_camera_trauma(3.2, 0.14)
		_spawn_combat_impact(muzzle_pos, dir, "physical", true)
	var anim_kind := "bow"
	if kind == "cannon":
		anim_kind = "cannon"
	elif kind == "spark" or kind == "spirit":
		anim_kind = "staff"
	elif kind == "acid":
		anim_kind = "flask"
	_start_attack_animation(anim_kind, dir, color, cooldown)
	_play_sound("shoot")
	var noise_radius := 145.0
	if kind == "cannon":
		noise_radius = 310.0
	elif kind == "spark" or kind == "spirit":
		noise_radius = 185.0
	elif kind == "acid":
		noise_radius = 125.0
	_emit_noise(player_position, noise_radius, "shot_%s" % kind, 1.0)
	attack_cooldown = cooldown


func _spawn_projectile(pos: Vector2, vel: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String = "physical", status: String = "", owner_peer := 1) -> void:
	projectiles.append({"pos": pos, "vel": vel, "damage": damage, "kind": kind, "color": color, "life": life, "damage_type": damage_type, "status": status, "owner_peer": owner_peer})


func _start_attack_animation(kind: String, dir: Vector2, color: Color, duration: float) -> void:
	attack_anim_kind = kind
	attack_anim_dir = dir.normalized() if dir.length() > 0.01 else Vector2(facing, 0)
	attack_anim_color = color
	attack_anim_duration = maxf(0.12, duration)
	attack_anim_time = attack_anim_duration


func _update_attack_animation(delta: float) -> void:
	attack_anim_time = maxf(0.0, attack_anim_time - delta)
	if attack_anim_time <= 0.0:
		attack_anim_kind = ""


func _weapon_damage_type(weapon: String) -> String:
	if weapon == "ash_sickle" or weapon == "spark_staff" or weapon == "root_spirit_rod":
		return "arcane"
	if weapon == "acid_flasks":
		return "poison"
	return "physical"


func _weapon_status(weapon: String) -> String:
	if weapon == "ash_sickle":
		return "slow"
	return ""


func _projectile_damage_type(kind: String) -> String:
	if kind == "acid":
		return "poison"
	if kind == "spark" or kind == "spirit" or kind == "turret":
		return "arcane"
	if kind == "arrow" and equipped_accessory == "fire_arrows":
		return "fire"
	return "physical"


func _projectile_status(kind: String) -> String:
	if kind == "acid":
		return "poison"
	if kind == "spirit":
		return "slow"
	if kind == "arrow" and equipped_accessory == "fire_arrows":
		return "burn"
	return ""


func _damage_enemy(index: int, damage: int, knockback: Vector2, damage_type: String = "physical", status: String = "") -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	if network_session != null and network_session.is_client() and network_session.joined and not network_applying_snapshot:
		var enemy_id := int(enemy.get("perception_id", -1))
		if enemy_id >= 0:
			network_session.request_enemy_damage(enemy_id, damage, knockback, damage_type, status)
		var preview_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		var preview_dir := knockback.normalized()
		if preview_dir.length_squared() < 0.01:
			preview_dir = (preview_pos - player_position).normalized()
		var preview_heavy := damage >= 14
		_spawn_damage_number(preview_pos + Vector2(0, -18), damage, _damage_color(damage_type), preview_heavy)
		_spawn_combat_impact(preview_pos, preview_dir, damage_type, preview_heavy)
		_play_sound("heavy_hit" if preview_heavy else "hit")
		return
	_force_enemy_combat(enemy, player_position, true)
	var final_damage := damage
	if damage_type == "poison":
		final_damage = int(ceil(float(damage) * 0.85))
	elif damage_type == "fire":
		final_damage = int(ceil(float(damage) * 0.95))
	elif damage_type == "arcane":
		final_damage = int(ceil(float(damage) * 1.08))
	var guarded := float(enemy.get("guard_time", 0.0)) > 0.0
	if guarded:
		final_damage = maxi(1, int(ceil(float(final_damage) * 0.40)))
	enemy["hp"] = int(enemy.get("hp", 1)) - final_damage
	var killed := int(enemy.get("hp", 1)) <= 0
	var enemy_type := str(enemy.get("type", ""))
	var heavy := killed or final_damage >= 14
	enemy["hit_timer"] = _enemy_animation_duration(enemy_type, "hurt", 0.12) if enemy_type in ["bat", "spore_bat", "cave_husk"] else 0.12
	if enemy_type == "spore_bat" and rng.randf() < 0.35:
		var spore_cloud_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		_spawn_enemy_impact(spore_cloud_pos, "spore_bat", "spore_cloud", int(enemy.get("facing", 1)), false, 0.38)
		if spore_cloud_pos.distance_to(player_position) <= 48.0:
			var cloud_dir := (player_position - spore_cloud_pos).normalized()
			if _damage_player(_incoming_damage(3, "poison"), cloud_dir, "poison"):
				_apply_player_status("poison")
	if status != "":
		_apply_enemy_status(enemy, status)
	var enemy_pos: Vector2 = enemy["pos"]
	var impact_dir := knockback.normalized()
	if impact_dir.length_squared() < 0.01:
		impact_dir = (enemy_pos - player_position).normalized()
	_spawn_damage_number(enemy_pos + Vector2(0, -18), final_damage, _damage_color(damage_type), heavy)
	_spawn_combat_impact(enemy_pos, impact_dir, damage_type, heavy, false, guarded)
	var feedback_distance := enemy_pos.distance_to(player_position)
	if feedback_distance <= 360.0:
		var distance_scale := clampf(1.0 - feedback_distance / 440.0, 0.25, 1.0)
		_add_camera_trauma((3.8 if heavy else 2.2) * distance_scale, 0.16 if heavy else 0.10)
		if feedback_distance <= 230.0:
			_trigger_hit_stop(0.055 if heavy else 0.032)
	_play_sound("block" if guarded else ("heavy_hit" if heavy else "hit"))
	var vel: Vector2 = enemy["vel"]
	vel += knockback * (80.0 if guarded else 150.0)
	enemy["vel"] = vel
	enemy["stun_timer"] = 0.38 if enemy_type in ["spore_bat", "cave_husk"] else (0.10 if guarded else 0.15)
	if killed:
		_kill_enemy(index)


func _apply_enemy_status(enemy: Dictionary, status: String) -> void:
	var statuses: Dictionary = enemy.get("statuses", {})
	var duration := 4.0
	if status == "slow":
		duration = 2.8
	elif status == "burn":
		duration = 3.5
	elif status == "poison":
		duration = 5.0
	statuses[status] = {"time": duration, "tick": 1.0}
	enemy["statuses"] = statuses


func _damage_color(damage_type: String) -> Color:
	if damage_type == "poison":
		return Color("89e36b")
	if damage_type == "fire":
		return Color("ff8a3c")
	if damage_type == "arcane":
		return Color("c49cff")
	return Color("ffe08a")


func _damage_enemies_in_radius(center: Vector2, radius: float, damage: int) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if not _enemy_can_be_hit(enemy):
			continue
		var hitbox := _enemy_hitbox_rect(enemy)
		var hit_point := _closest_point_on_rect(hitbox, center)
		if hit_point.distance_to(center) > radius:
			continue
		var pos: Vector2 = enemy["pos"]
		_damage_enemy(i, damage, (pos - center).normalized())


func _kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	var drop := str(enemy.get("drop", "wild_ichor"))
	var pos: Vector2 = enemy["pos"]
	var enemy_type := str(enemy.get("type", ""))
	_record_enemy_kill(enemy_type)
	if enemy_type == "stone_beast":
		stone_beast_defeated = true
		_spawn_loot(pos, "beast_core", 1)
		_spawn_loot(pos + Vector2(12, -8), "stoneblood_ore", 8)
		_unlock_stone_beast_progression()
		last_message = "Stone Beast defeated. Stoneblood veins awaken below."
	elif enemy_type == "heartwood_boss":
		boss_defeated = true
		_spawn_loot(pos, drop, 1)
		_spawn_loot(pos + Vector2(14, -8), "world_memory", 1)
		last_message = "Heartwood Core defeated. The world remembers you."
	elif enemy_type == "storm_herald":
		storm_herald_defeated = true
		storm_active = false
		storm_tornado_phase = ""
		_spawn_loot(pos, "wind_shard", 2)
		_spawn_loot(pos + Vector2(12, -8), "memory_shard", 3)
		last_message = "The storm breaks. The sky clears — a shard of living wind falls."
	elif enemy_type == "depth_warden":
		depth_warden_defeated = true
		_spawn_loot(pos, "earth_shard", 1)
		_spawn_loot(pos + Vector2(12, -8), "stoneblood_ore", 6)
		last_message = "The Warden crumbles to dust. A shard of living earth falls."
	elif enemy_type == "leviathan":
		sky_leviathan_defeated = true
		_spawn_loot(pos, "leviathan_scale", rng.randi_range(4, 6))
		_spawn_loot(pos + Vector2(12, -8), "sky_crystal", 6)
		_spawn_loot(pos + Vector2(-12, -8), "star_dust", 10)
		# The Sky Shard unlocks the next chapter.
		_spawn_loot(pos + Vector2(0, -18), "sky_shard", 1)
		last_message = "The Leviathan falls. Its scales and the Sky Shard are yours."
		_activate_wanderer_npc()
	elif enemy_type == "sky_herald":
		# Rare scout: always drops its wind-touched feathers (the only reliable
		# source of Zephyr Feathers before the sky islands are reached).
		_spawn_loot(pos, "zephyr_feather", 1 + (1 if rng.randf() < 0.35 else 0))
		_spawn_loot(pos + Vector2(8, -6), drop, 1)
		if rng.randf() < 0.20:
			_spawn_loot(pos + Vector2(-8, -6), "memory_shard", 1)
		last_message = "Defeated %s. The wind-touched feathers fall." % str(enemy.get("name", "enemy"))
	else:
		defeated_enemies += 1
		_spawn_loot(pos, drop, 1)
		if rng.randf() < 0.16:
			_spawn_loot(pos + Vector2(8, -6), "memory_shard", 1)
		last_message = "Defeated %s. Dropped %s." % [str(enemy.get("name", "enemy")), _item_display_name(drop)]
	_spawn_hit_particles(pos, Color("f2d38b"), 9)
	var corpse := enemy.duplicate(true)
	if enemy_type in ["bat", "spore_bat"]:
		corpse["death_phase"] = "fall"
		corpse["death_anim_time"] = 0.0
		corpse["death_velocity"] = (enemy.get("vel", Vector2.ZERO) as Vector2) * 0.45 + Vector2(0.0, 25.0)
		corpse["death_time"] = 4.0
		corpse["death_total"] = 4.0
	else:
		var death_duration := _enemy_animation_duration(enemy_type, "death", 0.36)
		corpse["death_time"] = death_duration
		corpse["death_total"] = death_duration
		corpse["anim_time"] = 0.0
	dying_enemies.append(corpse)
	enemies.remove_at(index)


func _spawn_loot(pos: Vector2, item_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var spread := Vector2(rng.randf_range(-58.0, 58.0), rng.randf_range(-170.0, -95.0))
	_spawn_loot_with_velocity(pos, item_id, amount, spread, 0.35)


func _spawn_loot_with_velocity(pos: Vector2, item_id: String, amount: int, velocity: Vector2, pickup_delay: float) -> void:
	if amount <= 0:
		return
	dropped_items.append({
		"id": item_id,
		"amount": amount,
		"pos": pos,
		"vel": velocity,
		"age": 0.0,
		"bob": rng.randf_range(0.0, TAU),
		"pickup_delay": pickup_delay,
		"network_id": next_network_loot_id
	})
	next_network_loot_id += 1


func _update_world_loot_and_fx(delta: float) -> void:
	_update_dropped_items(delta)
	_update_damage_numbers(delta)
	_update_hit_particles(delta)
	_update_combat_impacts(delta)
	_trim_mobile_transient_fx()


func _trim_mobile_transient_fx() -> void:
	if not mobile_ui_enabled:
		return
	while hit_particles.size() > MOBILE_MAX_HIT_PARTICLES:
		hit_particles.pop_front()
	while damage_numbers.size() > MOBILE_MAX_DAMAGE_NUMBERS:
		damage_numbers.pop_front()
	while combat_impacts.size() > MOBILE_MAX_COMBAT_IMPACTS:
		combat_impacts.pop_front()


func _update_dropped_items(delta: float) -> void:
	if network_session != null and network_session.is_client():
		var now := Time.get_ticks_msec()
		for pending_id in network_pending_loot.keys():
			if now - int(network_pending_loot[pending_id]) > 2000:
				network_pending_loot.erase(pending_id)
	for i in range(dropped_items.size() - 1, -1, -1):
		var item: Dictionary = dropped_items[i]
		var pos: Vector2 = item["pos"]
		var vel: Vector2 = item["vel"]
		var age := float(item.get("age", 0.0)) + delta
		var pickup_delay := maxf(0.0, float(item.get("pickup_delay", 0.0)) - delta)
		var to_player := player_position - pos
		var distance := to_player.length()
		if pickup_delay <= 0.0 and distance < LOOT_MAGNET_RADIUS:
			var pull := clampf(1.0 - distance / LOOT_MAGNET_RADIUS, 0.0, 1.0)
			vel = vel.lerp(to_player.normalized() * lerpf(160.0, 520.0, pull), 0.18)
		else:
			vel.y += GRAVITY * 0.55 * delta
			vel.x = lerpf(vel.x, 0.0, 0.025)
		var moved := _move_loot(pos, vel, delta)
		pos = moved["pos"]
		vel = moved["vel"]
		item["pos"] = pos
		item["vel"] = vel
		item["age"] = age
		item["pickup_delay"] = pickup_delay
		if pickup_delay <= 0.0 and distance < LOOT_PICKUP_RADIUS:
			if network_session != null and network_session.is_client() and network_session.joined:
				var network_id := int(item.get("network_id", -1))
				if network_id >= 0 and not network_pending_loot.has(network_id):
					network_pending_loot[network_id] = Time.get_ticks_msec()
					network_session.request_loot_pickup(network_id)
				dropped_items[i] = item
				continue
			var picked_id := str(item.get("id", ""))
			var picked_amount := int(item.get("amount", 1))
			_add_item(picked_id, picked_amount)
			_add_loot_notification(picked_id, picked_amount)
			_play_sound("pickup")
			last_message = "Picked up %s x%d." % [_item_display_name(picked_id), picked_amount]
			if picked_id == "wind_shard" and not wind_shard_picked:
				wind_shard_picked = true
				last_message = "The shard hums with wind... it tugs toward something deep underground."
				_toast_message(last_message, 5.0)
				_mark_journal_updated()
			dropped_items.remove_at(i)
		elif age > LOOT_DESPAWN_TIME:
			dropped_items.remove_at(i)


func _move_loot(pos: Vector2, vel: Vector2, delta: float) -> Dictionary:
	var size := Vector2(10, 10)
	var half := size * 0.5
	if _rect_collides(Rect2(pos - half, size)):
		for step in range(1, 9):
			var candidate := pos + Vector2(0, -float(step) * 2.0)
			if not _rect_collides(Rect2(candidate - half, size)):
				pos = candidate
				vel.y = 0.0
				break

	var x_pos := pos + Vector2(vel.x * delta, 0.0)
	if _rect_collides(Rect2(x_pos - half, size)):
		vel.x = 0.0
	else:
		pos = x_pos

	var y_pos := pos + Vector2(0.0, vel.y * delta)
	if _rect_collides(Rect2(y_pos - half, size)):
		vel.y = 0.0
	else:
		pos = y_pos

	if absf(vel.x) < 2.0:
		vel.x = 0.0
	return {"pos": pos, "vel": vel}


func _spawn_damage_number(pos: Vector2, amount: int, color: Color, heavy := false) -> void:
	var lifetime := 0.88 if heavy else 0.75
	damage_numbers.append({
		"text": str(amount),
		"pos": pos,
		"vel": Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-72.0, -50.0) if heavy else rng.randf_range(-58.0, -42.0)),
		"life": lifetime,
		"max_life": lifetime,
		"font_size": 15 if heavy else 12,
		"heavy": heavy,
		"color": color
	})


func _update_damage_numbers(delta: float) -> void:
	for i in range(damage_numbers.size() - 1, -1, -1):
		var number: Dictionary = damage_numbers[i]
		var pos: Vector2 = number["pos"]
		var vel: Vector2 = number["vel"]
		pos += vel * delta
		vel.y += 60.0 * delta
		number["pos"] = pos
		number["vel"] = vel
		number["life"] = float(number.get("life", 0.0)) - delta
		if float(number["life"]) <= 0.0:
			damage_numbers.remove_at(i)


func _add_loot_notification(item_id: String, amount: int) -> void:
	loot_notifications.push_front({"text": "+ %s x%d" % [_item_display_name(item_id), amount], "life": 2.5, "icon": item_id})
	while loot_notifications.size() > loot_feed_labels.size():
		loot_notifications.pop_back()


func _update_loot_feed() -> void:
	var delta := get_process_delta_time()
	for i in range(loot_notifications.size() - 1, -1, -1):
		var note: Dictionary = loot_notifications[i]
		note["life"] = float(note.get("life", 0.0)) - delta
		if float(note["life"]) <= 0.0:
			loot_notifications.remove_at(i)
	for i in range(loot_feed_labels.size()):
		var label := loot_feed_labels[i]
		var icon_rect := loot_feed_icons[i] if i < loot_feed_icons.size() else null
		if i < loot_notifications.size():
			var note: Dictionary = loot_notifications[i]
			var alpha := clampf(float(note.get("life", 0.0)) / 2.5, 0.0, 1.0)
			label.text = str(note.get("text", ""))
			label.modulate = Color(1.0, 0.92, 0.58, alpha)
			if icon_rect != null:
				var icon_id := str(note.get("icon", ""))
				icon_rect.texture = _item_icon(icon_id) if icon_id != "" else null
				icon_rect.modulate = Color(1.0, 0.92, 0.58, alpha)
		else:
			label.text = ""
			if icon_rect != null:
				icon_rect.texture = null
		var chip := loot_feed_chips[i] if i < loot_feed_chips.size() else null
		if chip != null:
			chip.visible = i < loot_notifications.size()


func _update_held_item_preview() -> void:
	if held_item_panel == null:
		return
	if held_item_id == "":
		held_item_panel.visible = false
		return
	var mouse_pos := get_viewport().get_mouse_position()
	held_item_panel.visible = true
	held_item_panel.offset_left = mouse_pos.x + 16.0
	held_item_panel.offset_top = mouse_pos.y + 14.0
	held_item_panel.offset_right = held_item_panel.offset_left + 72.0
	held_item_panel.offset_bottom = held_item_panel.offset_top + 40.0
	held_item_icon.texture = _item_icon(held_item_id)
	held_item_amount_label.text = "x%d" % held_item_amount


func _trigger_hit_stop(duration: float) -> void:
	combat_hit_stop_timer = maxf(combat_hit_stop_timer, clampf(duration, 0.0, 0.075))


func _add_camera_trauma(strength: float, duration: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)
	camera_shake_time = maxf(camera_shake_time, duration)
	camera_shake_duration = maxf(0.01, camera_shake_time)


func _combat_impact_color(damage_type: String, player_hit: bool, guarded: bool) -> Color:
	if guarded:
		return Color("b9c5d1")
	if player_hit:
		return Color("ff7b72")
	if damage_type == "poison":
		return Color("89e36b")
	if damage_type == "fire":
		return Color("ff8a3c")
	if damage_type == "arcane":
		return Color("c49cff")
	return Color("ffd77a")


func _spawn_combat_impact(pos: Vector2, direction: Vector2, damage_type: String, heavy: bool, player_hit := false, guarded := false) -> void:
	var dir := direction.normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	var color := _combat_impact_color(damage_type, player_hit, guarded)
	var lifetime := 0.18 if heavy else 0.13
	combat_impacts.append({
		"pos": pos,
		"dir": dir,
		"life": lifetime,
		"max_life": lifetime,
		"color": color,
		"heavy": heavy,
		"guarded": guarded
	})
	# Sparks spray back from the contact point, making the hit direction clear.
	var particle_count := 12 if heavy else 7
	for i in range(particle_count):
		var spread := rng.randf_range(-1.05, 1.05)
		var spark_dir := (-dir).rotated(spread)
		if i % 4 == 0:
			spark_dir = Vector2(-dir.y, dir.x) * (-1.0 if i % 8 == 0 else 1.0)
		var particle_life := rng.randf_range(0.18, 0.42 if heavy else 0.32)
		hit_particles.append({
			"pos": pos + spark_dir * rng.randf_range(1.0, 5.0),
			"vel": spark_dir * rng.randf_range(70.0, 175.0 if heavy else 135.0),
			"life": particle_life,
			"max_life": particle_life,
			"size": 3.0 if heavy and i < 3 else 2.0,
			"gravity": 150.0,
			"color": color.lightened(rng.randf_range(0.0, 0.22))
		})


func _update_combat_impacts(delta: float) -> void:
	for i in range(combat_impacts.size() - 1, -1, -1):
		var impact: Dictionary = combat_impacts[i]
		impact["life"] = float(impact.get("life", 0.0)) - delta
		if float(impact["life"]) <= 0.0:
			combat_impacts.remove_at(i)
		else:
			combat_impacts[i] = impact


func _spawn_hit_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var dir := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		var particle_life := rng.randf_range(0.22, 0.48)
		hit_particles.append({
			"pos": pos + dir * rng.randf_range(0.0, 8.0),
			"vel": dir * rng.randf_range(35.0, 115.0),
			"life": particle_life,
			"max_life": particle_life,
			"size": 2.0,
			"gravity": 0.0,
			"color": color
		})


func _update_hit_particles(delta: float) -> void:
	for i in range(hit_particles.size() - 1, -1, -1):
		var particle: Dictionary = hit_particles[i]
		var pos: Vector2 = particle["pos"]
		var vel: Vector2 = particle["vel"]
		vel.y += float(particle.get("gravity", 0.0)) * delta
		pos += vel * delta
		vel *= pow(0.88, delta * 60.0)
		particle["pos"] = pos
		particle["vel"] = vel
		particle["life"] = float(particle.get("life", 0.0)) - delta
		if float(particle["life"]) <= 0.0:
			hit_particles.remove_at(i)
		else:
			hit_particles[i] = particle


func _nearest_enemy_index(origin: Vector2, max_distance: float) -> int:
	var best_index := -1
	var best_distance := max_distance
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if not _enemy_can_be_hit(enemy):
			continue
		var distance := _closest_point_on_rect(_enemy_hitbox_rect(enemy), origin).distance_to(origin)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _move_player(motion: Vector2) -> void:
	if motion == Vector2.ZERO:
		return

	var next_pos := player_position + motion
	var next_rect := Rect2(next_pos - PLAYER_SIZE * 0.5, PLAYER_SIZE)

	if not _rect_collides(next_rect):
		player_position = next_pos
		if motion.y > 0.0:
			player_on_floor = false
		return

	if motion.x != 0.0:
		while absf(motion.x) > 0.5:
			var step := Vector2(signf(motion.x), 0.0)
			var stepped_rect := Rect2(player_position + step - PLAYER_SIZE * 0.5, PLAYER_SIZE)
			if _rect_collides(stepped_rect):
				# The terrain is tile-based, so a one-tile rise used to behave like
				# an invisible wall. Step up a single natural terrain tile instead.
				if _try_step_up(step):
					motion.x -= step.x
					continue
				player_velocity.x = 0.0
				return
			player_position += step
			motion.x -= step.x
		# NOTE: do NOT zero player_velocity.x here — it resets the
		# acceleration every frame and kills speed on auto step-up.
		return

	if motion.y != 0.0:
		var down := motion.y > 0.0
		while absf(motion.y) > 0.5:
			var step := Vector2(0.0, signf(motion.y))
			var stepped_rect := Rect2(player_position + step - PLAYER_SIZE * 0.5, PLAYER_SIZE)
			var blocked := _rect_collides_falling(stepped_rect) if down else _rect_collides(stepped_rect)
			if blocked:
				if down:
					player_on_floor = true
				player_velocity.y = 0.0
				return
			player_position += step
			motion.y -= step.y
		player_velocity.y = 0.0


func _try_step_up(horizontal_step: Vector2) -> bool:
	if not player_on_floor:
		return false
	for height in range(1, AUTO_STEP_HEIGHT + 1):
		var candidate_position := player_position + horizontal_step + Vector2(0.0, -float(height))
		var candidate_rect := Rect2(candidate_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
		if not _rect_collides(candidate_rect):
			player_position = candidate_position
			player_velocity.y = 0.0
			player_on_floor = true
			return true
	return false


func _rect_collides(rect: Rect2) -> bool:
	var min_x := floori(rect.position.x / TILE_SIZE)
	var max_x := floori((rect.position.x + rect.size.x - 1.0) / TILE_SIZE)
	var min_y := floori(rect.position.y / TILE_SIZE)
	var max_y := floori((rect.position.y + rect.size.y - 1.0) / TILE_SIZE)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _is_solid(x, y):
				return true
	return false


## Like _rect_collides but PLATFORM tiles also block (used for falling down).
func _rect_collides_falling(rect: Rect2) -> bool:
	var min_x := floori(rect.position.x / TILE_SIZE)
	var max_x := floori((rect.position.x + rect.size.x - 1.0) / TILE_SIZE)
	var min_y := floori(rect.position.y / TILE_SIZE)
	var max_y := floori((rect.position.y + rect.size.y - 1.0) / TILE_SIZE)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile := _get_tile(x, y)
			if _is_solid(x, y) or tile == Tile.PLATFORM:
				return true
	return false


func _is_on_floor() -> bool:
	var foot_rect := Rect2(
		Vector2(player_position.x - PLAYER_SIZE.x * 0.5 + 2.0, player_position.y + PLAYER_SIZE.y * 0.5),
		Vector2(PLAYER_SIZE.x - 4.0, 2.0)
	)
	return _rect_collides_falling(foot_rect)


func _handle_block_actions() -> void:
	if inventory_open or full_map_open:
		mining_progress = 0.0
		mining_target = Vector2i(-999, -999)
		return
	# Keep our own mouse state in addition to the InputMap action. This avoids
	# losing a held left click if the action map is not refreshed correctly.
	var is_mining := mouse_mine_held or Input.is_action_pressed("mine")
	if is_mining:
		# Mining always follows the block currently under the cursor. A held
		# button must never keep mining the previous target after the cursor moves.
		var cursor_target := _mouse_tile()
		if mining_target != cursor_target:
			mining_target = cursor_target
			mining_progress = 0.0
		_mine_target_tile(cursor_target)
	else:
		mining_progress = 0.0
		mining_target = Vector2i(-999, -999)

	if Input.is_action_just_pressed("place"):
		_place_target_tile()


func _mine_target_tile(tile_pos: Vector2i) -> void:
	if not _can_interact(tile_pos):
		return
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	if tile == Tile.AIR:
		_advance_mining_target(tile_pos)
		return
	if tile == Tile.WATER or tile == Tile.LAVA:
		mining_progress = 0.0
		mining_target = tile_pos
		return
	if _tool_power() < int(tile_required_power.get(tile, 1)):
		mining_progress = 0.0
		mining_target = tile_pos
		return
	if mining_target != tile_pos:
		mining_target = tile_pos
		mining_progress = 0.0

	var hardness := _mining_hardness(tile, tile_pos)
	mining_progress += get_process_delta_time() * _tool_speed()
	if mining_progress < hardness:
		return
	var mining_world_pos := Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	_emit_noise(mining_world_pos, clampf(82.0 + hardness * 42.0, 82.0, 145.0), "mining", 0.92)
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("mine", {"x": tile_pos.x, "y": tile_pos.y})
		_start_mining_tool_animation(tile_pos)
		_play_sound("mine")
		_advance_mining_target(tile_pos)
		return

	var item_id := str(tile_to_item.get(tile, "dirt"))
	if tile == Tile.LEAVES:
		_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
		_start_mining_tool_animation(tile_pos)
		_play_sound("mine")
		_advance_mining_target(tile_pos)
		return
	if tile == Tile.WOOD and _is_tree_base(tile_pos):
		_fell_tree_from(tile_pos)
		_start_mining_tool_animation(tile_pos)
		_play_sound("mine")
		_advance_mining_target(tile_pos)
		return
	if tile == Tile.STONE:
		stone_broken_count += 1
		if stone_broken_count >= 140 and not stone_beast_spawned and not stone_beast_defeated:
			_spawn_stone_beast()
	_spawn_loot(Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5), item_id, 1)
	_add_rare_drop(tile, Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5))
	if item_to_tile.has(item_id):
		selected_block = int(item_to_tile[item_id])
	_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
	_settle_unsupported_chest(tile_pos + Vector2i(0, -1))
	_start_mining_tool_animation(tile_pos)
	_play_sound("mine")
	_advance_mining_target(tile_pos)


func _advance_mining_target(from_pos: Vector2i) -> void:
	mining_progress = 0.0
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var direction := Vector2i(signi(from_pos.x - player_tile.x), signi(from_pos.y - player_tile.y))
	if direction == Vector2i.ZERO:
		direction = Vector2i(0, 1)
	for step in range(1, 7):
		var candidate := from_pos + direction * step
		if not _in_bounds(candidate.x, candidate.y) or not _can_interact(candidate):
			break
		var next_tile := _get_tile(candidate.x, candidate.y)
		if next_tile != Tile.AIR and next_tile != Tile.WATER and next_tile != Tile.LAVA:
			mining_target = candidate
			return
	mining_target = Vector2i(-999, -999)


func _start_mining_tool_animation(tile_pos: Vector2i) -> void:
	var target_pos := Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	var direction := (target_pos - player_position).normalized()
	if direction.length() < 0.1:
		direction = Vector2(float(facing), 0)
	_start_attack_animation("slash", direction, Color("ffd98a"), 0.18)


func _mining_hardness(tile: int, tile_pos: Vector2i) -> float:
	var hardness := float(tile_hardness.get(tile, 0.4))
	if tile == Tile.WOOD and _is_tree_base(tile_pos):
		hardness *= TREE_BASE_HARDNESS_MULTIPLIER
	return hardness


func _is_tree_base(tile_pos: Vector2i) -> bool:
	if _get_tile(tile_pos.x, tile_pos.y) != Tile.WOOD:
		return false
	var below := _get_tile(tile_pos.x, tile_pos.y + 1)
	if below == Tile.WOOD or below == Tile.LEAVES:
		return false
	return below == Tile.GRASS or below == Tile.DIRT or below == Tile.MOSS or below == Tile.ROOT or below == Tile.STONE or _is_biome_topsoil_tile(below)


func _fell_tree_from(base_pos: Vector2i) -> void:
	var tree_id := int(tree_tile_owners.get(_tile_key(base_pos), -1))
	if tree_id >= 0:
		_fell_owned_tree(base_pos, tree_id)
		return
	_fell_legacy_tree(base_pos)


func _fell_owned_tree(base_pos: Vector2i, tree_id: int) -> void:
	var owned_wood: Array[Vector2i] = []
	var owned_leaves: Array[Vector2i] = []
	for key_variant in tree_tile_owners.keys():
		var key := str(key_variant)
		if int(tree_tile_owners.get(key, -1)) != tree_id:
			continue
		var parts := key.split(",")
		if parts.size() != 2:
			continue
		var pos := Vector2i(int(parts[0]), int(parts[1]))
		var tile := _get_tile(pos.x, pos.y)
		if tile == Tile.WOOD:
			owned_wood.append(pos)
		elif tile == Tile.LEAVES:
			owned_leaves.append(pos)
	for pos in owned_wood:
		_set_tile(pos.x, pos.y, Tile.AIR)
	for pos in owned_leaves:
		_set_tile(pos.x, pos.y, Tile.AIR)
	_finish_tree_felling(base_pos, owned_wood.size(), owned_leaves.size())


func _fell_legacy_tree(base_pos: Vector2i) -> void:
	const TREE_RADIUS_X := 10
	const TREE_HEIGHT := 18
	var nearby_bases := _nearby_tree_bases(base_pos, TREE_RADIUS_X + 4, 10)
	var wood_queue: Array[Vector2i] = [base_pos]
	var wood_visited := {}
	var owned_wood: Array[Vector2i] = []
	while not wood_queue.is_empty():
		var current: Vector2i = wood_queue.pop_front()
		var key := "%d,%d" % [current.x, current.y]
		if wood_visited.has(key):
			continue
		wood_visited[key] = true
		if not _in_bounds(current.x, current.y):
			continue
		if abs(current.x - base_pos.x) > TREE_RADIUS_X or current.y < base_pos.y - TREE_HEIGHT or current.y > base_pos.y + 1:
			continue
		if _get_tile(current.x, current.y) != Tile.WOOD:
			continue
		if current != base_pos and _is_tree_base(current):
			continue
		if not _tree_tile_belongs_to_base(current, base_pos, nearby_bases):
			continue
		owned_wood.append(current)
		_set_tile(current.x, current.y, Tile.AIR)
		for offset in [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1)
		]:
			wood_queue.append(current + offset)

	var leaf_queue: Array[Vector2i] = []
	for wood_pos in owned_wood:
		for offset in [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1)
		]:
			leaf_queue.append(wood_pos + offset)
	var leaf_visited := {}
	var owned_leaves: Array[Vector2i] = []
	while not leaf_queue.is_empty():
		var current: Vector2i = leaf_queue.pop_front()
		var key := "%d,%d" % [current.x, current.y]
		if leaf_visited.has(key):
			continue
		leaf_visited[key] = true
		if not _in_bounds(current.x, current.y):
			continue
		if abs(current.x - base_pos.x) > TREE_RADIUS_X or current.y < base_pos.y - TREE_HEIGHT or current.y > base_pos.y + 1:
			continue
		if _get_tile(current.x, current.y) != Tile.LEAVES:
			continue
		if not _tree_tile_belongs_to_base(current, base_pos, nearby_bases):
			continue
		owned_leaves.append(current)
		_set_tile(current.x, current.y, Tile.AIR)
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			leaf_queue.append(current + offset)
	_finish_tree_felling(base_pos, owned_wood.size(), owned_leaves.size())


func _nearby_tree_bases(base_pos: Vector2i, radius_x: int, radius_y: int) -> Array[Vector2i]:
	var bases: Array[Vector2i] = [base_pos]
	for y in range(maxi(0, base_pos.y - radius_y), mini(WORLD_HEIGHT, base_pos.y + radius_y + 1)):
		for x in range(maxi(0, base_pos.x - radius_x), mini(WORLD_WIDTH, base_pos.x + radius_x + 1)):
			var candidate := Vector2i(x, y)
			if candidate != base_pos and _is_tree_base(candidate):
				bases.append(candidate)
	return bases


func _tree_tile_belongs_to_base(tile_pos: Vector2i, base_pos: Vector2i, nearby_bases: Array[Vector2i]) -> bool:
	var own_distance := absf(float(tile_pos.x - base_pos.x)) * 2.0 + absf(float(tile_pos.y - base_pos.y)) * 0.25
	for other_base in nearby_bases:
		if other_base == base_pos:
			continue
		var other_distance := absf(float(tile_pos.x - other_base.x)) * 2.0 + absf(float(tile_pos.y - other_base.y)) * 0.25
		if other_distance <= own_distance:
			return false
	return true


func _finish_tree_felling(base_pos: Vector2i, removed_wood: int, removed_leaves: int) -> void:
	if removed_wood <= 0:
		return
	var drop_pos := Vector2(base_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, -TILE_SIZE * 0.5)
	_spawn_loot(drop_pos, "wood", removed_wood)
	var sapling_chance := clampf(0.16 + float(removed_leaves) * 0.008, 0.16, 0.48)
	var sapling_drop := 1 if rng.randf() < sapling_chance else 0
	if sapling_drop > 0:
		_spawn_loot(drop_pos + Vector2(10, -6), "sapling", sapling_drop)
	last_message = "Tree felled: wood x%d%s." % [removed_wood, ", sapling x1" if sapling_drop > 0 else ""]

func _place_target_tile() -> void:
	var tile_pos := _mouse_tile()
	if npc_wanderer_active and player_position.distance_to(npc_wanderer_pos) < 90.0:
		_open_path_dialog()
		return
	if not _can_interact(tile_pos):
		return
	var target_tile := _get_tile(tile_pos.x, tile_pos.y)
	if target_tile in [Tile.STONE_ALTAR, Tile.DEPTH_ALTAR, Tile.SKY_OBELISK] and network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("interact", {"x": tile_pos.x, "y": tile_pos.y})
		return
	if target_tile == Tile.STONE_ALTAR:
		_activate_stone_altar(tile_pos)
		return
	if _get_tile(tile_pos.x, tile_pos.y) == Tile.DEPTH_ALTAR:
		_on_depth_altar_interact()
		return
	if _get_tile(tile_pos.x, tile_pos.y) == Tile.SKY_OBELISK:
		_on_sky_obelisk_interact()
		return
	if _get_tile(tile_pos.x, tile_pos.y) == Tile.CHEST:
		_open_chest(tile_pos)
		return
	if _get_tile(tile_pos.x, tile_pos.y) != Tile.AIR:
		return
	# Blueprint building: place the selected structure using raw resources.
	if active_build_id != "":
		if int(inventory.get("blueprint", 0)) <= 0:
			last_message = "You need a Blueprint to build."
			return
		var build_def: Dictionary = build_catalog.get(active_build_id, {})
		if build_def.is_empty():
			return
		var build_cost: Dictionary = build_def.get("cost", {})
		for res_id in build_cost.keys():
			if int(inventory.get(str(res_id), 0)) < int(build_cost[res_id]):
				last_message = "Not enough %s." % _item_display_name(str(res_id))
				return
		var build_tile := int(build_def.get("tile", Tile.AIR))
		if build_tile == Tile.CHEST and not _is_solid(tile_pos.x, tile_pos.y + 1):
			last_message = "Chests need solid ground below."
			return
		if build_tile == Tile.TORCH:
			var has_support := (
				_is_solid(tile_pos.x, tile_pos.y + 1)
				or _is_solid(tile_pos.x - 1, tile_pos.y)
				or _is_solid(tile_pos.x + 1, tile_pos.y)
			)
			if not has_support:
				last_message = "Torches need a floor or wall."
				return
		var tile_rect := Rect2(Vector2(tile_pos) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
		var player_rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
		if tile_rect.intersects(player_rect):
			return
		if network_session != null and network_session.is_client() and network_session.joined:
			network_session.request_game_action("place", {"x": tile_pos.x, "y": tile_pos.y, "item_id": "", "build_id": active_build_id})
			return
		for res_id in build_cost.keys():
			inventory[str(res_id)] = int(inventory.get(str(res_id), 0)) - int(build_cost[res_id])
		_set_tile(tile_pos.x, tile_pos.y, build_tile)
		if build_tile == Tile.CHEST:
			chest_loot[_tile_key(tile_pos)] = {}
		elif build_tile == Tile.BED:
			bed_spawn_pos = Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5, tile_pos.y * TILE_SIZE)
			last_message = "Spawn point set here."
		_play_sound("hit")
		return
	var item_id := _selected_item()
	if not item_to_tile.has(item_id):
		return
	if int(inventory.get(item_id, 0)) <= 0:
		return
	var tile := int(item_to_tile[item_id])
	if tile == Tile.SAPLING:
		var ground := _get_tile(tile_pos.x, tile_pos.y + 1)
		if ground != Tile.GRASS and ground != Tile.DIRT and ground != Tile.MOSS and ground != Tile.MUD:
			last_message = "Saplings need grass, dirt, moss, or mud below."
			return
	elif tile == Tile.CHEST:
		if not _is_solid(tile_pos.x, tile_pos.y + 1):
			last_message = "Chests need solid ground below."
			return
	elif tile == Tile.TORCH:
		var has_support := (
			_is_solid(tile_pos.x, tile_pos.y + 1)
			or _is_solid(tile_pos.x - 1, tile_pos.y)
			or _is_solid(tile_pos.x + 1, tile_pos.y)
		)
		if not has_support:
			last_message = "Torches need a floor or wall."
			return
	var tile_rect := Rect2(Vector2(tile_pos) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
	var player_rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	if tile_rect.intersects(player_rect):
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("place", {"x": tile_pos.x, "y": tile_pos.y, "item_id": item_id, "build_id": ""})
		return
	inventory[item_id] = int(inventory[item_id]) - 1
	selected_block = tile
	_set_tile(tile_pos.x, tile_pos.y, tile)
	if tile == Tile.CHEST:
		chest_loot[_tile_key(tile_pos)] = {}
	elif tile == Tile.BED:
		# Set spawn point at this bed.
		bed_spawn_pos = Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5, tile_pos.y * TILE_SIZE)
		last_message = "Spawn point set here."


func _settle_unsupported_chest(chest_pos: Vector2i) -> void:
	if not _in_bounds(chest_pos.x, chest_pos.y) or _get_tile(chest_pos.x, chest_pos.y) != Tile.CHEST:
		return
	if _is_solid(chest_pos.x, chest_pos.y + 1):
		return
	var landing_pos := Vector2i(-1, -1)
	for y in range(chest_pos.y + 1, WORLD_HEIGHT - 1):
		if _get_tile(chest_pos.x, y) == Tile.AIR and _is_solid(chest_pos.x, y + 1):
			landing_pos = Vector2i(chest_pos.x, y)
			break
	if landing_pos.x < 0:
		return

	var old_key := _tile_key(chest_pos)
	var loot: Dictionary = chest_loot.get(old_key, {})
	chest_loot.erase(old_key)
	_set_tile(chest_pos.x, chest_pos.y, Tile.AIR)
	_set_tile(landing_pos.x, landing_pos.y, Tile.CHEST)
	chest_loot[_tile_key(landing_pos)] = loot
	if active_chest_pos == chest_pos:
		active_chest_pos = landing_pos
		active_chest_key = _tile_key(landing_pos)


func _open_chest(tile_pos: Vector2i) -> void:
	var key := _tile_key(tile_pos)
	if not chest_loot.has(key):
		chest_loot[key] = {}
	active_chest_key = key
	active_chest_pos = tile_pos
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("chest_open", {"chest_key": key})
	elif network_session != null and network_session.is_server():
		network_open_chests[1] = key
	inventory_screen = "inventory"
	inventory_open = true
	last_message = "Opened Ancient Chest."
	_play_sound("pickup")


func _activate_stone_altar(tile_pos: Vector2i) -> void:
	if stone_beast_defeated:
		last_message = "The stone altar is silent."
		return
	if stone_beast_spawned:
		last_message = "The Stone Beast is already awake."
		return
	_spawn_stone_beast()
	_set_tile(tile_pos.x, tile_pos.y, Tile.RUIN)


func _spawn_stone_beast() -> void:
	var pos := _find_spawn_position_near_player(10, 16)
	pos.y += 80.0
	_spawn_enemy("stone_beast", pos)
	stone_beast_spawned = true
	_play_sound("boss")
	last_message = "Stone Beast has broken loose."


func _close_chest() -> void:
	if active_chest_key != "" and network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("chest_close", {"chest_key": active_chest_key})
	elif network_session != null and network_session.is_server():
		network_open_chests.erase(1)
	active_chest_key = ""
	active_chest_pos = Vector2i(-999, -999)


func _active_chest_items() -> Array[String]:
	var keys: Array[String] = []
	if active_chest_key == "" or not chest_loot.has(active_chest_key):
		return keys
	var loot: Dictionary = chest_loot[active_chest_key]
	for item_id in loot.keys():
		if int(loot[item_id]) > 0:
			keys.append(str(item_id))
	keys.sort()
	return keys


func _update_selection() -> void:
	for i in range(HOTBAR_SIZE):
		if Input.is_action_just_pressed("hotbar_%d" % (i + 1)):
			selected_slot = i
			var item_id := _selected_item()
			if tools.has(item_id):
				current_tool = item_id
			elif item_to_tile.has(item_id):
				selected_block = int(item_to_tile[item_id])
			_network_client_sync_loadout()


func _on_hotbar_slot_pressed(index: int) -> void:
	if held_item_id != "":
		return
	selected_slot = clampi(index, 0, hotbar.size() - 1)
	_update_selection_from_hotbar()
	_network_client_sync_loadout()


func _on_hotbar_slot_gui_input(event: InputEvent, index: int) -> void:
	_track_slot_longpress_event(event, "hotbar", index)
	if not inventory_open or held_item_id == "":
		return
	if event is InputEventMouseButton and not event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_drop_held_item_on_hotbar(index)
			get_viewport().set_input_as_handled()


func _track_slot_longpress_event(event: InputEvent, kind: String, index: int) -> void:
	# Touch devices deliver both the raw touch and an emulated mouse event;
	# only one of them may drive the long-press timer.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_slot_longpress(kind, index, touch.index, touch.position + _slot_event_origin(kind, index))
		else:
			_slot_longpress_pointer_released(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_slot_longpress_pointer_moved(drag.index, drag.position + _slot_event_origin(kind, index))
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_begin_slot_longpress(kind, index, -2, mouse.position + _slot_event_origin(kind, index))
			else:
				_slot_longpress_pointer_released(-2)


func _slot_event_origin(kind: String, index: int) -> Vector2:
	var button: Button = null
	if kind == "hotbar" and index >= 0 and index < hotbar_buttons.size():
		button = hotbar_buttons[index]
	elif kind == "inventory" and index >= 0 and index < inventory_slot_buttons.size():
		button = inventory_slot_buttons[index]
	if button == null:
		return Vector2.ZERO
	return button.get_global_rect().position


func _on_inventory_slot_pressed(index: int) -> void:
	if held_item_id != "":
		return
	var items := _inventory_item_ids()
	if index < 0 or index >= items.size():
		return
	var item_id := str(items[index])
	if int(inventory.get(item_id, 0)) <= 0:
		return
	selected_inventory_item_id = item_id
	last_message = "Selected %s." % _item_display_name(item_id)


func _on_inventory_slot_gui_input(event: InputEvent, index: int) -> void:
	if not inventory_open:
		return
	_track_slot_longpress_event(event, "inventory", index)
	if event is InputEventMouseButton and held_item_id == "":
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT and mouse_event.button_index != MOUSE_BUTTON_RIGHT:
			return
		if not mouse_event.pressed:
			return
		var items := _inventory_item_ids()
		if index < 0 or index >= items.size():
			return
		var item_id := str(items[index])
		var amount := int(inventory.get(item_id, 0))
		if amount <= 0:
			return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			pending_inventory_right_drop_id = item_id
			pending_inventory_right_drop_consumed = false
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and pending_inventory_right_drop_id == item_id:
			_drop_inventory_item_to_world(item_id, amount)
			pending_inventory_right_drop_consumed = true
		else:
			_take_inventory_stack(item_id, amount)
		get_viewport().set_input_as_handled()


func _on_chest_slot_gui_input(event: InputEvent, index: int) -> void:
	if active_chest_key == "":
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and held_item_id == "":
			if mouse_event.button_index != MOUSE_BUTTON_LEFT and mouse_event.button_index != MOUSE_BUTTON_RIGHT:
				return
			var items := _active_chest_items()
			if index < 0 or index >= items.size():
				return
			var item_id := str(items[index])
			var loot: Dictionary = chest_loot[active_chest_key]
			var amount := int(loot.get(item_id, 0))
			if amount <= 0:
				return
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_transfer_chest_stack_to_inventory(item_id)
			else:
				_take_chest_stack(item_id, maxi(1, int(ceil(float(amount) * 0.5))))
			# Consume only after the transfer, so the click cannot reach world mining.
			get_viewport().set_input_as_handled()
		elif not mouse_event.pressed and held_item_id != "" and (mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_RIGHT):
			_drop_held_item_on_chest()
			get_viewport().set_input_as_handled()


func _on_equipment_slot_gui_input(event: InputEvent, slot: String) -> void:
	if not inventory_open or held_item_id == "":
		return
	if event is InputEventMouseButton and not event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_drop_held_item_on_equipment(slot)
			get_viewport().set_input_as_handled()


func _take_inventory_stack(item_id: String, amount: int) -> void:
	var available := int(inventory.get(item_id, 0))
	var taken := clampi(amount, 1, available)
	inventory[item_id] = available - taken
	if int(inventory.get(item_id, 0)) <= 0:
		inventory.erase(item_id)
	held_item_id = item_id
	held_item_amount = taken
	selected_inventory_item_id = item_id
	last_message = "Dragging %s x%d." % [_item_display_name(item_id), taken]


func _take_chest_stack(item_id: String, amount: int) -> void:
	if active_chest_key == "" or not chest_loot.has(active_chest_key):
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("chest_take", {"chest_key": active_chest_key, "item_id": item_id, "amount": amount})
		return
	var loot: Dictionary = chest_loot[active_chest_key]
	var available := int(loot.get(item_id, 0))
	var taken := clampi(amount, 1, available)
	loot[item_id] = available - taken
	if int(loot.get(item_id, 0)) <= 0:
		loot.erase(item_id)
	chest_loot[active_chest_key] = loot
	if network_session != null and network_session.is_server():
		_network_broadcast_chest(active_chest_key)
	held_item_id = item_id
	held_item_amount = taken
	last_message = "Dragging %s x%d from chest." % [_item_display_name(item_id), taken]


func _transfer_chest_stack_to_inventory(item_id: String) -> void:
	if active_chest_key == "" or not chest_loot.has(active_chest_key):
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("chest_take", {"chest_key": active_chest_key, "item_id": item_id, "amount": 0})
		return
	var loot: Dictionary = chest_loot[active_chest_key]
	var amount := int(loot.get(item_id, 0))
	if amount <= 0:
		return
	_add_item(item_id, amount)
	loot.erase(item_id)
	chest_loot[active_chest_key] = loot
	if network_session != null and network_session.is_server():
		_network_broadcast_chest(active_chest_key)
	selected_inventory_item_id = item_id
	_add_loot_notification(item_id, amount)
	_play_sound("pickup")
	last_message = "Took %s x%d from chest." % [_item_display_name(item_id), amount]


func _drop_inventory_item_to_world(item_id: String, amount: int) -> void:
	var available := int(inventory.get(item_id, 0))
	if available <= 0:
		return
	var dropped := clampi(amount, 1, available)
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("drop", {"item_id": item_id, "amount": dropped})
		return
	inventory[item_id] = available - dropped
	if int(inventory.get(item_id, 0)) <= 0:
		inventory.erase(item_id)
		if selected_inventory_item_id == item_id:
			selected_inventory_item_id = ""
	var drop_pos := player_position + Vector2(float(facing) * 18.0, -6.0)
	var drop_vel := Vector2(float(facing) * 42.0, -28.0)
	_spawn_loot_with_velocity(drop_pos, item_id, dropped, drop_vel, 0.85)
	_clear_equipped_if_missing(item_id)
	last_message = "Dropped %s x%d." % [_item_display_name(item_id), dropped]


func _release_held_item(screen_pos: Vector2) -> void:
	if held_item_id == "":
		return
	for i in range(hotbar_buttons.size()):
		if hotbar_buttons[i].get_global_rect().has_point(screen_pos):
			_drop_held_item_on_hotbar(i)
			return
	if weapon_slot_button.get_global_rect().has_point(screen_pos):
		_drop_held_item_on_equipment("weapon")
		return
	if armor_slot_button.get_global_rect().has_point(screen_pos):
		_drop_held_item_on_equipment("armor")
		return
	if accessory_slot_button.get_global_rect().has_point(screen_pos):
		_drop_held_item_on_equipment("accessory")
		return
	if chest_panel.visible and chest_panel.get_global_rect().has_point(screen_pos):
		_drop_held_item_on_chest()
		return
	if inventory_panel.get_global_rect().has_point(screen_pos) or crafting_panel.get_global_rect().has_point(screen_pos):
		_return_held_item_to_inventory()
		return
	_throw_held_item_into_world()


func _drop_held_item_on_hotbar(index: int) -> void:
	if held_item_id == "":
		return
	selected_slot = clampi(index, 0, hotbar.size() - 1)
	hotbar[selected_slot] = held_item_id
	_return_held_item_to_inventory()
	_update_selection_from_hotbar()
	last_message = "Assigned %s to hotbar slot %d." % [_item_display_name(str(hotbar[selected_slot])), selected_slot + 1]
	_network_client_sync_loadout()


func _drop_held_item_on_equipment(slot: String) -> void:
	if held_item_id == "":
		return
	if gear_stats.has(held_item_id) and str((gear_stats[held_item_id] as Dictionary).get("slot", "")) == slot:
		_equip_item_id(held_item_id)
		_return_held_item_to_inventory()
	else:
		_return_held_item_to_inventory()
		last_message = "That item does not fit this slot."


func _return_held_item_to_inventory() -> void:
	if held_item_id == "":
		return
	_add_item(held_item_id, held_item_amount)
	selected_inventory_item_id = held_item_id
	held_item_id = ""
	held_item_amount = 0


func _drop_held_item_on_chest() -> void:
	if held_item_id == "":
		return
	if active_chest_key == "":
		_return_held_item_to_inventory()
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("chest_store", {"chest_key": active_chest_key, "item_id": held_item_id, "amount": held_item_amount})
		last_message = "Storing %s x%d…" % [_item_display_name(held_item_id), held_item_amount]
		held_item_id = ""
		held_item_amount = 0
		return
	var loot: Dictionary = chest_loot.get(active_chest_key, {})
	loot[held_item_id] = int(loot.get(held_item_id, 0)) + held_item_amount
	chest_loot[active_chest_key] = loot
	if network_session != null and network_session.is_server():
		_network_broadcast_chest(active_chest_key)
	last_message = "Stored %s x%d." % [_item_display_name(held_item_id), held_item_amount]
	held_item_id = ""
	held_item_amount = 0


func _throw_held_item_into_world() -> void:
	if held_item_id == "":
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("drop", {"item_id": held_item_id, "amount": held_item_amount})
		last_message = "Dropping %s x%d…" % [_item_display_name(held_item_id), held_item_amount]
		held_item_id = ""
		held_item_amount = 0
		return
	var drop_pos := player_position + Vector2(float(facing) * 18.0, -6.0)
	var drop_vel := Vector2(float(facing) * 55.0, -45.0)
	_spawn_loot_with_velocity(drop_pos, held_item_id, held_item_amount, drop_vel, 0.75)
	last_message = "Dropped %s x%d." % [_item_display_name(held_item_id), held_item_amount]
	_clear_equipped_if_missing(held_item_id)
	held_item_id = ""
	held_item_amount = 0


func _clear_equipped_if_missing(item_id: String) -> void:
	if int(inventory.get(item_id, 0)) > 0:
		return
	if equipped_weapon == item_id:
		equipped_weapon = ""
	if equipped_armor == item_id:
		equipped_armor = ""
	if equipped_accessory == item_id:
		equipped_accessory = ""


func _assign_selected_inventory_to_hotbar() -> void:
	var item_id := selected_inventory_item_id
	if item_id == "" or int(inventory.get(item_id, 0)) <= 0:
		last_message = "Select an inventory item first."
		return
	hotbar[selected_slot] = item_id
	_update_selection_from_hotbar()
	last_message = "Assigned %s to hotbar slot %d." % [_item_display_name(item_id), selected_slot + 1]
	_network_client_sync_loadout()


func _equip_selected_inventory_item() -> void:
	if selected_inventory_item_id == "":
		last_message = "Select an inventory item first."
		return
	_equip_item_id(selected_inventory_item_id)


func _drop_selected_inventory_item() -> void:
	var item_id := selected_inventory_item_id
	if item_id == "" or int(inventory.get(item_id, 0)) <= 0:
		last_message = "Select an inventory item first."
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("drop", {"item_id": item_id, "amount": 1})
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) - 1
	if int(inventory.get(item_id, 0)) <= 0:
		inventory.erase(item_id)
		selected_inventory_item_id = ""
	var drop_pos := player_position + Vector2(float(facing) * 18.0, -6.0)
	var drop_vel := Vector2(float(facing) * 55.0, -45.0)
	_spawn_loot_with_velocity(drop_pos, item_id, 1, drop_vel, 0.75)
	last_message = "Dropped %s." % _item_display_name(item_id)


func _sanitize_hotbar() -> void:
	# A hotbar slot is only a reference to an item that actually exists.
	# Clear stale references immediately after crafting, placing, or dropping.
	for i in range(hotbar.size()):
		var item_id := str(hotbar[i])
		if item_id == "" or int(inventory.get(item_id, 0)) <= 0:
			hotbar[i] = ""
	if selected_slot >= 0 and selected_slot < hotbar.size() and str(hotbar[selected_slot]) == "":
		_update_selection_from_hotbar()


func _inventory_item_ids() -> Array[String]:
	var keys: Array[String] = []
	for item_id in inventory.keys():
		if int(inventory[item_id]) <= 0:
			continue
		if int(inventory[item_id]) > 0:
			keys.append(str(item_id))
	keys.sort()
	return keys


func _selected_item() -> String:
	if selected_slot < 0 or selected_slot >= hotbar.size():
		return ""
	return str(hotbar[selected_slot])


func _add_item(item_id: String, amount: int) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	_record_material_found(item_id, amount)
	_maybe_learn_recipes_for_materials()


func _maybe_learn_recipes_for_materials() -> void:
	# Terraria-style: a recipe becomes known the moment the player holds all of
	# its ingredients, so new recipes are discoverable instead of hidden.
	var learned_any := false
	for recipe in recipes:
		var recipe_id := str(recipe.get("id", recipe.get("result", "")))
		if bool(known_recipes.get(recipe_id, false)):
			continue
		var cost: Dictionary = recipe.get("cost", {})
		var has_all := true
		for mat_id in cost.keys():
			if int(inventory.get(str(mat_id), 0)) < int(cost[mat_id]):
				has_all = false
				break
		if has_all:
			known_recipes[recipe_id] = true
			learned_any = true
	if learned_any:
		_mark_journal_updated()
		_ensure_selected_recipe_known()
		if journal_open:
			_refresh_journal()


func _add_rare_drop(tile: int, pos: Vector2) -> void:
	if tile == Tile.ROOT and rng.randf() < 0.12:
		_spawn_loot(pos + Vector2(4, -6), "root_core", 1)
		last_message = "Found rare material: Root Core."
	elif tile == Tile.RUIN and rng.randf() < 0.14:
		_spawn_loot(pos + Vector2(4, -6), "spark_shard", 1)
		last_message = "Found rare material: Spark Shard."
	elif tile == Tile.ASH and rng.randf() < 0.16:
		_spawn_loot(pos + Vector2(4, -6), "memory_shard", 1)
		last_message = "Found rare material: Memory Shard."
	elif tile == Tile.MOSS and rng.randf() < 0.10:
		_spawn_loot(pos + Vector2(4, -6), "wild_badge", 1)
		_play_sound("forest_event")
		last_message = "Mini-event: a forest cache opened."
	elif tile == Tile.GLOW_MUSHROOM and rng.randf() < 0.20:
		_spawn_loot(pos + Vector2(4, -6), "glowcap", 1)
		_play_sound("mushroom_event")
		last_message = "Found rare material: Glowcap."
	elif tile == Tile.ASH_BRICK and rng.randf() < 0.12:
		_spawn_loot(pos + Vector2(4, -6), "ash_relic", 1)
		_play_sound("ash_event")
		last_message = "Mini-event: ash bells answer under the city."
	elif tile == Tile.SUNKEN_STONE and rng.randf() < 0.12:
		_spawn_loot(pos + Vector2(4, -6), "drowned_pearl", 1)
		_play_sound("water_event")
		last_message = "Found rare material: Drowned Pearl."
	elif tile == Tile.LAVA_ROOT and rng.randf() < 0.14:
		_spawn_loot(pos + Vector2(4, -6), "night_ember", 1)
		_play_sound("lava_event")
		last_message = "Mini-event: lava roots pulse with heat."
	elif tile == Tile.ABYSS_CRYSTAL and rng.randf() < 0.18:
		_spawn_loot(pos + Vector2(4, -6), "abyss_lens", 1)
		_play_sound("glass_event")
		last_message = "Mini-event: the glass abyss sings."


func _select_recipe(direction: int) -> void:
	var known_indices := _visible_recipe_indices()
	if known_indices.is_empty():
		return
	var current_position := known_indices.find(selected_recipe_index)
	if current_position < 0:
		selected_recipe_index = known_indices[0]
		return
	selected_recipe_index = known_indices[wrapi(current_position + direction, 0, known_indices.size())]


func _on_recipe_button_pressed(index: int) -> void:
	if index < 0 or index >= recipes.size() or not _recipe_is_known(recipes[index]):
		return
	selected_recipe_index = index
	_update_hud()


func _craft_selected_recipe() -> void:
	var recipe := _selected_recipe()
	if recipe.is_empty():
		last_message = "No known recipe selected."
		return
	var station := str(recipe.get("station", "hand"))
	if not _has_station_nearby(station):
		last_message = "Need nearby station: %s." % _station_display_name(station)
		return
	if network_session != null and network_session.is_client() and network_session.joined:
		network_session.request_game_action("craft", {"recipe_id": str(recipe.get("id", recipe.get("result", "")))})
		return
	var cost: Dictionary = recipe.get("cost", {})
	for item_id in cost.keys():
		if int(inventory.get(str(item_id), 0)) < int(cost[item_id]):
			last_message = "Missing materials for %s." % _item_display_name(str(recipe.get("result", "")))
			return
	for item_id in cost.keys():
		inventory[str(item_id)] = int(inventory.get(str(item_id), 0)) - int(cost[item_id])
	var result := str(recipe.get("result", ""))
	var amount := int(recipe.get("amount", 1))
	_add_item(result, amount)
	_record_recipe_known(str(recipe.get("id", result)))
	if result == "acid_flasks" or result == "wild_badge":
		_record_alchemy_result(result, cost)
	selected_inventory_item_id = result
	hotbar[selected_slot] = result
	_update_selection_from_hotbar()
	last_message = "Crafted %s x%d." % [_item_display_name(result), amount]


func _equip_selected_item() -> void:
	var item_id := _selected_item()
	_equip_item_id(item_id)


func _equip_item_id(item_id: String) -> void:
	if tools.has(item_id):
		current_tool = item_id
		last_message = "Equipped tool: %s." % _item_display_name(item_id)
		_network_client_sync_loadout()
		return
	if not gear_stats.has(item_id):
		last_message = "%s cannot be equipped." % _item_display_name(item_id)
		return
	var gear: Dictionary = gear_stats[item_id]
	var slot := str(gear.get("slot", "weapon"))
	if slot == "weapon":
		equipped_weapon = item_id
	elif slot == "armor":
		equipped_armor = item_id
	elif slot == "accessory":
		equipped_accessory = item_id
	active_class = str(gear.get("class", "Any"))
	if active_class == "Any" and equipped_weapon != "":
		active_class = str((gear_stats.get(equipped_weapon, {}) as Dictionary).get("class", "Warrior"))
	last_message = "Equipped %s." % _item_display_name(item_id)
	_network_client_sync_loadout()


func _has_station_nearby(station: String) -> bool:
	if station == "hand":
		return true
	var wanted_tile := Tile.WORKBENCH
	if station == "furnace":
		wanted_tile = Tile.FURNACE
	elif station == "anvil":
		wanted_tile = Tile.ANVIL
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	for y in range(player_tile.y - 5, player_tile.y + 6):
		for x in range(player_tile.x - 5, player_tile.x + 6):
			if _in_bounds(x, y) and _get_tile(x, y) == wanted_tile:
				return true
	return false


func _selected_recipe() -> Dictionary:
	if recipes.is_empty():
		return {}
	_ensure_selected_recipe_known()
	if selected_recipe_index < 0 or selected_recipe_index >= recipes.size():
		return {}
	return recipes[selected_recipe_index]


func _recipe_is_known(recipe: Dictionary) -> bool:
	var recipe_id := str(recipe.get("id", recipe.get("result", "")))
	return bool(known_recipes.get(recipe_id, false))


func _known_recipe_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(recipes.size()):
		if _recipe_is_known(recipes[i]):
			indices.append(i)
	return indices


func _visible_recipe_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(recipes.size()):
		if not _recipe_is_known(recipes[i]):
			continue
		if recipe_station_filter != "all" and str(recipes[i].get("station", "hand")) != recipe_station_filter:
			continue
		indices.append(i)
	return indices


func _ensure_selected_recipe_known() -> void:
	if selected_recipe_index >= 0 and selected_recipe_index < recipes.size() and _recipe_is_known(recipes[selected_recipe_index]):
		if recipe_station_filter == "all" or str(recipes[selected_recipe_index].get("station", "hand")) == recipe_station_filter:
			return
	var known_indices := _visible_recipe_indices()
	selected_recipe_index = known_indices[0] if not known_indices.is_empty() else -1


func _recipe_id_exists(recipe_id: String) -> bool:
	for recipe in recipes:
		if str(recipe.get("id", recipe.get("result", ""))) == recipe_id:
			return true
	return false


func _learn_all_recipes() -> int:
	var learned_count := 0
	for recipe in recipes:
		var recipe_id := str(recipe.get("id", recipe.get("result", "")))
		if not bool(known_recipes.get(recipe_id, false)):
			known_recipes[recipe_id] = true
			learned_count += 1
	if learned_count > 0:
		journal_unread_count += learned_count
	_ensure_selected_recipe_known()
	if journal_open:
		_refresh_journal()
	_update_hud()
	return learned_count


func _recipe_cost_text(recipe: Dictionary) -> String:
	var cost: Dictionary = recipe.get("cost", {})
	var parts: Array[String] = []
	for item_id in cost.keys():
		parts.append("%s x%d" % [_item_display_name(str(item_id)), int(cost[item_id])])
	return ", ".join(parts)


func _station_display_name(station: String) -> String:
	if station == "hand":
		return "Hands"
	return _item_display_name(station)


func _item_display_name(item_id: String) -> String:
	return str(item_names.get(item_id, item_id))


func _tool_power() -> int:
	var tool: Dictionary = tools.get(current_tool, tools["wooden_pickaxe"])
	return int(tool.get("power", 1))


func _tool_speed() -> float:
	var tool: Dictionary = tools.get(current_tool, tools["wooden_pickaxe"])
	return float(tool.get("speed", 1.0)) * _temperature_action_multiplier()


func _total_damage() -> int:
	var total := 1
	for item_id in [equipped_weapon, equipped_accessory]:
		if gear_stats.has(item_id):
			total += int((gear_stats[item_id] as Dictionary).get("damage", 0))
	return total


func _total_defense() -> int:
	var total := 0
	for item_id in [equipped_armor, equipped_accessory]:
		if gear_stats.has(item_id):
			total += int((gear_stats[item_id] as Dictionary).get("defense", 0))
	return total


func _can_interact(tile_pos: Vector2i) -> bool:
	if not _in_bounds(tile_pos.x, tile_pos.y):
		return false
	var player_tile := player_position / TILE_SIZE
	return player_tile.distance_to(Vector2(tile_pos)) <= INTERACT_RANGE_TILES


func _mouse_tile() -> Vector2i:
	if _mobile_controls_enabled() and mobile_target_valid:
		return mobile_target_tile
	return Vector2i(floori(get_global_mouse_position().x / TILE_SIZE), floori(get_global_mouse_position().y / TILE_SIZE))


func _update_camera() -> void:
	if camera == null:
		return
	var offset := Vector2.ZERO
	if camera_shake_time > 0.0:
		var delta := get_process_delta_time()
		camera_shake_time = maxf(0.0, camera_shake_time - delta)
		camera_shake_phase += delta * 62.0
		var ratio := camera_shake_time / maxf(0.01, camera_shake_duration)
		var strength := camera_shake_strength * ratio * ratio
		offset = Vector2(
			sin(camera_shake_phase * 1.71) + sin(camera_shake_phase * 0.73) * 0.45,
			cos(camera_shake_phase * 1.37) + sin(camera_shake_phase * 0.91) * 0.40
		).normalized() * strength
		if camera_shake_time <= 0.0:
			camera_shake_strength = 0.0
			camera_shake_duration = 0.0
	camera.position = player_position + offset


func _adjust_camera_zoom(delta_zoom: float) -> void:
	if camera == null:
		return
	var next_zoom := clampf(camera.zoom.x + delta_zoom, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)


func _network_nearest_player_target(origin: Vector2) -> Dictionary:
	var best_peer := 1
	var best_position := player_position
	var best_distance := origin.distance_to(best_position)
	if network_session != null and network_session.is_server():
		best_peer = -1
		best_distance = INF
		for peer_variant in network_session.players.keys():
			var peer_id := int(peer_variant)
			var state: Dictionary = network_session.players[peer_id]
			var candidate: Vector2 = state.get("pos", player_position)
			var distance := origin.distance_to(candidate)
			if distance < best_distance:
				best_distance = distance
				best_peer = peer_id
				best_position = candidate
		if best_peer < 0:
			best_peer = 1
			best_position = player_position
	return {"peer_id": best_peer, "pos": best_position, "distance": best_distance}


func _network_local_player_state(display_name: String) -> Dictionary:
	var attack_ratio := 0.0
	if attack_anim_duration > 0.0:
		attack_ratio = clampf(1.0 - attack_anim_time / attack_anim_duration, 0.0, 1.0)
	return {
		"name": display_name,
		"pos": player_position,
		"vel": player_velocity,
		"facing": facing,
		"on_floor": player_on_floor,
		"health": health,
		"max_health": MAX_HEALTH,
		"oxygen": oxygen,
		"body_temperature": body_temperature,
		"flight_charge": flight_charge,
		"class": active_class,
		"weapon": equipped_weapon,
		"attack_kind": attack_anim_kind,
		"attack_ratio": attack_ratio
	}


func _network_default_player_profile(display_name: String, spawn: Vector2) -> Dictionary:
	return {
		"name": display_name,
		"inventory": {
			"wooden_pickaxe": 1,
			"builder_hammer": 1,
			"wooden_sword": 1,
			"dirt": 24,
			"wood": 12
		},
		"hotbar": ["wooden_pickaxe", "dirt", "stone", "wood", "workbench"],
		"selected_slot": 0,
		"current_tool": "wooden_pickaxe",
		"equipped_weapon": "",
		"equipped_armor": "",
		"equipped_accessory": "",
		"active_class": "Warrior",
		"health": MAX_HEALTH,
		"oxygen": MAX_OXYGEN,
		"body_temperature": NORMAL_BODY_TEMPERATURE,
		"flight_charge": FLIGHT_CHARGE_MAX,
		"position": [spawn.x, spawn.y],
		"bed_spawn": [-1.0, -1.0],
		"known_recipes": {},
		"regen_ready_msec": 0,
		"last_seen": int(Time.get_unix_time_from_system())
	}


func _network_profile_position(profile: Dictionary, fallback: Vector2) -> Vector2:
	var value: Variant = profile.get("position", [fallback.x, fallback.y])
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _network_profile_bed_spawn(profile: Dictionary) -> Vector2:
	var value: Variant = profile.get("bed_spawn", [-1.0, -1.0])
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2(-1.0, -1.0)


func _network_sanitize_profile(raw_profile: Dictionary, display_name: String, spawn: Vector2) -> Dictionary:
	var profile := _network_default_player_profile(display_name, spawn)
	var clean_inventory: Dictionary = {}
	var raw_inventory: Dictionary = raw_profile.get("inventory", {})
	for item_variant in raw_inventory.keys():
		var item_id := str(item_variant).substr(0, 48)
		var amount := clampi(int(raw_inventory[item_variant]), 0, 999999)
		if amount > 0 and (item_names.has(item_id) or tools.has(item_id) or gear_stats.has(item_id) or item_to_tile.has(item_id)):
			clean_inventory[item_id] = amount
	if clean_inventory.is_empty() and raw_profile.is_empty():
		clean_inventory = profile["inventory"].duplicate(true)
	profile["inventory"] = clean_inventory
	var clean_hotbar: Array[String] = []
	var raw_hotbar: Array = raw_profile.get("hotbar", profile["hotbar"])
	for i in range(HOTBAR_SIZE):
		var item_id := str(raw_hotbar[i]) if i < raw_hotbar.size() else ""
		clean_hotbar.append(item_id if int(clean_inventory.get(item_id, 0)) > 0 else "")
	profile["hotbar"] = clean_hotbar
	profile["name"] = display_name
	profile["selected_slot"] = clampi(int(raw_profile.get("selected_slot", 0)), 0, HOTBAR_SIZE - 1)
	var current_tool_id := str(raw_profile.get("current_tool", "wooden_pickaxe"))
	profile["current_tool"] = current_tool_id if tools.has(current_tool_id) and int(clean_inventory.get(current_tool_id, 0)) > 0 else "wooden_pickaxe"
	for slot_key in ["equipped_weapon", "equipped_armor", "equipped_accessory"]:
		var equipped_id := str(raw_profile.get(slot_key, ""))
		profile[slot_key] = equipped_id if gear_stats.has(equipped_id) and int(clean_inventory.get(equipped_id, 0)) > 0 else ""
	profile["active_class"] = str(raw_profile.get("active_class", "Warrior")).substr(0, 24)
	profile["health"] = clampi(int(raw_profile.get("health", MAX_HEALTH)), 0, MAX_HEALTH)
	profile["oxygen"] = clampf(float(raw_profile.get("oxygen", MAX_OXYGEN)), 0.0, MAX_OXYGEN)
	profile["body_temperature"] = clampf(float(raw_profile.get("body_temperature", NORMAL_BODY_TEMPERATURE)), 0.0, 100.0)
	profile["flight_charge"] = clampf(float(raw_profile.get("flight_charge", FLIGHT_CHARGE_MAX)), 0.0, FLIGHT_CHARGE_MAX)
	var saved_position := _network_profile_position(raw_profile, spawn)
	profile["position"] = [saved_position.x, saved_position.y]
	var saved_bed := _network_profile_bed_spawn(raw_profile)
	profile["bed_spawn"] = [saved_bed.x, saved_bed.y]
	profile["known_recipes"] = (raw_profile.get("known_recipes", {}) as Dictionary).duplicate(true)
	profile["regen_ready_msec"] = maxi(0, int(raw_profile.get("regen_ready_msec", 0)))
	profile["last_seen"] = int(Time.get_unix_time_from_system())
	return profile


func _network_profile_wire(profile: Dictionary, fallback: Vector2) -> Dictionary:
	var wire := profile.duplicate(true)
	wire["position"] = _network_profile_position(profile, fallback)
	wire["bed_spawn"] = _network_profile_bed_spawn(profile)
	return wire


func _network_prepare_player_profile(profile_id: String, display_name: String, spawn: Vector2) -> Dictionary:
	var stored: Dictionary = network_player_profiles.get(profile_id, {})
	var profile := _network_sanitize_profile(stored, display_name, spawn)
	# A dead player reconnects alive at their last valid spawn point.
	if int(profile.get("health", 0)) <= 0:
		profile["health"] = MAX_HEALTH
	network_player_profiles[profile_id] = profile
	return _network_profile_wire(profile, spawn)


func _network_profile_for_peer(peer_id: int) -> Dictionary:
	if network_session == null:
		return {}
	var profile_id: String = str(network_session.profile_id_for_peer(peer_id))
	if profile_id == "" or profile_id == "host":
		return {}
	var state: Dictionary = network_session.players.get(peer_id, {})
	var fallback: Vector2 = state.get("pos", player_position)
	if not network_player_profiles.has(profile_id):
		network_player_profiles[profile_id] = _network_sanitize_profile({}, str(state.get("name", "Player")), fallback)
	return (network_player_profiles[profile_id] as Dictionary).duplicate(true)


func _network_store_profile(peer_id: int, profile: Dictionary, message := "", send_to_client := true) -> void:
	if network_session == null:
		return
	var profile_id: String = str(network_session.profile_id_for_peer(peer_id))
	if profile_id == "" or profile_id == "host":
		return
	var state: Dictionary = network_session.players.get(peer_id, {})
	var fallback: Vector2 = state.get("pos", player_position)
	var clean := _network_sanitize_profile(profile, str(state.get("name", profile.get("name", "Player"))), fallback)
	network_player_profiles[profile_id] = clean
	if not state.is_empty():
		state["health"] = int(clean.get("health", MAX_HEALTH))
		state["oxygen"] = float(clean.get("oxygen", MAX_OXYGEN))
		state["body_temperature"] = float(clean.get("body_temperature", NORMAL_BODY_TEMPERATURE))
		state["flight_charge"] = float(clean.get("flight_charge", FLIGHT_CHARGE_MAX))
		state["class"] = str(clean.get("active_class", "Warrior"))
		state["weapon"] = str(clean.get("equipped_weapon", ""))
		network_session.players[peer_id] = state
	if send_to_client:
		network_session.send_player_profile(peer_id, _network_profile_wire(clean, fallback), message)


func _network_profile_add_item(profile: Dictionary, item_id: String, amount: int) -> void:
	if item_id == "" or amount <= 0:
		return
	var items: Dictionary = profile.get("inventory", {})
	items[item_id] = int(items.get(item_id, 0)) + amount
	profile["inventory"] = items
	var learned: Dictionary = profile.get("known_recipes", {})
	for recipe in recipes:
		var recipe_id := str(recipe.get("id", recipe.get("result", "")))
		if bool(learned.get(recipe_id, false)):
			continue
		var cost: Dictionary = recipe.get("cost", {})
		var has_all := true
		for material_variant in cost.keys():
			if int(items.get(str(material_variant), 0)) < int(cost[material_variant]):
				has_all = false
				break
		if has_all:
			learned[recipe_id] = true
	profile["known_recipes"] = learned


func _network_apply_player_profile(profile: Dictionary, initial: bool, message: String) -> void:
	if network_session == null or not network_session.is_client():
		return
	var received_inventory: Dictionary = (profile.get("inventory", {}) as Dictionary).duplicate(true)
	# Dragging is only a local UI representation. Keep the held amount outside
	# the visible inventory while accepting authoritative server snapshots.
	if held_item_id != "" and held_item_amount > 0:
		var remaining := maxi(0, int(received_inventory.get(held_item_id, 0)) - held_item_amount)
		if remaining > 0:
			received_inventory[held_item_id] = remaining
		else:
			received_inventory.erase(held_item_id)
	inventory = received_inventory
	var received_hotbar: Array = profile.get("hotbar", hotbar)
	if received_hotbar.size() == HOTBAR_SIZE:
		hotbar.assign(received_hotbar)
	selected_slot = clampi(int(profile.get("selected_slot", selected_slot)), 0, hotbar.size() - 1)
	current_tool = str(profile.get("current_tool", current_tool))
	equipped_weapon = str(profile.get("equipped_weapon", ""))
	equipped_armor = str(profile.get("equipped_armor", ""))
	equipped_accessory = str(profile.get("equipped_accessory", ""))
	active_class = str(profile.get("active_class", active_class))
	health = clampi(int(profile.get("health", health)), 0, MAX_HEALTH)
	oxygen = clampf(float(profile.get("oxygen", oxygen)), 0.0, MAX_OXYGEN)
	body_temperature = float(profile.get("body_temperature", body_temperature))
	flight_charge = clampf(float(profile.get("flight_charge", flight_charge)), 0.0, FLIGHT_CHARGE_MAX)
	bed_spawn_pos = _network_profile_bed_spawn(profile)
	known_recipes.merge(profile.get("known_recipes", {}), true)
	if initial:
		player_position = _network_profile_position(profile, player_position)
		player_velocity = Vector2.ZERO
	if message != "":
		last_message = message
	_sanitize_hotbar()
	_update_selection_from_hotbar()
	_update_hud()


func _network_server_update_profile_state(peer_id: int, state: Dictionary) -> void:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty():
		return
	var pos: Vector2 = state.get("pos", _network_profile_position(profile, player_position))
	profile["position"] = [pos.x, pos.y]
	var old_health := int(profile.get("health", MAX_HEALTH))
	var reported_health := clampi(int(state.get("health", old_health)), 0, MAX_HEALTH)
	profile["health"] = reported_health
	if reported_health < old_health:
		profile["regen_ready_msec"] = Time.get_ticks_msec() + int(REGEN_DELAY * 1000.0)
	profile["oxygen"] = clampf(float(state.get("oxygen", profile.get("oxygen", MAX_OXYGEN))), 0.0, MAX_OXYGEN)
	profile["body_temperature"] = clampf(float(state.get("body_temperature", profile.get("body_temperature", NORMAL_BODY_TEMPERATURE))), 0.0, 100.0)
	profile["flight_charge"] = clampf(float(state.get("flight_charge", profile.get("flight_charge", FLIGHT_CHARGE_MAX))), 0.0, FLIGHT_CHARGE_MAX)
	profile["last_seen"] = int(Time.get_unix_time_from_system())
	_network_store_profile(peer_id, profile, "", false)


func _network_server_peer_disconnected(peer_id: int, profile_id: String, state: Dictionary) -> void:
	network_open_chests.erase(peer_id)
	network_mine_ready_msec.erase(peer_id)
	if profile_id == "" or profile_id == "host":
		return
	var profile: Dictionary = network_player_profiles.get(profile_id, _network_default_player_profile(str(state.get("name", "Player")), state.get("pos", player_position)))
	var pos: Vector2 = state.get("pos", _network_profile_position(profile, player_position))
	profile["position"] = [pos.x, pos.y]
	profile["health"] = clampi(int(state.get("health", profile.get("health", MAX_HEALTH))), 0, MAX_HEALTH)
	profile["last_seen"] = int(Time.get_unix_time_from_system())
	network_player_profiles[profile_id] = profile
	_save_game()
	if dedicated_export_path != "":
		_export_world_file(dedicated_export_path)


func _network_server_grant_item(peer_id: int, loot_id: int, item_id: String, amount: int) -> void:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty() or amount <= 0:
		return
	_network_profile_add_item(profile, item_id, amount)
	var message := "Picked up %s x%d." % [_item_display_name(item_id), amount]
	_network_store_profile(peer_id, profile, message)


func _network_peer_can_interact(peer_id: int, tile_pos: Vector2i, extra_tiles := 0.0) -> bool:
	if not _in_bounds(tile_pos.x, tile_pos.y) or network_session == null:
		return false
	var state: Dictionary = network_session.players.get(peer_id, {})
	var pos: Vector2 = state.get("pos", Vector2.ZERO)
	var center := Vector2(float(tile_pos.x) + 0.5, float(tile_pos.y) + 0.5) * TILE_SIZE
	return pos.distance_to(center) <= (INTERACT_RANGE_TILES + extra_tiles) * TILE_SIZE


func _network_station_near_peer(peer_id: int, station: String) -> bool:
	if station == "hand":
		return true
	var state: Dictionary = network_session.players.get(peer_id, {})
	var pos: Vector2 = state.get("pos", Vector2.ZERO)
	var wanted_tile := Tile.WORKBENCH
	if station == "furnace":
		wanted_tile = Tile.FURNACE
	elif station == "anvil":
		wanted_tile = Tile.ANVIL
	var center := Vector2i(floori(pos.x / TILE_SIZE), floori(pos.y / TILE_SIZE))
	for y in range(center.y - 5, center.y + 6):
		for x in range(center.x - 5, center.x + 6):
			if _in_bounds(x, y) and _get_tile(x, y) == wanted_tile:
				return true
	return false


func _network_send_chest(peer_id: int, chest_key: String, message := "") -> void:
	if network_session != null:
		network_session.send_chest_state(peer_id, chest_key, (chest_loot.get(chest_key, {}) as Dictionary).duplicate(true), message)


func _network_broadcast_chest(chest_key: String) -> void:
	for peer_variant in network_open_chests.keys():
		var peer_id := int(peer_variant)
		if str(network_open_chests.get(peer_id, "")) == chest_key:
			_network_send_chest(peer_id, chest_key)


func _network_valid_chest(peer_id: int, chest_key: String) -> bool:
	var parts := chest_key.split(",")
	if parts.size() != 2:
		return false
	var pos := Vector2i(int(parts[0]), int(parts[1]))
	return _get_tile(pos.x, pos.y) == Tile.CHEST and _network_peer_can_interact(peer_id, pos, 1.0)


func _network_server_game_action(peer_id: int, action: String, payload: Dictionary) -> void:
	if network_session == null or not network_session.is_server():
		return
	match action:
		"craft":
			_network_action_craft(peer_id, str(payload.get("recipe_id", "")))
		"chest_open":
			var open_key := str(payload.get("chest_key", "")).substr(0, 32)
			if _network_valid_chest(peer_id, open_key):
				network_open_chests[peer_id] = open_key
				_network_send_chest(peer_id, open_key)
		"chest_close":
			network_open_chests.erase(peer_id)
		"chest_take":
			_network_action_chest_take(peer_id, str(payload.get("chest_key", "")), str(payload.get("item_id", "")), int(payload.get("amount", 0)))
		"chest_store":
			_network_action_chest_store(peer_id, str(payload.get("chest_key", "")), str(payload.get("item_id", "")), int(payload.get("amount", 0)))
		"drop":
			_network_action_drop(peer_id, str(payload.get("item_id", "")), int(payload.get("amount", 0)))
		"place":
			_network_action_place(peer_id, Vector2i(int(payload.get("x", -1)), int(payload.get("y", -1))), str(payload.get("item_id", "")), str(payload.get("build_id", "")))
		"mine":
			_network_action_mine(peer_id, Vector2i(int(payload.get("x", -1)), int(payload.get("y", -1))))
		"interact":
			_network_action_interact(peer_id, Vector2i(int(payload.get("x", -1)), int(payload.get("y", -1))))
		"consume":
			_network_action_consume(peer_id, str(payload.get("item_id", "")))
		"loadout":
			_network_action_loadout(peer_id, payload)
		"respawn":
			_network_action_respawn(peer_id, int(payload.get("reported_health", 0)))


func _network_action_craft(peer_id: int, recipe_id: String) -> void:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty():
		return
	var recipe: Dictionary = {}
	for candidate in recipes:
		if str(candidate.get("id", candidate.get("result", ""))) == recipe_id:
			recipe = candidate
			break
	if recipe.is_empty() or not _network_station_near_peer(peer_id, str(recipe.get("station", "hand"))):
		return
	var items: Dictionary = profile.get("inventory", {})
	var cost: Dictionary = recipe.get("cost", {})
	for item_variant in cost.keys():
		if int(items.get(str(item_variant), 0)) < int(cost[item_variant]):
			return
	for item_variant in cost.keys():
		var item_id := str(item_variant)
		items[item_id] = int(items.get(item_id, 0)) - int(cost[item_variant])
		if int(items[item_id]) <= 0:
			items.erase(item_id)
	profile["inventory"] = items
	var result := str(recipe.get("result", ""))
	var amount := int(recipe.get("amount", 1))
	_network_profile_add_item(profile, result, amount)
	var learned: Dictionary = profile.get("known_recipes", {})
	learned[recipe_id] = true
	profile["known_recipes"] = learned
	var profile_hotbar: Array = profile.get("hotbar", [])
	var profile_slot := clampi(int(profile.get("selected_slot", 0)), 0, HOTBAR_SIZE - 1)
	if profile_hotbar.size() == HOTBAR_SIZE:
		profile_hotbar[profile_slot] = result
		profile["hotbar"] = profile_hotbar
	_network_store_profile(peer_id, profile, "Crafted %s x%d." % [_item_display_name(result), amount])


func _network_action_chest_take(peer_id: int, chest_key: String, item_id: String, requested_amount: int) -> void:
	if not _network_valid_chest(peer_id, chest_key):
		return
	var loot: Dictionary = chest_loot.get(chest_key, {})
	var available := int(loot.get(item_id, 0))
	var amount := available if requested_amount <= 0 else mini(available, requested_amount)
	if amount <= 0:
		_network_send_chest(peer_id, chest_key)
		return
	loot[item_id] = available - amount
	if int(loot[item_id]) <= 0:
		loot.erase(item_id)
	chest_loot[chest_key] = loot
	var profile := _network_profile_for_peer(peer_id)
	_network_profile_add_item(profile, item_id, amount)
	_network_store_profile(peer_id, profile, "Took %s x%d from chest." % [_item_display_name(item_id), amount])
	_network_broadcast_chest(chest_key)


func _network_action_chest_store(peer_id: int, chest_key: String, item_id: String, requested_amount: int) -> void:
	if not _network_valid_chest(peer_id, chest_key):
		return
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	var amount := mini(maxi(0, requested_amount), int(items.get(item_id, 0)))
	if amount <= 0:
		return
	items[item_id] = int(items[item_id]) - amount
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	profile["inventory"] = items
	var loot: Dictionary = chest_loot.get(chest_key, {})
	loot[item_id] = int(loot.get(item_id, 0)) + amount
	chest_loot[chest_key] = loot
	_network_store_profile(peer_id, profile, "Stored %s x%d." % [_item_display_name(item_id), amount])
	_network_broadcast_chest(chest_key)


func _network_action_drop(peer_id: int, item_id: String, requested_amount: int) -> void:
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	var amount := mini(maxi(0, requested_amount), int(items.get(item_id, 0)))
	if amount <= 0:
		return
	items[item_id] = int(items[item_id]) - amount
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	profile["inventory"] = items
	var state: Dictionary = network_session.players.get(peer_id, {})
	var drop_pos: Vector2 = state.get("pos", player_position)
	var drop_facing := 1 if int(state.get("facing", 1)) >= 0 else -1
	_spawn_loot_with_velocity(drop_pos + Vector2(float(drop_facing) * 18.0, -6.0), item_id, amount, Vector2(float(drop_facing) * 55.0, -45.0), 0.75)
	_network_store_profile(peer_id, profile, "Dropped %s x%d." % [_item_display_name(item_id), amount])


func _network_action_place(peer_id: int, tile_pos: Vector2i, item_id: String, build_id: String) -> void:
	if not _network_peer_can_interact(peer_id, tile_pos) or _get_tile(tile_pos.x, tile_pos.y) != Tile.AIR:
		return
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	var costs: Dictionary = {}
	var placed_tile := Tile.AIR
	if build_id != "":
		var build_def: Dictionary = build_catalog.get(build_id, {})
		if build_def.is_empty() or int(items.get("blueprint", 0)) <= 0:
			return
		costs = (build_def.get("cost", {}) as Dictionary).duplicate(true)
		placed_tile = int(build_def.get("tile", Tile.AIR))
	else:
		if not item_to_tile.has(item_id) or int(items.get(item_id, 0)) <= 0:
			return
		costs[item_id] = 1
		placed_tile = int(item_to_tile[item_id])
	for resource_variant in costs.keys():
		if int(items.get(str(resource_variant), 0)) < int(costs[resource_variant]):
			return
	if placed_tile == Tile.CHEST and not _is_solid(tile_pos.x, tile_pos.y + 1):
		return
	if placed_tile == Tile.SAPLING:
		var ground := _get_tile(tile_pos.x, tile_pos.y + 1)
		if ground not in [Tile.GRASS, Tile.DIRT, Tile.MOSS, Tile.MUD]:
			return
	if placed_tile == Tile.TORCH and not (_is_solid(tile_pos.x, tile_pos.y + 1) or _is_solid(tile_pos.x - 1, tile_pos.y) or _is_solid(tile_pos.x + 1, tile_pos.y)):
		return
	var state: Dictionary = network_session.players.get(peer_id, {})
	var peer_pos: Vector2 = state.get("pos", Vector2.ZERO)
	if Rect2(Vector2(tile_pos) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE)).intersects(Rect2(peer_pos - PLAYER_SIZE * 0.5, PLAYER_SIZE)):
		return
	for resource_variant in costs.keys():
		var resource_id := str(resource_variant)
		items[resource_id] = int(items.get(resource_id, 0)) - int(costs[resource_variant])
		if int(items[resource_id]) <= 0:
			items.erase(resource_id)
	profile["inventory"] = items
	_set_tile(tile_pos.x, tile_pos.y, placed_tile)
	if placed_tile == Tile.CHEST:
		chest_loot[_tile_key(tile_pos)] = {}
	elif placed_tile == Tile.BED:
		profile["bed_spawn"] = [tile_pos.x * TILE_SIZE + TILE_SIZE * 0.5, tile_pos.y * TILE_SIZE]
	_network_store_profile(peer_id, profile, "Placed %s." % _item_display_name(item_id if item_id != "" else build_id))


func _network_action_mine(peer_id: int, tile_pos: Vector2i) -> void:
	if not _network_peer_can_interact(peer_id, tile_pos):
		return
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	if tile in [Tile.AIR, Tile.WATER, Tile.LAVA]:
		return
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	var tool_id := str(profile.get("current_tool", "wooden_pickaxe"))
	if not tools.has(tool_id) or int(items.get(tool_id, 0)) <= 0:
		tool_id = "wooden_pickaxe"
	var tool: Dictionary = tools.get(tool_id, tools["wooden_pickaxe"])
	if int(tool.get("power", 1)) < int(tile_required_power.get(tile, 1)):
		return
	var hardness := _mining_hardness(tile, tile_pos)
	var minimum_msec := int(maxf(90.0, hardness / maxf(0.1, float(tool.get("speed", 1.0))) * 700.0))
	var now := Time.get_ticks_msec()
	if now < int(network_mine_ready_msec.get(peer_id, 0)):
		return
	network_mine_ready_msec[peer_id] = now + minimum_msec
	var world_pos := Vector2(tile_pos) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	if tile == Tile.LEAVES:
		_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
		return
	if tile == Tile.WOOD and _is_tree_base(tile_pos):
		_fell_tree_from(tile_pos)
		return
	if tile == Tile.CHEST:
		var chest_key := _tile_key(tile_pos)
		if not (chest_loot.get(chest_key, {}) as Dictionary).is_empty():
			return
		chest_loot.erase(chest_key)
	if tile == Tile.STONE:
		stone_broken_count += 1
		if stone_broken_count >= 140 and not stone_beast_spawned and not stone_beast_defeated:
			_spawn_stone_beast()
	var item_id := str(tile_to_item.get(tile, "dirt"))
	_spawn_loot(world_pos, item_id, 1)
	_add_rare_drop(tile, world_pos - Vector2(8, 8))
	_set_tile(tile_pos.x, tile_pos.y, Tile.AIR)
	_settle_unsupported_chest(tile_pos + Vector2i(0, -1))


func _network_action_interact(peer_id: int, tile_pos: Vector2i) -> void:
	if not _network_peer_can_interact(peer_id, tile_pos):
		return
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	if tile == Tile.STONE_ALTAR:
		if stone_beast_defeated or stone_beast_spawned:
			return
		var state: Dictionary = network_session.players.get(peer_id, {})
		var peer_pos: Vector2 = state.get("pos", player_position)
		_spawn_enemy("stone_beast", peer_pos + Vector2(180.0, 80.0))
		stone_beast_spawned = true
		_set_tile(tile_pos.x, tile_pos.y, Tile.RUIN)
	elif tile == Tile.DEPTH_ALTAR:
		if depth_warden_defeated or depth_warden_spawned or int(items.get("wind_shard", 0)) <= 0:
			return
		items["wind_shard"] = int(items["wind_shard"]) - 1
		if int(items["wind_shard"]) <= 0:
			items.erase("wind_shard")
		profile["inventory"] = items
		depth_sanctum_activated = true
		depth_warden_spawned = true
		_spawn_depth_warden()
		_network_store_profile(peer_id, profile, "The wind shard is consumed. THE DEPTH WARDEN AWAKENS!")
	elif tile == Tile.SKY_OBELISK:
		if sky_leviathan_defeated or sky_leviathan_spawned or int(items.get("sky_fragment", 0)) < SKY_FRAGMENTS_NEEDED:
			return
		items["sky_fragment"] = int(items["sky_fragment"]) - SKY_FRAGMENTS_NEEDED
		if int(items["sky_fragment"]) <= 0:
			items.erase("sky_fragment")
		profile["inventory"] = items
		sky_leviathan_spawned = true
		_spawn_sky_leviathan()
		_network_store_profile(peer_id, profile, "The shards are consumed. THE SKY LEVIATHAN AWAKENS!")


func _network_action_consume(peer_id: int, item_id: String) -> void:
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	if int(items.get(item_id, 0)) <= 0:
		return
	var used := false
	if item_id == "star_dust" and float(profile.get("flight_charge", FLIGHT_CHARGE_MAX)) < FLIGHT_CHARGE_MAX - 0.5:
		profile["flight_charge"] = minf(FLIGHT_CHARGE_MAX, float(profile.get("flight_charge", 0.0)) + 50.0)
		used = true
	elif consumables.has(item_id) and int(profile.get("health", MAX_HEALTH)) < MAX_HEALTH:
		var effect: Dictionary = consumables[item_id]
		profile["health"] = mini(MAX_HEALTH, int(profile.get("health", MAX_HEALTH)) + int(effect.get("heal", 0)))
		used = true
	if not used:
		return
	items[item_id] = int(items[item_id]) - 1
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	profile["inventory"] = items
	_network_store_profile(peer_id, profile, "Used %s." % _item_display_name(item_id))


func _network_action_loadout(peer_id: int, payload: Dictionary) -> void:
	var profile := _network_profile_for_peer(peer_id)
	var items: Dictionary = profile.get("inventory", {})
	var requested_hotbar: Array = payload.get("hotbar", [])
	var clean_hotbar: Array[String] = []
	for i in range(HOTBAR_SIZE):
		var item_id := str(requested_hotbar[i]) if i < requested_hotbar.size() else ""
		clean_hotbar.append(item_id if int(items.get(item_id, 0)) > 0 else "")
	profile["hotbar"] = clean_hotbar
	profile["selected_slot"] = clampi(int(payload.get("selected_slot", profile.get("selected_slot", 0))), 0, HOTBAR_SIZE - 1)
	var requested_tool := str(payload.get("current_tool", profile.get("current_tool", "wooden_pickaxe")))
	if tools.has(requested_tool) and int(items.get(requested_tool, 0)) > 0:
		profile["current_tool"] = requested_tool
	for slot_key in ["equipped_weapon", "equipped_armor", "equipped_accessory"]:
		var requested_id := str(payload.get(slot_key, profile.get(slot_key, "")))
		if requested_id == "":
			profile[slot_key] = ""
		elif gear_stats.has(requested_id) and str((gear_stats[requested_id] as Dictionary).get("slot", "")) == slot_key.trim_prefix("equipped_") and int(items.get(requested_id, 0)) > 0:
			profile[slot_key] = requested_id
	profile["active_class"] = str(payload.get("active_class", profile.get("active_class", "Warrior"))).substr(0, 24)
	_network_store_profile(peer_id, profile)


func _network_action_respawn(peer_id: int, reported_health: int) -> void:
	var state: Dictionary = network_session.players.get(peer_id, {})
	if int(state.get("health", MAX_HEALTH)) > 0 and reported_health > 0:
		return
	var profile := _network_profile_for_peer(peer_id)
	var fallback := _network_spawn_for_peer(peer_id)
	var spawn := _network_profile_bed_spawn(profile)
	var bed_tile := Vector2i(floori(spawn.x / TILE_SIZE), floori(spawn.y / TILE_SIZE))
	if spawn.x < 0.0 or spawn.y < 0.0 or not _in_bounds(bed_tile.x, bed_tile.y) or _get_tile(bed_tile.x, bed_tile.y) != Tile.BED:
		spawn = fallback
	else:
		spawn += Vector2(0.0, -24.0)
	profile["health"] = MAX_HEALTH
	profile["regen_ready_msec"] = 0
	profile["oxygen"] = MAX_OXYGEN
	profile["body_temperature"] = NORMAL_BODY_TEMPERATURE
	profile["position"] = [spawn.x, spawn.y]
	state["health"] = MAX_HEALTH
	state["respawn_grace_until"] = Time.get_ticks_msec() + 1500
	state["pos"] = spawn
	state["vel"] = Vector2.ZERO
	network_session.players[peer_id] = state
	_network_store_profile(peer_id, profile, "", false)
	network_session.send_respawn(peer_id, spawn, MAX_HEALTH)


func _network_validated_attack_damage(peer_id: int, requested_damage: int, attack_kind: String) -> int:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty():
		return clampi(requested_damage, 1, 120)
	var weapon := str(profile.get("equipped_weapon", ""))
	var accessory := str(profile.get("equipped_accessory", ""))
	var maximum := 5 if weapon == "" else 1
	for item_id in [weapon, accessory]:
		if gear_stats.has(item_id):
			maximum += int((gear_stats[item_id] as Dictionary).get("damage", 0))
	if attack_kind == "cannon" and weapon == "hand_cannon":
		maximum += 5
	elif attack_kind in ["spark", "spirit"]:
		maximum += 4 if weapon != "" else 0
	return clampi(requested_damage, 1, maxi(1, maximum))


func _network_validate_projectile_kind(peer_id: int, kind: String) -> bool:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty():
		return true
	var weapon := str(profile.get("equipped_weapon", ""))
	var allowed: Dictionary = {
		"arrow": ["wooden_bow", "copper_bow"],
		"cannon": ["hand_cannon"],
		"spark": ["spark_staff"],
		"spirit": ["root_spirit_rod"],
		"acid": ["acid_flasks"],
		"turret": ["small_turret"]
	}
	return allowed.has(kind) and weapon in (allowed[kind] as Array)


func _network_update_remote_regeneration() -> void:
	if network_session == null or not network_session.is_server():
		return
	var now := Time.get_ticks_msec()
	for peer_variant in network_session.players.keys():
		var peer_id := int(peer_variant)
		if peer_id == 1:
			continue
		var profile := _network_profile_for_peer(peer_id)
		var current_health := int(profile.get("health", MAX_HEALTH))
		if current_health <= 0 or current_health >= MAX_HEALTH or now < int(profile.get("regen_ready_msec", 0)):
			continue
		profile["health"] = mini(MAX_HEALTH, current_health + 1)
		_network_store_profile(peer_id, profile)


func _network_server_apply_player_damage(peer_id: int, raw_damage: int, damage_type: String, _status: String) -> Dictionary:
	var profile := _network_profile_for_peer(peer_id)
	if profile.is_empty():
		return {}
	var defense := 0
	for item_id in [str(profile.get("equipped_armor", "")), str(profile.get("equipped_accessory", ""))]:
		if gear_stats.has(item_id):
			defense += int((gear_stats[item_id] as Dictionary).get("defense", 0))
	var effective_defense := defense
	if damage_type == "poison":
		effective_defense = int(floor(float(defense) * 0.55))
	elif damage_type == "fire" or damage_type == "arcane":
		effective_defense = int(floor(float(defense) * 0.72))
	var damage := maxi(1, raw_damage - effective_defense)
	damage = maxi(damage, maxi(1, int(ceil(float(raw_damage) * 0.35))))
	profile["health"] = maxi(0, int(profile.get("health", MAX_HEALTH)) - damage)
	profile["regen_ready_msec"] = Time.get_ticks_msec() + int(REGEN_DELAY * 1000.0)
	_network_store_profile(peer_id, profile, "", false)
	return {"health": int(profile["health"]), "damage": damage}


func _network_receive_chest_state(chest_key: String, loot: Dictionary, message: String) -> void:
	chest_loot[chest_key] = loot.duplicate(true)
	if message != "":
		last_message = message
	_update_hud()


func _network_receive_authoritative_damage(new_health: int, damage: int, direction: Vector2, damage_type: String, status: String, attacker_name: String) -> void:
	var old_health := health
	if damage > 0:
		_damage_player(damage, direction, damage_type)
	health = clampi(new_health, 0, MAX_HEALTH)
	if status != "":
		_apply_player_status(status)
	if attacker_name != "" and damage > 0:
		last_message = "%s hit you for %d." % [attacker_name, damage]
	if health <= 0 and old_health > 0 and network_session != null and network_session.is_client():
		network_session.request_game_action("respawn", {"reported_health": 0})


func _network_apply_respawn(spawn: Vector2, restored_health: int) -> void:
	network_applying_respawn = true
	_respawn_player()
	player_position = spawn
	player_velocity = Vector2.ZERO
	health = clampi(restored_health, 1, MAX_HEALTH)
	network_applying_respawn = false
	last_message = "Respawned in the server world."


func _network_client_sync_loadout() -> void:
	if network_session == null or not network_session.is_client() or not network_session.joined:
		return
	network_session.request_game_action("loadout", {
		"hotbar": hotbar.duplicate(),
		"selected_slot": selected_slot,
		"current_tool": current_tool,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"active_class": active_class
	})


func _build_network_world_data() -> Dictionary:
	var data := _build_save_data()
	# The host save owns terrain/progression. Personal inventory and vitals stay
	# local to each participant and are not cloned from the host.
	for personal_key in [
		"player_position", "health", "oxygen", "body_temperature", "inventory",
		"hotbar", "selected_slot", "current_tool", "selected_recipe_index",
		"equipped_weapon", "equipped_armor", "equipped_accessory", "flight_charge",
		"active_class", "network_player_profiles"
	]:
		data.erase(personal_key)
	data["network_world_name"] = current_world_name
	data["network_protocol"] = NETWORK_SESSION_SCRIPT.PROTOCOL_VERSION
	return data


func _network_apply_world_data(data: Dictionary, spawn: Vector2, hosted_world_name: String) -> void:
	network_applying_snapshot = true
	_apply_save_data(data)
	player_position = spawn
	player_velocity = Vector2.ZERO
	health = MAX_HEALTH
	player_hurt_timer = 0.0
	current_world_index = -1
	current_world_name = hosted_world_name
	world_loaded = true
	world_generation_in_progress = false
	if renderer_mgr != null:
		renderer_mgr.mark_all_dirty()
	network_applying_snapshot = false
	game_paused = false
	_hide_multiplayer_panel()
	_hide_main_menu()
	_update_hud()
	_update_network_badge()
	queue_redraw()


func _network_spawn_for_peer(peer_id: int) -> Vector2:
	var base := player_position
	if network_session != null and network_session.is_dedicated():
		var spawn_x := int(WORLD_WIDTH / 2)
		var spawn_y := int(surface_heights[spawn_x]) if spawn_x < surface_heights.size() else 60
		base = Vector2(spawn_x * TILE_SIZE + TILE_SIZE * 0.5, (spawn_y - 2) * TILE_SIZE)
	var slot: int = (peer_id + (int(network_session.player_count()) if network_session != null else 0)) % 7
	return base + Vector2(float(slot - 3) * 18.0, -8.0)


func _network_build_entity_snapshot() -> Dictionary:
	return {
		"world_time": world_time,
		"weather": weather,
		"weather_timer": weather_timer,
		"weather_intensity": weather_intensity,
		"weather_target_intensity": weather_target_intensity,
		"weather_lightning_flash": weather_lightning_flash,
		"enemies": enemies.duplicate(true),
		"dying_enemies": dying_enemies.duplicate(true),
		"projectiles": projectiles.duplicate(true),
		"enemy_projectiles": enemy_projectiles.duplicate(true),
		"enemy_impacts": enemy_impact_effects.duplicate(true),
		"dropped_items": dropped_items.duplicate(true),
		"boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated,
		"stone_beast_spawned": stone_beast_spawned,
		"stone_beast_defeated": stone_beast_defeated,
		"storm_active": storm_active,
		"storm_tornado_phase": storm_tornado_phase,
		"storm_tornado_pos": storm_tornado_pos
	}


func _network_apply_entity_snapshot(snapshot: Dictionary) -> void:
	if network_session == null or not network_session.is_client():
		return
	network_applying_snapshot = true
	world_time = float(snapshot.get("world_time", world_time))
	_apply_weather_snapshot(snapshot)
	enemies = snapshot.get("enemies", enemies)
	dying_enemies = snapshot.get("dying_enemies", dying_enemies)
	projectiles = snapshot.get("projectiles", projectiles)
	enemy_projectiles = snapshot.get("enemy_projectiles", enemy_projectiles)
	enemy_impact_effects = snapshot.get("enemy_impacts", enemy_impact_effects)
	dropped_items = snapshot.get("dropped_items", dropped_items)
	boss_spawned = bool(snapshot.get("boss_spawned", boss_spawned))
	boss_defeated = bool(snapshot.get("boss_defeated", boss_defeated))
	stone_beast_spawned = bool(snapshot.get("stone_beast_spawned", stone_beast_spawned))
	stone_beast_defeated = bool(snapshot.get("stone_beast_defeated", stone_beast_defeated))
	storm_active = bool(snapshot.get("storm_active", storm_active))
	storm_tornado_phase = str(snapshot.get("storm_tornado_phase", storm_tornado_phase))
	storm_tornado_pos = snapshot.get("storm_tornado_pos", storm_tornado_pos)
	network_applying_snapshot = false
	queue_redraw()


func _network_server_damage_enemy(sender_peer: int, enemy_id: int, damage: int, knockback: Vector2, damage_type: String, status: String) -> void:
	if network_session == null or not network_session.is_server():
		return
	var state: Dictionary = network_session.players.get(sender_peer, {})
	var attacker_pos: Vector2 = state.get("pos", Vector2.ZERO)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if int(enemy.get("perception_id", -1)) != enemy_id:
			continue
		var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		if attacker_pos.distance_to(enemy_pos) > 540.0:
			return
		_damage_enemy(i, damage, knockback, damage_type, status)
		return


func _network_server_spawn_projectile(sender_peer: int, pos: Vector2, velocity: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String, status: String) -> void:
	if network_session == null or not network_session.is_server():
		return
	_spawn_projectile(pos, velocity, damage, kind, color, life, damage_type, status, sender_peer)
	_emit_noise(pos, 310.0 if kind == "cannon" else 150.0, "network_shot", 1.0)


func _network_world_size_tiles() -> Vector2i:
	return Vector2i(WORLD_WIDTH, WORLD_HEIGHT)


func _network_world_bounds() -> Vector2:
	return Vector2(WORLD_WIDTH * TILE_SIZE, WORLD_HEIGHT * TILE_SIZE)


func _network_tile_size() -> int:
	return TILE_SIZE


func _network_tile_count() -> int:
	return Tile.size()


func _network_server_pickup_loot(sender_peer: int, loot_id: int) -> void:
	if network_session == null or not network_session.is_server():
		return
	var state: Dictionary = network_session.players.get(sender_peer, {})
	var collector_pos: Vector2 = state.get("pos", Vector2.ZERO)
	for i in range(dropped_items.size() - 1, -1, -1):
		var item: Dictionary = dropped_items[i]
		if int(item.get("network_id", -1)) != loot_id:
			continue
		var item_pos: Vector2 = item.get("pos", Vector2.ZERO)
		if collector_pos.distance_to(item_pos) > LOOT_MAGNET_RADIUS + 12.0:
			return
		var item_id := str(item.get("id", ""))
		var amount := int(item.get("amount", 1))
		if item_id == "wind_shard":
			wind_shard_picked = true
		dropped_items.remove_at(i)
		network_session.grant_loot(sender_peer, loot_id, item_id, amount)
		return


func _network_receive_loot(loot_id: int, item_id: String, amount: int) -> void:
	network_pending_loot.erase(loot_id)
	if item_id == "" or amount <= 0:
		return
	# Remote inventory was already mutated by the authoritative profile update.
	if network_session == null or not network_session.is_client():
		_add_item(item_id, amount)
	_add_loot_notification(item_id, amount)
	_play_sound("pickup")
	last_message = "Picked up %s x%d." % [_item_display_name(item_id), amount]
	if item_id == "wind_shard" and not wind_shard_picked:
		wind_shard_picked = true
		last_message = "The shard hums with wind... it tugs toward something deep underground."
		_toast_message(last_message, 5.0)
		_mark_journal_updated()


func _network_allow_direct_tile_change(_peer_id: int, x: int, y: int, tile: int) -> bool:
	if not _in_bounds(x, y):
		return false
	var key := _tile_key(Vector2i(x, y))
	var current := _get_tile(x, y)
	if current in [Tile.DOOR, Tile.TRAPDOOR] and tile == Tile.AIR:
		network_open_tiles[key] = current
		return true
	if current == Tile.AIR and int(network_open_tiles.get(key, -1)) == tile and tile in [Tile.DOOR, Tile.TRAPDOOR]:
		network_open_tiles.erase(key)
		return true
	return false


func _network_apply_tile_change(x: int, y: int, tile: int) -> void:
	if not _in_bounds(x, y) or tile < 0 or tile >= Tile.size():
		return
	_set_tile(x, y, tile)
	if renderer_mgr != null:
		renderer_mgr.mark_chunk_dirty(x, y)


func _network_apply_liquid_states(changes: Array) -> void:
	# Runtime liquid movement is server-authoritative. Each compact state carries
	# x, y, tile id and fill level after all transfers in that simulation tick.
	for state_variant in changes:
		if not state_variant is Array:
			continue
		var state: Array = state_variant
		if state.size() < 4:
			continue
		var x := int(state[0])
		var y := int(state[1])
		var tile := int(state[2])
		var level := int(state[3])
		if not _in_bounds(x, y) or tile < 0 or tile >= Tile.size():
			continue
		if tile != Tile.AIR and tile != Tile.WATER and tile != Tile.LAVA and tile != Tile.STONE:
			continue
		_set_tile(x, y, tile)
		if liquid_sim != null and (tile == Tile.WATER or tile == Tile.LAVA):
			liquid_sim.set_level(x, y, clampi(level, 1, liquid_sim.LEVEL_MAX))
		if renderer_mgr != null:
			renderer_mgr.mark_chunk_dirty(x, y)
	world_map_dirty = true


func _network_receive_player_damage(amount: int, direction: Vector2, damage_type: String, attacker_name: String) -> void:
	if network_session == null or not network_session.pvp_enabled:
		return
	if _damage_player(amount, direction, damage_type):
		last_message = "%s hit you for %d." % [attacker_name, amount]


func _network_receive_enemy_hit(raw_damage: int, direction: Vector2, damage_type: String, status: String) -> void:
	var damage := _incoming_damage(raw_damage, damage_type)
	if not _damage_player(damage, direction, damage_type):
		return
	player_velocity += direction.normalized() * 115.0 + Vector2(0.0, -55.0)
	if status != "":
		_apply_player_status(status)


func _network_join_rejected(reason: String) -> void:
	_on_network_status_changed(reason)
	_show_main_menu()
	_show_multiplayer_panel()


func _network_return_to_menu(reason: String) -> void:
	game_paused = false
	world_loaded = false
	_hide_multiplayer_panel()
	_show_main_menu()
	_on_network_status_changed(reason)


func _world_path(index: int) -> String:
	return "user://worlds/world_%d.json" % index


func _ensure_worlds_dir() -> void:
	DirAccess.make_dir_recursive_absolute("user://worlds")


func _load_worlds_meta() -> void:
	worlds_meta.clear()
	if not FileAccess.file_exists(WORLDS_INDEX):
		return
	var file := FileAccess.open(WORLDS_INDEX, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		worlds_meta = parsed


func _save_worlds_meta() -> void:
	_ensure_worlds_dir()
	var file := FileAccess.open(WORLDS_INDEX, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(worlds_meta))


func _world_meta(index: int) -> Dictionary:
	for meta in worlds_meta:
		if int(meta.get("index", -1)) == index:
			return meta
	return {}


func _list_worlds() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for meta in worlds_meta:
		var d: Dictionary = meta
		var idx := int(d.get("index", -1))
		d["has_save"] = FileAccess.file_exists(_world_path(idx))
		out.append(d)
	out.sort_custom(func(a, b): return int(a.get("index", 0)) < int(b.get("index", 0)))
	return out


func _next_free_world_index() -> int:
	var used: Dictionary = {}
	for meta in worlds_meta:
		used[int(meta.get("index", -1))] = true
	var i := 0
	while used.has(i):
		i += 1
	return i


func _create_world(world_name: String) -> int:
	_ensure_worlds_dir()
	var idx := _next_free_world_index()
	worlds_meta.append({
		"index": idx,
		"name": world_name if world_name != "" else "World %d" % (idx + 1),
		"seed": randi(),
		"time": int(Time.get_unix_time_from_system()),
	})
	_save_worlds_meta()
	return idx


func _delete_world(index: int) -> void:
	for i in range(worlds_meta.size() - 1, -1, -1):
		if int(worlds_meta[i].get("index", -1)) == index:
			worlds_meta.remove_at(i)
	_save_worlds_meta()
	if FileAccess.file_exists(_world_path(index)):
		DirAccess.remove_absolute(_world_path(index))


func _rename_world(index: int, new_name: String) -> void:
	for meta in worlds_meta:
		if int(meta.get("index", -1)) == index:
			meta["name"] = new_name
	_save_worlds_meta()


func _select_world(index: int) -> bool:
	if not FileAccess.file_exists(_world_path(index)):
		return false
	current_world_index = index
	current_world_name = str(_world_meta(index).get("name", "World"))
	_load_game_from_path(_world_path(index))
	world_loaded = true
	return true


func _backup_existing_world(path: String) -> void:
	if current_world_index < 0 or not path.begins_with("user://worlds/") or not FileAccess.file_exists(path):
		return
	var now := Time.get_ticks_msec()
	if now - int(world_backup_msec.get(path, -WORLD_BACKUP_INTERVAL_MSEC)) < WORLD_BACKUP_INTERVAL_MSEC:
		return
	world_backup_msec[path] = now
	var backup_dir := "user://backups/world_%d" % current_world_index
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_dir))
	var timestamp := int(Time.get_unix_time_from_system())
	var target := "%s/world_%d_%d.json" % [backup_dir, current_world_index, timestamp]
	if not _copy_file_bytes(path, target):
		return
	var directory := DirAccess.open(backup_dir)
	if directory == null:
		return
	var files: Array[String] = []
	for file_name in directory.get_files():
		if file_name.ends_with(".json"):
			files.append(file_name)
	files.sort()
	while files.size() > WORLD_BACKUP_LIMIT:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_dir.path_join(files.pop_front())))


func _save_game_to_path(path: String) -> void:
	_backup_existing_world(path)
	var data := _build_save_data()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	if current_world_index >= 0:
		for meta in worlds_meta:
			if int(meta.get("index", -1)) == current_world_index:
				meta["time"] = int(Time.get_unix_time_from_system())
				meta["seed"] = seed
		_save_worlds_meta()


func _build_save_data() -> Dictionary:
	return {
		"seed": seed,
		"world": world,
		"surface_heights": surface_heights,
		"surface_biomes": surface_biomes,
		"liquid_levels": liquid_sim.serialize_levels() if liquid_sim != null else {},
		"chest_loot": chest_loot,
		"network_player_profiles": network_player_profiles,
		"tree_tile_owners": tree_tile_owners,
		"next_tree_id": next_tree_id,
		"known_recipes": known_recipes,
		"bestiary_knowledge": bestiary_knowledge,
		"material_knowledge": material_knowledge,
		"alchemy_knowledge": alchemy_knowledge,
		"explored_tiles": Marshalls.raw_to_base64(explored_tiles),
		"player_position": [player_position.x, player_position.y],
		"health": health,
		"oxygen": oxygen,
		"body_temperature": body_temperature,
		"inventory": inventory,
		"hotbar": hotbar,
		"selected_slot": selected_slot,
		"current_tool": current_tool,
		"selected_recipe_index": selected_recipe_index,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"flight_charge": flight_charge,
		"active_class": active_class,
		"world_time": world_time,
		"weather": weather,
		"weather_timer": weather_timer,
		"weather_intensity": weather_intensity,
		"weather_target_intensity": weather_target_intensity,
		"weather_lightning_timer": weather_lightning_timer,
		"weather_rng_state": weather_state_rng.state,
		"defeated_enemies": defeated_enemies,
		"boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated,
		"stone_broken_count": stone_broken_count,
		"stone_beast_spawned": stone_beast_spawned,
		"stone_beast_defeated": stone_beast_defeated,
		"mushroom_path_opened": mushroom_path_opened,
		"storm_herald_defeated": storm_herald_defeated,
		"wind_shard_picked": wind_shard_picked,
		"depth_warden_defeated": depth_warden_defeated,
		"sky_leviathan_spawned": sky_leviathan_spawned,
		"sky_leviathan_defeated": sky_leviathan_defeated,
		"path_choice": path_choice,
		"npc_wanderer_active": npc_wanderer_active,
		"observatory_pos": [observatory_pos.x, observatory_pos.y],
		"moon_altar_pos": [moon_altar_pos.x, moon_altar_pos.y]
	}


func _load_game_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_apply_save_data(parsed)
	return true


func _apply_save_data(data: Dictionary) -> void:
	seed = int(data.get("seed", seed))
	world = data.get("world", world)
	world_map_dirty = true
	_invalidate_world_tile_caches()
	if world.size() != WORLD_HEIGHT or world.is_empty() or (world[0] as Array).size() != WORLD_WIDTH:
		_generate_world()
		last_message = "Old save used a different world size. A new world was generated."
		return
	chest_loot = data.get("chest_loot", {})
	network_player_profiles = data.get("network_player_profiles", {})
	tree_tile_owners = data.get("tree_tile_owners", {})
	next_tree_id = maxi(1, int(data.get("next_tree_id", 1)))
	_reset_knowledge()
	known_recipes.merge(data.get("known_recipes", {}), true)
	bestiary_knowledge = data.get("bestiary_knowledge", {})
	material_knowledge = data.get("material_knowledge", {})
	alchemy_knowledge = data.get("alchemy_knowledge", {})
	var loaded_heights: Array = data.get("surface_heights", surface_heights)
	var loaded_biomes: Array = data.get("surface_biomes", surface_biomes)
	if loaded_heights.size() == surface_heights.size():
		surface_heights.assign(loaded_heights)
	if loaded_biomes.size() == surface_biomes.size():
		surface_biomes.assign(loaded_biomes)
	# Seam fields are deterministic derived data: rebuild them locally after a
	# disk load or network world transfer instead of serializing extra arrays.
	_setup_transition_noise()
	_rebuild_border_metadata()
	var pos: Array = data.get("player_position", [player_position.x, player_position.y])
	player_position = Vector2(float(pos[0]), float(pos[1]))
	health = clampf(float(data.get("health", health)), 1.0, MAX_HEALTH)
	oxygen = float(data.get("oxygen", oxygen))
	body_temperature = float(data.get("body_temperature", body_temperature))
	inventory = data.get("inventory", inventory)
	var loaded_hotbar: Array = data.get("hotbar", hotbar)
	if not loaded_hotbar.is_empty():
		hotbar.assign(loaded_hotbar)
	selected_slot = clampi(int(data.get("selected_slot", selected_slot)), 0, hotbar.size() - 1)
	current_tool = str(data.get("current_tool", current_tool))
	selected_recipe_index = int(data.get("selected_recipe_index", selected_recipe_index))
	equipped_weapon = str(data.get("equipped_weapon", ""))
	equipped_armor = str(data.get("equipped_armor", ""))
	equipped_accessory = str(data.get("equipped_accessory", ""))
	flight_charge = clampf(float(data.get("flight_charge", FLIGHT_CHARGE_MAX)), 0.0, FLIGHT_CHARGE_MAX)
	active_class = str(data.get("active_class", "Warrior"))
	world_time = float(data.get("world_time", world_time))
	_restore_weather_state(data)
	defeated_enemies = int(data.get("defeated_enemies", 0))
	boss_spawned = bool(data.get("boss_spawned", false))
	boss_defeated = bool(data.get("boss_defeated", false))
	stone_broken_count = int(data.get("stone_broken_count", 0))
	stone_beast_spawned = bool(data.get("stone_beast_spawned", false))
	stone_beast_defeated = bool(data.get("stone_beast_defeated", false))
	mushroom_path_opened = bool(data.get("mushroom_path_opened", false))
	storm_herald_defeated = bool(data.get("storm_herald_defeated", false))
	wind_shard_picked = bool(data.get("wind_shard_picked", wind_shard_picked))
	depth_warden_defeated = bool(data.get("depth_warden_defeated", depth_warden_defeated))
	sky_leviathan_spawned = bool(data.get("sky_leviathan_spawned", false))
	sky_leviathan_defeated = bool(data.get("sky_leviathan_defeated", false))
	path_choice = str(data.get("path_choice", ""))
	npc_wanderer_active = bool(data.get("npc_wanderer_active", false))
	if npc_wanderer_active and sky_arena_pos.x >= 0:
		npc_wanderer_pos = Vector2(sky_arena_pos.x * TILE_SIZE + TILE_SIZE * 0.5, (sky_arena_pos.y - 8) * TILE_SIZE)
	var obs_arr: Array = data.get("observatory_pos", [-1, -1])
	if obs_arr.size() >= 2:
		observatory_pos = Vector2i(int(obs_arr[0]), int(obs_arr[1]))
	var moon_arr: Array = data.get("moon_altar_pos", [-1, -1])
	if moon_arr.size() >= 2:
		moon_altar_pos = Vector2i(int(moon_arr[0]), int(moon_arr[1]))
	if storm_herald_defeated:
		storm_active = false
		storm_tornado_phase = ""
	var explored_b64 := str(data.get("explored_tiles", ""))
	if explored_b64 != "":
		var decoded := Marshalls.base64_to_raw(explored_b64)
		if decoded.size() == WORLD_WIDTH * WORLD_HEIGHT:
			explored_tiles = decoded
	# Rebuild the derived liquid index, then restore compact partial fill data.
	# Saves from before this feature simply contain full liquid blocks.
	if liquid_sim != null:
		liquid_sim.rebuild(world)
		var loaded_liquid_levels: Variant = data.get("liquid_levels", {})
		if loaded_liquid_levels is Dictionary:
			liquid_sim.restore_levels(loaded_liquid_levels)
	if renderer_mgr != null:
		renderer_mgr.mark_all_dirty()
	_update_hud()


func _save_game() -> void:
	# Joined clients never overwrite the host's world with a partial local copy.
	if network_session != null and network_session.is_client():
		return
	if current_world_index >= 0:
		_save_game_to_path(_world_path(current_world_index))


func _load_game() -> void:
	if current_world_index >= 0:
		_load_game_from_path(_world_path(current_world_index))


func _migrate_legacy_save() -> void:
	# If there are no worlds yet but a legacy save exists, import it as world 0.
	if not worlds_meta.is_empty():
		return
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var idx := 0
	worlds_meta.append({"index": idx, "name": "Shadowgrove", "seed": randi(), "time": int(Time.get_unix_time_from_system())})
	_save_worlds_meta()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		var out := FileAccess.open(_world_path(idx), FileAccess.WRITE)
		if out != null:
			out.store_string(file.get_as_text())
	# keep legacy file; new saves go to world_0





func _rebuild_sapling_positions() -> void:
	sapling_positions.clear()
	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			if _get_tile(x, y) == Tile.SAPLING:
				sapling_positions["%d,%d" % [x, y]] = Vector2i(x, y)


func _update_selection_from_hotbar() -> void:
	var item_id := _selected_item()
	if tools.has(item_id):
		current_tool = item_id
	elif item_to_tile.has(item_id):
		selected_block = int(item_to_tile[item_id])


func _update_hud() -> void:
	_update_chest_open_state()
	var tile_pos := _mouse_tile()
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	var target_name := str(tile_names.get(tile, "Void"))
	var mine_percent := 0
	if mining_target == tile_pos and tile != Tile.AIR:
		mine_percent = int(clampf(mining_progress / _mining_hardness(tile, tile_pos), 0.0, 1.0) * 100.0)
	var recipe := _selected_recipe()
	var result := str(recipe.get("result", ""))
	var station := str(recipe.get("station", "hand"))

	var biome := _current_biome()
	# Only actual information remains on screen; empty status-effect markers are hidden.
	hud_label.text = "%d / %d" % [health, MAX_HEALTH]
	hud_health_bar.value = health
	hud_armor_value.text = "ARMOR  %d" % _total_defense()
	hud_status_label.text = _format_player_statuses().strip_edges()
	_update_health_hearts()
	if flight_charge_label != null:
		var has_flight := _equipped_accessory_has("flight") or equipped_accessory == "cloudwing_amulet"
		flight_charge_label.visible = has_flight
		if has_flight:
			flight_charge_label.text = "FLIGHT %d%%" % int(round(flight_charge))
	if armor_chip_label != null:
		armor_chip_label.text = str(_total_defense())
	if hud_class_label != null:
		hud_class_label.text = "%s | DMG %d" % [active_class, _total_damage()]
	if vitals_seed_label != null:
		vitals_seed_label.text = "SEED %d" % seed
	# (Storm progress moved to the journal — see the Storm tab.)
	_rebuild_status_chips()
	_update_day_icon()
	_update_hud_toast()
	var show_oxygen := oxygen < MAX_OXYGEN - 0.5 or _player_overlaps_tile(Tile.WATER)
	oxygen_panel.visible = show_oxygen
	if show_oxygen:
		oxygen_bar.value = oxygen
		oxygen_value.text = "%d%%" % int(round(oxygen))
	_update_temperature_hud()
	minimap_time_label.text = "MAP · M"
	var biome_text := _biome_display_name(biome).to_upper()
	if weather != WEATHER_CLEAR and _weather_strength() > 0.15:
		biome_text += " · %s" % _weather_display_name(weather).to_upper()
	minimap_biome_label.text = biome_text
	var prompt := ""
	if not inventory_open and not full_map_open and not journal_open and _can_interact(tile_pos):
		if tile == Tile.CHEST:
			prompt = "RMB  OPEN ANCIENT CHEST"
		elif tile == Tile.STONE_ALTAR:
			prompt = "RMB  AWAKEN ALTAR"
		elif tile == Tile.SKY_OBELISK:
			prompt = "RMB  OFFER SKY SHARDS"
	context_hint_panel.visible = prompt != ""
	context_hint_label.text = prompt
	_update_hotbar_buttons()
	var chest_open := inventory_open and active_chest_key != ""
	inventory_backdrop.visible = inventory_open
	# Exactly one primary screen is visible. Chests replace the loadout card,
	# while the backpack remains available for transfers.
	equipment_overlay.visible = inventory_open and inventory_screen == "inventory" and not chest_open
	inventory_panel.visible = inventory_open and inventory_screen == "inventory"
	crafting_panel.visible = inventory_open and inventory_screen == "crafting" and not chest_open
	chest_panel.visible = chest_open
	_update_mobile_controls_visibility()
	if minimap_panel != null:
		minimap_panel.visible = not inventory_open and not full_map_open and not journal_open
	if journal_access_button != null:
		journal_access_button.visible = not mobile_ui_enabled and not inventory_open and not full_map_open and not journal_open
		journal_access_button.text = "JOURNAL" if journal_unread_count <= 0 else "JOURNAL  +%d" % journal_unread_count
	if not inventory_open:
		return

	_update_inventory_buttons()
	_update_chest_buttons()
	_update_equipment_buttons()
	_update_recipe_buttons()
	inventory_title_label.text = "INVENTORY · 30 SLOTS"
	equipment_label.text = "EQUIPPED"
	equipment_environment_label.text = "COLD %d%%  |  HEAT %d%%" % [
		int(round(_temperature_protection("cold_protection") * 100.0)),
		int(round(_temperature_protection("heat_protection") * 100.0))
	]
	if char_stats_label != null:
		char_stats_label.text = "CLASS   %s\nDAMAGE   %d\nDEFENSE   %d\nCOLD/HEAT   %d%% / %d%%" % [
			active_class,
			_total_damage(),
			_total_defense(),
			int(round(_temperature_protection("cold_protection") * 100.0)),
			int(round(_temperature_protection("heat_protection") * 100.0))
		]
	_apply_station_filter_styles()
	selected_item_label.text = _format_selected_inventory_item()
	assign_hotbar_button.disabled = selected_inventory_item_id == "" or held_item_id != ""
	equip_inventory_button.disabled = selected_inventory_item_id == "" or held_item_id != "" or (not tools.has(selected_inventory_item_id) and not gear_stats.has(selected_inventory_item_id))
	drop_inventory_button.disabled = true
	crafting_label.text = _format_recipe_panel(recipe, result, station)
	stations_label.text = _station_status_text()
	message_label.text = "Message: %s" % last_message
	controls_label.text = "TAB/I close | Click inventory item to select | Use buttons for hotbar/equip | Z/X recipe | C craft | E equip hotbar item | F attack"


func _update_boss_bar() -> void:
	var boss := _boss_enemy()
	if boss.is_empty():
		boss_panel.visible = false
		return
	boss_panel.visible = true
	boss_label.text = str(boss.get("name", "Boss"))
	boss_hp_bar.max_value = float(boss.get("max_hp", 1))
	boss_hp_bar.value = maxf(0.0, float(boss.get("hp", 0)))


func _boss_enemy() -> Dictionary:
	for enemy in enemies:
		var data: Dictionary = enemy
		var t := str(data.get("type", ""))
		if t == "heartwood_boss" or t == "stone_beast" or t == "storm_herald" or t == "depth_warden" or t == "leviathan":
			return data
	return {}


func _format_player_statuses() -> String:
	if player_statuses.is_empty():
		return ""
	var parts: Array[String] = []
	for status in player_statuses.keys():
		var label := str(status).substr(0, 1).to_upper()
		var data: Dictionary = player_statuses[status]
		parts.append("%s%d" % [label, ceili(float(data.get("time", 0.0)))])
	return " [%s]" % " ".join(parts)


func _update_temperature_hud() -> void:
	if temperature_bar == null or temperature_value == null or temperature_title == null:
		return
	temperature_bar.value = body_temperature
	temperature_value.text = "%dC" % int(round(body_temperature))
	var next_state := "stable"
	var color := Color("ffd98a")
	if body_temperature <= 31.0:
		next_state = "freezing"
		color = Color("5aa9c4")
	elif body_temperature < 34.0:
		next_state = "cold"
		color = Color("8ed0e3")
	elif body_temperature >= 43.0:
		next_state = "burning"
		color = Color("e65f45")
	elif body_temperature > 40.0:
		next_state = "hot"
		color = Color("e39a59")
	temperature_title.add_theme_color_override("font_color", color)
	temperature_value.add_theme_color_override("font_color", color)
	if next_state == temperature_visual_state:
		return
	temperature_visual_state = next_state
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_border_width_all(1)
	fill.border_color = color.lightened(0.35)
	fill.content_margin_left = 2
	fill.content_margin_top = 2
	fill.content_margin_right = 2
	fill.content_margin_bottom = 2
	temperature_bar.add_theme_stylebox_override("fill", fill)


func _format_oxygen_status() -> String:
	if oxygen >= MAX_OXYGEN - 0.5 and not _player_overlaps_tile(Tile.WATER):
		return ""
	return " | AIR %d%%" % int(round(oxygen))


func _biome_display_name(biome: String) -> String:
	if biome == "forest":
		return "Forest"
	if biome == "sky_islands":
		return "Sky Islands"
	if biome == "frost_wasteland":
		return "Frost Wasteland"
	if biome == "marsh":
		return "Mossy Marsh"
	if biome == "ash_desert":
		return "Ash Desert"
	if biome == "ash_ruins":
		return "Ashen Ruins"
	if biome == "frost_caves":
		return "Frost Caves"
	if biome == "mushroom_halls":
		return "Mushroom Halls"
	if biome == "ash_city":
		return "Ash City"
	if biome == "sunken_ruins":
		return "Sunken Ruins"
	if biome == "lava_roots":
		return "Lava Roots"
	if biome == "glass_abyss":
		return "Glass Abyss"
	return "Caves"


func _format_equipment_panel(target_name: String, tile_pos: Vector2i, mine_percent: int) -> String:
	return "Equipment\nClass: %s | Damage: %d | Defense: %d\nSelected tool: %s P%d\nTarget: %s [%d,%d] Mining %d%%" % [
		active_class,
		_total_damage(),
		_total_defense(),
		str(tools.get(current_tool, {"name": current_tool}).get("name", current_tool)),
		_tool_power(),
		target_name,
		tile_pos.x,
		tile_pos.y,
		mine_percent
	]


func _item_characteristic_lines(item_id: String) -> Array[String]:
	var lines: Array[String] = []
	if tools.has(item_id):
		var tool: Dictionary = tools[item_id]
		lines.append("Mining power %d | mining speed %.2f" % [
			int(tool.get("power", 1)),
			float(tool.get("speed", 1.0))
		])
	elif gear_stats.has(item_id):
		var gear: Dictionary = gear_stats[item_id]
		var stats: Array[String] = []
		var damage := int(gear.get("damage", 0))
		var defense := int(gear.get("defense", 0))
		if damage != 0:
			stats.append("damage +%d" % damage)
		if defense != 0:
			stats.append("defense +%d" % defense)
		if stats.is_empty():
			stats.append("utility")
		lines.append("%s | class %s | %s" % [
			str(gear.get("slot", "gear")).capitalize(),
			str(gear.get("class", "Any")),
			" | ".join(stats)
		])
		var cold_protection := float(gear.get("cold_protection", 0.0))
		var heat_protection := float(gear.get("heat_protection", 0.0))
		if cold_protection > 0.0 or heat_protection > 0.0:
			lines.append("Cold protection %d%% | heat protection %d%%" % [
				int(round(cold_protection * 100.0)),
				int(round(heat_protection * 100.0))
			])
		if float(gear.get("speed_bonus", 0.0)) > 0.0:
			lines.append("Movement speed +%d%%" % int(round(float(gear["speed_bonus"]) * 100.0)))
		if bool(gear.get("water_breathing", false)):
			lines.append("Allows breathing underwater")
		if bool(gear.get("heat_resistance", false)):
			lines.append("Greatly reduces lava damage")
		if bool(gear.get("flight", false)):
			lines.append("Enables powered flight")
		if bool(gear.get("flight_bonus", false)) or item_id == "cloudwing_amulet":
			lines.append("Improves aerial mobility")
		if bool(gear.get("grapple", false)):
			lines.append("Enables the grappling hook")
		if bool(gear.get("sky_compass", false)):
			lines.append("Points toward undiscovered sky locations")
		if bool(gear.get("water_affinity", false)):
			lines.append("Water-attuned equipment")
	elif consumables.has(item_id):
		var consumable: Dictionary = consumables[item_id]
		if int(consumable.get("heal", 0)) > 0:
			lines.append("Restores %d health" % int(consumable["heal"]))
	elif item_to_tile.has(item_id):
		lines.append("Placeable block")
	return lines


func _item_tooltip_text(item_id: String, amount: int) -> String:
	if item_id == "":
		return ""
	var lines: Array[String] = ["%s x%d" % [_item_display_name(item_id), amount]]
	lines.append_array(_item_characteristic_lines(item_id))
	return "\n".join(lines)


func _format_selected_inventory_item() -> String:
	if held_item_id != "":
		return "Dragging: %s x%d\nRelease over hotbar/equipment/inventory, or outside menu to drop. Right-click a stack to take half." % [_item_display_name(held_item_id), held_item_amount]
	if selected_inventory_item_id == "" or int(inventory.get(selected_inventory_item_id, 0)) <= 0:
		return "Selected item: none\nLeft-drag a stack. Right-drag takes half."
	var parts := ["Selected: %s x%d" % [_item_display_name(selected_inventory_item_id), int(inventory.get(selected_inventory_item_id, 0))]]
	parts.append_array(_item_characteristic_lines(selected_inventory_item_id))
	return "\n".join(parts)


func _format_recipe_panel(recipe: Dictionary, result: String, station: String) -> String:
	if recipe.is_empty():
		return "Select a recipe"
	var can_station := _has_station_nearby(station)
	var can_materials := _has_recipe_materials(recipe)
	var lines: Array[String] = []
	lines.append("%s x%d" % [_item_display_name(result), int(recipe.get("amount", 1))])
	lines.append("Station: %s [%s]" % [
		_station_display_name(station),
		"READY" if can_station else "NOT NEARBY"
	])
	lines.append("Materials:")
	var cost: Dictionary = recipe.get("cost", {})
	for item_id in cost.keys():
		var need := int(cost[item_id])
		var have := int(inventory.get(str(item_id), 0))
		lines.append("%s: %d / %d%s" % [
			_item_display_name(str(item_id)),
			have,
			need,
			"" if have >= need else "  MISSING"
		])
	lines.append("READY TO CRAFT" if can_station and can_materials else "CANNOT CRAFT")
	return "\n".join(lines)


func _has_recipe_materials(recipe: Dictionary) -> bool:
	var cost: Dictionary = recipe.get("cost", {})
	for item_id in cost.keys():
		if int(inventory.get(str(item_id), 0)) < int(cost[item_id]):
			return false
	return true


func _missing_recipe_text(recipe: Dictionary) -> String:
	var cost: Dictionary = recipe.get("cost", {})
	var missing: Array[String] = []
	for item_id in cost.keys():
		var need := int(cost[item_id])
		var have := int(inventory.get(str(item_id), 0))
		if have < need:
			missing.append("%s %d/%d" % [_item_display_name(str(item_id)), have, need])
	return ", ".join(missing)


func _format_hotbar() -> String:
	var parts: Array[String] = []
	for i in range(hotbar.size()):
		var item_id := str(hotbar[i])
		var marker := ">" if i == selected_slot else "-"
		var name := str(item_names.get(item_id, item_id))
		var amount := int(inventory.get(item_id, 0))
		parts.append("%s %d %s x%d" % [marker, i + 1, name, amount])
	return "HOTBAR  " + "     ".join(parts)


func _update_hotbar_buttons() -> void:
	_sanitize_hotbar()
	for i in range(hotbar_buttons.size()):
		var item_id := str(hotbar[i])
		var selected := i == selected_slot
		if int(inventory.get(item_id, 0)) <= 0:
			item_id = ""
		_configure_slot_button(hotbar_buttons[i], item_id, int(inventory.get(item_id, 0)), selected, str(i + 1))
		_apply_compass_hotbar_slot_style(hotbar_buttons[i], selected)
		if i < hotbar_arrow_labels.size():
			hotbar_arrow_labels[i].visible = selected


func _update_inventory_buttons() -> void:
	var items := _inventory_item_ids()
	for i in range(inventory_slot_buttons.size()):
		if i < items.size():
			var item_id := str(items[i])
			var selected := item_id == selected_inventory_item_id
			_configure_slot_button(inventory_slot_buttons[i], item_id, int(inventory.get(item_id, 0)), selected, "")
			_apply_compass_inventory_slot_style(inventory_slot_buttons[i], selected)
		else:
			_configure_slot_button(inventory_slot_buttons[i], "", 0, false, "")
			_apply_compass_inventory_slot_style(inventory_slot_buttons[i], false)


func _update_chest_buttons() -> void:
	var items := _active_chest_items()
	for i in range(chest_slot_buttons.size()):
		if i < items.size():
			var item_id := str(items[i])
			var loot: Dictionary = chest_loot.get(active_chest_key, {})
			_configure_slot_button(chest_slot_buttons[i], item_id, int(loot.get(item_id, 0)), false, "")
			_apply_compass_inventory_slot_style(chest_slot_buttons[i], false)
		else:
			_configure_slot_button(chest_slot_buttons[i], "", 0, false, "")
			_apply_compass_inventory_slot_style(chest_slot_buttons[i], false)


func _update_chest_open_state() -> void:
	if active_chest_key == "":
		return
	if not inventory_open:
		_close_chest()
		return
	if not _in_bounds(active_chest_pos.x, active_chest_pos.y) or _get_tile(active_chest_pos.x, active_chest_pos.y) != Tile.CHEST:
		_close_chest()
		return
	if not _can_interact(active_chest_pos):
		_close_chest()


func _update_equipment_buttons() -> void:
	_configure_slot_button(weapon_slot_button, equipped_weapon, int(inventory.get(equipped_weapon, 1)), false, "")
	_apply_compass_inventory_slot_style(weapon_slot_button, equipped_weapon != "", true)
	weapon_slot_button.disabled = true
	weapon_slot_button.tooltip_text = "Weapon: empty" if equipped_weapon == "" else _item_tooltip_text(equipped_weapon, 1)
	_configure_slot_button(armor_slot_button, equipped_armor, int(inventory.get(equipped_armor, 1)), false, "")
	_apply_compass_inventory_slot_style(armor_slot_button, equipped_armor != "", true)
	armor_slot_button.disabled = true
	armor_slot_button.tooltip_text = "Armor: empty" if equipped_armor == "" else _item_tooltip_text(equipped_armor, 1)
	_configure_slot_button(accessory_slot_button, equipped_accessory, int(inventory.get(equipped_accessory, 1)), false, "")
	_apply_compass_inventory_slot_style(accessory_slot_button, equipped_accessory != "", true)
	accessory_slot_button.disabled = true
	accessory_slot_button.tooltip_text = "Charm: empty" if equipped_accessory == "" else _item_tooltip_text(equipped_accessory, 1)


func _update_recipe_buttons() -> void:
	for i in range(recipe_buttons.size()):
		var button := recipe_buttons[i]
		if i >= recipes.size():
			button.visible = false
			continue
		var recipe: Dictionary = recipes[i]
		var known := _recipe_is_known(recipe)
		var matches_filter := recipe_station_filter == "all" or str(recipe.get("station", "hand")) == recipe_station_filter
		button.visible = known and matches_filter
		if not known or not matches_filter:
			button.icon = null
			button.text = ""
			button.tooltip_text = ""
			continue
		var result := str(recipe.get("result", ""))
		var ready := _has_station_nearby(str(recipe.get("station", "hand"))) and _has_recipe_materials(recipe)
		var status := "READY" if ready else "LOCKED"
		button.icon = _item_icon(result)
		button.expand_icon = true
		button.text = ""
		button.tooltip_text = "%s x%d [%s]\nStation: %s\nCost: %s\nMissing: %s" % [
			_item_display_name(result),
			int(recipe.get("amount", 1)),
			status,
			_station_display_name(str(recipe.get("station", "hand"))),
			_recipe_cost_text(recipe),
			_missing_recipe_text(recipe)
		]
		button.disabled = false
		_apply_recipe_button_style(button, i == selected_recipe_index, ready)
	if craft_button != null:
		var selected := _selected_recipe()
		craft_button.disabled = selected.is_empty() or not (_has_station_nearby(str(selected.get("station", "hand"))) and _has_recipe_materials(selected))


func _apply_recipe_button_style(button: Button, selected: bool, ready: bool) -> void:
	var style := _pixel_sb("res://assets/ui/slot_selected.png" if selected else "res://assets/ui/slot.png", 5)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	var hover := _pixel_sb("res://assets/ui/slot_selected.png", 5)
	hover.content_margin_left = 6
	hover.content_margin_top = 6
	hover.content_margin_right = 6
	hover.content_margin_bottom = 6
	button.add_theme_stylebox_override("hover", hover)


func _configure_slot_button(button: Button, item_id: String, amount: int, selected: bool, prefix: String) -> void:
	_apply_slot_style(button, selected)
	if item_id == "":
		button.icon = null
		button.text = ""
		button.tooltip_text = ""
		button.disabled = true
		return
	button.disabled = false
	button.icon = _item_icon(item_id)
	var amount_text := "" if amount <= 1 else str(amount)
	button.text = ("%s\n%s" % [prefix, amount_text]).strip_edges()
	button.tooltip_text = _item_tooltip_text(item_id, amount)


func _item_icon(item_id: String) -> Texture2D:
	if item_icon_cache.has(item_id):
		return item_icon_cache[item_id]
	var file_texture: Texture2D = _load_png_texture("res://assets/textures/items/%s.png" % item_id)
	if file_texture != null:
		item_icon_cache[item_id] = file_texture
		return file_texture
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var main := _item_icon_color(item_id)
	var dark := main.darkened(0.38)
	var light := main.lightened(0.35)
	if item_id.contains("pickaxe"):
		_icon_rect(image, 5, 6, 12, 3, light)
		_icon_rect(image, 14, 9, 3, 3, light)
		_icon_rect(image, 9, 9, 3, 10, dark)
	elif item_id.contains("sword") or item_id.contains("spear") or item_id.contains("sickle"):
		_icon_rect(image, 11, 3, 3, 14, light)
		_icon_rect(image, 8, 14, 9, 3, dark)
		_icon_rect(image, 10, 17, 4, 4, Color("6b4428"))
	elif item_id.contains("bow"):
		_icon_rect(image, 7, 4, 3, 16, main)
		_icon_rect(image, 14, 5, 2, 14, light)
		_icon_rect(image, 10, 11, 7, 2, dark)
	elif item_id.contains("shield") or item_id.contains("armor") or item_id.contains("charm") or item_id.contains("ring"):
		_icon_rect(image, 7, 4, 10, 12, main)
		_icon_rect(image, 9, 16, 6, 4, dark)
		_icon_rect(image, 10, 7, 4, 5, light)
	elif item_id.contains("salve"):
		# small bottle / flask
		_icon_rect(image, 8, 3, 8, 5, light)
		_icon_rect(image, 7, 7, 10, 12, main)
		_icon_rect(image, 9, 10, 4, 5, light)
		_icon_rect(image, 10, 19, 4, 2, dark)
	elif item_id == "leviathan_scale":
		# overlapping dragon-like scales
		_icon_rect(image, 5, 4, 14, 6, dark)
		_icon_rect(image, 6, 5, 12, 4, main)
		_icon_rect(image, 5, 10, 14, 6, dark)
		_icon_rect(image, 6, 11, 12, 4, light)
		_icon_rect(image, 8, 16, 8, 4, dark)
		_icon_rect(image, 9, 17, 6, 2, main)
	elif item_id == "sky_shard":
		# the true Sky Shard: a tall glowing crystal (Chapter IV key)
		_icon_rect(image, 10, 2, 4, 16, dark)
		_icon_rect(image, 11, 3, 3, 14, main)
		_icon_rect(image, 12, 4, 2, 4, Color("f2fcff"))
		_icon_rect(image, 8, 16, 8, 3, dark)
		_icon_rect(image, 9, 17, 6, 2, Color("fff3c0"))
	elif item_id == "sky_compass":
		# golden compass: ring + needle
		_icon_rect(image, 5, 5, 14, 14, dark)
		_icon_rect(image, 6, 6, 12, 12, main)
		_icon_rect(image, 8, 8, 8, 8, light)
		_icon_rect(image, 11, 3, 2, 4, Color("f2fcff"))
		_icon_rect(image, 11, 17, 2, 4, Color("fff3c0"))
		_icon_rect(image, 3, 11, 4, 2, Color("fff3c0"))
		_icon_rect(image, 17, 11, 4, 2, Color("fff3c0"))
		_icon_rect(image, 11, 11, 2, 2, Color("e8d9a0"))
	elif item_id == "sky_scale_armor":
		# scaled chestplate
		_icon_rect(image, 6, 5, 12, 12, dark)
		_icon_rect(image, 7, 6, 10, 10, main)
		_icon_rect(image, 5, 5, 14, 2, dark)
		_icon_rect(image, 8, 8, 5, 3, light)
		_icon_rect(image, 9, 13, 6, 3, Color("7a9ad8"))
	elif item_id == "sky_lance":
		# long sky-blue lance
		_icon_rect(image, 11, 2, 3, 20, dark)
		_icon_rect(image, 12, 3, 2, 18, main)
		_icon_rect(image, 10, 2, 5, 4, light)
		_icon_rect(image, 8, 18, 7, 3, dark)
	elif item_id == "cloudwing_amulet":
		# pendant with a small wing
		_icon_rect(image, 6, 4, 4, 12, dark)
		_icon_rect(image, 8, 3, 4, 13, main)
		_icon_rect(image, 11, 4, 4, 11, light)
		_icon_rect(image, 14, 6, 3, 8, dark)
		_icon_rect(image, 10, 16, 4, 4, Color("f2fcff"))
		_icon_rect(image, 11, 20, 2, 2, Color("f2fcff"))
	elif item_id == "jetpack":
		# techno backpack with a nozzle
		_icon_rect(image, 7, 5, 10, 13, dark)
		_icon_rect(image, 8, 6, 8, 10, main)
		_icon_rect(image, 9, 8, 4, 3, light)
		_icon_rect(image, 10, 16, 4, 3, dark)
		_icon_rect(image, 11, 19, 2, 3, Color("ff8a3c"))
		_icon_rect(image, 6, 7, 2, 4, light)
	elif item_id == "wind_wings":
		# feathered wings
		_icon_rect(image, 5, 4, 4, 14, dark)
		_icon_rect(image, 8, 3, 4, 15, main)
		_icon_rect(image, 11, 4, 4, 13, light)
		_icon_rect(image, 14, 6, 3, 10, dark)
		_icon_rect(image, 9, 6, 2, 3, Color("f2fcff"))
	elif item_id.contains("bar"):
		_icon_rect(image, 5, 9, 14, 7, main)
		_icon_rect(image, 7, 7, 10, 3, light)
	elif item_id.contains("ore") or item_id in ["ash", "root", "stone", "ruin_brick", "memory_shard", "spark_shard", "root_core", "ash_glass", "sky_crystal", "sky_fragment", "sky_shard", "star_dust", "cloudstone"]:
		_icon_rect(image, 5, 7, 13, 10, dark)
		_icon_rect(image, 7, 5, 8, 5, main)
		_icon_rect(image, 12, 12, 5, 4, light)
	elif item_to_tile.has(item_id):
		_icon_rect(image, 5, 5, 14, 14, main)
		_icon_rect(image, 7, 7, 10, 3, light)
		_icon_rect(image, 6, 16, 12, 2, dark)
	else:
		_icon_rect(image, 6, 6, 12, 12, main)
		_icon_rect(image, 9, 9, 6, 6, light)
	var texture := ImageTexture.create_from_image(image)
	item_icon_cache[item_id] = texture
	return texture


func _item_icon_color(item_id: String) -> Color:
	if item_id.contains("copper"):
		return Color("c97a45")
	if item_id.contains("iron"):
		return Color("c9c6b7")
	if item_id == "ash_sand":
		return Color("c9b591")
	if item_id == "frozen_dirt":
		return Color("8fa3b8")
	if item_id == "mud":
		return Color("6b5340")
	if item_id == "rubble":
		return Color("8d7f72")
	if item_id.contains("ash") or item_id.contains("memory"):
		return Color("9b7bd8")
	if item_id.contains("root"):
		return Color("8a6638")
	if item_id.contains("spark") or item_id.contains("fire"):
		return Color("ffcf5f")
	if item_id.contains("ruin") or item_id.contains("cannon"):
		return Color("81759a")
	if item_id.contains("chest"):
		return Color("b98746")
	if item_id == "torch":
		return Color("ffd36b")
	if item_id.contains("wood") or item_id == "workbench" or item_id.contains("heartwood"):
		return Color("a66a35")
	if item_id.contains("salve"):
		return Color("8fe06f")
	if item_id.contains("moss"):
		return Color("5c9a63")
	if item_id.contains("ward"):
		return Color("ffb84d")
	if item_id == "sky_scale_armor":
		return Color("9fc8e8")
	if item_id == "sky_lance":
		return Color("ffd98a")
	if item_id == "cloudwing_amulet":
		return Color("b8e4f2")
	if item_id == "sky_compass":
		return Color("e8d9a0")
	if item_id == "leviathan_scale":
		return Color("aed6ff")
	if item_id == "sky_shard":
		return Color("f0e0a8")
	if item_id == "sky_fragment":
		return Color("9fd0e8")
	if item_id == "jetpack":
		return Color("b0a88f")
	if item_id == "wind_wings":
		return Color("ffd98a")
	if item_id.contains("sky") or item_id.contains("zephyr") or item_id == "cloudstone":
		return Color("8fd8f5")
	if item_id.contains("star_dust"):
		return Color("ffe9a8")
	if item_id == "stone" or item_id == "furnace" or item_id == "anvil":
		return Color("69717c")
	if item_id == "dirt":
		return Color("7a4a2a")
	if item_id == "leaf":
		return Color("4a7b50")
	return Color("7fb6d6")


func _icon_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for yy in range(y, y + height):
		for xx in range(x, x + width):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
				image.set_pixel(xx, yy, color)


func _format_inventory_contents() -> String:
	var keys: Array[String] = []
	for item_id in inventory.keys():
		if int(inventory[item_id]) > 0:
			keys.append(str(item_id))
	keys.sort()
	if keys.is_empty():
		return "empty"
	var lines: Array[String] = []
	var current_line := ""
	for item_id in keys:
		var part := "%s x%d" % [_item_display_name(item_id), int(inventory[item_id])]
		if current_line.length() + part.length() > 88:
			lines.append(current_line)
			current_line = part
		elif current_line == "":
			current_line = part
		else:
			current_line += " | " + part
	if current_line != "":
		lines.append(current_line)
	return "\n".join(lines)


func _station_status_text() -> String:
	return "STATIONS NEARBY\nWorkbench: %s\nFurnace: %s\nAnvil: %s" % [
		"YES" if _has_station_nearby("workbench") else "NO",
		"YES" if _has_station_nearby("furnace") else "NO",
		"YES" if _has_station_nearby("anvil") else "NO"
	]


func _empty_name(item_id: String) -> String:
	if item_id == "":
		return "none"
	return _item_display_name(item_id)


func _draw_background() -> void:
	var view_rect := get_viewport_rect()
	var top_left := camera.get_screen_center_position() - view_rect.size * 0.5 / camera.zoom
	var bottom_right := camera.get_screen_center_position() + view_rect.size * 0.5 / camera.zoom
	var biome := _current_biome()
	var sky := _biome_background_color(biome).lerp(Color("070912"), (1.0 - _daylight_factor()) * 0.55)
	draw_rect(Rect2(top_left, bottom_right - top_left), sky)
	_draw_biome_backdrop(biome, top_left, bottom_right)
	for i in range(18):
		var x := fposmod(float(seed % 997) * 3.0 + float(i) * 173.0, WORLD_WIDTH * TILE_SIZE)
		var y := 38.0 + float((seed + i * 31) % 90)
		if biome == "forest" or _is_night():
			draw_circle(Vector2(x, y), 1.2, Color("d7e4ee", 0.25 + (1.0 - _daylight_factor()) * 0.55))


func _biome_background_color(biome: String) -> Color:
	if biome == "sky_islands":
		return Color("9fd4e8")
	if biome == "forest":
		return Color("172b2a")
	if biome == "frost_wasteland" or biome == "frost_caves":
		return Color("17283b")
	if biome == "marsh":
		return Color("142722")
	if biome == "ash_desert":
		return Color("30211d")
	if biome == "ash_ruins":
		return Color("211b21")
	if biome == "mushroom_halls":

		return Color("171628")
	if biome == "ash_city":
		return Color("211b21")
	if biome == "sunken_ruins":
		return Color("102633")
	if biome == "lava_roots":
		return Color("241412")
	if biome == "glass_abyss":
		return Color("07151c")
	return Color("151b24")


func _draw_biome_backdrop(biome: String, top_left: Vector2, bottom_right: Vector2) -> void:
	var width := bottom_right.x - top_left.x
	var height := bottom_right.y - top_left.y
	var base_y := top_left.y + height * 0.62
	var parallax_x := camera.get_screen_center_position().x * 0.18
	if biome == "sky_islands":
		# Drifting cloud layers make the sky feel alive above the islands.
		for layer in range(3):
			var layer_color := Color(1.0, 1.0, 1.0, 0.16 + float(layer) * 0.10)
			var spacing := 150.0 - float(layer) * 26.0
			var speed := 0.04 + float(layer) * 0.03
			for i in range(10):
				var x := top_left.x + fposmod(float(i) * spacing - camera.get_screen_center_position().x * speed, width + 260.0) - 130.0
				var y := top_left.y + float((seed + i * 53 + layer * 17) % int(maxf(1.0, height)))
				draw_circle(Vector2(x, y), 26.0 + float(layer) * 10.0, layer_color)
				draw_circle(Vector2(x + 34.0, y + 10.0), 18.0 + float(layer) * 7.0, layer_color)
	elif biome == "forest":
		# Three parallax forest layers. Small clustered crowns read as trees instead
		# of the oversized faint circles used by the old placeholder backdrop.
		for layer in range(3):
			var layer_factor := 0.10 + float(layer) * 0.12
			var spacing := 86.0 - float(layer) * 11.0
			var trunk_color := Color("0b1b16", 0.42 + float(layer) * 0.11)
			var crown_color := Color("123322", 0.30 + float(layer) * 0.10)
			for i in range(18):
				var x := top_left.x + fposmod(float(i) * spacing - camera.get_screen_center_position().x * layer_factor, width + 120.0) - 60.0
				var h := 52.0 + float((seed + i * 19 + layer * 31) % 48)
				var y := base_y + float(layer) * 12.0 - h
				draw_rect(Rect2(Vector2(x + 9, y + 18), Vector2(6 + layer * 2, h)), trunk_color)
				draw_circle(Vector2(x + 11, y + 15), 18.0 + layer * 3.0, crown_color)
				draw_circle(Vector2(x - 2, y + 24), 13.0 + layer * 2.0, crown_color)
				draw_circle(Vector2(x + 24, y + 25), 14.0 + layer * 2.0, crown_color)
		for i in range(12):
			var fern_x := top_left.x + fposmod(float(i * 71) - parallax_x * 0.55, width + 80.0) - 40.0
			var fern_y := base_y + 34.0
			draw_line(Vector2(fern_x, fern_y), Vector2(fern_x + 4, fern_y - 14), Color("28553a", 0.48), 2.0)
			draw_line(Vector2(fern_x + 3, fern_y - 8), Vector2(fern_x - 4, fern_y - 12), Color("386b45", 0.40), 1.0)
			draw_line(Vector2(fern_x + 3, fern_y - 10), Vector2(fern_x + 10, fern_y - 15), Color("386b45", 0.40), 1.0)
	elif biome == "mushroom_halls":
		for i in range(13):
			var x := top_left.x + fposmod(float(i * 121) - parallax_x, width + 160.0) - 80.0
			var h := 36.0 + float((seed + i * 23) % 50)
			draw_rect(Rect2(Vector2(x, base_y - h), Vector2(8, h)), Color("221b38", 0.62))
			draw_circle(Vector2(x + 4, base_y - h), 22.0, Color("4d315d", 0.38))
			draw_circle(Vector2(x + 10, base_y - h - 4), 2.0, Color("88ffd8", 0.55))
	elif biome == "ash_city":
		for i in range(14):
			var x := top_left.x + fposmod(float(i * 91) - parallax_x, width + 130.0) - 65.0
			var h := 44.0 + float((seed + i * 19) % 70)
			draw_rect(Rect2(Vector2(x, base_y - h), Vector2(24, h)), Color("141015", 0.66))
			draw_rect(Rect2(Vector2(x + 5, base_y - h + 10), Vector2(4, 4)), Color("d07d54", 0.32))
	elif biome == "sunken_ruins":
		for i in range(12):
			var x := top_left.x + fposmod(float(i * 112) - parallax_x, width + 150.0) - 75.0
			draw_line(Vector2(x, top_left.y), Vector2(x - 32, bottom_right.y), Color("6eb7c4", 0.10), 2.0)
			draw_rect(Rect2(Vector2(x, base_y - 42), Vector2(18, 58)), Color("0b1d24", 0.58))
	elif biome == "lava_roots":
		for i in range(18):
			var x := top_left.x + fposmod(float(i * 83) - parallax_x, width + 130.0) - 65.0
			draw_line(Vector2(x, top_left.y), Vector2(x + 26, bottom_right.y), Color("8d2e1e", 0.35), 5.0)
			draw_circle(Vector2(x + 8, base_y), 3.0, Color("ff7d3b", 0.55))
	elif biome == "glass_abyss":
		for i in range(20):
			var x := top_left.x + fposmod(float(i * 73) - parallax_x, width + 120.0) - 60.0
			var y := top_left.y + float((seed + i * 31) % int(maxf(1.0, height)))
			draw_line(Vector2(x, y), Vector2(x + 18, y + 52), Color("b8f4ff", 0.18), 1.0)
			draw_circle(Vector2(x + 8, y + 18), 1.5, Color("e8ffff", 0.35))


func _draw_visible_world() -> void:
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var half_size := view_rect.size * 0.5 / camera.zoom
	var min_x := clampi(floori((center.x - half_size.x) / TILE_SIZE) - VIEW_PADDING, 0, WORLD_WIDTH - 1)
	var max_x := clampi(ceili((center.x + half_size.x) / TILE_SIZE) + VIEW_PADDING, 0, WORLD_WIDTH - 1)
	var min_y := clampi(floori((center.y - half_size.y) / TILE_SIZE) - VIEW_PADDING, 0, WORLD_HEIGHT - 1)
	var max_y := clampi(ceili((center.y + half_size.y) / TILE_SIZE) + VIEW_PADDING, 0, WORLD_HEIGHT - 1)
	var min_chunk_x := int(floori(float(min_x) / float(CHUNK_SIZE)))
	var max_chunk_x := int(floori(float(max_x) / float(CHUNK_SIZE)))
	var min_chunk_y := int(floori(float(min_y) / float(CHUNK_SIZE)))
	var max_chunk_y := int(floori(float(max_y) / float(CHUNK_SIZE)))

	for chunk_y in range(min_chunk_y, max_chunk_y + 1):
		for chunk_x in range(min_chunk_x, max_chunk_x + 1):
			_draw_chunk(chunk_x, chunk_y, min_x, max_x, min_y, max_y)


func _collect_visible_light_sources() -> void:
	# The player light moves every frame; static tile lights only need a rescan
	# when the padded camera bounds or terrain revision changes.
	visible_light_sources.clear()
	visible_light_sources.append({
		"pos": player_position / TILE_SIZE,
		"radius": 7.0,
		"intensity": 0.95,
		"kind": "player"
	})
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var half_size := view_rect.size * 0.5 / camera.zoom
	var light_padding := 13
	var min_x := clampi(floori((center.x - half_size.x) / TILE_SIZE) - light_padding, 0, WORLD_WIDTH - 1)
	var max_x := clampi(ceili((center.x + half_size.x) / TILE_SIZE) + light_padding, 0, WORLD_WIDTH - 1)
	var min_y := clampi(floori((center.y - half_size.y) / TILE_SIZE) - light_padding, 0, WORLD_HEIGHT - 1)
	var max_y := clampi(ceili((center.y + half_size.y) / TILE_SIZE) + light_padding, 0, WORLD_HEIGHT - 1)
	var scan_bounds := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	if cached_light_revision == world_tile_revision and cached_light_bounds == scan_bounds:
		visible_light_sources.append_array(cached_static_light_sources)
		return

	cached_static_light_sources.clear()
	cached_light_bounds = scan_bounds
	cached_light_revision = world_tile_revision
	static_light_scan_count += 1
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile := _get_tile(x, y)
			var radius := 0.0
			var intensity := 1.0
			var kind := ""
			if tile == Tile.TORCH:
				radius = 12.0
				kind = "torch"
			elif tile == Tile.LANTERN:
				radius = 14.0
				kind = "lantern"
			elif tile == Tile.LAVA:
				var exposed := _get_tile(x, y - 1) != Tile.LAVA
				if exposed and _visual_hash(x, y, 47) % 4 == 0:
					radius = 4.5
					intensity = 0.34
					kind = "lava"
			elif tile == Tile.GLOW_MUSHROOM:
				radius = 7.0
				intensity = 0.82
				kind = "mushroom"
			elif tile == Tile.ABYSS_CRYSTAL:
				radius = 6.0
				intensity = 0.72
				kind = "crystal"
			elif tile == Tile.SKY_CRYSTAL:
				radius = 6.0
				intensity = 0.70
				kind = "crystal"
			if radius > 0.0:
				cached_static_light_sources.append({
					"pos": Vector2(x + 0.5, y + 0.5),
					"radius": radius,
					"intensity": intensity,
					"kind": kind
				})
	visible_light_sources.append_array(cached_static_light_sources)


func _tile_texture_at(tile: int, x: int, y: int) -> Texture2D:
	# Surface biome palettes cover the whole upper crust of their column, and
	# follow the terrain blend so tinting never recreates a hard border.
	if x >= 0 and x < surface_heights.size() and y <= surface_heights[x] + 26:
		var surface_biome := _visual_biome_at(x, y)
		var biome_tiles: Dictionary = biome_tile_textures.get(surface_biome, {})
		if biome_tiles.has(tile):
			return biome_tiles[tile] as Texture2D
	var variants: Array = tile_texture_variants.get(tile, [])
	if variants.is_empty():
		return tile_textures.get(tile, null) as Texture2D
	# Deterministic coordinates choose a stable variant, avoiding a repeated tile grid.
	var raw_index: int = x * 31 + y * 17 + tile * 13
	var variant_index: int = ((raw_index % variants.size()) + variants.size()) % variants.size()
	return variants[variant_index] as Texture2D


func _visual_hash(x: int, y: int, salt: int) -> int:
	var raw: int = x * 31 + y * 17 + seed * 13 + salt * 97
	return ((raw % 997) + 997) % 997


func _draw_air_decoration(x: int, y: int) -> void:
	if x <= 0 or x >= WORLD_WIDTH - 1 or y <= 0 or y >= WORLD_HEIGHT - 1:
		return
	var below := _get_tile(x, y + 1)
	var above := _get_tile(x, y - 1)
	var depth := y - surface_heights[x]
	var origin := Vector2(x * TILE_SIZE, y * TILE_SIZE)
	var mark := _visual_hash(x, y, 3)
	# Surface tufts, pebbles and small plants are visual only: no movement cost.
	if depth >= -1 and depth <= 1 and (below == Tile.GRASS or below == Tile.MOSS):
		if mark % 17 == 0:
			draw_line(origin + Vector2(7, 15), origin + Vector2(5, 9), Color("5f9d58"), 1.0)
			draw_line(origin + Vector2(8, 15), origin + Vector2(10, 10), Color("77b968"), 1.0)
		elif mark % 29 == 0:
			draw_circle(origin + Vector2(8, 14), 2.0, Color("67706c"))
		elif mark % 41 == 0:
			draw_circle(origin + Vector2(7, 13), 1.0, Color("d6c476"))
		return
	# The ash desert gets its own surface litter: pebbles and dry dead twigs.
	if depth >= -1 and depth <= 1 and below == Tile.ASH_SAND:
		if mark % 23 == 0:
			draw_circle(origin + Vector2(8, 14), 2.0, Color("8f8375"))
		elif mark % 37 == 0:
			draw_line(origin + Vector2(7, 15), origin + Vector2(5, 10), Color("b3a58f"), 1.0)
			draw_line(origin + Vector2(7, 13), origin + Vector2(10, 11), Color("b3a58f"), 1.0)
		return
	if depth < 8:
		return
	# Visual stalactites / stalagmites and biome details inside caves.
	if above != Tile.AIR and mark % 47 == 0:
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(3, 0), origin + Vector2(13, 0), origin + Vector2(8, 9)
		]), Color("4e5a5d"))
	elif below != Tile.AIR and mark % 53 == 0:
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(3, 16), origin + Vector2(13, 16), origin + Vector2(8, 7)
		]), Color("566264"))
	elif below == Tile.MUSHROOM_SOIL and mark % 11 == 0:
		draw_rect(Rect2(origin + Vector2(7, 8), Vector2(2, 8)), Color("7c6446"))
		draw_circle(origin + Vector2(8, 7), 4.0, Color("d172aa"))
		draw_circle(origin + Vector2(6, 6), 1.0, Color("f2b4d1"))
	elif below == Tile.SUNKEN_STONE and mark % 19 == 0:
		draw_circle(origin + Vector2(8, 11), 2.0, Color("77c3ca", 0.45))
		draw_circle(origin + Vector2(10, 6), 1.0, Color("a6e7e4", 0.55))
	elif below == Tile.LAVA_ROOT and mark % 23 == 0:
		draw_circle(origin + Vector2(8, 12), 1.5, Color("ff8a45"))
	elif below == Tile.GLASS_STONE and mark % 17 == 0:
		draw_colored_polygon(PackedVector2Array([
			origin + Vector2(7, 15), origin + Vector2(10, 4), origin + Vector2(12, 15)
		]), Color("9ee9e5", 0.72))


func _liquid_surface_rect(x: int, y: int, rect: Rect2) -> Rect2:
	var ratio := _liquid_fill_ratio(x, y)
	if ratio >= 0.999:
		return rect
	var filled_height := maxf(1.0, float(TILE_SIZE) * ratio)
	return Rect2(
		rect.position + Vector2(0.0, float(TILE_SIZE) - filled_height),
		Vector2(float(TILE_SIZE), filled_height)
	)


func _draw_liquid_motion(x: int, y: int, tile: int, rect: Rect2) -> void:
	var above_air := _get_tile(x, y - 1) == Tile.AIR
	var time := float(Time.get_ticks_msec()) / 1000.0
	var phase := sin(time * (2.0 if tile == Tile.WATER else 3.4) + float(x) * 0.75)
	if above_air:
		var wave_color := Color("91d7d8", 0.72) if tile == Tile.WATER else Color("ffd05d", 0.82)
		var max_wave_y := maxf(0.5, rect.size.y - 0.5)
		var left_y := clampf(1.0 + phase * 0.55, 0.5, max_wave_y)
		var right_y := clampf(1.0 - phase * 0.55, 0.5, max_wave_y)
		draw_line(rect.position + Vector2(0, left_y), rect.position + Vector2(rect.size.x, right_y), wave_color, 1.0)
	if rect.size.y < 6.0:
		return
	var mark := _visual_hash(x, y, 7)
	if tile == Tile.WATER and mark % 31 == 0:
		var bubble_y := clampf(8.0 + phase * 2.0, 2.0, rect.size.y - 1.0)
		draw_circle(rect.position + Vector2(7, bubble_y), 1.0, Color("c9ffff", 0.5))
	elif tile == Tile.LAVA and mark % 29 == 0:
		var ember_y := clampf(8.0 + phase, 2.0, rect.size.y - 1.0)
		draw_circle(rect.position + Vector2(8, ember_y), 1.0, Color("ffb34d", 0.75))


func _draw_chunk(chunk_x: int, chunk_y: int, min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var start_x := maxi(chunk_x * CHUNK_SIZE, min_x)
	var end_x := mini(start_x + CHUNK_SIZE - 1, max_x)
	var start_y := maxi(chunk_y * CHUNK_SIZE, min_y)
	var end_y := mini(start_y + CHUNK_SIZE - 1, max_y)
	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			var tile := _get_tile(x, y)
			if tile == Tile.AIR:
				_draw_air_decoration(x, y)
				continue
			var base_color: Color = tile_colors.get(tile, Color.WHITE)
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var texture: Texture2D = _tile_texture_at(tile, x, y)
			if texture != null:
				var texture_rect := rect
				if _uses_large_station_sprite(tile):
					# Stations stay one collision tile, but use a larger visual sprite.
					texture_rect = Rect2(rect.position + Vector2(-8, -16), Vector2(TILE_SIZE * 2, TILE_SIZE * 2))
					# A grounded shadow prevents stations from reading as loose inventory icons.
					draw_rect(Rect2(rect.position + Vector2(1, TILE_SIZE - 3), Vector2(TILE_SIZE - 2, 3)), Color(0.0, 0.0, 0.0, 0.42))
				if tile == Tile.WATER or tile == Tile.LAVA:
					var surface_rect := _liquid_surface_rect(x, y, rect)
					var source_rect := Rect2(
						Vector2(0.0, float(texture.get_height()) - surface_rect.size.y),
						Vector2(float(texture.get_width()), surface_rect.size.y)
					)
					draw_texture_rect_region(texture, surface_rect, source_rect, Color.WHITE)
					_draw_liquid_motion(x, y, tile, surface_rect)
				else:
					draw_texture_rect(texture, texture_rect, false, Color.WHITE)
				_draw_exposed_edge_breakup(x, y, tile, rect)
			else:
				var fallback_rect := _liquid_surface_rect(x, y, rect) if tile == Tile.WATER or tile == Tile.LAVA else rect
				draw_rect(fallback_rect, base_color)
				draw_rect(fallback_rect, base_color.darkened(0.18), false, 1.0)
				_draw_tile_details(fallback_rect, tile, base_color)


func _lit_tile_color(x: int, y: int, tile: int) -> Color:
	var base: Color = tile_colors.get(tile, Color.WHITE)
	var light: float = _light_at_tile(x, y)
	return base.lerp(Color("06070a"), 1.0 - light)


func _draw_exposed_edge_breakup(x: int, y: int, tile: int, rect: Rect2) -> void:
	if not _uses_organic_edges(tile):
		return
	var air_color := Color("17202a")
	var above_air := _get_tile(x, y - 1) == Tile.AIR
	var below_air := _get_tile(x, y + 1) == Tile.AIR
	var left_air := _get_tile(x - 1, y) == Tile.AIR
	var right_air := _get_tile(x + 1, y) == Tile.AIR
	if above_air:
		_draw_edge_chip(rect.position, Vector2i(2, 0), Vector2i(3, 1), air_color)
		_draw_edge_chip(rect.position, Vector2i(9, 0), Vector2i(2, 2), air_color)
		if tile == Tile.GRASS:
			draw_rect(Rect2(rect.position + Vector2(4, 0), Vector2(2, 1)), Color("75c86a"))
	if below_air:
		_draw_edge_chip(rect.position, Vector2i(4, 15), Vector2i(4, 1), air_color)
		_draw_edge_chip(rect.position, Vector2i(12, 14), Vector2i(2, 2), air_color)
	if left_air:
		_draw_edge_chip(rect.position, Vector2i(0, 3), Vector2i(1, 4), air_color)
		_draw_edge_chip(rect.position, Vector2i(0, 11), Vector2i(2, 2), air_color)
	if right_air:
		_draw_edge_chip(rect.position, Vector2i(15, 5), Vector2i(1, 4), air_color)
		_draw_edge_chip(rect.position, Vector2i(14, 12), Vector2i(2, 2), air_color)
	if above_air and left_air:
		_draw_edge_chip(rect.position, Vector2i(0, 0), Vector2i(3, 3), air_color)
	if above_air and right_air:
		_draw_edge_chip(rect.position, Vector2i(13, 0), Vector2i(3, 2), air_color)
	if below_air and left_air:
		_draw_edge_chip(rect.position, Vector2i(0, 14), Vector2i(2, 2), air_color)
	if below_air and right_air:
		_draw_edge_chip(rect.position, Vector2i(14, 14), Vector2i(2, 2), air_color)


func _uses_large_station_sprite(tile: int) -> bool:
	return tile == Tile.WORKBENCH or tile == Tile.FURNACE or tile == Tile.ANVIL or tile == Tile.CHEST


func _uses_organic_edges(tile: int) -> bool:
	return tile == Tile.GRASS or tile == Tile.DIRT or tile == Tile.STONE or tile == Tile.COPPER or tile == Tile.IRON or tile == Tile.ASH or tile == Tile.ROOT or tile == Tile.RUIN or tile == Tile.MOSS or tile == Tile.MUSHROOM_SOIL or tile == Tile.ASH_BRICK or tile == Tile.SUNKEN_STONE or tile == Tile.LAVA_ROOT or tile == Tile.GLASS_STONE or tile == Tile.ABYSS_CRYSTAL or tile == Tile.SKY_GRASS or tile == Tile.CLOUDSTONE or _is_biome_topsoil_tile(tile)


func _draw_edge_chip(origin: Vector2, offset: Vector2i, size: Vector2i, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(offset), Vector2(size)), color)


func _draw_tile_details(rect: Rect2, tile: int, color: Color) -> void:
	if tile == Tile.COPPER:
		_draw_ore_specks(rect, Color("ffb15f"), Color("6c3620"))
	elif tile == Tile.IRON:
		_draw_ore_specks(rect, Color("f0eee2"), Color("7a7a73"))
	elif tile == Tile.ASH:
		_draw_ore_specks(rect, Color("b79cff"), Color("24202e"))
		draw_rect(rect.grow(-2), Color("9276d5", 0.22), false, 1.0)
	elif tile == Tile.RUIN:
		draw_rect(rect.grow(-2), Color("b5a7d8", 0.35), false, 1.0)
		draw_line(rect.position + Vector2(3, 5), rect.position + Vector2(13, 5), Color("b5a7d8", 0.5), 1.0)
		draw_line(rect.position + Vector2(5, 11), rect.position + Vector2(15, 11), Color("342d3e", 0.7), 1.0)
	elif tile == Tile.WORKBENCH:
		draw_rect(rect.grow(-3), Color("d59b55", 0.45), false, 1.0)
		draw_line(rect.position + Vector2(3, 6), rect.position + Vector2(13, 6), Color("3d2414", 0.75), 1.0)
	elif tile == Tile.FURNACE:
		draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(8, 7)), Color("ff7d3b", 0.75))
		draw_rect(rect.grow(-2), Color("b6c1c8", 0.35), false, 1.0)
	elif tile == Tile.ANVIL:
		draw_rect(Rect2(rect.position + Vector2(3, 5), Vector2(10, 4)), Color("a6b4c8", 0.8))
		draw_rect(Rect2(rect.position + Vector2(6, 9), Vector2(4, 4)), Color("2a3341", 0.8))
	elif tile == Tile.TURRET:
		draw_rect(Rect2(rect.position + Vector2(3, 6), Vector2(10, 5)), Color("bcd8dd", 0.75))
		draw_rect(Rect2(rect.position + Vector2(11, 7), Vector2(5, 2)), Color("e5fbff", 0.8))
	elif tile == Tile.CHEST:
		draw_rect(Rect2(rect.position + Vector2(2, 5), Vector2(12, 8)), Color("b98746"))
		draw_rect(Rect2(rect.position + Vector2(2, 4), Vector2(12, 3)), Color("d0a15c"))
		draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(2, 3)), Color("f2d47b"))
		draw_rect(Rect2(rect.position + Vector2(2, 11), Vector2(12, 2)), Color("6f4425"))
	elif tile == Tile.STONE_ALTAR:
		draw_rect(Rect2(rect.position + Vector2(3, 8), Vector2(10, 5)), Color("71675d"))
		draw_rect(Rect2(rect.position + Vector2(5, 4), Vector2(6, 5)), Color("94877b"))
		draw_rect(Rect2(rect.position + Vector2(7, 5), Vector2(2, 6)), Color("b7f3dc"))
	elif tile == Tile.STONEBLOOD:
		_draw_ore_specks(rect, Color("8df0d0"), Color("284b48"))
		draw_rect(rect.grow(-2), Color("6fb3a2", 0.18), false, 1.0)
	elif tile == Tile.MOSS:
		_draw_ore_specks(rect, Color("7dcc72"), Color("213d25"))
	elif tile == Tile.MUSHROOM_SOIL:
		_draw_ore_specks(rect, Color("d38acc"), Color("2c2034"))
	elif tile == Tile.GLOW_MUSHROOM:
		draw_rect(Rect2(rect.position + Vector2(6, 6), Vector2(4, 7)), Color("5aa086"))
		draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(10, 5)), Color("88ffd8"))
	elif tile == Tile.ASH_BRICK:
		draw_rect(rect.grow(-2), Color("c0a6c8", 0.25), false, 1.0)
		draw_line(rect.position + Vector2(1, 6), rect.position + Vector2(15, 6), Color("2a222e"), 1.0)
	elif tile == Tile.SUNKEN_STONE:
		_draw_ore_specks(rect, Color("7bc8d2"), Color("18343e"))
	elif tile == Tile.LAVA_ROOT:
		draw_line(rect.position + Vector2(2, 13), rect.position + Vector2(14, 3), Color("ff7d3b"), 2.0)
		draw_line(rect.position + Vector2(5, 15), rect.position + Vector2(13, 8), Color("5d2118"), 2.0)
	elif tile == Tile.GLASS_STONE:
		draw_line(rect.position + Vector2(3, 13), rect.position + Vector2(13, 3), Color("d8ffff", 0.65), 1.0)
		draw_rect(rect.grow(-2), Color("b8f4ff", 0.22), false, 1.0)
	elif tile == Tile.ABYSS_CRYSTAL:
		draw_rect(Rect2(rect.position + Vector2(6, 2), Vector2(4, 12)), Color("d8ffff"))
		draw_rect(Rect2(rect.position + Vector2(4, 6), Vector2(8, 5)), Color("7fc7ff", 0.75))
	elif tile == Tile.WATER:
		draw_rect(rect, Color("327d9b", 0.62))
		draw_line(rect.position + Vector2(1, 3), rect.position + Vector2(10, 3), Color("8ed9ee", 0.55), 1.0)
	elif tile == Tile.LAVA:
		draw_rect(rect, Color("e64b24", 0.92))
		draw_line(rect.position + Vector2(1, 4), rect.position + Vector2(13, 4), Color("ffd05b", 0.85), 2.0)
		draw_rect(Rect2(rect.position + Vector2(5, 10), Vector2(5, 2)), Color("ff8a32"))
	elif tile == Tile.SKY_OBELISK:
		draw_rect(Rect2(rect.position + Vector2(6, 2), Vector2(4, 12)), Color("ffd98a"))
		draw_rect(Rect2(rect.position + Vector2(3, 8), Vector2(10, 4)), Color("9fc0f5"))
		draw_rect(Rect2(rect.position + Vector2(5, 12), Vector2(6, 3)), Color("7a9ad8"))
		draw_rect(Rect2(rect.position + Vector2(7, 3), Vector2(2, 2)), Color("f2fcff"))
	elif tile == Tile.SKY_GRASS:
		draw_rect(rect, Color("c9f2ee", 0.9))
		draw_rect(Rect2(rect.position + Vector2(4, 0), Vector2(2, 1)), Color("7ad4c8"))
		draw_rect(Rect2(rect.position + Vector2(9, 0), Vector2(3, 1)), Color("8ae0d4"))
		draw_rect(Rect2(rect.position + Vector2(2, 3), Vector2(12, 1)), Color("dff7f4", 0.8))
	elif tile == Tile.CLOUDSTONE:
		draw_rect(rect, Color("d8e8f2", 0.95))
		draw_rect(Rect2(rect.position + Vector2(3, 4), Vector2(10, 6)), Color("eef6fb", 0.9))
		draw_rect(Rect2(rect.position + Vector2(5, 6), Vector2(6, 2)), Color("c3d8e6", 0.9))
		draw_rect(Rect2(rect.position + Vector2(2, 11), Vector2(12, 2)), Color("b9d0df", 0.7))
	elif tile == Tile.SKY_CRYSTAL:
		draw_rect(Rect2(rect.position + Vector2(6, 2), Vector2(4, 12)), Color("c9f2ff"))
		draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(8, 6)), Color("8fd8f5", 0.85))
		draw_rect(Rect2(rect.position + Vector2(7, 4), Vector2(2, 2)), Color("f2fcff"))
	elif tile == Tile.SAPLING:
		draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(2, 8)), Color("6b4428"))
		draw_rect(Rect2(rect.position + Vector2(3, 4), Vector2(6, 5)), Color("63a75e"))
		draw_rect(Rect2(rect.position + Vector2(8, 2), Vector2(5, 6)), Color("7bc96e"))
	elif tile == Tile.TORCH:
		draw_rect(Rect2(rect.position + Vector2(7, 6), Vector2(2, 9)), Color("754425"))
		draw_rect(Rect2(rect.position + Vector2(6, 4), Vector2(4, 4)), Color("ff9f43"))
		draw_rect(Rect2(rect.position + Vector2(7, 2), Vector2(2, 4)), Color("ffe27a"))
		draw_rect(Rect2(rect.position + Vector2(8, 3), Vector2(1, 2)), Color("fff4b0"))


func _draw_ore_specks(rect: Rect2, bright: Color, dark: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(3, 3)), bright)
	draw_rect(Rect2(rect.position + Vector2(10, 5), Vector2(2, 2)), bright.lightened(0.15))
	draw_rect(Rect2(rect.position + Vector2(6, 11), Vector2(4, 2)), bright.darkened(0.05))
	draw_rect(Rect2(rect.position + Vector2(2, 10), Vector2(2, 2)), dark)
	draw_rect(rect.grow(-1), bright, false, 1.0)


func _draw_combat_entities() -> void:
	var visible_rect := _visible_world_draw_rect(160.0)
	for projectile in projectiles:
		var pos: Vector2 = projectile["pos"]
		if not visible_rect.has_point(pos):
			continue
		var color: Color = projectile.get("color", Color.WHITE)
		var kind := str(projectile.get("kind", "bolt"))
		var radius := 2.0
		if kind == "cannon":
			radius = 3.0
		elif kind == "acid":
			radius = 3.5
		draw_circle(pos, radius, color)
		draw_circle(pos - (projectile["vel"] as Vector2).normalized() * 4.0, maxf(1.0, radius - 1.0), color.darkened(0.35))
	for corpse in dying_enemies:
		if visible_rect.has_point(corpse.get("pos", Vector2.ZERO)):
			_draw_dying_enemy(corpse)
	for projectile in enemy_projectiles:
		var projectile_pos: Vector2 = projectile["pos"]
		if not visible_rect.has_point(projectile_pos):
			continue
		var projectile_color: Color = projectile.get("color", Color.WHITE)
		if str(projectile.get("special", "")) == "wild_ichor" and _draw_wild_ichor_projectile(projectile):
			pass
		elif str(projectile.get("special", "")) == "cave_husk_rock" and _draw_cave_husk_rock_projectile(projectile):
			pass
		elif str(projectile.get("special", "")) == "mushroom_poison" and _draw_enemy_pack_projectile(projectile, "mushroom_beetle", "poison_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "ash_phantom_ember" and _draw_enemy_pack_projectile(projectile, "ash_phantom", "ember_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "ash_wisp_ember" and _draw_enemy_pack_projectile(projectile, "ash_wisp", "ember_projectile", 0.44):
			pass
		elif str(projectile.get("special", "")) == "sentinel_ash" and _draw_enemy_pack_projectile(projectile, "ash_sentinel", "sentinel_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "drowned_harpoon" and _draw_enemy_pack_projectile(projectile, "drowned_guard", "harpoon_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "drowned_wave" and _draw_enemy_pack_projectile(projectile, "drowned_guard", "wave_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "ember_seed" and _draw_enemy_pack_projectile(projectile, "ember_rootling", "ember_seed", 0.50):
			pass
		elif str(projectile.get("special", "")) == "glass_shard" and _draw_enemy_pack_projectile(projectile, "glass_wraith", "shard_projectile", 0.50):
			pass
		elif str(projectile.get("special", "")) == "night_fire" and _draw_enemy_pack_projectile(projectile, "night_ember", "fire_projectile", 0.44):
			pass
		elif str(projectile.get("special", "")) == "ruin_bolt" and _draw_enemy_pack_projectile(projectile, "ruin_drone", "drone_bolt", 0.50):
			pass
		elif str(projectile.get("special", "")) == "stone_falling_rock" and _draw_enemy_pack_projectile(projectile, "stone_beast", "falling_rock", 0.72):
			pass
		else:
			draw_circle(projectile_pos, 3.0, projectile_color)
			draw_circle(projectile_pos - (projectile["vel"] as Vector2).normalized() * 4.0, 1.5, projectile_color.darkened(0.35))
	for effect in enemy_impact_effects:
		if visible_rect.has_point(effect.get("pos", Vector2.ZERO)):
			_draw_enemy_impact(effect)
	for enemy in enemies:
		if visible_rect.has_point(enemy.get("pos", Vector2.ZERO)):
			_draw_enemy(enemy)


func _draw_perception_debug() -> void:
	if not perception_debug_enabled:
		return
	for noise in perception_noise_events:
		var event: Dictionary = noise
		var noise_pos: Vector2 = event.get("pos", Vector2.ZERO)
		var radius := float(event.get("radius", 0.0))
		var life_ratio := clampf(float(event.get("life", 0.0)) / maxf(0.01, float(event.get("max_life", NOISE_EVENT_LIFETIME))), 0.0, 1.0)
		draw_arc(noise_pos, radius, 0.0, TAU, 48, Color(0.35, 0.75, 1.0, 0.22 + life_ratio * 0.42), 1.5)
		if ui_font != null:
			draw_string(ui_font, noise_pos + Vector2(-radius, -5.0), str(event.get("kind", "noise")), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, Color(0.55, 0.85, 1.0, 0.9))
	for enemy in enemies:
		var data: Dictionary = enemy
		if bool(data.get("burrow_hidden", false)):
			continue
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var enemy_type := str(data.get("type", ""))
		var profile := _enemy_perception_profile(enemy_type)
		var state := str(data.get("perception_state", PERCEPTION_CALM))
		var color := Color("8aa0aa")
		if state == PERCEPTION_SUSPICIOUS:
			color = Color("f2d36b")
		elif state == PERCEPTION_INVESTIGATE:
			color = Color("e9a75f")
		elif state == PERCEPTION_COMBAT:
			color = Color("f05b61")
		elif state == PERCEPTION_SEARCH:
			color = Color("c18cff")
		elif state == PERCEPTION_RETURN:
			color = Color("77b8d4")
		var vision_range := float(data.get("debug_vision_range", profile.get("vision_range", 165.0)))
		var half_angle := deg_to_rad(float(profile.get("vision_angle", 120.0)) * 0.5)
		var center_angle := 0.0 if int(data.get("facing", 1)) >= 0 else PI
		draw_arc(pos, vision_range, center_angle - half_angle, center_angle + half_angle, 32, Color(color, 0.42), 1.0)
		draw_line(pos, pos + Vector2.RIGHT.rotated(center_angle - half_angle) * vision_range, Color(color, 0.28), 1.0)
		draw_line(pos, pos + Vector2.RIGHT.rotated(center_angle + half_angle) * vision_range, Color(color, 0.28), 1.0)
		var last_known: Vector2 = data.get("last_known_pos", pos)
		if state in [PERCEPTION_INVESTIGATE, PERCEPTION_COMBAT, PERCEPTION_SEARCH]:
			draw_line(pos, last_known, Color(color, 0.45), 1.0)
			draw_circle(last_known, 3.0, Color(color, 0.80))
		if ui_font != null:
			var suspicion_percent := int(round(float(data.get("suspicion", 0.0)) * 100.0))
			var light_percent := int(round(float(data.get("debug_player_light", 0.0)) * 100.0))
			var label := "%s  S:%d%% L:%d%%" % [state, suspicion_percent, light_percent]
			draw_string(ui_font, pos + Vector2(-62.0, -34.0), label, HORIZONTAL_ALIGNMENT_CENTER, 124.0, 9, color)


func _draw_dying_enemy(corpse: Dictionary) -> void:
	var pos: Vector2 = corpse["pos"]
	var size: Vector2 = corpse["size"]
	var total := maxf(0.01, float(corpse.get("death_total", 0.35)))
	var ratio := clampf(float(corpse.get("death_time", 0.0)) / total, 0.0, 1.0)
	var enemy_type := str(corpse.get("type", "wild_slime"))
	var visual_type := _enemy_visual_type(corpse)
	if enemy_textures.has(visual_type):
		var death_sets: Dictionary = enemy_animation_textures.get(visual_type, {})
		var death_state := "death"
		if enemy_type == "bat":
			death_state = "death_impact" if str(corpse.get("death_phase", "fall")) == "impact" else "death_fall"
		var texture: Texture2D = death_sets.get(death_state, death_sets.get("death", enemy_textures[visual_type])) as Texture2D
		var is_strip := death_sets.has(death_state) or death_sets.has("death")
		var death_spec := _enemy_animation_spec(visual_type, death_state)
		if death_spec.is_empty():
			death_spec = _enemy_animation_spec(visual_type, "death")
		var frame_count := int(death_spec.get("frames", 6)) if is_strip else 4
		var frame_width := maxi(1, int(texture.get_width() / frame_count))
		var frame_height := texture.get_height() if is_strip else maxi(1, int(texture.get_height() / 3))
		var frame_index := mini(frame_count - 1, int(floor((1.0 - ratio) * float(frame_count))))
		if enemy_type in ["bat", "spore_bat"]:
			var death_fps := maxf(1.0, float(death_spec.get("fps", 12.0)))
			frame_index = mini(frame_count - 1, int(floor(float(corpse.get("death_anim_time", 0.0)) * death_fps)))
		var scale := _enemy_sprite_scale(visual_type)
		var draw_size := Vector2(frame_width, frame_height) * scale
		var death_anchor := _enemy_animation_anchor(visual_type, Vector2(frame_width, frame_height))
		var local_x := -death_anchor.x * scale if is_strip else -draw_size.x * 0.5
		var ground_anchor := float(enemy_sprite_ground_anchors.get(visual_type, frame_height))
		var local_y := size.y * 0.5 - ground_anchor * scale - _enemy_animation_ground_clearance(visual_type)
		var fade := Color(1.0, 1.0, 1.0, clampf(ratio * 4.0, 0.0, 1.0))
		if enemy_type == "bat":
			if death_state == "death_fall":
				local_y = -draw_size.y * 0.5
				fade = Color.WHITE
			else:
				local_y = size.y * 0.5 - float(frame_height) * scale
				var impact_total := maxf(0.01, _enemy_animation_duration("bat", "death_impact", 0.50))
				fade = Color(1.0, 1.0, 1.0, clampf(float(corpse.get("death_time", 0.0)) / impact_total * 4.0, 0.0, 1.0))
		elif enemy_type == "spore_bat":
			if str(corpse.get("death_phase", "fall")) == "fall":
				local_y = -draw_size.y * 0.5
				fade = Color.WHITE
			else:
				local_y = size.y * 0.5 - float(frame_height) * scale
				var spore_impact_total := maxf(0.01, _enemy_animation_duration("spore_bat", "death_impact", 0.60))
				fade = Color(1.0, 1.0, 1.0, clampf(float(corpse.get("death_time", 0.0)) / spore_impact_total * 4.0, 0.0, 1.0))
		var facing := int(corpse.get("facing", 1))
		draw_set_transform(pos, 0.0, Vector2(float(facing), 1.0))
		draw_texture_rect_region(texture, Rect2(Vector2(local_x, local_y), draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height), fade)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemy_attack_telegraph(enemy: Dictionary, pos: Vector2, size: Vector2) -> void:
	var windup := float(enemy.get("attack_windup", 0.0))
	if windup <= 0.0:
		return
	var total := maxf(windup, float(enemy.get("attack_total", windup)))
	var progress := clampf(1.0 - windup / total, 0.0, 1.0)
	var urgent := progress >= 0.68
	var color := Color("ff655d") if urgent else Color("f2a33a")
	var visual_size := _enemy_visual_size(_enemy_visual_type(enemy))
	var radius := maxf(maxf(size.x, size.y), maxf(visual_size.x, visual_size.y) * 0.42) + 7.0
	var pulse := 1.0 + sin(progress * PI * 5.0) * 0.8
	var alpha := 0.48 + progress * 0.42
	# Track + countdown arc make the exact strike moment readable on a phone.
	draw_arc(pos, radius + pulse, 0.0, TAU, 28, Color(0.08, 0.035, 0.025, 0.62), 2.0)
	draw_arc(pos, radius + pulse, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, Color(color, alpha), 2.0)
	var facing_dir := Vector2(float(int(enemy.get("facing", 1))), 0.0)
	draw_line(pos + facing_dir * (radius - 2.0), pos + facing_dir * (radius + 7.0), Color(color, alpha), 2.0)
	var marker_pos := pos + Vector2(0.0, -radius - 7.0)
	draw_colored_polygon(PackedVector2Array([
		marker_pos + Vector2(0, -4), marker_pos + Vector2(4, 0),
		marker_pos + Vector2(0, 4), marker_pos + Vector2(-4, 0)
	]), Color(color, alpha))


func _draw_enemy(enemy: Dictionary) -> void:
	if bool(enemy.get("burrow_hidden", false)):
		return
	var pos: Vector2 = enemy["pos"]
	var size: Vector2 = enemy["size"]
	var color: Color = enemy.get("color", Color("ffffff"))
	if float(enemy.get("hit_timer", 0.0)) > 0.0:
		color = ENEMY_HIT_FLASH_COLOR
	var rect := Rect2(pos - size * 0.5, size)
	var hitbox_rect := _enemy_hitbox_rect(enemy)
	var enemy_type := str(enemy.get("type", "wild_slime"))
	var visual_type := _enemy_visual_type(enemy)
	_draw_enemy_attack_telegraph(enemy, pos, size)
	var has_sprite := _draw_enemy_sprite(enemy, visual_type, pos, size)
	if has_sprite and enemy_type == "cave_husk" and str(enemy.get("anim_state", "")) == "attack_1":
		_draw_enemy_overlay_animation(enemy, enemy_type, "reach_vfx", pos)
	if has_sprite:
		pass
	elif enemy_type == "stone_beast":
		draw_rect(Rect2(rect.position + Vector2(3, 10), Vector2(size.x - 6, size.y - 12)), color)
		draw_rect(Rect2(rect.position + Vector2(9, 2), Vector2(size.x - 18, 13)), color.lightened(0.12))
		draw_rect(Rect2(rect.position + Vector2(13, 12), Vector2(5, 5)), Color("b7f3dc"))
		draw_rect(Rect2(rect.position + Vector2(size.x - 18, 12), Vector2(5, 5)), Color("b7f3dc"))
		draw_rect(Rect2(rect.position + Vector2(8, size.y - 6), Vector2(size.x - 16, 4)), Color("4d4640"))
	elif enemy_type == "heartwood_boss":
		draw_rect(Rect2(rect.position + Vector2(8, 0), Vector2(size.x - 16, size.y)), color.darkened(0.18))
		draw_rect(Rect2(rect.position + Vector2(4, 8), Vector2(size.x - 8, size.y - 12)), color)
		draw_rect(Rect2(rect.position + Vector2(13, 13), Vector2(5, 5)), Color("f5cf7b"))
		draw_rect(Rect2(rect.position + Vector2(size.x - 18, 13), Vector2(5, 5)), Color("f5cf7b"))
		draw_rect(Rect2(rect.position + Vector2(10, size.y - 8), Vector2(size.x - 20, 5)), Color("5c3825"))
	elif enemy_type == "bat":
		draw_line(pos + Vector2(-10, 0), pos + Vector2(-2, -4), color.lightened(0.1), 3.0)
		draw_line(pos + Vector2(2, -4), pos + Vector2(10, 0), color.lightened(0.1), 3.0)
		draw_rect(Rect2(pos + Vector2(-4, -3), Vector2(8, 7)), color)
	elif enemy_type == "ruin_drone":
		draw_rect(Rect2(pos - Vector2(7, 7), Vector2(14, 14)), color)
		draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), Color("cfe9ff"))
		draw_line(pos + Vector2(-10, 0), pos + Vector2(-7, 0), color.lightened(0.25), 2.0)
		draw_line(pos + Vector2(7, 0), pos + Vector2(10, 0), color.lightened(0.25), 2.0)
	elif bool(enemy.get("flying", false)):
		draw_circle(pos, size.x * 0.45, color)
		draw_circle(pos + Vector2(-4, -2), 2.0, Color("fff6d4"))
		draw_circle(pos + Vector2(4, -2), 2.0, Color("fff6d4"))
		draw_rect(Rect2(pos + Vector2(-8, 4), Vector2(16, 2)), color.darkened(0.35))
	elif enemy_type == "cave_worm":
		draw_rect(Rect2(rect.position + Vector2(1, 3), Vector2(size.x - 2, size.y - 4)), color)
		for x in range(5, int(size.x) - 3, 6):
			draw_rect(Rect2(rect.position + Vector2(x, 4), Vector2(2, size.y - 6)), color.darkened(0.28))
	elif enemy_type == "mushroom_beetle":
		draw_rect(Rect2(rect.position + Vector2(2, 5), Vector2(size.x - 4, size.y - 5)), color)
		draw_rect(Rect2(rect.position + Vector2(5, 1), Vector2(size.x - 10, 7)), Color("d06a7e"))
		draw_rect(Rect2(rect.position + Vector2(8, 3), Vector2(2, 2)), Color("fff3c0"))
	elif enemy_type == "root_crawler":
		draw_rect(Rect2(rect.position + Vector2(2, 4), Vector2(size.x - 4, size.y - 4)), color)
		draw_line(rect.position + Vector2(2, 4), rect.position + Vector2(size.x - 2, 2), color.lightened(0.2), 2.0)
	elif enemy_type == "cave_husk":
		draw_rect(rect.grow(-2), color)
		draw_rect(Rect2(rect.position + Vector2(3, 2), Vector2(size.x - 6, 5)), color.lightened(0.18))
		draw_rect(Rect2(rect.position + Vector2(5, 8), Vector2(2, 2)), Color("ffdc8a"))
		draw_rect(Rect2(rect.position + Vector2(size.x - 7, 8), Vector2(2, 2)), Color("ffdc8a"))
	else:
		draw_rect(Rect2(rect.position + Vector2(2, 4), Vector2(size.x - 4, size.y - 4)), color)
		draw_rect(Rect2(rect.position + Vector2(4, 1), Vector2(size.x - 8, 5)), color.lightened(0.18))
		draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(2, 2)), Color("13331f"))
		draw_rect(Rect2(rect.position + Vector2(size.x - 7, 5), Vector2(2, 2)), Color("13331f"))
	var hp := maxf(0.0, float(enemy.get("hp", 1)) / float(enemy.get("max_hp", 1)))
	var statuses: Dictionary = enemy.get("statuses", {})
	var show_health := hp < 0.999 or float(enemy.get("hit_timer", 0.0)) > 0.0 or float(enemy.get("attack_windup", 0.0)) > 0.0 or str(enemy.get("perception_state", PERCEPTION_CALM)) == PERCEPTION_COMBAT or not statuses.is_empty()
	if show_health:
		var visual_height := _enemy_visual_size(visual_type).y
		var bar_y := pos.y - maxf(size.y * 0.5 + 6.0, visual_height * 0.5 + 5.0)
		var bar_pos := Vector2(hitbox_rect.position.x, bar_y)
		draw_rect(Rect2(bar_pos, Vector2(hitbox_rect.size.x, 3)), Color("1a1012", 0.9))
		draw_rect(Rect2(bar_pos, Vector2(hitbox_rect.size.x * hp, 3)), Color("d94b52"))
		var status_x := bar_pos.x
		for status in statuses.keys():
			var status_color := Color("89e36b") if str(status) == "poison" else (Color("ff8a3c") if str(status) == "burn" else Color("9fc5ff"))
			draw_rect(Rect2(Vector2(status_x, bar_pos.y - 4), Vector2(4, 3)), status_color)
			status_x += 5.0


func _draw_enemy_sprite(enemy: Dictionary, enemy_type: String, pos: Vector2, collision_size: Vector2) -> bool:
	if not enemy_textures.has(enemy_type):
		return false
	var requested_animation_state := str(enemy.get("anim_state", "idle"))
	var animation_state := _enemy_animation_visual_state(enemy_type, requested_animation_state)
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var texture: Texture2D = animation_sets.get(animation_state, null)
	var use_action_strip := texture != null
	var animation_spec := _enemy_animation_spec(enemy_type, animation_state)
	if texture == null:
		# Any state missing from the pack falls back to the pack's OWN idle
		# strip. Never fall back to the legacy static atlas: it has a
		# different art style and frame grid, which made creatures visibly
		# swap into "another mob" mid-attack.
		texture = animation_sets.get("idle", enemy_textures.get(enemy_type)) as Texture2D
		if texture == null:
			return false
		animation_spec = _enemy_animation_spec(enemy_type, "idle")
		use_action_strip = animation_sets.has("idle")
	var frame_count := int(animation_spec.get("frames", 6)) if use_action_strip else 4
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height() if use_action_strip else maxi(1, int(texture.get_height() / 3))
	var source_y := 0
	if not use_action_strip:
		if animation_state == "move":
			source_y = frame_height
		elif animation_state.begins_with("attack_"):
			source_y = frame_height * 2
	var frame_index := 0
	var anim_time := float(enemy.get("anim_time", 0.0))
	if use_action_strip and not animation_spec.is_empty():
		var fps := maxf(1.0, float(animation_spec.get("fps", 8.0)))
		var raw_frame := int(floor(anim_time * fps))
		frame_index = raw_frame % frame_count if bool(animation_spec.get("loop", false)) else mini(frame_count - 1, raw_frame)
	elif animation_state.begins_with("attack_"):
		frame_index = mini(frame_count - 1, int(floor(anim_time * 10.0)))
		if float(enemy.get("attack_flash", 0.0)) > 0.0:
			frame_index = frame_count - 1
	elif animation_state == "hurt":
		frame_index = mini(frame_count - 1, int(floor(anim_time * 14.0)))
	elif animation_state == "move":
		frame_index = int(floor(anim_time * 8.0)) % frame_count
	else:
		frame_index = int(floor(anim_time * 3.5)) % frame_count
	var source_rect := Rect2(frame_index * frame_width, source_y, frame_width, frame_height)
	var flying := bool(enemy.get("flying", false))
	var scale := _enemy_sprite_scale(enemy_type)
	var draw_size := Vector2(frame_width, frame_height) * scale
	var animation_anchor := _enemy_animation_anchor(enemy_type, Vector2(frame_width, frame_height))
	var local_x := -animation_anchor.x * scale if use_action_strip else -draw_size.x * 0.5
	var ground_anchor := float(enemy_sprite_ground_anchors.get(enemy_type, frame_height))
	var local_y := -draw_size.y * 0.5 if flying else collision_size.y * 0.5 - ground_anchor * scale - _enemy_animation_ground_clearance(enemy_type)
	var facing := int(enemy.get("facing", 1))
	var flip_scale := Vector2(-1.0, 1.0) if facing < 0 else Vector2.ONE
	var modulate := Color.WHITE
	if float(enemy.get("hit_timer", 0.0)) > 0.0:
		modulate = ENEMY_HIT_FLASH_COLOR
	draw_set_transform(pos, 0.0, flip_scale)
	draw_texture_rect_region(texture, Rect2(Vector2(local_x, local_y), draw_size), source_rect, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_wild_ichor_projectile(projectile: Dictionary) -> bool:
	var animation_sets: Dictionary = enemy_animation_textures.get("wild_slime", {})
	var texture: Texture2D = animation_sets.get("ichor_projectile", null)
	var spec := _enemy_animation_spec("wild_slime", "ichor_projectile")
	if texture == null or spec.is_empty():
		return false
	var frame_count := maxi(1, int(spec.get("frames", 1)))
	var fps := maxf(1.0, float(spec.get("fps", 14.0)))
	var frame_index := int(floor(float(projectile.get("anim_time", 0.0)) * fps)) % frame_count
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height()
	var draw_size := Vector2(frame_width, frame_height) * 0.32
	var velocity: Vector2 = projectile.get("vel", Vector2.LEFT)
	var rotation := velocity.angle() - PI
	draw_set_transform(projectile["pos"], rotation, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(-draw_size * 0.5, draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_cave_husk_rock_projectile(projectile: Dictionary) -> bool:
	var animation_sets: Dictionary = enemy_animation_textures.get("cave_husk", {})
	var texture: Texture2D = animation_sets.get("rock_projectile", null)
	var spec := _enemy_animation_spec("cave_husk", "rock_projectile")
	if texture == null or spec.is_empty():
		return false
	var frame_count := maxi(1, int(spec.get("frames", 1)))
	var fps := maxf(1.0, float(spec.get("fps", 12.0)))
	var frame_index := int(floor(float(projectile.get("anim_time", 0.0)) * fps)) % frame_count
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height()
	var draw_size := Vector2(frame_width, frame_height) * 0.50
	var velocity: Vector2 = projectile.get("vel", Vector2.RIGHT)
	var facing_scale := Vector2(1.0 if velocity.x >= 0.0 else -1.0, 1.0)
	draw_set_transform(projectile["pos"], 0.0, facing_scale)
	draw_texture_rect_region(texture, Rect2(-draw_size * 0.5, draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_enemy_pack_projectile(projectile: Dictionary, enemy_type: String, state: String, scale: float) -> bool:
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var texture: Texture2D = animation_sets.get(state, null)
	var spec := _enemy_animation_spec(enemy_type, state)
	if texture == null or spec.is_empty():
		return false
	var frame_count := maxi(1, int(spec.get("frames", 1)))
	var fps := maxf(1.0, float(spec.get("fps", 14.0)))
	var frame_index := int(floor(float(projectile.get("anim_time", 0.0)) * fps)) % frame_count
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height()
	var draw_size := Vector2(frame_width, frame_height) * scale
	var velocity: Vector2 = projectile.get("vel", Vector2.RIGHT)
	var facing_scale := Vector2(1.0 if velocity.x >= 0.0 else -1.0, 1.0)
	var anchor := _enemy_animation_state_anchor(enemy_type, state, Vector2(frame_width, frame_height))
	draw_set_transform(projectile["pos"], 0.0, facing_scale)
	draw_texture_rect_region(texture, Rect2(-anchor * scale, draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_enemy_overlay_animation(enemy: Dictionary, enemy_type: String, state: String, pos: Vector2) -> void:
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var texture: Texture2D = animation_sets.get(state, null)
	var spec := _enemy_animation_spec(enemy_type, state)
	if texture == null or spec.is_empty():
		return
	var frame_count := maxi(1, int(spec.get("frames", 1)))
	var fps := maxf(1.0, float(spec.get("fps", 8.0)))
	var frame_index := mini(frame_count - 1, int(floor(float(enemy.get("anim_time", 0.0)) * fps)))
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height()
	var scale := _enemy_sprite_scale(enemy_type)
	var frame_size := Vector2(frame_width, frame_height)
	var draw_size := frame_size * scale
	var anchor := _enemy_animation_anchor(enemy_type, frame_size)
	var facing_scale := Vector2(float(int(enemy.get("facing", 1))), 1.0)
	draw_set_transform(pos, 0.0, facing_scale)
	draw_texture_rect_region(texture, Rect2(-anchor * scale, draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemy_impact(effect: Dictionary) -> void:
	var enemy_type := str(effect.get("enemy_type", "wild_slime"))
	var state := str(effect.get("state", ""))
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var texture: Texture2D = animation_sets.get(state, null)
	var spec := _enemy_animation_spec(enemy_type, state)
	if texture == null or spec.is_empty():
		return
	var frame_count := maxi(1, int(spec.get("frames", 1)))
	var fps := maxf(1.0, float(spec.get("fps", 14.0)))
	var frame_index := mini(frame_count - 1, int(floor(float(effect.get("time", 0.0)) * fps)))
	var frame_width := maxi(1, int(texture.get_width() / frame_count))
	var frame_height := texture.get_height()
	var effect_scale := float(effect.get("scale", 0.34))
	var frame_size := Vector2(frame_width, frame_height)
	var draw_size := frame_size * effect_scale
	var anchor := _enemy_animation_state_anchor(enemy_type, state, frame_size) if bool(effect.get("use_pack_anchor", false)) else frame_size * 0.5
	var facing_scale := Vector2(float(int(effect.get("facing", 1))), 1.0)
	draw_set_transform(effect["pos"], 0.0, facing_scale)
	draw_texture_rect_region(texture, Rect2(-anchor * effect_scale, draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _enemy_sprite_scale(enemy_type: String) -> float:
	if enemy_type == "stone_beast" or enemy_type == "heartwood_boss":
		return 0.72
	if enemy_type in ["bat", "spore_bat", "ash_wisp", "night_ember", "frost_bat"]:
		return 0.44
	if enemy_type == "root_crawler":
		return 0.48
	if enemy_type == "cave_worm":
		return 0.56
	return 0.50


func _enemy_visual_size(enemy_type: String) -> Vector2:
	if not enemy_textures.has(enemy_type):
		return Vector2(24, 24)
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var idle_texture: Texture2D = animation_sets.get("idle", null)
	var idle_spec := _enemy_animation_spec(enemy_type, "idle")
	if idle_texture != null and not idle_spec.is_empty():
		var frame_count := maxi(1, int(idle_spec.get("frames", 1)))
		return Vector2(float(idle_texture.get_width()) / float(frame_count), float(idle_texture.get_height())) * _enemy_sprite_scale(enemy_type)
	var texture: Texture2D = enemy_textures[enemy_type]
	return Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()) / 3.0) * _enemy_sprite_scale(enemy_type)

func _draw_combat_impact(impact: Dictionary) -> void:
	var pos: Vector2 = impact.get("pos", Vector2.ZERO)
	var dir: Vector2 = impact.get("dir", Vector2.RIGHT)
	var max_life := maxf(0.01, float(impact.get("max_life", 0.13)))
	var ratio := clampf(float(impact.get("life", 0.0)) / max_life, 0.0, 1.0)
	var progress := 1.0 - ratio
	var heavy := bool(impact.get("heavy", false))
	var guarded := bool(impact.get("guarded", false))
	var color: Color = impact.get("color", Color.WHITE)
	color.a = ratio
	var perp := Vector2(-dir.y, dir.x)
	var length := (17.0 if heavy else 11.0) * (0.65 + progress * 0.55)
	var width := 3.0 if heavy else 2.0
	# Contact cross and expanding ring are deliberately brief and pixel-sharp.
	draw_line(pos - dir * length * 0.35, pos + dir * length, color, width)
	draw_line(pos - perp * length * 0.65, pos + perp * length * 0.65, color.lightened(0.18), width)
	var ring_radius := lerpf(3.0, 16.0 if heavy else 11.0, progress)
	draw_arc(pos, ring_radius, 0.0, TAU, 18, Color(color, ratio * 0.72), 2.0 if heavy else 1.0)
	if guarded:
		draw_line(pos + Vector2(-7, -9), pos + Vector2(7, 9), color, 2.0)
		draw_line(pos + Vector2(7, -9), pos + Vector2(-7, 9), color, 2.0)


func _visible_world_draw_rect(margin := 96.0) -> Rect2:
	var view_size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view_size * 0.5, view_size).grow(margin)


func _draw_world_loot_and_fx() -> void:
	var visible_rect := _visible_world_draw_rect()
	for item in dropped_items:
		if visible_rect.has_point(item.get("pos", Vector2.ZERO)):
			_draw_dropped_item(item)
	for impact in combat_impacts:
		if visible_rect.has_point(impact.get("pos", Vector2.ZERO)):
			_draw_combat_impact(impact)
	for particle in hit_particles:
		var particle_pos: Vector2 = particle.get("pos", Vector2.ZERO)
		if not visible_rect.has_point(particle_pos):
			continue
		var particle_max_life := maxf(0.01, float(particle.get("max_life", 0.48)))
		var particle_life := clampf(float(particle.get("life", 0.0)) / particle_max_life, 0.0, 1.0)
		var color: Color = particle.get("color", Color.WHITE)
		color.a = particle_life
		var pos: Vector2 = particle["pos"]
		var size := float(particle.get("size", 2.0))
		var velocity: Vector2 = particle.get("vel", Vector2.ZERO)
		if velocity.length_squared() > 900.0:
			draw_line(pos, pos - velocity.normalized() * (size + 2.0), color, maxf(1.0, size - 1.0))
		draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color)
	for number in damage_numbers:
		if ui_font == null:
			continue
		var number_pos: Vector2 = number.get("pos", Vector2.ZERO)
		if not visible_rect.has_point(number_pos):
			continue
		var number_max_life := maxf(0.01, float(number.get("max_life", 0.75)))
		var number_life := clampf(float(number.get("life", 0.0)) / number_max_life, 0.0, 1.0)
		var color: Color = number.get("color", Color.WHITE)
		color.a = number_life
		var pos: Vector2 = number["pos"]
		var font_size := int(number.get("font_size", 12))
		var text := str(number.get("text", ""))
		draw_string(ui_font, pos + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_CENTER, 44.0, font_size, Color(0.02, 0.025, 0.035, number_life * 0.90))
		draw_string(ui_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 44.0, font_size, color)


func _draw_dropped_item(item: Dictionary) -> void:
	var pos: Vector2 = item["pos"]
	var age := float(item.get("age", 0.0))
	var bob := sin(age * 7.0 + float(item.get("bob", 0.0))) * 2.0
	var draw_pos := pos + Vector2(0, bob)
	var to_player := player_position - pos
	var magnet := clampf(1.0 - to_player.length() / LOOT_MAGNET_RADIUS, 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(-7, 6), Vector2(14, 3)), Color("0b0e13", 0.22))
	if magnet > 0.0 and float(item.get("pickup_delay", 0.0)) <= 0.0:
		draw_line(pos, pos + to_player.normalized() * 10.0, Color("f5d978", 0.25 + magnet * 0.35), 1.0)
	var item_id := str(item.get("id", ""))
	var icon := _item_icon(item_id)
	var icon_size := 18.0 + sin(age * 10.0) * 0.8
	var icon_rect := Rect2(draw_pos - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	if icon != null:
		draw_texture_rect(icon, icon_rect, false, Color(1, 1, 1, 1))
	else:
		draw_rect(icon_rect.grow(-4), _item_icon_color(item_id))
	var amount := int(item.get("amount", 1))
	if amount > 1 and ui_font != null:
		draw_string(ui_font, draw_pos + Vector2(6, 9), str(amount), HORIZONTAL_ALIGNMENT_LEFT, 28.0, 9, Color("fff1b8"))


func _light_at_tile(x: int, y: int, ignore_player := false) -> float:
	var light := 0.02
	if x >= 0 and x < surface_heights.size() and y <= surface_heights[x] + 2:
		light = maxf(light, _daylight_factor())
	var sample_pos := Vector2(x + 0.5, y + 0.5)
	for source in visible_light_sources:
		if ignore_player and str(source.get("kind", "")) == "player":
			continue
		var source_pos: Vector2 = source["pos"]
		var radius := float(source["radius"])
		var distance := sample_pos.distance_to(source_pos)
		if distance >= radius:
			continue
		var falloff := 1.0 - distance / radius
		var source_light := float(source.get("intensity", 1.0)) * falloff * falloff
		light = maxf(light, source_light)
	return clampf(light, 0.02, 1.0)


func _draw_darkness_overlay() -> void:
	# A single smooth overlay avoids visible seams between tile-sized dark rectangles.
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var half_size := view_rect.size * 0.5 / camera.zoom
	var player_tile_x := clampi(floori(player_position.x / TILE_SIZE), 0, WORLD_WIDTH - 1)
	var player_tile_y := clampi(floori(player_position.y / TILE_SIZE), 0, WORLD_HEIGHT - 1)
	var underground := player_tile_y > surface_heights[player_tile_x] + 2
	var darkness := (1.0 - _daylight_factor()) * 0.48
	if underground:
		darkness = maxf(darkness, 0.56)
	var world_rect := Rect2(center - half_size - Vector2(2, 2), view_rect.size / camera.zoom + Vector2(4, 4))
	if darkness > 0.01:
		draw_rect(world_rect, Color(0.008, 0.012, 0.02, darkness))
	# Soft light pools retain depth in caves without drawing a grid.
	if underground or darkness > 0.22:
		draw_circle(player_position, 112.0, Color("476756", 0.05))
		draw_circle(player_position, 70.0, Color("6e9679", 0.08))
		draw_circle(player_position, 32.0, Color("a7cf9d", 0.10))
	for source in visible_light_sources:
		var source_pos: Vector2 = (source["pos"] as Vector2) * TILE_SIZE
		var radius := float(source.get("radius", 0.0)) * TILE_SIZE
		var kind := str(source.get("kind", ""))
		if radius <= 0.0 or kind == "player":
			continue
		if kind == "torch":
			draw_circle(source_pos, radius * 0.62, Color("ffbd68", 0.05))
		elif kind == "lava":
			draw_circle(source_pos, radius * 0.45, Color("e84c2a", 0.018))
		elif kind == "mushroom":
			draw_circle(source_pos, radius * 0.55, Color("79c99a", 0.035))
		elif kind == "crystal":
			draw_circle(source_pos, radius * 0.52, Color("86d9f4", 0.032))


func _draw_player_damage_flash() -> void:
	if player_hurt_flash <= 0.0 or camera == null:
		return
	var ratio := clampf(player_hurt_flash / 0.20, 0.0, 1.0)
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var world_size := view_rect.size / camera.zoom
	var top_left := center - world_size * 0.5
	var edge := 8.0 / camera.zoom.x
	var alpha := ratio * 0.16
	# A restrained pixel vignette: four flat edge bands, never a bright full-screen flash.
	draw_rect(Rect2(top_left, Vector2(world_size.x, edge)), Color(0.75, 0.06, 0.08, alpha))
	draw_rect(Rect2(top_left + Vector2(0, world_size.y - edge), Vector2(world_size.x, edge)), Color(0.75, 0.06, 0.08, alpha))
	draw_rect(Rect2(top_left, Vector2(edge, world_size.y)), Color(0.75, 0.06, 0.08, alpha))
	draw_rect(Rect2(top_left + Vector2(world_size.x - edge, 0), Vector2(edge, world_size.y)), Color(0.75, 0.06, 0.08, alpha))


func _draw_network_players() -> void:
	if network_session == null or not network_session.is_active() or not network_session.joined:
		return
	var own_id: int = int(network_session.local_peer_id())
	for peer_variant in network_session.players.keys():
		var peer_id := int(peer_variant)
		if peer_id == own_id:
			continue
		var state: Dictionary = network_session.players[peer_id]
		_draw_network_player(peer_id, state)


func _draw_network_player(peer_id: int, state: Dictionary) -> void:
	var pos: Vector2 = state.get("render_pos", state.get("pos", Vector2.ZERO))
	var vel: Vector2 = state.get("vel", Vector2.ZERO)
	var remote_facing := 1 if int(state.get("facing", 1)) >= 0 else -1
	var on_floor := bool(state.get("on_floor", false))
	var attack_kind := str(state.get("attack_kind", ""))
	var attack_ratio := clampf(float(state.get("attack_ratio", 0.0)), 0.0, 1.0)
	var tint: Color = state.get("tint", Color.WHITE)
	if player_texture != null:
		var row := 0
		var frame_count := 8
		var frame_index := 0
		var fps := 5.0
		if attack_kind != "":
			var attack_rows := {"slash": 4, "spear": 5, "bow": 6, "cannon": 7, "staff": 8, "flask": 10, "turret": 11}
			row = int(attack_rows.get(attack_kind, 4))
			frame_index = mini(frame_count - 1, int(floor(attack_ratio * float(frame_count))))
		elif not on_floor:
			row = 2
			frame_index = 0 if vel.y < -140.0 else (2 if vel.y < -45.0 else (4 if vel.y < 45.0 else 6))
		elif absf(vel.x) > 5.0:
			row = 1
			fps = 10.0
			frame_index = int(floor(float(Time.get_ticks_msec()) / 1000.0 * fps)) % frame_count
		else:
			frame_index = int(floor(float(Time.get_ticks_msec()) / 1000.0 * fps + float(peer_id) * 0.37)) % frame_count
		var source_rect := Rect2(frame_index * player_frame_size.x, row * player_frame_size.y, player_frame_size.x, player_frame_size.y)
		var draw_size := Vector2(player_frame_size) * 0.68
		var destination := Rect2(Vector2(-draw_size.x * 0.5, PLAYER_SIZE.y * 0.5 - draw_size.y), draw_size)
		draw_set_transform(pos, 0.0, Vector2(-1.0, 1.0) if remote_facing < 0 else Vector2.ONE)
		draw_texture_rect_region(player_texture, destination, source_rect, Color.WHITE.lerp(tint, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_rect(Rect2(pos - PLAYER_SIZE * 0.5, PLAYER_SIZE), tint)

	var remote_health := maxf(0.0, float(state.get("health", MAX_HEALTH)))
	var remote_max_health := maxf(1.0, float(state.get("max_health", MAX_HEALTH)))
	var health_ratio := clampf(remote_health / remote_max_health, 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(-16, -31), Vector2(32, 3)), Color("151820", 0.90))
	draw_rect(Rect2(pos + Vector2(-16, -31), Vector2(32.0 * health_ratio, 3)), Color("64cf83"))
	if ui_font != null:
		draw_string(ui_font, pos + Vector2(-44, -36), str(state.get("name", "Player")), HORIZONTAL_ALIGNMENT_CENTER, 88.0, 8, tint)


func _draw_player() -> void:
	if network_session != null and network_session.is_dedicated():
		return
	if _draw_player_sprite():
		return
	var rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	var skin := Color("d9b47f")
	var skin_shadow := Color("9e744e")
	var hair := Color("2d2530")
	var tunic := Color("7d4b5c")
	var tunic_dark := Color("4a2f44")
	var boot := Color("2b2530")
	var boot_dark := Color("17141b")
	var metal := Color("c6b889")
	var moving := absf(player_velocity.x) > 5.0 and player_on_floor
	var jumping := not player_on_floor and player_velocity.y < -20.0
	var falling := not player_on_floor and player_velocity.y >= -20.0
	var time := float(Time.get_ticks_msec()) / 1000.0
	var walk_wave := sin(time * 13.0)
	var walk_switch := 1 if walk_wave >= 0.0 else -1
	var idle_bob := 1.0 if player_on_floor and not moving and sin(time * 3.0) > 0.65 else 0.0
	var base := rect.position + Vector2(0, idle_bob)

	var head_pos := base + Vector2(3, 1)
	if jumping:
		head_pos.y -= 1.0
	draw_rect(Rect2(head_pos + Vector2(1, 0), Vector2(6, 2)), hair)
	draw_rect(Rect2(head_pos, Vector2(8, 7)), skin)
	draw_rect(Rect2(head_pos + Vector2(0, 0), Vector2(8, 2)), hair)
	draw_rect(Rect2(head_pos + Vector2(0, 2), Vector2(2, 3)), hair)
	draw_rect(Rect2(head_pos + Vector2(6, 3), Vector2(1, 2)), skin_shadow)
	var eye_x := head_pos.x + (5 if facing > 0 else 2)
	draw_rect(Rect2(eye_x, head_pos.y + 3, 1, 1), Color("f7edd0"))

	var body_pos := base + Vector2(2, 9)
	if moving:
		body_pos.y += 1.0 if walk_switch > 0 else 0.0
	elif jumping:
		body_pos.y -= 1.0
	draw_rect(Rect2(body_pos, Vector2(8, 10)), tunic_dark)
	draw_rect(Rect2(body_pos + Vector2(1, 0), Vector2(6, 9)), tunic)
	draw_rect(Rect2(body_pos + Vector2(3, 1), Vector2(2, 7)), Color("b57263"))
	draw_rect(Rect2(body_pos + Vector2(1, 8), Vector2(6, 2)), Color("3c2738"))

	var arm_y := body_pos.y + 2
	var front_arm_swing := 0
	var back_arm_swing := 0
	if moving:
		front_arm_swing = -walk_switch
		back_arm_swing = walk_switch
	elif jumping:
		front_arm_swing = -2
		back_arm_swing = -1
	elif falling:
		front_arm_swing = -1
		back_arm_swing = 1
	if facing > 0:
		draw_rect(Rect2(body_pos.x - 1, arm_y + back_arm_swing, 2, 7), skin_shadow)
		draw_rect(Rect2(body_pos.x + 8, arm_y + front_arm_swing, 2, 7), skin)
		draw_rect(Rect2(body_pos.x + 9, arm_y + 5 + front_arm_swing, 4, 2), metal)
	else:
		draw_rect(Rect2(body_pos.x + 8, arm_y + back_arm_swing, 2, 7), skin_shadow)
		draw_rect(Rect2(body_pos.x - 1, arm_y + front_arm_swing, 2, 7), skin)
		draw_rect(Rect2(body_pos.x - 5, arm_y + 5 + front_arm_swing, 4, 2), metal)

	var leg_y := base.y + 20
	var left_leg := Vector2(base.x + 3, leg_y)
	var right_leg := Vector2(base.x + 7, leg_y)
	var left_len := 6
	var right_len := 6
	var left_foot_x := -1
	var right_foot_x := 0
	if moving:
		left_len = 7 if walk_switch > 0 else 5
		right_len = 5 if walk_switch > 0 else 7
		left_foot_x = -2 if walk_switch > 0 else 0
		right_foot_x = 1 if walk_switch > 0 else -1
	elif jumping:
		left_len = 4
		right_len = 5
		left_foot_x = -1
		right_foot_x = 1
	elif falling:
		left_len = 7
		right_len = 7
		left_foot_x = 0
		right_foot_x = 0
	draw_rect(Rect2(left_leg, Vector2(3, left_len)), boot)
	draw_rect(Rect2(right_leg, Vector2(3, right_len)), boot)
	draw_rect(Rect2(left_leg + Vector2(left_foot_x, left_len), Vector2(4, 2)), boot_dark)
	draw_rect(Rect2(right_leg + Vector2(right_foot_x, right_len), Vector2(4, 2)), boot_dark)


func _draw_player_sprite() -> bool:
	if player_texture == null:
		return false
	var row := 0
	var frame_count := 8
	var frame_index := 0
	var fps := 5.0
	if attack_anim_kind != "" and attack_anim_duration > 0.0:
		var attack_rows := {
			"slash": 4,
			"spear": 5,
			"bow": 6,
			"cannon": 7,
			"staff": 8,
			"flask": 10,
			"turret": 11
		}
		row = int(attack_rows.get(attack_anim_kind, 4))
		var progress := 1.0 - clampf(attack_anim_time / attack_anim_duration, 0.0, 1.0)
		frame_index = mini(frame_count - 1, int(floor(progress * float(frame_count))))
	elif not player_on_floor:
		row = 2
		if player_velocity.y < -140.0:
			frame_index = 0
		elif player_velocity.y < -45.0:
			frame_index = 2
		elif player_velocity.y < 45.0:
			frame_index = 4
		else:
			frame_index = 6
	elif absf(player_velocity.x) > 5.0:
		row = 1
		fps = 10.0
		frame_index = int(floor(float(Time.get_ticks_msec()) / 1000.0 * fps)) % frame_count
	else:
		row = 0
		frame_index = int(floor(float(Time.get_ticks_msec()) / 1000.0 * fps)) % frame_count
	var source_rect := Rect2(
		frame_index * player_frame_size.x,
		row * player_frame_size.y,
		player_frame_size.x,
		player_frame_size.y
	)
	var draw_size := Vector2(player_frame_size) * 0.68
	var destination := Rect2(
		Vector2(-draw_size.x * 0.5, PLAYER_SIZE.y * 0.5 - draw_size.y),
		draw_size
	)
	var flip_scale := Vector2(-1.0, 1.0) if facing < 0 else Vector2.ONE
	var modulate := Color.WHITE
	if player_hurt_timer > 0.0 and int(Time.get_ticks_msec() / 60) % 2 == 0:
		modulate = Color("ffd0c4")
	draw_set_transform(player_position, 0.0, flip_scale)
	draw_texture_rect_region(player_texture, destination, source_rect, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_attack_animation() -> void:
	if attack_anim_kind == "" or attack_anim_duration <= 0.0:
		return
	# Draw the actual equipped item/tool in the character's hand. No generic
	# lines, sticks or semicircle overlays are used for player attacks.
	var weapon_id := equipped_weapon if equipped_weapon != "" else current_tool
	if weapon_id == "":
		return
	var weapon_texture := _item_icon(weapon_id)
	if weapon_texture == null:
		return
	var progress := 1.0 - clampf(attack_anim_time / attack_anim_duration, 0.0, 1.0)
	var hand := player_position + Vector2(float(facing) * 7.0, -4.0)
	var angle := 0.0
	var offset := Vector2(float(facing) * 8.0, 0.0)
	var icon_size := 26.0
	if attack_anim_kind == "slash":
		angle = float(facing) * lerpf(-1.05, 0.95, progress)
		offset += Vector2(float(facing) * sin(progress * PI) * 10.0, -2.0)
	elif attack_anim_kind == "spear":
		angle = float(facing) * 0.15
		offset += Vector2(float(facing) * lerpf(4.0, 26.0, sin(progress * PI)), 0.0)
		icon_size = 30.0
	elif attack_anim_kind == "bow":
		angle = float(facing) * -0.20
		offset += Vector2(float(facing) * lerpf(3.0, -5.0, sin(progress * PI)), -2.0)
	elif attack_anim_kind == "cannon":
		angle = 0.0
		offset += Vector2(float(facing) * (12.0 - sin(progress * PI) * 7.0), 1.0)
		icon_size = 28.0
	elif attack_anim_kind == "staff":
		angle = float(facing) * -0.45
		offset += Vector2(float(facing) * 10.0, -4.0)
	elif attack_anim_kind == "flask":
		angle = float(facing) * lerpf(-0.5, 0.8, progress)
		offset += Vector2(float(facing) * lerpf(4.0, 22.0, progress), -sin(progress * PI) * 10.0)
	elif attack_anim_kind == "turret":
		angle = 0.0
		offset += Vector2(float(facing) * 12.0, 1.0)
	var transform_scale := Vector2(float(facing), 1.0)
	draw_set_transform(hand + offset, angle, transform_scale)
	draw_texture_rect(weapon_texture, Rect2(Vector2(-icon_size * 0.5, -icon_size * 0.5), Vector2(icon_size, icon_size)), false, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Magic is shown as a compact glow around the actual staff/rod, not a line.
	if attack_anim_kind == "staff":
		var glow_pos := hand + offset + Vector2(float(facing) * 9.0, -7.0)
		draw_circle(glow_pos, 3.0 + sin(progress * PI) * 3.0, attack_anim_color)
		draw_circle(glow_pos, 1.5, Color("fff3c0"))

func _draw_target_cursor() -> void:
	var tile_pos := _mouse_tile()
	if not _can_interact(tile_pos):
		return
	var rect := Rect2(Vector2(tile_pos) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
	draw_rect(rect, Color("ffffff", 0.18))
	draw_rect(rect, Color("f4d35e"), false, 1.5)
	var tile := _get_tile(tile_pos.x, tile_pos.y)
	if mining_target == tile_pos and tile != Tile.AIR:
		var percent := int(clampf(mining_progress / _mining_hardness(tile, tile_pos), 0.0, 1.0) * 100.0)
		var label_pos := get_global_mouse_position() + Vector2(14, -18)
		var label_rect := Rect2(label_pos + Vector2(-4, -14), Vector2(48, 20))
		draw_rect(label_rect, Color("0b1016", 0.82))
		draw_rect(Rect2(label_rect.position + Vector2(3, 15), Vector2(42, 3)), Color("263443"))
		draw_rect(Rect2(label_rect.position + Vector2(3, 15), Vector2(42.0 * float(percent) / 100.0, 3)), Color("f0d27a"))
		if ui_font != null:
			draw_string(ui_font, label_pos, "%d%%" % percent, HORIZONTAL_ALIGNMENT_LEFT, 46.0, 12, Color("f6e7ad"))


func _update_minimap(delta: float) -> void:
	if minimap_rect == null or world.is_empty():
		return
	minimap_timer += delta
	var refresh_interval := MOBILE_MINIMAP_REFRESH_INTERVAL if mobile_ui_enabled else 1.0
	if minimap_timer < refresh_interval:
		return
	minimap_timer = 0.0

	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var network_markers_move: bool = (
		network_session != null and network_session.is_active()
		and network_session.joined and network_session.player_count() > 1
	)
	if center == minimap_rendered_center and world_tile_revision == minimap_rendered_revision and not network_markers_move:
		return
	minimap_rendered_center = center
	minimap_rendered_revision = world_tile_revision
	minimap_rebuild_count += 1
	var local_image := _build_local_minimap_image(148, 148)
	minimap_rect.texture = ImageTexture.create_from_image(local_image)
	if full_map_open and full_map_rect != null:
		_rebuild_world_map_image()
		var large_image := world_map_image.duplicate()
		_draw_sky_islands_on_map(large_image)
		_draw_network_world_map_markers(large_image, 3)
		_draw_map_player_marker(large_image, 4)
		full_map_rect.texture = ImageTexture.create_from_image(large_image)
		_update_map_fog()


func _refresh_map_textures() -> void:
	if world.is_empty():
		return
	minimap_rendered_center = Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	minimap_rendered_revision = world_tile_revision
	minimap_rebuild_count += 1
	var local_image := _build_local_minimap_image(148, 148)
	if minimap_rect != null:
		minimap_rect.texture = ImageTexture.create_from_image(local_image)
	if full_map_rect != null:
		_rebuild_world_map_image()
		var large_image := world_map_image.duplicate()
		_draw_map_player_marker(large_image, 4)
		_draw_sky_islands_on_map(large_image)
		full_map_rect.texture = ImageTexture.create_from_image(large_image)
		_update_map_fog()


func _build_local_minimap_image(width: int, height: int) -> Image:
	# Show a useful neighborhood around the player instead of shrinking the full world.
	# Square view so the circular lens keeps its aspect; the lens masks the edges.
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_x := floori(player_position.x / TILE_SIZE)
	var center_y := floori(player_position.y / TILE_SIZE)
	var view_tiles_x := maxi(30, int(float(width) * 0.46))
	var view_tiles_y := maxi(20, int(float(height) * 0.46))
	for py in range(height):
		var world_y := center_y + int(floor((float(py) / float(maxi(1, height - 1)) - 0.5) * float(view_tiles_y)))
		for px in range(width):
			var world_x := center_x + int(floor((float(px) / float(maxi(1, width - 1)) - 0.5) * float(view_tiles_x)))
			var color := Color("080a0b")
			if _in_bounds(world_x, world_y) and _is_tile_explored(world_x, world_y):
				var tile := _get_tile(world_x, world_y)
				color = Color("10151d") if tile == Tile.AIR else tile_colors.get(tile, Color.WHITE).darkened(0.15)
			# Circular lens mask with a soft edge.
			var distance := Vector2(px + 0.5 - float(width) * 0.5, py + 0.5 - float(height) * 0.5).length()
			var edge := float(mini(width, height)) * 0.5 - 3.0
			color.a = clampf((edge - distance) / 3.0, 0.0, 1.0)
			image.set_pixel(px, py, color)
	_draw_network_local_map_markers(image, center_x, center_y, view_tiles_x, view_tiles_y, 2)
	_draw_local_map_player_marker(image, 2)
	return image


func _draw_local_map_player_marker(image: Image, radius: int) -> void:
	var marker_x := int(image.get_width() / 2)
	var marker_y := int(image.get_height() / 2)
	for yy in range(marker_y - radius, marker_y + radius + 1):
		for xx in range(marker_x - radius, marker_x + radius + 1):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
				if Vector2(xx - marker_x, yy - marker_y).length() <= float(radius):
					image.set_pixel(xx, yy, Color("ffeb7a"))


func _draw_network_local_map_markers(image: Image, center_x: int, center_y: int, view_tiles_x: int, view_tiles_y: int, radius: int) -> void:
	if network_session == null or not network_session.is_active() or not network_session.joined:
		return
	var own_id: int = int(network_session.local_peer_id())
	for peer_variant in network_session.players.keys():
		var peer_id := int(peer_variant)
		if peer_id == own_id:
			continue
		var state: Dictionary = network_session.players.get(peer_id, {})
		var pos: Vector2 = state.get("render_pos", state.get("pos", Vector2.ZERO))
		var world_x := pos.x / TILE_SIZE
		var world_y := pos.y / TILE_SIZE
		var px := int(((world_x - float(center_x)) / float(maxi(1, view_tiles_x)) + 0.5) * float(image.get_width() - 1))
		var py := int(((world_y - float(center_y)) / float(maxi(1, view_tiles_y)) + 0.5) * float(image.get_height() - 1))
		if px < 0 or py < 0 or px >= image.get_width() or py >= image.get_height():
			continue
		var edge := float(mini(image.get_width(), image.get_height())) * 0.5 - 4.0
		if Vector2(px + 0.5 - float(image.get_width()) * 0.5, py + 0.5 - float(image.get_height()) * 0.5).length() > edge:
			continue
		_draw_map_marker_dot(image, px, py, radius, state.get("tint", Color("72d8ff")))


func _draw_network_world_map_markers(image: Image, radius: int) -> void:
	if network_session == null or not network_session.is_active() or not network_session.joined:
		return
	var own_id: int = int(network_session.local_peer_id())
	for peer_variant in network_session.players.keys():
		var peer_id := int(peer_variant)
		if peer_id == own_id:
			continue
		var state: Dictionary = network_session.players.get(peer_id, {})
		var pos: Vector2 = state.get("render_pos", state.get("pos", Vector2.ZERO))
		var px := clampi(int(pos.x / float(WORLD_WIDTH * TILE_SIZE) * float(image.get_width())), 0, image.get_width() - 1)
		var py := clampi(int(pos.y / float(WORLD_HEIGHT * TILE_SIZE) * float(image.get_height())), 0, image.get_height() - 1)
		_draw_map_marker_dot(image, px, py, radius, state.get("tint", Color("72d8ff")))


func _draw_map_marker_dot(image: Image, marker_x: int, marker_y: int, radius: int, color: Color) -> void:
	for yy in range(marker_y - radius, marker_y + radius + 1):
		for xx in range(marker_x - radius, marker_x + radius + 1):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height() and Vector2(xx - marker_x, yy - marker_y).length() <= float(radius):
				image.set_pixel(xx, yy, color)


func _rebuild_world_map_image() -> void:
	if not world_map_dirty and world_map_image != null:
		return
	world_map_image = Image.create(FULL_MAP_WIDTH, FULL_MAP_HEIGHT, false, Image.FORMAT_RGBA8)
	for py in range(FULL_MAP_HEIGHT):
		var world_y := int(float(py) / float(FULL_MAP_HEIGHT - 1) * float(WORLD_HEIGHT - 1))
		for px in range(FULL_MAP_WIDTH):
			var world_x := int(float(px) / float(FULL_MAP_WIDTH - 1) * float(WORLD_WIDTH - 1))
			var color := Color("080a0b")
			if _is_tile_explored(world_x, world_y):
				var tile := _get_tile(world_x, world_y)
				color = Color("10151d") if tile == Tile.AIR else tile_colors.get(tile, Color.WHITE).darkened(0.15)
			world_map_image.set_pixel(px, py, color)
	world_map_dirty = false


func _draw_map_player_marker(image: Image, radius: int) -> void:
	var marker_x := clampi(int(player_position.x / float(WORLD_WIDTH * TILE_SIZE) * float(image.get_width())), 0, image.get_width() - 1)
	var marker_y := clampi(int(player_position.y / float(WORLD_HEIGHT * TILE_SIZE) * float(image.get_height())), 0, image.get_height() - 1)
	for yy in range(marker_y - radius, marker_y + radius + 1):
		for xx in range(marker_x - radius, marker_x + radius + 1):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
				if Vector2(xx - marker_x, yy - marker_y).length() <= float(radius):
					image.set_pixel(xx, yy, Color("ffeb7a"))


func _get_tile(x: int, y: int) -> int:
	if not _in_bounds(x, y):
		return Tile.STONE
	return int(world[y][x])


func _invalidate_world_tile_caches() -> void:
	world_tile_revision += 1
	cached_light_revision = -1


func _set_tile(x: int, y: int, tile: int) -> void:
	if _in_bounds(x, y):
		var key := "%d,%d" % [x, y]
		var previous_tile := int(world[y][x])
		if previous_tile == Tile.SAPLING and tile != Tile.SAPLING:
			sapling_positions.erase(key)
		if previous_tile != tile:
			tree_tile_owners.erase(key)
		world[y][x] = tile
		world_map_dirty = true
		if previous_tile != tile and not world_generation_in_progress:
			_invalidate_world_tile_caches()
		if tile == Tile.SAPLING:
			sapling_positions[key] = Vector2i(x, y)
		if liquid_sim != null and not world_generation_in_progress:
			liquid_sim.on_tile_changed(x, y, tile)
		if previous_tile != tile and world_loaded and not world_generation_in_progress and network_session != null:
			network_session.notify_local_tile_changed(x, y, tile)


func _is_solid(x: int, y: int) -> bool:
	if not _in_bounds(x, y):
		return true
	return bool(solid_tiles.get(_get_tile(x, y), false))


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < WORLD_WIDTH and y < WORLD_HEIGHT
