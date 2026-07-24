extends Node2D

const TILE_SIZE := 16
const WORLD_WIDTH := 560
const WORLD_HEIGHT := 190
const VIEW_PADDING := 4
const GRAVITY := 1700.0
const MOVE_SPEED := 210.0
const JUMP_SPEED := -520.0
const PLAYER_SIZE := Vector2(12, 28)
const AUTO_STEP_HEIGHT := TILE_SIZE
const INTERACT_RANGE_TILES := 6.0
const SAVE_PATH := "user://ashen_roots_save.json"
const MAX_HEALTH := 100
const FALL_DAMAGE_SPEED := 760.0
const CHUNK_SIZE := 16
const MINIMAP_WIDTH := 180
const MINIMAP_HEIGHT := 70
const FULL_MAP_WIDTH := 560
const FULL_MAP_HEIGHT := 190
const HOTBAR_SIZE := 5
const INVENTORY_GRID_SIZE := 24
const VIRTUAL_JOYSTICK_SCRIPT := preload("res://scripts/virtual_joystick.gd")
const SLOT_SIZE := 54
const MIN_CAMERA_ZOOM := 1.9
const MAX_CAMERA_ZOOM := 3.1
const DAY_DURATION := 1500.0
const NIGHT_DURATION := 450.0
const FULL_DAY_DURATION := DAY_DURATION + NIGHT_DURATION
const MAX_ENEMIES := 12
const ENEMY_SPAWN_INTERVAL := 2.4
const PLAYER_HURT_COOLDOWN := 0.8
const USE_EXTERNAL_ENEMY_ANIMATION_STRIPS := false
const LOOT_PICKUP_RADIUS := 20.0
const LOOT_MAGNET_RADIUS := 76.0
const LOOT_DESPAWN_TIME := 240.0
const MAX_OXYGEN := 100.0

enum Tile {
	AIR,
	GRASS,
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
	TORCH
}

var tile_names: Dictionary = {
	Tile.AIR: "Air",
	Tile.GRASS: "Grass",
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
	Tile.TORCH: "Torch"
}

var tile_colors: Dictionary = {
	Tile.GRASS: Color("4f9f5f"),
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
	Tile.LAVA: Color("ff6a2b", 0.90),
	Tile.WATER_PLANT: Color("4aa88c"),
	Tile.BUBBLE_VENT: Color("6b8790"),
	Tile.DRAIN_VALVE: Color("7893a0"),
	Tile.SAPLING: Color("63a75e"),
	Tile.TORCH: Color("ffd36b")
}

var solid_tiles: Dictionary = {
	Tile.GRASS: true,
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
	Tile.DRAIN_VALVE: true
}

var tile_hardness: Dictionary = {
	Tile.GRASS: 0.28,
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
	Tile.TORCH: 0.10
}

var tile_required_power: Dictionary = {
	Tile.GRASS: 1,
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
	Tile.TORCH: 1
}

var tile_to_item: Dictionary = {
	Tile.GRASS: "dirt",
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
	Tile.TORCH: "torch"
}

var item_to_tile: Dictionary = {
	"dirt": Tile.DIRT,
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
	"torch": Tile.TORCH
}

var item_names: Dictionary = {
	"dirt": "Dirt",
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
	"ancient_chest": "Ancient Chest",
	"torch": "Torch",
	"stone_altar": "Stone Altar",
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
	"wild_badge": "Wild Badge"
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
	"copper_armor": {"slot": "armor", "class": "Any", "defense": 5},
	"iron_armor": {"slot": "armor", "class": "Any", "defense": 9},
	"ash_charm": {"slot": "accessory", "class": "Memory Reaper", "damage": 3},
	"root_ring": {"slot": "accessory", "class": "Summoner", "defense": 2},
	"wild_badge": {"slot": "accessory", "class": "Any", "damage": 2, "defense": 1},
	"diving_charm": {"slot": "accessory", "class": "Any", "defense": 1, "water_breathing": true},
	"ember_ward": {"slot": "accessory", "class": "Any", "defense": 2, "heat_resistance": true},
	"harpoon": {"slot": "weapon", "class": "Sniper", "damage": 23},
	"tidal_trident": {"slot": "weapon", "class": "Warrior", "damage": 21},
	"tide_staff": {"slot": "weapon", "class": "Mage", "damage": 19},
	"drowned_armor": {"slot": "armor", "class": "Any", "defense": 13, "water_affinity": true}
}

var recipes: Array[Dictionary] = [
	{"id": "workbench", "station": "hand", "cost": {"wood": 8}, "result": "workbench", "amount": 1},
	{"id": "torch", "station": "hand", "cost": {"wood": 1, "ash": 1}, "result": "torch", "amount": 4},
	{"id": "ancient_chest", "station": "workbench", "cost": {"wood": 12, "stone": 6}, "result": "ancient_chest", "amount": 1},
	{"id": "wooden_pickaxe", "station": "workbench", "cost": {"wood": 10, "stone": 4}, "result": "wooden_pickaxe", "amount": 1},
	{"id": "furnace", "station": "workbench", "cost": {"stone": 18, "wood": 4}, "result": "furnace", "amount": 1},
	{"id": "copper_bar", "station": "furnace", "cost": {"copper_ore": 3, "wood": 1}, "result": "copper_bar", "amount": 1},
	{"id": "iron_bar", "station": "furnace", "cost": {"iron_ore": 3, "wood": 1}, "result": "iron_bar", "amount": 1},
	{"id": "ash_glass", "station": "furnace", "cost": {"ash": 4, "stone": 1}, "result": "ash_glass", "amount": 1},
	{"id": "anvil", "station": "workbench", "cost": {"copper_bar": 5, "stone": 8}, "result": "anvil", "amount": 1},
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
	{"id": "tide_staff", "station": "anvil", "cost": {"guardian_core": 1, "abyss_crystal": 3, "drowned_pearl": 4}, "result": "tide_staff", "amount": 1},
	{"id": "drowned_armor", "station": "anvil", "cost": {"guardian_core": 1, "sunken_stone": 16, "kelp_fiber": 8}, "result": "drowned_armor", "amount": 1}
]

var world: Array = []
var surface_heights: Array[int] = []
var chest_loot: Dictionary = {}
var seed := 0
var rng := RandomNumberGenerator.new()
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
var biome_check_timer := 0.0
var cached_biome := "forest"
var hud_update_timer := 0.0
var last_message := "Gather wood and stone, then craft a workbench."
var inventory_open := false
var health := MAX_HEALTH
var oxygen := MAX_OXYGEN
var drowning_tick := 0.0
var lava_tick := 0.0
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
var crafting_label: Label
var stations_label: Label
var message_label: Label
var controls_label: Label
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
var minimap_panel: PanelContainer
var full_map_panel: PanelContainer
var full_map_rect: TextureRect
var full_map_open := false
var world_map_image: Image
var world_map_dirty := true
# Persistent fog of war: 0 = unexplored, 1 = discovered.
var explored_tiles := PackedByteArray()
var last_explored_tile := Vector2i(-999, -999)
var visible_light_sources: Array[Dictionary] = []
var mobile_controls: Control
var mobile_gameplay_controls: Control
var mobile_ui_enabled := false
var mobile_target_tile := Vector2i(-999, -999)
var mobile_target_valid := false
var mobile_world_touch_index := -1
var mobile_attack_target := Vector2.ZERO
var mobile_attack_target_valid := false
var item_icon_cache: Dictionary = {}
var tile_texture_paths: Dictionary = {}
var tile_textures: Dictionary = {}
var tile_texture_variants: Dictionary = {}
var enemy_textures: Dictionary = {}
var enemy_animation_textures: Dictionary = {}
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
var enemies: Array[Dictionary] = []
var dying_enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var dropped_items: Array[Dictionary] = []
var damage_numbers: Array[Dictionary] = []
var hit_particles: Array[Dictionary] = []
var attack_cooldown := 0.0
var attack_anim_time := 0.0
var attack_anim_duration := 0.0
var attack_anim_kind := ""
var attack_anim_dir := Vector2.RIGHT
var attack_anim_color := Color("f0d27a")
var enemy_spawn_timer := 0.0
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
var sound_players: Dictionary = {}
var player_texture: Texture2D
var player_frame_size := Vector2i(48, 64)


func _ready() -> void:
	ui_font = ThemeDB.fallback_font
	mobile_ui_enabled = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	_setup_texture_paths()
	_load_texture_assets()
	_setup_input_actions()
	_setup_camera()
	_setup_hud()
	_setup_audio()
	_generate_world()
	set_process(true)


func _process(delta: float) -> void:
	if debug_console_open:
		player_velocity = Vector2.ZERO
		_update_camera()
		_update_hud()
		queue_redraw()
		return
	if Input.is_action_just_pressed("regen_world"):
		_generate_world()
		return
	if Input.is_action_just_pressed("save_world"):
		_save_game()
	if Input.is_action_just_pressed("load_world"):
		_load_game()
	if not inventory_open and not full_map_open and Input.is_action_just_pressed("zoom_in"):
		_adjust_camera_zoom(0.14)
	if not inventory_open and not full_map_open and Input.is_action_just_pressed("zoom_out"):
		_adjust_camera_zoom(-0.14)
	if Input.is_action_just_pressed("toggle_inventory"):
		if full_map_open:
			_set_full_map_open(false)
		inventory_open = not inventory_open
		if not inventory_open:
			_close_chest()
	if Input.is_action_just_pressed("toggle_map"):
		_set_full_map_open(not full_map_open)
	if inventory_open and Input.is_action_just_pressed("recipe_prev"):
		_select_recipe(-1)
	if inventory_open and Input.is_action_just_pressed("recipe_next"):
		_select_recipe(1)
	if inventory_open and Input.is_action_just_pressed("craft_item"):
		_craft_selected_recipe()
	if inventory_open and Input.is_action_just_pressed("equip_item"):
		_equip_selected_item()
	if Input.is_action_just_pressed("attack"):
		_try_player_attack()

	_update_day_night(delta)
	_update_player(delta)
	_update_liquid_physics(delta)
	_update_saplings(delta)
	_update_biome_cache(delta)
	_update_biome_audio()
	_update_selection()
	_handle_block_actions()
	_update_combat(delta)
	_update_attack_animation(delta)
	_update_world_loot_and_fx(delta)
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


func _input(event: InputEvent) -> void:
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
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_mine_held = mouse_event.pressed


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		physical_move_left_held = false
		physical_move_right_held = false
		physical_noclip_up_held = false
		physical_noclip_down_held = false
		mouse_mine_held = false


func _unhandled_input(event: InputEvent) -> void:
	if not _mobile_controls_enabled() or full_map_open or inventory_open:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
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


func _handle_mobile_world_press(world_pos: Vector2) -> void:
	mobile_target_tile = Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
	mobile_target_valid = _in_bounds(mobile_target_tile.x, mobile_target_tile.y)
	if not mobile_target_valid:
		_try_player_attack_at(world_pos)
		return
	if _enemy_at_world_position(world_pos):
		_try_player_attack_at(world_pos)
		return
	var tile := _get_tile(mobile_target_tile.x, mobile_target_tile.y)
	if _can_interact(mobile_target_tile) and (tile == Tile.CHEST or tile == Tile.STONE_ALTAR):
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
		var size: Vector2 = enemy["size"]
		var enemy_rect := Rect2((enemy["pos"] as Vector2) - size * 0.5, size)
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
	_draw_attack_animation()
	_draw_darkness_overlay()
	_draw_target_cursor()


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
		Tile.SAPLING: "res://assets/textures/tiles/sapling.png"
	}


func _load_texture_assets() -> void:
	tile_textures.clear()
	tile_texture_variants.clear()
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
	for enemy_type in enemy_sprite_specs.keys():
		var texture: Texture2D = _load_png_texture("res://assets/textures/enemies/%s.png" % str(enemy_type))
		if texture != null:
			enemy_textures[str(enemy_type)] = texture
	enemy_animation_textures.clear()
	if USE_EXTERNAL_ENEMY_ANIMATION_STRIPS:
		var animation_states := {
			"wild_slime": ["idle", "move", "attack_1", "attack_2", "hurt", "death"],
			"mossling": ["idle", "move", "attack_1", "attack_2", "hurt", "death"],
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


func _load_png_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


func _setup_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	# Ashen Compass Arc: floating information, no large background panels.
	var status_root := Control.new()
	status_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_root.offset_left = 18
	status_root.offset_top = 22
	status_root.offset_right = 220
	status_root.offset_bottom = 116
	status_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_root)
	hud_label = Label.new()
	hud_label.position = Vector2(0, 0)
	hud_label.size = Vector2(174, 13)
	hud_label.add_theme_font_size_override("font_size", 10)
	hud_label.add_theme_color_override("font_color", Color("ded8c8"))
	status_root.add_child(hud_label)
	hud_health_bar = _make_compass_progress_bar(Color("d65455"))
	hud_health_bar.position = Vector2(0, 16)
	hud_health_bar.size = Vector2(174, 7)
	status_root.add_child(hud_health_bar)
	hud_armor_value = Label.new()
	hud_armor_value.position = Vector2(0, 30)
	hud_armor_value.size = Vector2(100, 14)
	hud_armor_value.add_theme_font_size_override("font_size", 9)
	hud_armor_value.add_theme_color_override("font_color", Color("c7c5bc"))
	status_root.add_child(hud_armor_value)
	hud_status_label = Label.new()
	hud_status_label.position = Vector2(0, 47)
	hud_status_label.size = Vector2(190, 14)
	hud_status_label.add_theme_font_size_override("font_size", 9)
	hud_status_label.add_theme_color_override("font_color", Color("d9b969"))
	status_root.add_child(hud_status_label)

	oxygen_panel = Control.new()
	oxygen_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	oxygen_panel.offset_left = 18
	oxygen_panel.offset_top = 95
	oxygen_panel.offset_right = 168
	oxygen_panel.offset_bottom = 114
	oxygen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oxygen_panel.visible = false
	canvas.add_child(oxygen_panel)
	var oxygen_title := Label.new()
	oxygen_title.text = "AIR"
	oxygen_title.position = Vector2(0, 0)
	oxygen_title.size = Vector2(26, 14)
	oxygen_title.add_theme_font_size_override("font_size", 8)
	oxygen_title.add_theme_color_override("font_color", Color("59a5c0"))
	oxygen_panel.add_child(oxygen_title)
	oxygen_bar = _make_compass_progress_bar(Color("59a5c0"))
	oxygen_bar.position = Vector2(29, 3)
	oxygen_bar.size = Vector2(93, 5)
	oxygen_panel.add_child(oxygen_bar)
	oxygen_value = Label.new()
	oxygen_value.position = Vector2(126, 0)
	oxygen_value.size = Vector2(30, 14)
	oxygen_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	oxygen_value.add_theme_font_size_override("font_size", 8)
	oxygen_value.add_theme_color_override("font_color", Color("8ed0e3"))
	oxygen_panel.add_child(oxygen_value)

	minimap_panel = _make_compass_map_frame()
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -194
	minimap_panel.offset_top = 18
	minimap_panel.offset_right = -18
	minimap_panel.offset_bottom = 136
	minimap_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	minimap_panel.tooltip_text = "Open world map"
	minimap_panel.gui_input.connect(_on_minimap_gui_input)
	canvas.add_child(minimap_panel)
	var minimap_root := Control.new()
	minimap_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_panel.add_child(minimap_root)
	minimap_rect = TextureRect.new()
	minimap_rect.position = Vector2(2, 2)
	minimap_rect.size = Vector2(172, 72)
	minimap_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	minimap_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(minimap_rect)
	minimap_time_label = Label.new()
	minimap_time_label.position = Vector2(0, 79)
	minimap_time_label.size = Vector2(176, 14)
	minimap_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap_time_label.add_theme_font_size_override("font_size", 8)
	minimap_time_label.add_theme_color_override("font_color", Color("59a5c0"))
	minimap_root.add_child(minimap_time_label)
	minimap_biome_label = Label.new()
	minimap_biome_label.position = Vector2(0, 94)
	minimap_biome_label.size = Vector2(176, 14)
	minimap_biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap_biome_label.add_theme_font_size_override("font_size", 8)
	minimap_biome_label.add_theme_color_override("font_color", Color("8fc47f"))
	minimap_root.add_child(minimap_biome_label)

	var hotbar_root := Control.new()
	hotbar_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar_root.offset_left = -190
	hotbar_root.offset_top = -155
	hotbar_root.offset_right = 190
	hotbar_root.offset_bottom = 0
	hotbar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hotbar_root)
	var slot_positions := [Vector2(10, 75), Vector2(80, 50), Vector2(150, 40), Vector2(220, 50), Vector2(290, 75)]
	for i in range(HOTBAR_SIZE):
		var slot := _make_slot_button()
		slot.position = slot_positions[i]
		slot.size = Vector2(60, 60)
		slot.custom_minimum_size = Vector2(60, 60)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		slot.gui_input.connect(_on_hotbar_slot_gui_input.bind(i))
		hotbar_buttons.append(slot)
		hotbar_root.add_child(slot)

	context_hint_panel = Control.new()
	context_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	context_hint_panel.offset_left = -140
	context_hint_panel.offset_top = -172
	context_hint_panel.offset_right = 140
	context_hint_panel.offset_bottom = -145
	context_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context_hint_panel.visible = false
	canvas.add_child(context_hint_panel)
	context_hint_label = Label.new()
	context_hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	context_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	context_hint_label.add_theme_font_size_override("font_size", 10)
	context_hint_label.add_theme_color_override("font_color", Color("d9b969"))
	context_hint_panel.add_child(context_hint_label)

	full_map_panel = _make_hud_panel(Vector2.ZERO, Vector2.ZERO)
	full_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	full_map_panel.anchor_left = 0.055
	full_map_panel.anchor_top = 0.065
	full_map_panel.anchor_right = 0.945
	full_map_panel.anchor_bottom = 0.90
	full_map_panel.offset_left = 0
	full_map_panel.offset_top = 0
	full_map_panel.offset_right = 0
	full_map_panel.offset_bottom = 0
	full_map_panel.visible = false
	full_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	full_map_panel.z_index = 60
	canvas.add_child(full_map_panel)
	var full_map_box := VBoxContainer.new()
	full_map_box.add_theme_constant_override("separation", 6)
	full_map_panel.add_child(full_map_box)
	var full_map_header := HBoxContainer.new()
	full_map_box.add_child(full_map_header)
	var full_map_title := Label.new()
	full_map_title.text = "WORLD MAP"
	full_map_title.add_theme_font_size_override("font_size", 18)
	full_map_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_map_header.add_child(full_map_title)
	var full_map_close := Button.new()
	full_map_close.text = "X"
	full_map_close.tooltip_text = "Close map"
	full_map_close.custom_minimum_size = Vector2(42, 34)
	full_map_close.focus_mode = Control.FOCUS_NONE
	full_map_close.pressed.connect(_set_full_map_open.bind(false))
	full_map_header.add_child(full_map_close)
	full_map_rect = TextureRect.new()
	full_map_rect.custom_minimum_size = Vector2(FULL_MAP_WIDTH, FULL_MAP_HEIGHT)
	full_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	full_map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	full_map_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	full_map_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_map_box.add_child(full_map_rect)

	chest_panel = _make_compass_clear_panel()
	chest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chest_panel.offset_left = -364
	chest_panel.offset_top = 122
	chest_panel.offset_right = -56
	chest_panel.offset_bottom = 470
	chest_panel.visible = false
	chest_panel.z_index = 52
	canvas.add_child(chest_panel)
	var chest_box := VBoxContainer.new()
	chest_box.add_theme_constant_override("separation", 8)
	chest_panel.add_child(chest_box)
	var chest_title := Label.new()
	chest_title.text = "ANCIENT CHEST"
	chest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_title.add_theme_font_size_override("font_size", 11)
	chest_title.add_theme_color_override("font_color", Color("d9b969"))
	chest_box.add_child(chest_title)
	var chest_grid := GridContainer.new()
	chest_grid.columns = 4
	chest_grid.add_theme_constant_override("h_separation", 8)
	chest_grid.add_theme_constant_override("v_separation", 8)
	chest_box.add_child(chest_grid)
	for i in range(15):
		var chest_slot := _make_slot_button()
		chest_slot.custom_minimum_size = Vector2(64, 64)
		chest_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		chest_slot.gui_input.connect(_on_chest_slot_gui_input.bind(i))
		chest_slot_buttons.append(chest_slot)
		chest_grid.add_child(chest_slot)

	boss_panel = _make_compass_clear_panel()
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -250
	boss_panel.offset_top = 12
	boss_panel.offset_right = 250
	boss_panel.offset_bottom = 48
	boss_panel.visible = false
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(boss_panel)
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 2)
	boss_panel.add_child(boss_box)
	boss_label = Label.new()
	boss_label.add_theme_font_size_override("font_size", 11)
	boss_label.add_theme_color_override("font_color", Color("d9b969"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_label)
	boss_hp_bar = _make_compass_progress_bar(Color("d65455"))
	boss_hp_bar.custom_minimum_size = Vector2(496, 5)
	boss_hp_bar.show_percentage = false
	boss_hp_bar.max_value = 100.0
	boss_box.add_child(boss_hp_bar)

	var loot_feed := VBoxContainer.new()
	loot_feed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	loot_feed.offset_left = -205
	loot_feed.offset_top = 300
	loot_feed.offset_right = -18
	loot_feed.offset_bottom = 470
	loot_feed.alignment = BoxContainer.ALIGNMENT_END
	loot_feed.add_theme_constant_override("separation", 7)
	loot_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(loot_feed)
	for i in range(5):
		var feed_label := Label.new()
		feed_label.add_theme_font_size_override("font_size", 11)
		feed_label.add_theme_color_override("font_color", Color("ded8c8"))
		feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		loot_feed_labels.append(feed_label)
		loot_feed.add_child(feed_label)

	# Inventory overlay: dim world, floating equipment / backpack / crafting areas.
	inventory_backdrop = ColorRect.new()
	inventory_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_backdrop.color = Color(0.025, 0.035, 0.03, 0.74)
	# The dimmer is visual only. It must never consume clicks meant for slots.
	inventory_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_backdrop.visible = false
	inventory_backdrop.z_index = 50
	canvas.add_child(inventory_backdrop)

	equipment_overlay = Control.new()
	equipment_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	equipment_overlay.offset_left = 72
	equipment_overlay.offset_top = 142
	equipment_overlay.offset_right = 292
	equipment_overlay.offset_bottom = 570
	equipment_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	equipment_overlay.visible = false
	equipment_overlay.z_index = 51
	canvas.add_child(equipment_overlay)
	equipment_label = Label.new()
	equipment_label.text = "EQUIPPED"
	equipment_label.position = Vector2(70, 0)
	equipment_label.size = Vector2(120, 20)
	equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_label.add_theme_font_size_override("font_size", 11)
	equipment_label.add_theme_color_override("font_color", Color("9f998d"))
	equipment_overlay.add_child(equipment_label)
	var equipment_line := ColorRect.new()
	equipment_line.position = Vector2(48, 18)
	equipment_line.size = Vector2(150, 1)
	equipment_line.color = Color("806043", 0.7)
	equipment_overlay.add_child(equipment_line)
	var equipment_box := VBoxContainer.new()
	equipment_box.position = Vector2(0, 35)
	equipment_box.size = Vector2(220, 260)
	equipment_box.add_theme_constant_override("separation", 14)
	equipment_overlay.add_child(equipment_box)
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 12)
	equipment_box.add_child(weapon_row)
	weapon_slot_button = _make_slot_button()
	weapon_slot_button.custom_minimum_size = Vector2(58, 58)
	weapon_slot_button.tooltip_text = "Weapon"
	weapon_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("weapon"))
	weapon_row.add_child(weapon_slot_button)
	var weapon_label := Label.new()
	weapon_label.text = "WEAPON"
	weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 9)
	weapon_label.add_theme_color_override("font_color", Color("ded8c8"))
	weapon_row.add_child(weapon_label)
	var armor_row := HBoxContainer.new()
	armor_row.add_theme_constant_override("separation", 12)
	equipment_box.add_child(armor_row)
	armor_slot_button = _make_slot_button()
	armor_slot_button.custom_minimum_size = Vector2(58, 58)
	armor_slot_button.tooltip_text = "Armor"
	armor_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("armor"))
	armor_row.add_child(armor_slot_button)
	var armor_label := Label.new()
	armor_label.text = "ARMOR"
	armor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	armor_label.add_theme_font_size_override("font_size", 9)
	armor_label.add_theme_color_override("font_color", Color("ded8c8"))
	armor_row.add_child(armor_label)
	var accessory_row := HBoxContainer.new()
	accessory_row.add_theme_constant_override("separation", 12)
	equipment_box.add_child(accessory_row)
	accessory_slot_button = _make_slot_button()
	accessory_slot_button.custom_minimum_size = Vector2(58, 58)
	accessory_slot_button.tooltip_text = "Charm"
	accessory_slot_button.gui_input.connect(_on_equipment_slot_gui_input.bind("accessory"))
	accessory_row.add_child(accessory_slot_button)
	var accessory_label := Label.new()
	accessory_label.text = "CHARM"
	accessory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	accessory_label.add_theme_font_size_override("font_size", 9)
	accessory_label.add_theme_color_override("font_color", Color("ded8c8"))
	accessory_row.add_child(accessory_label)

	inventory_panel = _make_compass_clear_panel()
	inventory_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	inventory_panel.anchor_left = 0.5
	inventory_panel.anchor_right = 0.5
	inventory_panel.offset_left = -230
	inventory_panel.offset_top = 122
	inventory_panel.offset_right = 230
	inventory_panel.offset_bottom = 613
	inventory_panel.visible = false
	inventory_panel.z_index = 51
	canvas.add_child(inventory_panel)
	var inventory_box := VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_box)
	inventory_title_label = Label.new()
	inventory_title_label.text = "BACKPACK"
	inventory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title_label.add_theme_font_size_override("font_size", 11)
	inventory_title_label.add_theme_color_override("font_color", Color("9f998d"))
	inventory_title_label.visible = true
	inventory_box.add_child(inventory_title_label)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 6
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inventory_box.add_child(inv_grid)
	for i in range(INVENTORY_GRID_SIZE):
		var inv_slot := _make_slot_button()
		inv_slot.custom_minimum_size = Vector2(64, 64)
		inv_slot.gui_input.connect(_on_inventory_slot_gui_input.bind(i))
		inv_slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		inventory_slot_buttons.append(inv_slot)
		inv_grid.add_child(inv_slot)
	selected_item_label = Label.new()
	selected_item_label.custom_minimum_size = Vector2(420, 48)
	selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_item_label.add_theme_font_size_override("font_size", 10)
	selected_item_label.add_theme_color_override("font_color", Color("ded8c8"))
	selected_item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_item_label.visible = true
	inventory_box.add_child(selected_item_label)
	var inventory_actions := HBoxContainer.new()
	inventory_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	inventory_actions.add_theme_constant_override("separation", 8)
	inventory_actions.visible = true
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
	message_label.add_theme_color_override("font_color", Color("9f998d"))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.visible = true
	inventory_box.add_child(message_label)

	crafting_panel = _make_compass_clear_panel()
	crafting_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	crafting_panel.offset_left = -364
	crafting_panel.offset_top = 122
	crafting_panel.offset_right = -56
	crafting_panel.offset_bottom = 610
	crafting_panel.visible = false
	crafting_panel.z_index = 51
	canvas.add_child(crafting_panel)
	var crafting_box := VBoxContainer.new()
	crafting_box.add_theme_constant_override("separation", 8)
	crafting_panel.add_child(crafting_box)
	var recipe_title := Label.new()
	recipe_title.text = "QUICK CRAFT"
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_title.add_theme_font_size_override("font_size", 11)
	recipe_title.add_theme_color_override("font_color", Color("9f998d"))
	recipe_title.visible = true
	crafting_box.add_child(recipe_title)
	var recipe_scroll := ScrollContainer.new()
	recipe_scroll.custom_minimum_size = Vector2(300, 220)
	crafting_box.add_child(recipe_scroll)
	var recipe_list := GridContainer.new()
	recipe_list.columns = 4
	recipe_list.add_theme_constant_override("h_separation", 8)
	recipe_list.add_theme_constant_override("v_separation", 8)
	recipe_scroll.add_child(recipe_list)
	for i in range(recipes.size()):
		var recipe_button := _make_slot_button()
		recipe_button.custom_minimum_size = Vector2(64, 64)
		recipe_button.focus_mode = Control.FOCUS_NONE
		recipe_button.add_theme_font_size_override("font_size", 10)
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(i))
		recipe_buttons.append(recipe_button)
		recipe_list.add_child(recipe_button)
	crafting_label = Label.new()
	crafting_label.custom_minimum_size = Vector2(300, 110)
	crafting_label.add_theme_font_size_override("font_size", 10)
	crafting_label.add_theme_color_override("font_color", Color("ded8c8"))
	crafting_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crafting_label.visible = true
	crafting_box.add_child(crafting_label)
	craft_button = _make_compass_action_button("CRAFT")
	craft_button.pressed.connect(_craft_selected_recipe)
	crafting_box.add_child(craft_button)
	stations_label = Label.new()
	stations_label.visible = false
	crafting_box.add_child(stations_label)
	controls_label = Label.new()
	controls_label.visible = false
	crafting_box.add_child(controls_label)

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

	_setup_mobile_controls(canvas)
	_setup_debug_console(canvas)


func _setup_debug_console(canvas: CanvasLayer) -> void:
	debug_console_panel = PanelContainer.new()
	debug_console_panel.name = "DebugConsole"
	debug_console_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_console_panel.offset_left = 22
	debug_console_panel.offset_top = 18
	debug_console_panel.offset_right = 670
	debug_console_panel.offset_bottom = 352
	debug_console_panel.z_index = 200
	debug_console_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("090d12", 0.97)
	panel_style.border_color = Color("6f8d91")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel_style.content_margin_left = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 12
	panel_style.content_margin_bottom = 10
	debug_console_panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(debug_console_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	debug_console_panel.add_child(layout)

	var title := Label.new()
	title.text = "DEV CONSOLE   F1 / `"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("9fd3c7"))
	layout.add_child(title)

	debug_console_output = RichTextLabel.new()
	debug_console_output.bbcode_enabled = true
	debug_console_output.fit_content = false
	debug_console_output.scroll_active = true
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

	var left_group := Control.new()
	left_group.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left_group.offset_left = 78
	left_group.offset_top = -220
	left_group.offset_right = 250
	left_group.offset_bottom = -48
	left_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_gameplay_controls.add_child(left_group)
	var joystick := Control.new()
	joystick.set_script(VIRTUAL_JOYSTICK_SCRIPT)
	joystick.position = Vector2(0, 0)
	joystick.size = Vector2(172, 172)
	left_group.add_child(joystick)

	var right_group := Control.new()
	right_group.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_group.offset_left = -342
	right_group.offset_top = -286
	right_group.offset_right = -28
	right_group.offset_bottom = -28
	right_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_gameplay_controls.add_child(right_group)
	_add_mobile_hold_button(right_group, "JUMP", Vector2(0, 116), "jump", "Jump", Vector2(132, 132), true)
	_add_mobile_tap_button(right_group, "ATK", Vector2(160, 0), _mobile_attack_button_pressed, "Attack", Vector2(136, 136), true)

	var top_group := Control.new()
	top_group.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_group.offset_left = -396
	top_group.offset_top = 14
	top_group.offset_right = -328
	top_group.offset_bottom = 66
	top_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls.add_child(top_group)
	_add_mobile_tap_button(top_group, "INV", Vector2.ZERO, _toggle_inventory_from_ui, "Inventory", Vector2(68, 52))


func _add_mobile_hold_button(parent: Control, text: String, position: Vector2, action: StringName, tooltip: String, size := Vector2(68, 68), circular := false) -> void:
	var button := _make_mobile_button(text, position, size, tooltip, circular)
	button.button_down.connect(_mobile_action_down.bind(action))
	button.button_up.connect(_mobile_action_up.bind(action))
	button.mouse_exited.connect(_mobile_action_up.bind(action))
	parent.add_child(button)


func _add_mobile_tap_button(parent: Control, text: String, position: Vector2, callback: Callable, tooltip: String, size := Vector2(68, 58), circular := false) -> void:
	var button := _make_mobile_button(text, position, size, tooltip, circular)
	button.pressed.connect(callback)
	parent.add_child(button)


func _make_mobile_button(text: String, position: Vector2, size: Vector2, tooltip: String, circular := false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.custom_minimum_size = size
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("111821", 0.70)
	normal.border_color = Color("9bb3bc", 0.78)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(int(minf(size.x, size.y) * 0.5) if circular else 6)
	button.add_theme_stylebox_override("normal", normal)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("d0a84c", 0.88)
	pressed.border_color = Color("ffe39a")
	button.add_theme_stylebox_override("pressed", pressed)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("263443", 0.82)
	button.add_theme_stylebox_override("hover", hover)
	return button


func _mobile_action_down(action: StringName) -> void:
	Input.action_press(action)


func _mobile_action_up(action: StringName) -> void:
	Input.action_release(action)


func _release_mobile_actions() -> void:
	mobile_world_touch_index = -1
	for action in [&"move_left", &"move_right", &"jump", &"mine", &"place", &"attack"]:
		Input.action_release(action)


func _toggle_inventory_from_ui() -> void:
	if full_map_open:
		_set_full_map_open(false)
	inventory_open = not inventory_open
	if not inventory_open:
		_close_chest()
	_update_mobile_controls_visibility()


func _toggle_map_from_ui() -> void:
	_set_full_map_open(not full_map_open)


func _on_minimap_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_toggle_map_from_ui()
			minimap_panel.accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_toggle_map_from_ui()
			minimap_panel.accept_event()


func _mobile_attack_button_pressed() -> void:
	_try_player_attack_at(player_position + Vector2(float(facing) * 100.0, 0.0))


func _mobile_controls_enabled() -> bool:
	return mobile_ui_enabled


func _set_full_map_open(open: bool) -> void:
	full_map_open = open
	if full_map_panel != null:
		full_map_panel.visible = open
	if open:
		inventory_open = false
		_close_chest()
		_release_mobile_actions()
		_refresh_map_textures()
	_update_mobile_controls_visibility()


func _update_mobile_controls_visibility() -> void:
	if mobile_controls != null:
		mobile_controls.visible = mobile_ui_enabled and not full_map_open and not debug_console_open
	if mobile_gameplay_controls != null:
		mobile_gameplay_controls.visible = mobile_ui_enabled and not full_map_open and not inventory_open and not debug_console_open
		if not mobile_gameplay_controls.visible:
			_release_mobile_actions()


func _setup_audio() -> void:
	sound_players.clear()
	var sounds := {
		"hit": {"freq": 180.0, "duration": 0.08, "volume": -10.0},
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111821", 0.88)
	style.border_color = Color("5b7180", 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_compass_clear_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_compass_map_frame() -> PanelContainer:
	# The local map floats directly over the world without a visible frame.
	return _make_compass_clear_panel()


func _make_compass_progress_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("090b0a", 0.62)
	background.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _apply_compass_hotbar_slot_style(button: Button, selected: bool) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color("1b201c", 0.88)
	base.border_color = Color("d9b969") if selected else Color("806043")
	base.set_border_width_all(2 if selected else 1)
	base.set_corner_radius_all(30)
	base.content_margin_left = 5
	base.content_margin_top = 5
	base.content_margin_right = 5
	base.content_margin_bottom = 5
	button.add_theme_stylebox_override("normal", base)
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2a3229", 0.96)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("101310", 0.98)
	button.add_theme_stylebox_override("pressed", pressed)


func _make_compass_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(102, 28)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	var base := StyleBoxFlat.new()
	base.bg_color = Color("1b201c", 0.90)
	base.border_color = Color("806043")
	base.set_border_width_all(1)
	base.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", base)
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2a3229", 0.98)
	hover.border_color = Color("d9b969")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("101310", 1.0)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


func _apply_compass_inventory_slot_style(button: Button, selected: bool, equipment := false) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color("1b201c", 0.92)
	base.border_color = Color("d9b969") if selected else Color("806043")
	base.set_border_width_all(2 if selected else 1)
	base.set_corner_radius_all(28 if equipment else 12)
	base.content_margin_left = 5
	base.content_margin_top = 5
	base.content_margin_right = 5
	base.content_margin_bottom = 5
	button.add_theme_stylebox_override("normal", base)
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2a3229", 0.98)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("101310", 1.0)
	button.add_theme_stylebox_override("pressed", pressed)


func _make_slot_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 10)
	_apply_slot_style(button, false)
	return button


func _apply_slot_style(button: Button, selected: bool) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color("1b2430", 0.96)
	base.border_color = Color("f0d27a") if selected else Color("60717d")
	base.set_border_width_all(2 if selected else 1)
	base.set_corner_radius_all(3)
	button.add_theme_stylebox_override("normal", base)
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color("263443", 0.98)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("111820", 1.0)
	button.add_theme_stylebox_override("pressed", pressed)


func _setup_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_ensure_key_action("regen_world", [KEY_R])
	_ensure_key_action("save_world", [KEY_F5])
	_ensure_key_action("load_world", [KEY_F9])
	_ensure_key_action("toggle_inventory", [KEY_TAB, KEY_I])
	_ensure_key_action("toggle_map", [KEY_M])
	_ensure_key_action("recipe_prev", [KEY_Z])
	_ensure_key_action("recipe_next", [KEY_X])
	_ensure_key_action("craft_item", [KEY_C])
	_ensure_key_action("equip_item", [KEY_E])
	_ensure_key_action("attack", [KEY_F])
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
	seed = int(Time.get_unix_time_from_system()) % 1000000000
	rng.seed = seed
	_reset_inventory()
	health = MAX_HEALTH
	oxygen = MAX_OXYGEN
	drowning_tick = 0.0
	lava_tick = 0.0
	liquid_flow_timer = 0.0
	liquid_flow_phase = 0
	sapling_growth_timer = 0.0
	enemies.clear()
	dying_enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	dropped_items.clear()
	damage_numbers.clear()
	hit_particles.clear()
	loot_notifications.clear()
	attack_anim_time = 0.0
	attack_anim_kind = ""
	held_item_id = ""
	held_item_amount = 0
	world_time = 28.0
	defeated_enemies = 0
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
	chest_loot.clear()
	sapling_positions.clear()
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
	_add_cave_decorations()
	_add_trees()
	_add_roots()
	_add_ruins()
	_spawn_player()
	_reset_exploration()
	_reveal_player_surroundings()
	cached_biome = _compute_current_biome()
	_update_minimap(999.0)


func _reset_inventory() -> void:
	inventory.clear()
	inventory["wooden_pickaxe"] = 1
	inventory["builder_hammer"] = 1
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


func _pick_base_tile(x: int, y: int, cave_noise: FastNoiseLite, ore_noise: FastNoiseLite) -> int:
	var surface_y: int = surface_heights[x]
	if y < surface_y:
		return Tile.AIR
	if y == surface_y:
		return Tile.GRASS

	var depth := y - surface_y
	var cave_value := cave_noise.get_noise_2d(float(x), float(y))
	if depth > 8 and cave_value > 0.34:
		return Tile.AIR

	if depth < 7:
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
	for i in range(34):
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
		if rng.randf() < 0.82:
			_carve_tunnel(room_centers[i], room_centers[i + 1], rng.randi_range(2, 3))


func _add_biomes() -> void:
	_add_forest_floor_details()
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
	if rng.randf() < 0.32:
		_place_chest(pos, _make_chest_loot("forest"))


func _add_mushroom_halls() -> void:
	for i in range(8):
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
		_place_chest(center + Vector2i(rng.randi_range(-5, 5), rng.randi_range(-1, 2)), _make_chest_loot("mushroom"))


func _add_ash_cities() -> void:
	for i in range(5):
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
		_place_chest(Vector2i(left + rng.randi_range(3, w - 4), top + h - 2), _make_chest_loot("ash_city"))


func _add_sunken_ruins() -> void:
	for i in range(6):
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
		_place_chest(center + Vector2i(rng.randi_range(-4, 4), rng.randi_range(0, 3)), _make_chest_loot("sunken"))


func _add_lava_roots() -> void:
	for i in range(34):
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
	for i in range(5):
		var pos := Vector2i(rng.randi_range(35, WORLD_WIDTH - 36), rng.randi_range(WORLD_HEIGHT - 58, WORLD_HEIGHT - 18))
		var radius_x := rng.randi_range(7, 13)
		var radius_y := rng.randi_range(3, 6)
		_carve_cave_blob(pos, radius_x, radius_y)
		_fill_liquid_pool(pos, radius_x - 1, radius_y, pos.y + 1, Tile.LAVA)
		_place_chest(pos, _make_chest_loot("lava_root"))


func _add_glass_abyss() -> void:
	for i in range(7):
		var center := Vector2i(rng.randi_range(28, WORLD_WIDTH - 29), rng.randi_range(WORLD_HEIGHT - 46, WORLD_HEIGHT - 12))
		_carve_cave_blob(center, rng.randi_range(12, 24), rng.randi_range(5, 11))
		_paint_biome_patch(center, rng.randi_range(15, 27), rng.randi_range(7, 13), Tile.GLASS_STONE, Tile.STONE)
		for crystal in range(rng.randi_range(8, 18)):
			var x := center.x + rng.randi_range(-20, 20)
			var y := center.y + rng.randi_range(-8, 10)
			if _in_bounds(x, y) and _get_tile(x, y) != Tile.AIR and rng.randf() < 0.55:
				_set_tile(x, y, Tile.ABYSS_CRYSTAL)
		_place_chest(center + Vector2i(rng.randi_range(-5, 5), rng.randi_range(-1, 3)), _make_chest_loot("glass"))


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


func _add_cave_structures() -> void:
	for i in range(11):
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
	for i in range(160):
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
	_place_chest(Vector2i(left + rng.randi_range(2, w - 3), top + h - 2), _make_chest_loot("ruin"))
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
	_place_chest(Vector2i(left + rng.randi_range(2, w - 3), floor_y), _make_chest_loot("root"))
	if rng.randf() < 0.35:
		_set_tile(left + int(w / 2), floor_y, Tile.STONE_ALTAR)


func _place_chest(pos: Vector2i, loot: Dictionary) -> void:
	if not _in_bounds(pos.x, pos.y) or not _in_bounds(pos.x, pos.y + 1):
		return
	if _get_tile(pos.x, pos.y + 1) == Tile.AIR:
		_set_tile(pos.x, pos.y + 1, Tile.RUIN)
	_set_tile(pos.x, pos.y, Tile.CHEST)
	chest_loot[_tile_key(pos)] = loot


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
	for i in range(32):
		var x := rng.randi_range(18, WORLD_WIDTH - 19)
		var y := rng.randi_range(surface_heights[x] + 34, WORLD_HEIGHT - 10)
		for yy in range(y - 2, y + 3):
			for xx in range(x - 3, x + 4):
				if _in_bounds(xx, yy) and _get_tile(xx, yy) == Tile.STONE and rng.randf() < 0.42:
					_set_tile(xx, yy, Tile.STONEBLOOD)
	for i in range(5):
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
	for i in range(9):
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
	for x in range(8, WORLD_WIDTH - 8):
		if rng.randf() > 0.055:
			continue
		var ground_y: int = surface_heights[x]
		if _get_tile(x, ground_y) != Tile.GRASS:
			continue
		var is_giant := rng.randf() < 0.18
		var is_dead := not is_giant and rng.randf() < 0.14
		var height := rng.randi_range(13, 19) if is_giant else (rng.randi_range(9, 14) if is_dead else rng.randi_range(7, 12))
		var trunk_width := rng.randi_range(2, 3) if is_giant else (1 if height < 10 else 2)
		var trunk_left := x - int(floor(float(trunk_width - 1) * 0.5))
		for y in range(ground_y - height, ground_y):
			for offset in range(trunk_width):
				var trunk_x := trunk_left + offset
				var narrows_at_top := is_giant and y < ground_y - height + 3 and (offset == 0 or offset == trunk_width - 1)
				if not narrows_at_top:
					_set_tile(trunk_x, y, Tile.WOOD)
			if is_giant and y > ground_y - 4:
				_set_tile(trunk_left - 1, y, Tile.ROOT)
				_set_tile(trunk_left + trunk_width, y, Tile.ROOT)

		var branch_count := rng.randi_range(4, 7) if is_giant else rng.randi_range(1, 3)
		var branch_ends: Array[Vector2i] = []
		for branch_index in range(branch_count):
			var dir := -1 if branch_index % 2 == 0 else 1
			if rng.randf() < 0.35:
				dir *= -1
			var min_from_top := 3 if is_giant else 2
			var max_from_ground := height - 3
			var branch_y := ground_y - rng.randi_range(min_from_top, max_from_ground)
			var length := rng.randi_range(5, 9) if is_giant else rng.randi_range(3, 5)
			var rise := rng.randi_range(1, 3) if is_giant else rng.randi_range(0, 2)
			var start_x := trunk_left if dir < 0 else trunk_left + trunk_width - 1
			branch_ends.append(_add_tree_branch(Vector2i(start_x, branch_y), dir, length, rise))

		var crown_center := Vector2i(x, ground_y - height)
		if is_dead:
			# Dead trees become rooty silhouettes with bare crooked branches.
			for root_offset in range(-2, 3):
				if root_offset != 0 and _get_tile(x + root_offset, ground_y - 1) == Tile.AIR:
					_set_tile(x + root_offset, ground_y - 1, Tile.ROOT)
		else:
			_add_leaf_cluster(crown_center, rng.randi_range(6, 8) if is_giant else rng.randi_range(4, 5), rng.randi_range(4, 6) if is_giant else rng.randi_range(3, 4))
			_add_leaf_cluster(crown_center + Vector2i(-4, 1), rng.randi_range(4, 6), rng.randi_range(3, 5))
			_add_leaf_cluster(crown_center + Vector2i(4, 1), rng.randi_range(4, 6), rng.randi_range(3, 5))
			_add_leaf_cluster(crown_center + Vector2i(0, -3), rng.randi_range(4, 6), rng.randi_range(2, 4))
			for branch_end in branch_ends:
				var leaf_rx := rng.randi_range(3, 5) if is_giant else rng.randi_range(2, 4)
				var leaf_ry := rng.randi_range(2, 4)
				_add_leaf_cluster(branch_end + Vector2i(0, -1), leaf_rx, leaf_ry)


func _add_tree_branch(start: Vector2i, dir: int, length: int, rise: int) -> Vector2i:
	var end := start
	for i in range(1, length + 1):
		var branch_x := start.x + dir * i
		var branch_y := start.y - int(round(float(i) / float(maxi(1, length)) * float(rise)))
		end = Vector2i(branch_x, branch_y)
		_set_tile(branch_x, branch_y, Tile.WOOD)
		if i > 2 and i % 3 == 0 and rng.randf() < 0.7:
			_set_tile(branch_x, branch_y - 1, Tile.WOOD)
		if i > 3 and rng.randf() < 0.28:
			var offshoot_dir := -dir if rng.randf() < 0.45 else dir
			_set_tile(branch_x + offshoot_dir, branch_y - 1, Tile.WOOD)
	return end


func _add_leaf_cluster(center: Vector2i, radius_x: int, radius_y: int) -> void:
	for yy in range(center.y - radius_y, center.y + radius_y + 1):
		for xx in range(center.x - radius_x, center.x + radius_x + 1):
			if not _in_bounds(xx, yy):
				continue
			var dx := float(xx - center.x) / float(maxi(1, radius_x))
			var dy := float(yy - center.y) / float(maxi(1, radius_y))
			var edge_noise := rng.randf_range(-0.28, 0.22)
			if dx * dx + dy * dy <= 1.0 + edge_noise and _get_tile(xx, yy) == Tile.AIR:
				_set_tile(xx, yy, Tile.LEAVES)


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
	if below != Tile.GRASS and below != Tile.DIRT and below != Tile.MOSS:
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
	var height := rng.randi_range(7, 10)
	_set_tile(pos.x, pos.y, Tile.AIR)
	for y in range(pos.y - height + 1, pos.y + 1):
		_set_tile(pos.x, y, Tile.WOOD)
	var crown := Vector2i(pos.x, pos.y - height + 1)
	_add_leaf_cluster(crown, rng.randi_range(3, 4), rng.randi_range(3, 4))
	_add_leaf_cluster(crown + Vector2i(-2, 1), 3, 3)
	_add_leaf_cluster(crown + Vector2i(2, 1), 3, 3)
	for branch_index in range(rng.randi_range(1, 3)):
		var dir := -1 if branch_index % 2 == 0 else 1
		var branch_y := pos.y - rng.randi_range(3, height - 2)
		var branch_end := _add_tree_branch(Vector2i(pos.x, branch_y), dir, rng.randi_range(2, 4), rng.randi_range(0, 1))
		_add_leaf_cluster(branch_end, 2, 2)


func _add_roots() -> void:
	for i in range(42):
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
	for i in range(7):
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


func _update_player(delta: float) -> void:
	if noclip_enabled:
		var horizontal := float(int(Input.is_action_pressed("move_right") or physical_move_right_held) - int(Input.is_action_pressed("move_left") or physical_move_left_held))
		var vertical := float(int(physical_noclip_down_held) - int(physical_noclip_up_held))
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
	if absf(direction) > 0.01:
		facing = 1 if direction > 0.0 else -1
	var liquid_speed := 0.62 if in_water else (0.43 if in_lava else 1.0)
	player_velocity.x = direction * MOVE_SPEED * _player_speed_multiplier() * liquid_speed
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

	_move_player(Vector2(player_velocity.x * delta, 0.0))
	_move_player(Vector2(0.0, player_velocity.y * delta))
	player_on_floor = _is_on_floor()
	_reveal_player_surroundings()
	if player_on_floor and not was_on_floor:
		_apply_fall_damage(landing_speed)
		landing_speed = 0.0
	_update_liquid_hazards(delta, in_water, in_lava)


func _player_overlaps_tile(tile: int) -> bool:
	var rect := Rect2(player_position - PLAYER_SIZE * 0.45, PLAYER_SIZE * 0.90)
	var min_x := floori(rect.position.x / TILE_SIZE)
	var max_x := floori((rect.end.x - 1.0) / TILE_SIZE)
	var min_y := floori(rect.position.y / TILE_SIZE)
	var max_y := floori((rect.end.y - 1.0) / TILE_SIZE)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _get_tile(x, y) == tile:
				return true
	return false


func _player_head_submerged() -> bool:
	var head_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori((player_position.y - PLAYER_SIZE.y * 0.38) / TILE_SIZE))
	return _get_tile(head_tile.x, head_tile.y) == Tile.WATER


func _equipped_accessory_has(property_name: String) -> bool:
	if equipped_accessory == "" or not gear_stats.has(equipped_accessory):
		return false
	return bool((gear_stats[equipped_accessory] as Dictionary).get(property_name, false))


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


func _update_liquid_physics(delta: float) -> void:
	# Lightweight local cellular flow. Only liquid near the player is simulated,
	# so caves can fill and drain without scanning the whole 560×190 world.
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


func _damage_player(amount: int) -> void:
	if god_mode_enabled:
		health = MAX_HEALTH
		return
	if amount <= 0:
		return
	if player_hurt_timer > 0.0:
		return
	health = maxi(0, health - amount)
	player_hurt_timer = PLAYER_HURT_COOLDOWN
	_spawn_damage_number(player_position + Vector2(0, -22), amount, Color("ff7777"))
	_play_sound("hurt")
	last_message = "Ouch! Took %d damage." % amount
	if health <= 0:
		_respawn_player()


func _incoming_damage(amount: int, damage_type: String) -> int:
	var defense := _total_defense()
	if player_statuses.has("armor_break"):
		defense = maxi(0, defense - 3)
	if damage_type == "poison":
		defense = int(floor(float(defense) * 0.55))
	elif damage_type == "fire" or damage_type == "arcane":
		defense = int(floor(float(defense) * 0.72))
	var final_damage := maxi(1, amount - defense)
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
	return multiplier


func _respawn_player() -> void:
	health = MAX_HEALTH
	oxygen = MAX_OXYGEN
	drowning_tick = 0.0
	lava_tick = 0.0
	enemies.clear()
	dying_enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	dropped_items.clear()
	damage_numbers.clear()
	hit_particles.clear()
	attack_anim_time = 0.0
	attack_anim_kind = ""
	held_item_id = ""
	held_item_amount = 0
	_spawn_player()


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


func _update_combat(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	player_hurt_timer = maxf(0.0, player_hurt_timer - delta)
	enemy_spawn_timer -= delta
	if enemy_spawn_timer <= 0.0:
		enemy_spawn_timer = ENEMY_SPAWN_INTERVAL
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
	_update_engineer_turret(delta)
	_update_status_effects(delta)


func _try_spawn_enemy() -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var player_tile := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var depth := player_tile.y - int(surface_heights[clampi(player_tile.x, 0, surface_heights.size() - 1)])
	var near_ruins := _has_tile_near_player(Tile.RUIN, 13)
	var near_roots := _has_tile_near_player(Tile.ROOT, 10)
	var biome := _current_biome()
	var in_cave := depth > 10
	var spawn_chance := 0.22
	if _is_night():
		spawn_chance = 0.70
	elif in_cave:
		spawn_chance = 0.48
	if near_ruins:
		spawn_chance += 0.18
	if rng.randf() > spawn_chance:
		return
	var enemy_type := "ash_wisp"
	if biome == "glass_abyss":
		enemy_type = "glass_wraith"
	elif biome == "lava_roots":
		enemy_type = "ember_rootling"
	elif biome == "sunken_ruins":
		enemy_type = "drowned_guard"
	elif biome == "ash_city":
		enemy_type = "ash_sentinel" if rng.randf() < 0.55 else "ruin_drone"
	elif biome == "mushroom_halls":
		enemy_type = "mushroom_beetle" if rng.randf() < 0.65 else "spore_bat"
	elif biome == "forest" and rng.randf() < 0.45:
		enemy_type = "mossling"
	elif near_ruins and rng.randf() < 0.55:
		enemy_type = "ruin_drone"
	elif _is_night():
		enemy_type = "ash_phantom" if rng.randf() < 0.42 else "night_ember"
	elif mushroom_path_opened and depth > 24 and rng.randf() < 0.35:
		enemy_type = "mushroom_beetle"
	elif near_roots and rng.randf() < 0.55:
		enemy_type = "root_crawler"
	elif in_cave:
		enemy_type = "cave_worm" if rng.randf() < 0.34 else ("bat" if rng.randf() < 0.5 else "cave_husk")
	elif rng.randf() < 0.55:
		enemy_type = "wild_slime"
	var spawn_data := _enemy_template(enemy_type)
	var pos := _find_spawn_position_near_player(18, 30, bool(spawn_data.get("flying", false)), spawn_data.get("size", Vector2(16, 16)))
	_spawn_enemy(enemy_type, pos)


func _compute_current_biome() -> String:
	var tile_pos := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	var surface_y: int = surface_heights[clampi(tile_pos.x, 0, surface_heights.size() - 1)]
	var depth := tile_pos.y - surface_y
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
		return "forest"
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
	last_message = "Entered %s." % _biome_display_name(biome)


func _has_tile_near_player(tile: int, radius: int) -> bool:
	var center := Vector2i(floori(player_position.x / TILE_SIZE), floori(player_position.y / TILE_SIZE))
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if _in_bounds(x, y) and _get_tile(x, y) == tile:
				return true
	return false


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


func _spawn_enemy(enemy_type: String, pos: Vector2) -> void:
	var data := _enemy_template(enemy_type)
	data["type"] = enemy_type
	data["pos"] = pos
	data["vel"] = Vector2.ZERO
	data["hit_timer"] = 0.0
	data["stun_timer"] = 0.0
	data["attack_windup"] = 0.0
	data["attack_flash"] = 0.0
	data["attack_cooldown"] = rng.randf_range(0.25, 0.8)
	data["facing"] = -1
	data["anim_offset"] = rng.randf() * 10.0
	data["anim_state"] = "idle"
	data["anim_time"] = 0.0
	data["home_pos"] = pos
	data["stuck_time"] = 0.0
	data["jump_cooldown"] = rng.randf_range(0.0, 0.25)
	data["avoid_timer"] = 0.0
	data["avoid_direction"] = 0
	if enemy_type == "heartwood_boss":
		data["spawn_timer"] = 0.85
		data["phase_two"] = false
		data["phase_timer"] = 0.0
		data["anim_state"] = "spawn"
	enemies.append(data)


func _enemy_template(enemy_type: String) -> Dictionary:
	if enemy_type == "mossling":
		return {"name": "Mossling", "hp": 20, "max_hp": 20, "damage": 6, "damage_type": "physical", "speed": 72.0, "flying": false, "size": Vector2(18, 12), "color": Color("5c9a63"), "drop": "moss_fiber"}
	if enemy_type == "cave_worm":
		return {"name": "Cave Worm", "hp": 46, "max_hp": 46, "damage": 11, "damage_type": "physical", "speed": 82.0, "flying": false, "size": Vector2(34, 12), "color": Color("9b6b4d"), "drop": "wild_ichor", "status_on_hit": "slow"}
	if enemy_type == "bat":
		return {"name": "Bat", "hp": 16, "max_hp": 16, "damage": 6, "damage_type": "physical", "speed": 128.0, "flying": true, "size": Vector2(18, 10), "color": Color("4f5165"), "drop": "wild_ichor"}
	if enemy_type == "spore_bat":
		return {"name": "Spore Bat", "hp": 22, "max_hp": 22, "damage": 8, "damage_type": "poison", "speed": 118.0, "flying": true, "size": Vector2(19, 11), "color": Color("79c98b"), "drop": "glowcap", "status_on_hit": "poison"}
	if enemy_type == "ash_phantom":
		return {"name": "Ash Phantom", "hp": 32, "max_hp": 32, "damage": 10, "damage_type": "fire", "speed": 88.0, "flying": true, "size": Vector2(18, 24), "color": Color("a88cff"), "drop": "memory_shard", "status_on_hit": "burn"}
	if enemy_type == "mushroom_beetle":
		return {"name": "Mushroom Beetle", "hp": 34, "max_hp": 34, "damage": 9, "damage_type": "poison", "speed": 54.0, "flying": false, "size": Vector2(20, 14), "color": Color("65b47d"), "drop": "mushroom_spore", "status_on_hit": "poison"}
	if enemy_type == "root_crawler":
		return {"name": "Root Crawler", "hp": 30, "max_hp": 30, "damage": 8, "damage_type": "physical", "speed": 62.0, "flying": false, "size": Vector2(22, 12), "color": Color("8a6638"), "drop": "root", "status_on_hit": "slow"}
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
		return {"name": "Cave Husk", "hp": 38, "max_hp": 38, "damage": 10, "damage_type": "physical", "speed": 58.0, "flying": false, "size": Vector2(16, 22), "color": Color("8f8796"), "drop": "wild_ichor"}
	if enemy_type == "ash_wisp":
		return {"name": "Ash Wisp", "hp": 22, "max_hp": 22, "damage": 8, "damage_type": "arcane", "speed": 76.0, "flying": true, "size": Vector2(14, 14), "color": Color("b79cff"), "drop": "spark_shard"}
	if enemy_type == "heartwood_boss":
		return {"name": "Heartwood Core", "hp": 260, "max_hp": 260, "damage": 18, "damage_type": "physical", "speed": 46.0, "flying": false, "size": Vector2(42, 48), "color": Color("8b5a36"), "drop": "heartwood_core"}
	return {"name": "Wild Slime", "hp": 18, "max_hp": 18, "damage": 7, "damage_type": "physical", "speed": 64.0, "flying": false, "size": Vector2(16, 13), "color": Color("5fbf7b"), "drop": "wild_ichor"}


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
		enemy["jump_cooldown"] = maxf(0.0, float(enemy.get("jump_cooldown", 0.0)) - delta)
		enemy["avoid_timer"] = maxf(0.0, float(enemy.get("avoid_timer", 0.0)) - delta)
		var pos: Vector2 = enemy["pos"]
		var old_pos := pos
		var vel: Vector2 = enemy["vel"]
		var size: Vector2 = enemy["size"]
		var to_player := player_position - pos
		var distance := to_player.length()
		var facing := 1 if to_player.x >= 0.0 else -1
		if absf(to_player.x) > 2.0:
			enemy["facing"] = facing
		var speed := float(enemy.get("speed", 50.0))
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
		var move_intent := 0
		var desired_flying_velocity := Vector2.ZERO
		var vertical_attack_tolerance := maxf(28.0, size.y * 1.25)
		var can_begin_attack := distance <= attack_range
		if not flying and _enemy_attack_kind(enemy_type, int(enemy.get("attack_index", 1))) in ["melee", "dash", "roll", "slam", "whip"]:
			can_begin_attack = can_begin_attack and absf(to_player.y) <= vertical_attack_tolerance

		if stunned:
			vel.x = move_toward(vel.x, 0.0, speed * 3.0 * delta)
		elif attack_windup > 0.0:
			attack_windup = maxf(0.0, attack_windup - delta)
			vel.x = move_toward(vel.x, 0.0, speed * 7.0 * delta)
			if attack_windup <= 0.0:
				enemy["attack_flash"] = 0.16
				enemy["attack_cooldown"] = 1.10 if flying else 0.95
				if enemy_type == "heartwood_boss" and bool(enemy.get("phase_two", false)):
					enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) * 0.72
				vel += _execute_enemy_attack(enemy, pos, facing, distance, attack_range)
		else:
			if float(enemy.get("attack_cooldown", 0.0)) <= 0.0 and can_begin_attack:
				var next_attack := _choose_enemy_attack_index(enemy)
				enemy["attack_index"] = next_attack
				attack_windup = _enemy_attack_windup(str(enemy.get("type", "")), next_attack, windup_duration)
				enemy["attack_total"] = attack_windup
				vel.x = 0.0
			else:
				if flying:
					var hover_target := player_position + Vector2(float(-facing) * attack_range * 0.72, sin(float(Time.get_ticks_msec()) / 260.0 + float(enemy.get("anim_offset", 0.0))) * 12.0)
					var desired := hover_target - pos
					desired_flying_velocity = desired.normalized() * speed if desired.length() > 3.0 else Vector2.ZERO
				else:
					move_intent = facing if distance > attack_range * 0.72 else 0

		if not flying and not stunned and attack_windup <= 0.0:
			var avoid_direction := int(enemy.get("avoid_direction", 0))
			if float(enemy.get("avoid_timer", 0.0)) > 0.0 and avoid_direction != 0:
				move_intent = avoid_direction
			var desired_x := float(move_intent) * speed
			vel.x = move_toward(vel.x, desired_x, speed * 7.0 * delta)

		if not flying:
			var on_floor := _enemy_on_floor(pos, size)
			if on_floor and vel.y > 0.0:
				vel.y = 0.0
			if not stunned and attack_windup <= 0.0 and move_intent != 0 and on_floor and float(enemy.get("jump_cooldown", 0.0)) <= 0.0:
				var blocked_ahead := _enemy_wall_ahead(pos, size, move_intent)
				var gap_ahead := not _enemy_ground_ahead(pos, size, move_intent)
				if blocked_ahead or (gap_ahead and _enemy_has_landing_ahead(pos, size, move_intent)):
					vel.y = _enemy_jump_speed(size)
					enemy["jump_cooldown"] = 0.48
			vel.y += GRAVITY * delta
			pos = _move_enemy(pos, vel * delta, size)
			if _enemy_on_floor(pos, size) and vel.y > 0.0:
				vel.y = 0.0
			var expected_motion := move_intent != 0 and attack_windup <= 0.0 and not stunned
			var made_progress := absf(old_pos.x - pos.x) > maxf(0.25, speed * delta * 0.12)
			var stuck_time := float(enemy.get("stuck_time", 0.0))
			stuck_time = maxf(0.0, stuck_time - delta * 2.0) if not expected_motion or made_progress else stuck_time + delta
			if stuck_time > 0.32 and _enemy_on_floor(pos, size) and float(enemy.get("jump_cooldown", 0.0)) <= 0.0:
				vel.y = _enemy_jump_speed(size) * 1.08
				enemy["jump_cooldown"] = 0.58
			if stuck_time > 1.05:
				enemy["avoid_direction"] = -facing
				enemy["avoid_timer"] = 0.55
				stuck_time = 0.0
			enemy["stuck_time"] = stuck_time
		else:
			if not stunned and attack_windup <= 0.0:
				desired_flying_velocity += _enemy_flying_avoidance(pos, size, desired_flying_velocity) * speed
				vel = vel.move_toward(desired_flying_velocity.limit_length(speed), speed * 4.5 * delta)
			else:
				vel = vel.move_toward(Vector2.ZERO, speed * 5.0 * delta)
			pos = _move_flying_enemy(pos, vel * delta, size)
			var flying_progress := old_pos.distance_to(pos)
			if desired_flying_velocity.length_squared() > 25.0 and flying_progress < 0.2:
				var flying_stuck := float(enemy.get("stuck_time", 0.0)) + delta
				if flying_stuck > 0.35:
					vel.y += (-1.0 if player_position.y <= pos.y else 1.0) * speed * 0.85
					vel.x *= -0.45
					flying_stuck = 0.0
				enemy["stuck_time"] = flying_stuck
			else:
				enemy["stuck_time"] = maxf(0.0, float(enemy.get("stuck_time", 0.0)) - delta * 2.0)

		enemy["attack_windup"] = attack_windup
		var next_anim_state := "idle"
		if float(enemy.get("hit_timer", 0.0)) > 0.0:
			next_anim_state = "hurt"
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


func _enemy_attack_range(enemy_type: String, size: Vector2, flying: bool) -> float:
	if enemy_type in ["ash_wisp", "ruin_drone", "spore_bat", "glass_wraith", "night_ember", "ash_phantom"]:
		return 150.0
	if enemy_type in ["ash_sentinel", "drowned_guard", "ember_rootling", "cave_husk", "mushroom_beetle"]:
		return 92.0
	if enemy_type == "heartwood_boss":
		return 118.0
	return maxf(24.0, size.x * (1.45 if flying else 1.05))


func _enemy_jump_speed(size: Vector2) -> float:
	if size.y >= 38.0:
		return -390.0
	if size.y >= 24.0:
		return -340.0
	return -305.0


func _enemy_wall_ahead(pos: Vector2, size: Vector2, direction: int) -> bool:
	var probe_x := pos.x + float(direction) * (size.x * 0.5 + 3.0)
	var probe := Rect2(Vector2(probe_x - 1.5, pos.y - size.y * 0.5 + 3.0), Vector2(3.0, maxf(4.0, size.y - 6.0)))
	return _rect_collides(probe)


func _enemy_ground_ahead(pos: Vector2, size: Vector2, direction: int) -> bool:
	var probe_x := pos.x + float(direction) * (size.x * 0.5 + 5.0)
	var probe_y := pos.y + size.y * 0.5 + 1.0
	return _rect_collides(Rect2(Vector2(probe_x - 2.0, probe_y), Vector2(4.0, 7.0)))


func _enemy_has_landing_ahead(pos: Vector2, size: Vector2, direction: int) -> bool:
	for tile_step in range(1, 4):
		var probe_x := pos.x + float(direction) * (size.x * 0.5 + float(tile_step * TILE_SIZE))
		var probe_y := pos.y + size.y * 0.5 + 1.0
		if _rect_collides(Rect2(Vector2(probe_x - 3.0, probe_y), Vector2(6.0, TILE_SIZE * 2.2))):
			return true
	return false


func _enemy_flying_avoidance(pos: Vector2, size: Vector2, desired_velocity: Vector2) -> Vector2:
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
	return Vector2(0.0, -1.0 if player_position.y <= pos.y else 1.0)

func _update_enemy_deaths(delta: float) -> void:
	for i in range(dying_enemies.size() - 1, -1, -1):
		var corpse: Dictionary = dying_enemies[i]
		corpse["death_time"] = float(corpse.get("death_time", 0.0)) - delta
		if float(corpse["death_time"]) <= 0.0:
			dying_enemies.remove_at(i)
		else:
			dying_enemies[i] = corpse


func _enemy_attack_count(enemy_type: String) -> int:
	if enemy_type == "stone_beast" or enemy_type == "heartwood_boss":
		return 6
	if enemy_type in ["ash_sentinel", "drowned_guard", "glass_wraith"]:
		return 4
	if enemy_type in ["root_crawler", "cave_worm", "cave_husk", "spore_bat", "mushroom_beetle", "ash_phantom", "ruin_drone", "ember_rootling", "night_ember"]:
		return 3
	if enemy_type in ["wild_slime", "mossling", "bat", "ash_wisp"]:
		return 2
	return 1


func _choose_enemy_attack_index(enemy: Dictionary) -> int:
	var count := _enemy_attack_count(str(enemy.get("type", "")))
	var previous := int(enemy.get("attack_index", 0))
	return previous % count + 1


func _enemy_attack_windup(enemy_type: String, attack_index: int, default_time: float) -> float:
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
		return "dash" if attack_index == 1 else "pulse"
	if enemy_type == "cave_husk":
		return "melee" if attack_index == 1 else ("projectile" if attack_index == 2 else "slam")
	if enemy_type == "spore_bat":
		return "dash" if attack_index == 1 else ("projectile" if attack_index == 2 else "burst")
	if enemy_type == "mushroom_beetle":
		return "melee" if attack_index == 1 else ("dash" if attack_index == 2 else "projectile")
	if enemy_type == "ash_phantom":
		return "dash" if attack_index == 1 else ("projectile" if attack_index == 2 else "burst")
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


func _execute_enemy_attack(enemy: Dictionary, pos: Vector2, facing: int, distance: float, attack_range: float) -> Vector2:
	var enemy_type := str(enemy.get("type", ""))
	var attack_index := int(enemy.get("attack_index", 1))
	var kind := _enemy_attack_kind(enemy_type, attack_index)
	var raw_damage := int(enemy.get("damage", 1))
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
			_spawn_enemy_projectile(pos + burst_dir * 8.0, burst_dir * 150.0, raw_damage, burst_color, burst_type, applied_status)
		return Vector2.ZERO
	if kind == "whip":
		if distance <= 52.0:
			_enemy_hit_player(enemy, facing, "root_bind")
		return Vector2.ZERO
	if kind == "burrow":
		if distance <= 64.0:
			_enemy_hit_player(enemy, facing, "root_bind" if enemy_type == "root_crawler" else "slow")
		return Vector2(float(facing) * 220.0, -40.0)
	if kind == "pulse":
		if distance <= 68.0:
			_enemy_hit_player(enemy, facing)
			player_velocity += Vector2(float(facing) * 150.0, -25.0)
		return Vector2.ZERO
	if kind == "slam":
		if distance <= 42.0:
			_enemy_hit_player(enemy, facing, "armor_break")
		return Vector2.ZERO
	if kind == "guard":
		enemy["guard_time"] = 1.35
		return Vector2.ZERO
	if kind == "harpoon":
		var harpoon_dir := (player_position - pos).normalized()
		_spawn_enemy_projectile(pos + harpoon_dir * 12.0, harpoon_dir * 230.0, raw_damage, Color("86c8d0"), "physical", "slow", "harpoon")
		return Vector2.ZERO
	if kind == "wave":
		var wave_dir := Vector2(float(facing), 0)
		_spawn_enemy_projectile(pos + wave_dir * 12.0, wave_dir * 145.0, raw_damage, Color("62b8ca"), "physical", "wet", "wave")
		return Vector2.ZERO
	if kind == "rootburst":
		if distance <= 64.0:
			_enemy_hit_player(enemy, facing, "root_bind" if enemy_type == "heartwood_boss" else "burn")
			if enemy_type != "heartwood_boss":
				_apply_player_status("root_bind")
		return Vector2.ZERO
	if kind == "triple":
		for angle in [-0.24, 0.0, 0.24]:
			var flame_dir := Vector2(float(facing), 0).rotated(angle)
			_spawn_enemy_projectile(pos + flame_dir * 10.0, flame_dir * 195.0, raw_damage, Color("ff8a45"), "fire", "burn")
		return Vector2.ZERO
	if kind == "seed":
		var seed_dir := (player_position - pos).normalized()
		_spawn_enemy_projectile(pos + seed_dir * 14.0, seed_dir * 175.0, raw_damage, Color("c790d3"), "physical", "slow", "seed")
		return Vector2.ZERO
	if kind == "summon":
		for summon_index in range(2):
			var summon_pos := _find_spawn_position_near_player(7 + summon_index * 2, 10 + summon_index * 2, false, Vector2(18, 12))
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
		for angle in [-0.34, -0.17, 0.0, 0.17, 0.34]:
			var shard_dir := Vector2(float(facing), 0).rotated(angle)
			_spawn_enemy_projectile(pos + shard_dir * 10.0, shard_dir * 210.0, raw_damage, Color("b8f4ff"), "physical", "fragile")
		return Vector2.ZERO
	if kind == "teleport_slash":
		if distance <= 68.0:
			_enemy_hit_player(enemy, facing, "fragile")
		return Vector2(float(facing) * 230.0, -35.0)
	if kind == "cage":
		if distance <= 88.0:
			_enemy_hit_player(enemy, facing, "root_bind")
		return Vector2.ZERO
	if kind == "shockwave":
		if distance <= 80.0:
			_enemy_hit_player(enemy, facing, "slow")
		return Vector2.ZERO
	if kind == "rockfall":
		for offset in [-32.0, 0.0, 32.0]:
			var rock_target := player_position + Vector2(offset, -70.0)
			_spawn_enemy_projectile(rock_target, Vector2(0, 155.0), raw_damage, Color("a9a49a"), "physical", "")
		return Vector2.ZERO
	if kind == "spikes":
		if distance <= 96.0:
			_enemy_hit_player(enemy, facing, "slow")
		return Vector2.ZERO
	if kind == "projectile" or kind == "laser":
		var direction := (player_position - pos).normalized()
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
		_spawn_enemy_projectile(pos + direction * 12.0, direction * speed, raw_damage, color, str(enemy.get("damage_type", "physical")), status)
		_play_sound("shoot")
		return Vector2.ZERO
	if kind == "roll":
		if distance <= attack_range + 28.0:
			_enemy_hit_player(enemy, facing, "slow")
		return Vector2(float(facing) * 245.0, -25.0)
	if kind == "dash":
		if distance <= attack_range + 20.0:
			_enemy_hit_player(enemy, facing)
		return Vector2(float(facing) * (250.0 if enemy_type == "stone_beast" else 175.0), -65.0)
	if distance <= attack_range + 14.0:
		_enemy_hit_player(enemy, facing)
	return Vector2.ZERO


func _enemy_hit_player(enemy: Dictionary, facing: int, forced_status := "") -> void:
	_damage_player(_incoming_damage(int(enemy.get("damage", 1)), str(enemy.get("damage_type", "physical"))))
	player_velocity += Vector2(float(facing) * 115.0, -80.0)
	if forced_status != "":
		_apply_player_status(forced_status)
	elif enemy.has("status_on_hit"):
		_apply_player_status(str(enemy["status_on_hit"]))


func _spawn_enemy_projectile(pos: Vector2, vel: Vector2, damage: int, color: Color, damage_type: String, status: String, special := "") -> void:
	enemy_projectiles.append({
		"pos": pos,
		"vel": vel,
		"damage": damage,
		"color": color,
		"life": 2.3,
		"damage_type": damage_type,
		"status": status,
		"special": special
	})


func _enemy_on_floor(pos: Vector2, size: Vector2) -> bool:
	var foot_rect := Rect2(Vector2(pos.x - size.x * 0.4, pos.y + size.y * 0.5), Vector2(size.x * 0.8, 2.0))
	return _rect_collides(foot_rect)


func _move_enemy(pos: Vector2, motion: Vector2, size: Vector2) -> Vector2:
	if motion.x != 0.0:
		var x_pos := pos + Vector2(motion.x, 0.0)
		if not _rect_collides(Rect2(x_pos - size * 0.5, size)):
			pos = x_pos
		elif _enemy_on_floor(pos, size):
			for step_height in range(2, TILE_SIZE + 3, 2):
				var step_pos := pos + Vector2(motion.x, -float(step_height))
				if not _rect_collides(Rect2(step_pos - size * 0.5, size)) and _enemy_on_floor(step_pos, size):
					pos = step_pos
					break
	if motion.y != 0.0:
		var y_pos := pos + Vector2(0.0, motion.y)
		if not _rect_collides(Rect2(y_pos - size * 0.5, size)):
			pos = y_pos
	return pos


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
			var size: Vector2 = enemy["size"]
			var enemy_rect := Rect2((enemy["pos"] as Vector2) - size * 0.5, size)
			if enemy_rect.has_point(pos):
				_damage_enemy(enemy_index, int(projectile.get("damage", 1)), Vector2(signf(vel.x), -0.3), str(projectile.get("damage_type", "physical")), str(projectile.get("status", "")))
				remove = true
				if kind == "acid":
					_damage_enemies_in_radius(pos, 28.0, int(projectile.get("damage", 1)) / 2)
				break
		if remove:
			projectiles.remove_at(i)


func _update_enemy_projectiles(delta: float) -> void:
	var player_rect := Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)
	for i in range(enemy_projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = enemy_projectiles[i]
		var pos: Vector2 = projectile["pos"]
		pos += (projectile["vel"] as Vector2) * delta
		projectile["pos"] = pos
		projectile["life"] = float(projectile.get("life", 0.0)) - delta
		var remove := float(projectile["life"]) <= 0.0
		var tile := _get_tile(floori(pos.x / TILE_SIZE), floori(pos.y / TILE_SIZE))
		if tile != Tile.AIR and tile != Tile.WATER and tile != Tile.LAVA:
			remove = true
		if player_rect.grow(3.0).has_point(pos):
			_damage_player(_incoming_damage(int(projectile.get("damage", 1)), str(projectile.get("damage_type", "physical"))))
			var direction := (projectile["vel"] as Vector2).normalized()
			var special := str(projectile.get("special", ""))
			if special == "harpoon":
				player_velocity += -direction * 180.0 + Vector2(0, -35.0)
			else:
				player_velocity += direction * 95.0 + Vector2(0, -45.0)
			var status := str(projectile.get("status", ""))
			if status != "":
				_apply_player_status(status)
			_spawn_hit_particles(pos, projectile.get("color", Color.WHITE), 4)
			remove = true
		if remove:
			enemy_projectiles.remove_at(i)
		else:
			enemy_projectiles[i] = projectile


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
	_spawn_projectile(player_position + dir * 14.0, dir * 310.0, _total_damage(), "turret", Color("aeefff"), 1.0, "arcane", "")
	_start_attack_animation("turret", dir, Color("aeefff"), 0.18)
	_play_sound("shoot")
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
	mobile_attack_target = target
	mobile_attack_target_valid = use_target
	if use_target and absf(target.x - player_position.x) > 4.0:
		facing = 1 if target.x > player_position.x else -1
	var weapon := equipped_weapon
	if weapon == "":
		_melee_attack(20.0, 5, 0.34)
	elif weapon.contains("sword") or weapon.contains("sickle"):
		_melee_attack(34.0, _total_damage(), 0.38)
	elif weapon.contains("spear"):
		_melee_attack(48.0, _total_damage() + 2, 0.48)
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


func _melee_attack(range_px: float, damage: int, cooldown: float) -> void:
	var center := player_position + Vector2(float(facing) * range_px * 0.6, 0.0)
	var attack_rect := Rect2(center - Vector2(range_px * 0.5, 18.0), Vector2(range_px, 36.0))
	var hit := false
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var size: Vector2 = enemy["size"]
		var enemy_rect := Rect2((enemy["pos"] as Vector2) - size * 0.5, size)
		if attack_rect.intersects(enemy_rect):
			_damage_enemy(i, damage, Vector2(facing, -0.2), _weapon_damage_type(equipped_weapon), _weapon_status(equipped_weapon))
			hit = true
	var weapon := equipped_weapon
	var anim_kind := "spear" if weapon.contains("spear") else "slash"
	_start_attack_animation(anim_kind, Vector2(facing, 0), Color("f0d27a"), cooldown)
	_play_sound("hit")
	attack_cooldown = cooldown
	last_message = "Hit!" if hit else "Swing."


func _fire_projectile_weapon(speed: float, damage: int, kind: String, color: Color, cooldown: float) -> void:
	var aim_position := mobile_attack_target if mobile_attack_target_valid else get_global_mouse_position()
	var aim_dir := aim_position - player_position
	if aim_dir.length() < 8.0:
		aim_dir = Vector2(facing, 0)
	var dir := aim_dir.normalized()
	_spawn_projectile(player_position + dir * 14.0, dir * speed, damage, kind, color, 1.5, _projectile_damage_type(kind), _projectile_status(kind))
	var anim_kind := "bow"
	if kind == "cannon":
		anim_kind = "cannon"
	elif kind == "spark" or kind == "spirit":
		anim_kind = "staff"
	elif kind == "acid":
		anim_kind = "flask"
	_start_attack_animation(anim_kind, dir, color, cooldown)
	_play_sound("shoot")
	attack_cooldown = cooldown
	last_message = "Fired %s." % kind


func _spawn_projectile(pos: Vector2, vel: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String = "physical", status: String = "") -> void:
	projectiles.append({"pos": pos, "vel": vel, "damage": damage, "kind": kind, "color": color, "life": life, "damage_type": damage_type, "status": status})


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
	var final_damage := damage
	if damage_type == "poison":
		final_damage = int(ceil(float(damage) * 0.85))
	elif damage_type == "fire":
		final_damage = int(ceil(float(damage) * 0.95))
	elif damage_type == "arcane":
		final_damage = int(ceil(float(damage) * 1.08))
	if float(enemy.get("guard_time", 0.0)) > 0.0:
		final_damage = maxi(1, int(ceil(float(final_damage) * 0.40)))
	enemy["hp"] = int(enemy.get("hp", 1)) - final_damage
	enemy["hit_timer"] = 0.12
	if status != "":
		_apply_enemy_status(enemy, status)
	var enemy_pos: Vector2 = enemy["pos"]
	_spawn_damage_number(enemy_pos + Vector2(0, -18), final_damage, _damage_color(damage_type))
	_spawn_hit_particles(enemy_pos, Color("ffd18a"), 5)
	_play_sound("hit")
	var vel: Vector2 = enemy["vel"]
	vel += knockback * 150.0
	enemy["vel"] = vel
	enemy["stun_timer"] = 0.15
	if int(enemy.get("hp", 1)) <= 0:
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
		var pos: Vector2 = enemy["pos"]
		if pos.distance_to(center) <= radius:
			_damage_enemy(i, damage, (pos - center).normalized())


func _kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy: Dictionary = enemies[index]
	var drop := str(enemy.get("drop", "wild_ichor"))
	var pos: Vector2 = enemy["pos"]
	var enemy_type := str(enemy.get("type", ""))
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
	else:
		defeated_enemies += 1
		_spawn_loot(pos, drop, 1)
		if rng.randf() < 0.16:
			_spawn_loot(pos + Vector2(8, -6), "memory_shard", 1)
		last_message = "Defeated %s. Dropped %s." % [str(enemy.get("name", "enemy")), _item_display_name(drop)]
	_spawn_hit_particles(pos, Color("f2d38b"), 9)
	var corpse := enemy.duplicate(true)
	corpse["death_time"] = 0.36
	corpse["death_total"] = 0.36
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
		"pickup_delay": pickup_delay
	})


func _update_world_loot_and_fx(delta: float) -> void:
	_update_dropped_items(delta)
	_update_damage_numbers(delta)
	_update_hit_particles(delta)


func _update_dropped_items(delta: float) -> void:
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
			var picked_id := str(item.get("id", ""))
			var picked_amount := int(item.get("amount", 1))
			_add_item(picked_id, picked_amount)
			_add_loot_notification(picked_id, picked_amount)
			_play_sound("pickup")
			last_message = "Picked up %s x%d." % [_item_display_name(picked_id), picked_amount]
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


func _spawn_damage_number(pos: Vector2, amount: int, color: Color) -> void:
	damage_numbers.append({
		"text": str(amount),
		"pos": pos,
		"vel": Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-58.0, -42.0)),
		"life": 0.75,
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
	loot_notifications.push_front({"text": "+ %s x%d" % [_item_display_name(item_id), amount], "life": 2.5})
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
		if i < loot_notifications.size():
			var note: Dictionary = loot_notifications[i]
			var alpha := clampf(float(note.get("life", 0.0)) / 2.5, 0.0, 1.0)
			label.text = str(note.get("text", ""))
			label.modulate = Color(1.0, 0.92, 0.58, alpha)
		else:
			label.text = ""


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


func _spawn_hit_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var dir := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		hit_particles.append({
			"pos": pos + dir * rng.randf_range(0.0, 8.0),
			"vel": dir * rng.randf_range(35.0, 115.0),
			"life": rng.randf_range(0.22, 0.48),
			"color": color
		})


func _update_hit_particles(delta: float) -> void:
	for i in range(hit_particles.size() - 1, -1, -1):
		var particle: Dictionary = hit_particles[i]
		var pos: Vector2 = particle["pos"]
		var vel: Vector2 = particle["vel"]
		pos += vel * delta
		vel *= 0.88
		particle["pos"] = pos
		particle["vel"] = vel
		particle["life"] = float(particle.get("life", 0.0)) - delta
		if float(particle["life"]) <= 0.0:
			hit_particles.remove_at(i)


func _nearest_enemy_index(origin: Vector2, max_distance: float) -> int:
	var best_index := -1
	var best_distance := max_distance
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var pos: Vector2 = enemy["pos"]
		var distance := pos.distance_to(origin)
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
		player_velocity.x = 0.0
		return

	if motion.y != 0.0:
		while absf(motion.y) > 0.5:
			var step := Vector2(0.0, signf(motion.y))
			var stepped_rect := Rect2(player_position + step - PLAYER_SIZE * 0.5, PLAYER_SIZE)
			if _rect_collides(stepped_rect):
				if motion.y > 0.0:
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


func _is_on_floor() -> bool:
	var foot_rect := Rect2(
		Vector2(player_position.x - PLAYER_SIZE.x * 0.5 + 2.0, player_position.y + PLAYER_SIZE.y * 0.5),
		Vector2(PLAYER_SIZE.x - 4.0, 2.0)
	)
	return _rect_collides(foot_rect)


func _handle_block_actions() -> void:
	if inventory_open or full_map_open:
		mining_progress = 0.0
		mining_target = Vector2i(-999, -999)
		return
	# Keep our own mouse state in addition to the InputMap action. This avoids
	# losing a held left click if the action map is not refreshed correctly.
	var is_mining := mouse_mine_held or Input.is_action_pressed("mine")
	if is_mining:
		# Keep the initial block until the button is released. Camera movement or
		# a one-pixel mouse wobble must not cancel a nearly completed block.
		if mining_target.x < 0:
			mining_target = _mouse_tile()
			mining_progress = 0.0
		_mine_target_tile(mining_target)
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

	var hardness := float(tile_hardness.get(tile, 0.4))
	mining_progress += get_process_delta_time() * _tool_speed()
	if mining_progress < hardness:
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
	_start_attack_animation("slash", direction, Color("d9b969"), 0.18)


func _is_tree_base(tile_pos: Vector2i) -> bool:
	if _get_tile(tile_pos.x, tile_pos.y) != Tile.WOOD:
		return false
	var below := _get_tile(tile_pos.x, tile_pos.y + 1)
	if below == Tile.WOOD or below == Tile.LEAVES:
		return false
	return below == Tile.GRASS or below == Tile.DIRT or below == Tile.MOSS or below == Tile.ROOT or below == Tile.STONE


func _fell_tree_from(base_pos: Vector2i) -> void:
	# Wood is traversed separately from leaves. The old mixed BFS could travel
	# through touching leaf canopies and cut several nearby trees at once.
	const TREE_RADIUS_X := 18
	const TREE_HEIGHT := 30
	var wood_queue: Array[Vector2i] = [base_pos]
	var wood_visited := {}
	var owned_wood: Array[Vector2i] = []
	var removed_wood := 0
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
		# Never cross into the base of another tree.
		if current != base_pos and _is_tree_base(current):
			continue
		owned_wood.append(current)
		removed_wood += 1
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
	var removed_leaves := 0
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
		removed_leaves += 1
		_set_tile(current.x, current.y, Tile.AIR)
		# Leaves may connect to more leaves, but never back into another wood trunk.
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			leaf_queue.append(current + offset)
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
	if not _can_interact(tile_pos):
		return
	if _get_tile(tile_pos.x, tile_pos.y) == Tile.STONE_ALTAR:
		_activate_stone_altar(tile_pos)
		return
	if _get_tile(tile_pos.x, tile_pos.y) == Tile.CHEST:
		_open_chest(tile_pos)
		return
	if _get_tile(tile_pos.x, tile_pos.y) != Tile.AIR:
		return
	var item_id := _selected_item()
	if not item_to_tile.has(item_id):
		return
	if int(inventory.get(item_id, 0)) <= 0:
		return
	var tile := int(item_to_tile[item_id])
	if tile == Tile.SAPLING:
		var ground := _get_tile(tile_pos.x, tile_pos.y + 1)
		if ground != Tile.GRASS and ground != Tile.DIRT and ground != Tile.MOSS:
			last_message = "Saplings need grass, dirt, or moss below."
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
	inventory[item_id] = int(inventory[item_id]) - 1
	selected_block = tile
	_set_tile(tile_pos.x, tile_pos.y, tile)
	if tile == Tile.CHEST:
		chest_loot[_tile_key(tile_pos)] = {}


func _open_chest(tile_pos: Vector2i) -> void:
	var key := _tile_key(tile_pos)
	if not chest_loot.has(key):
		chest_loot[key] = {}
	active_chest_key = key
	active_chest_pos = tile_pos
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


func _on_hotbar_slot_pressed(index: int) -> void:
	if held_item_id != "":
		return
	selected_slot = clampi(index, 0, hotbar.size() - 1)
	_update_selection_from_hotbar()


func _on_hotbar_slot_gui_input(event: InputEvent, index: int) -> void:
	if not inventory_open or held_item_id == "":
		return
	if event is InputEventMouseButton and not event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_drop_held_item_on_hotbar(index)
			get_viewport().set_input_as_handled()


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
	var loot: Dictionary = chest_loot[active_chest_key]
	var available := int(loot.get(item_id, 0))
	var taken := clampi(amount, 1, available)
	loot[item_id] = available - taken
	if int(loot.get(item_id, 0)) <= 0:
		loot.erase(item_id)
	chest_loot[active_chest_key] = loot
	held_item_id = item_id
	held_item_amount = taken
	last_message = "Dragging %s x%d from chest." % [_item_display_name(item_id), taken]


func _transfer_chest_stack_to_inventory(item_id: String) -> void:
	if active_chest_key == "" or not chest_loot.has(active_chest_key):
		return
	var loot: Dictionary = chest_loot[active_chest_key]
	var amount := int(loot.get(item_id, 0))
	if amount <= 0:
		return
	_add_item(item_id, amount)
	loot.erase(item_id)
	chest_loot[active_chest_key] = loot
	selected_inventory_item_id = item_id
	_add_loot_notification(item_id, amount)
	_play_sound("pickup")
	last_message = "Took %s x%d from chest." % [_item_display_name(item_id), amount]


func _drop_inventory_item_to_world(item_id: String, amount: int) -> void:
	var available := int(inventory.get(item_id, 0))
	if available <= 0:
		return
	var dropped := clampi(amount, 1, available)
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
	var loot: Dictionary = chest_loot.get(active_chest_key, {})
	loot[held_item_id] = int(loot.get(held_item_id, 0)) + held_item_amount
	chest_loot[active_chest_key] = loot
	last_message = "Stored %s x%d." % [_item_display_name(held_item_id), held_item_amount]
	held_item_id = ""
	held_item_amount = 0


func _throw_held_item_into_world() -> void:
	if held_item_id == "":
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
	inventory[item_id] = int(inventory.get(item_id, 0)) - 1
	if int(inventory.get(item_id, 0)) <= 0:
		inventory.erase(item_id)
		selected_inventory_item_id = ""
	var drop_pos := player_position + Vector2(float(facing) * 18.0, -6.0)
	var drop_vel := Vector2(float(facing) * 55.0, -45.0)
	_spawn_loot_with_velocity(drop_pos, item_id, 1, drop_vel, 0.75)
	last_message = "Dropped %s." % _item_display_name(item_id)


func _inventory_item_ids() -> Array[String]:
	var keys: Array[String] = []
	for item_id in inventory.keys():
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
	if recipes.is_empty():
		return
	selected_recipe_index = wrapi(selected_recipe_index + direction, 0, recipes.size())


func _on_recipe_button_pressed(index: int) -> void:
	selected_recipe_index = clampi(index, 0, recipes.size() - 1)
	_update_hud()


func _craft_selected_recipe() -> void:
	if recipes.is_empty():
		return
	var recipe: Dictionary = recipes[selected_recipe_index]
	var station := str(recipe.get("station", "hand"))
	if not _has_station_nearby(station):
		last_message = "Need nearby station: %s." % _station_display_name(station)
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
	selected_recipe_index = clampi(selected_recipe_index, 0, recipes.size() - 1)
	return recipes[selected_recipe_index]


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
	return float(tool.get("speed", 1.0))


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
	camera.position = player_position


func _adjust_camera_zoom(delta_zoom: float) -> void:
	if camera == null:
		return
	var next_zoom := clampf(camera.zoom.x + delta_zoom, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)


func _save_game() -> void:
	var data := {
		"seed": seed,
		"world": world,
		"surface_heights": surface_heights,
		"chest_loot": chest_loot,
		"explored_tiles": Marshalls.raw_to_base64(explored_tiles),
		"player_position": [player_position.x, player_position.y],
		"health": health,
		"oxygen": oxygen,
		"inventory": inventory,
		"hotbar": hotbar,
		"selected_slot": selected_slot,
		"current_tool": current_tool,
		"selected_recipe_index": selected_recipe_index,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"active_class": active_class,
		"world_time": world_time,
		"defeated_enemies": defeated_enemies,
		"boss_spawned": boss_spawned,
		"boss_defeated": boss_defeated,
		"stone_broken_count": stone_broken_count,
		"stone_beast_spawned": stone_beast_spawned,
		"stone_beast_defeated": stone_beast_defeated,
		"mushroom_path_opened": mushroom_path_opened
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	seed = int(data.get("seed", seed))
	world = data.get("world", world)
	world_map_dirty = true
	if world.size() != WORLD_HEIGHT or world.is_empty() or (world[0] as Array).size() != WORLD_WIDTH:
		_generate_world()
		last_message = "Old save used a different world size. A new liquid world was generated."
		return
	chest_loot = data.get("chest_loot", {})
	var loaded_heights: Array = data.get("surface_heights", surface_heights)
	surface_heights.clear()
	for h in loaded_heights:
		surface_heights.append(int(h))
	var loaded_position: Array = data.get("player_position", [player_position.x, player_position.y])
	if loaded_position.size() >= 2:
		player_position = Vector2(float(loaded_position[0]), float(loaded_position[1]))
	var saved_exploration := str(data.get("explored_tiles", ""))
	var loaded_exploration := Marshalls.base64_to_raw(saved_exploration) if not saved_exploration.is_empty() else PackedByteArray()
	if loaded_exploration.size() == WORLD_WIDTH * WORLD_HEIGHT:
		explored_tiles = loaded_exploration
		last_explored_tile = Vector2i(-999, -999)
	else:
		_reset_exploration()
	_reveal_player_surroundings()
	player_velocity = Vector2.ZERO
	player_statuses.clear()
	health = clampi(int(data.get("health", MAX_HEALTH)), 1, MAX_HEALTH)
	oxygen = clampf(float(data.get("oxygen", MAX_OXYGEN)), 0.0, MAX_OXYGEN)
	drowning_tick = 0.0
	lava_tick = 0.0
	liquid_flow_timer = 0.0
	liquid_flow_phase = 0
	inventory = data.get("inventory", inventory)
	hotbar = data.get("hotbar", hotbar)
	selected_slot = clampi(int(data.get("selected_slot", 0)), 0, hotbar.size() - 1)
	current_tool = str(data.get("current_tool", "wooden_pickaxe"))
	selected_recipe_index = clampi(int(data.get("selected_recipe_index", 0)), 0, recipes.size() - 1)
	equipped_weapon = str(data.get("equipped_weapon", ""))
	equipped_armor = str(data.get("equipped_armor", ""))
	equipped_accessory = str(data.get("equipped_accessory", ""))
	selected_inventory_item_id = ""
	active_class = str(data.get("active_class", active_class))
	world_time = float(data.get("world_time", world_time))
	defeated_enemies = int(data.get("defeated_enemies", defeated_enemies))
	boss_spawned = bool(data.get("boss_spawned", boss_spawned))
	boss_defeated = bool(data.get("boss_defeated", boss_defeated))
	stone_broken_count = int(data.get("stone_broken_count", stone_broken_count))
	stone_beast_spawned = bool(data.get("stone_beast_spawned", stone_beast_spawned))
	stone_beast_defeated = bool(data.get("stone_beast_defeated", stone_beast_defeated))
	mushroom_path_opened = bool(data.get("mushroom_path_opened", mushroom_path_opened))
	_rebuild_sapling_positions()
	cached_biome = _compute_current_biome()
	biome_check_timer = 0.0
	hud_update_timer = 0.0
	enemies.clear()
	dying_enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	dropped_items.clear()
	damage_numbers.clear()
	hit_particles.clear()
	loot_notifications.clear()
	attack_anim_time = 0.0
	attack_anim_kind = ""
	held_item_id = ""
	held_item_amount = 0
	_update_selection_from_hotbar()
	_update_camera()
	_update_minimap(999.0)
	_update_hud()


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
		mine_percent = int(clampf(mining_progress / float(tile_hardness.get(tile, 1.0)), 0.0, 1.0) * 100.0)
	var recipe := _selected_recipe()
	var result := str(recipe.get("result", ""))
	var station := str(recipe.get("station", "hand"))

	var biome := _current_biome()
	# Only actual information remains on screen; empty status-effect markers are hidden.
	hud_label.text = "%d / %d" % [health, MAX_HEALTH]
	hud_health_bar.value = health
	hud_armor_value.text = "ARMOR  %d" % _total_defense()
	hud_status_label.text = _format_player_statuses().strip_edges()
	var show_oxygen := oxygen < MAX_OXYGEN - 0.5 or _player_overlaps_tile(Tile.WATER)
	oxygen_panel.visible = show_oxygen
	if show_oxygen:
		oxygen_bar.value = oxygen
		oxygen_value.text = "%d%%" % int(round(oxygen))
	minimap_time_label.text = _time_period_text().to_upper()
	minimap_biome_label.text = _biome_display_name(biome).to_upper()
	var prompt := ""
	if not inventory_open and not full_map_open and _can_interact(tile_pos):
		if tile == Tile.CHEST:
			prompt = "RMB  OPEN ANCIENT CHEST"
		elif tile == Tile.STONE_ALTAR:
			prompt = "RMB  AWAKEN ALTAR"
	context_hint_panel.visible = prompt != ""
	context_hint_label.text = prompt
	_update_hotbar_buttons()
	var chest_open := inventory_open and active_chest_key != ""
	inventory_backdrop.visible = inventory_open
	equipment_overlay.visible = inventory_open
	inventory_panel.visible = inventory_open
	# The chest deliberately takes the crafting column instead of overlapping it.
	crafting_panel.visible = inventory_open and not chest_open
	chest_panel.visible = chest_open
	_update_mobile_controls_visibility()
	if minimap_panel != null:
		minimap_panel.visible = not chest_panel.visible and not full_map_open
	if not inventory_open:
		return

	_update_inventory_buttons()
	_update_chest_buttons()
	_update_equipment_buttons()
	_update_recipe_buttons()
	inventory_title_label.text = "BACKPACK"
	equipment_label.text = "EQUIPPED"
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
		if str(data.get("type", "")) == "heartwood_boss" or str(data.get("type", "")) == "stone_beast":
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


func _format_oxygen_status() -> String:
	if oxygen >= MAX_OXYGEN - 0.5 and not _player_overlaps_tile(Tile.WATER):
		return ""
	return " | AIR %d%%" % int(round(oxygen))


func _biome_display_name(biome: String) -> String:
	if biome == "forest":
		return "Forest"
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


func _format_selected_inventory_item() -> String:
	if held_item_id != "":
		return "Dragging: %s x%d\nRelease over hotbar/equipment/inventory, or outside menu to drop. Right-click a stack to take half." % [_item_display_name(held_item_id), held_item_amount]
	if selected_inventory_item_id == "" or int(inventory.get(selected_inventory_item_id, 0)) <= 0:
		return "Selected item: none\nLeft-drag a stack. Right-drag takes half."
	var parts := ["Selected: %s x%d" % [_item_display_name(selected_inventory_item_id), int(inventory.get(selected_inventory_item_id, 0))]]
	if tools.has(selected_inventory_item_id):
		var tool: Dictionary = tools[selected_inventory_item_id]
		parts.append("Tool power %d | speed %.2f" % [int(tool.get("power", 1)), float(tool.get("speed", 1.0))])
	elif gear_stats.has(selected_inventory_item_id):
		var gear: Dictionary = gear_stats[selected_inventory_item_id]
		parts.append("%s | class %s | damage +%d | defense +%d" % [
			str(gear.get("slot", "gear")).capitalize(),
			str(gear.get("class", "Any")),
			int(gear.get("damage", 0)),
			int(gear.get("defense", 0))
		])
		if bool(gear.get("water_breathing", false)):
			parts.append("Allows breathing underwater")
		if bool(gear.get("heat_resistance", false)):
			parts.append("Greatly reduces lava damage")
	elif item_to_tile.has(selected_inventory_item_id):
		parts.append("Placeable block")
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
	for i in range(hotbar_buttons.size()):
		var item_id := str(hotbar[i])
		var selected := i == selected_slot
		_configure_slot_button(hotbar_buttons[i], item_id, int(inventory.get(item_id, 0)), selected, str(i + 1))
		_apply_compass_hotbar_slot_style(hotbar_buttons[i], selected)


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
	weapon_slot_button.tooltip_text = "Weapon: %s" % _empty_name(equipped_weapon)
	_configure_slot_button(armor_slot_button, equipped_armor, int(inventory.get(equipped_armor, 1)), false, "")
	_apply_compass_inventory_slot_style(armor_slot_button, equipped_armor != "", true)
	armor_slot_button.disabled = true
	armor_slot_button.tooltip_text = "Armor: %s" % _empty_name(equipped_armor)
	_configure_slot_button(accessory_slot_button, equipped_accessory, int(inventory.get(equipped_accessory, 1)), false, "")
	_apply_compass_inventory_slot_style(accessory_slot_button, equipped_accessory != "", true)
	accessory_slot_button.disabled = true
	accessory_slot_button.tooltip_text = "Charm: %s" % _empty_name(equipped_accessory)


func _update_recipe_buttons() -> void:
	for i in range(recipe_buttons.size()):
		var button := recipe_buttons[i]
		if i >= recipes.size():
			button.visible = false
			continue
		button.visible = true
		var recipe: Dictionary = recipes[i]
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2a3229", 0.96) if selected else Color("1b201c", 0.92)
	style.border_color = Color("d9b969") if selected else (Color("8fc47f") if ready else Color("806043"))
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("344035", 0.98)
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
	button.tooltip_text = "%s x%d" % [_item_display_name(item_id), amount]


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
	elif item_id.contains("bar"):
		_icon_rect(image, 5, 9, 14, 7, main)
		_icon_rect(image, 7, 7, 10, 3, light)
	elif item_id.contains("ore") or item_id in ["ash", "root", "stone", "ruin_brick", "memory_shard", "spark_shard", "root_core", "ash_glass"]:
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
	if item_id.contains("wood") or item_id == "workbench":
		return Color("a66a35")
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
	if biome == "forest":
		return Color("172b2a")
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
	if biome == "forest":
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
	visible_light_sources.clear()
	visible_light_sources.append({
		"pos": player_position / TILE_SIZE,
		"radius": 7.0,
		"intensity": 0.95
	})
	var view_rect := get_viewport_rect()
	var center := camera.get_screen_center_position()
	var half_size := view_rect.size * 0.5 / camera.zoom
	var light_padding := 13
	var min_x := clampi(floori((center.x - half_size.x) / TILE_SIZE) - light_padding, 0, WORLD_WIDTH - 1)
	var max_x := clampi(ceili((center.x + half_size.x) / TILE_SIZE) + light_padding, 0, WORLD_WIDTH - 1)
	var min_y := clampi(floori((center.y - half_size.y) / TILE_SIZE) - light_padding, 0, WORLD_HEIGHT - 1)
	var max_y := clampi(ceili((center.y + half_size.y) / TILE_SIZE) + light_padding, 0, WORLD_HEIGHT - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile := _get_tile(x, y)
			var radius := 0.0
			var intensity := 1.0
			if tile == Tile.TORCH:
				radius = 12.0
			elif tile == Tile.LAVA:
				radius = 9.0
				intensity = 0.92
			elif tile == Tile.GLOW_MUSHROOM:
				radius = 7.0
				intensity = 0.82
			elif tile == Tile.ABYSS_CRYSTAL:
				radius = 6.0
				intensity = 0.72
			if radius > 0.0:
				visible_light_sources.append({
					"pos": Vector2(x + 0.5, y + 0.5),
					"radius": radius,
					"intensity": intensity
				})


func _tile_texture_at(tile: int, x: int, y: int) -> Texture2D:
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


func _draw_liquid_motion(x: int, y: int, tile: int, rect: Rect2) -> void:
	var above_air := _get_tile(x, y - 1) == Tile.AIR
	var time := float(Time.get_ticks_msec()) / 1000.0
	var phase := sin(time * (2.0 if tile == Tile.WATER else 3.4) + float(x) * 0.75)
	if above_air:
		var wave_color := Color("91d7d8", 0.72) if tile == Tile.WATER else Color("ffd05d", 0.82)
		draw_line(rect.position + Vector2(0, 2.0 + phase), rect.position + Vector2(TILE_SIZE, 2.0 - phase), wave_color, 1.0)
	var mark := _visual_hash(x, y, 7)
	if tile == Tile.WATER and mark % 31 == 0:
		draw_circle(rect.position + Vector2(7, 8 + phase * 2.0), 1.0, Color("c9ffff", 0.5))
	elif tile == Tile.LAVA and mark % 29 == 0:
		draw_circle(rect.position + Vector2(8, 8 + phase), 1.0, Color("ffb34d", 0.75))


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
				draw_texture_rect(texture, texture_rect, false, Color.WHITE)
				if tile == Tile.WATER or tile == Tile.LAVA:
					_draw_liquid_motion(x, y, tile, rect)
				if _uses_large_station_sprite(tile):
					_draw_nearby_station_label(tile, rect)
				_draw_exposed_edge_breakup(x, y, tile, rect)
			else:
				draw_rect(rect, base_color)
				draw_rect(rect, base_color.darkened(0.18), false, 1.0)
				_draw_tile_details(rect, tile, base_color)


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


func _draw_nearby_station_label(tile: int, rect: Rect2) -> void:
	if ui_font == null:
		return
	var station_center := rect.position + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	if station_center.distance_to(player_position) > TILE_SIZE * 6.0:
		return
	var label := "ANCIENT CHEST"
	if tile == Tile.WORKBENCH:
		label = "WORKBENCH"
	elif tile == Tile.FURNACE:
		label = "FURNACE"
	elif tile == Tile.ANVIL:
		label = "ANVIL"
	var label_pos := rect.position + Vector2(TILE_SIZE * 0.5, -11)
	draw_line(rect.position + Vector2(3, -4), rect.position + Vector2(TILE_SIZE - 3, -4), Color("d9b969", 0.52), 1.0)
	draw_string(ui_font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, 82.0, 9, Color("e6d6ac"))


func _uses_organic_edges(tile: int) -> bool:
	return tile == Tile.GRASS or tile == Tile.DIRT or tile == Tile.STONE or tile == Tile.COPPER or tile == Tile.IRON or tile == Tile.ASH or tile == Tile.ROOT or tile == Tile.RUIN or tile == Tile.MOSS or tile == Tile.MUSHROOM_SOIL or tile == Tile.ASH_BRICK or tile == Tile.SUNKEN_STONE or tile == Tile.LAVA_ROOT or tile == Tile.GLASS_STONE or tile == Tile.ABYSS_CRYSTAL


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
	for projectile in projectiles:
		var pos: Vector2 = projectile["pos"]
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
		_draw_dying_enemy(corpse)
	for projectile in enemy_projectiles:
		var projectile_pos: Vector2 = projectile["pos"]
		var projectile_color: Color = projectile.get("color", Color.WHITE)
		draw_circle(projectile_pos, 3.0, projectile_color)
		draw_circle(projectile_pos - (projectile["vel"] as Vector2).normalized() * 4.0, 1.5, projectile_color.darkened(0.35))
	for enemy in enemies:
		_draw_enemy(enemy)


func _draw_dying_enemy(corpse: Dictionary) -> void:
	var pos: Vector2 = corpse["pos"]
	var size: Vector2 = corpse["size"]
	var total := maxf(0.01, float(corpse.get("death_total", 0.35)))
	var ratio := clampf(float(corpse.get("death_time", 0.0)) / total, 0.0, 1.0)
	var enemy_type := str(corpse.get("type", "wild_slime"))
	if enemy_textures.has(enemy_type):
		var death_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
		var texture: Texture2D = death_sets.get("death", enemy_textures[enemy_type]) as Texture2D
		var is_strip := death_sets.has("death")
		var frame_count := 6 if is_strip else 4
		var frame_width := maxi(1, int(texture.get_width() / frame_count))
		var frame_height := texture.get_height() if is_strip else maxi(1, int(texture.get_height() / 3))
		var frame_index := mini(frame_count - 1, int(floor((1.0 - ratio) * float(frame_count))))
		var scale := 0.50 if enemy_type not in ["stone_beast", "heartwood_boss"] else 0.72
		var draw_size := Vector2(frame_width, frame_height) * scale
		var local_y := size.y * 0.5 - draw_size.y * ratio
		var fade := Color(1.0, 0.82, 0.72, ratio)
		var facing := int(corpse.get("facing", 1))
		draw_set_transform(pos + Vector2(0, (1.0 - ratio) * size.y * 0.4), 0.0, Vector2(float(facing), ratio))
		draw_texture_rect_region(texture, Rect2(Vector2(-draw_size.x * 0.5, local_y), draw_size), Rect2(frame_index * frame_width, 0, frame_width, frame_height), fade)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	var size: Vector2 = enemy["size"]
	var color: Color = enemy.get("color", Color("ffffff"))
	if float(enemy.get("hit_timer", 0.0)) > 0.0:
		color = Color("fff0d0")
	var rect := Rect2(pos - size * 0.5, size)
	var enemy_type := str(enemy.get("type", "wild_slime"))
	var has_sprite := _draw_enemy_sprite(enemy, enemy_type, pos, size)
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
	var visual_height := _enemy_visual_size(enemy_type).y
	var bar_y := pos.y - maxf(size.y * 0.5 + 6.0, visual_height * 0.5 + 5.0)
	var bar_pos := Vector2(rect.position.x, bar_y)
	draw_rect(Rect2(bar_pos, Vector2(size.x, 3)), Color("1a1012", 0.9))
	draw_rect(Rect2(bar_pos, Vector2(size.x * hp, 3)), Color("d94b52"))
	var statuses: Dictionary = enemy.get("statuses", {})
	var status_x := bar_pos.x
	for status in statuses.keys():
		var status_color := Color("89e36b") if str(status) == "poison" else (Color("ff8a3c") if str(status) == "burn" else Color("9fc5ff"))
		draw_rect(Rect2(Vector2(status_x, bar_pos.y - 4), Vector2(4, 3)), status_color)
		status_x += 5.0


func _draw_enemy_sprite(enemy: Dictionary, enemy_type: String, pos: Vector2, collision_size: Vector2) -> bool:
	if not enemy_textures.has(enemy_type):
		return false
	var animation_state := str(enemy.get("anim_state", "idle"))
	var animation_sets: Dictionary = enemy_animation_textures.get(enemy_type, {})
	var texture: Texture2D = animation_sets.get(animation_state, null)
	var use_action_strip := texture != null
	if texture == null:
		texture = animation_sets.get("idle", enemy_textures[enemy_type]) as Texture2D
	var frame_count := 6 if use_action_strip else 4
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
	if animation_state.begins_with("attack_"):
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
	var local_y := -draw_size.y * 0.5 if flying else collision_size.y * 0.5 - draw_size.y
	var facing := int(enemy.get("facing", 1))
	var flip_scale := Vector2(-1.0, 1.0) if facing < 0 else Vector2.ONE
	var modulate := Color.WHITE
	if float(enemy.get("hit_timer", 0.0)) > 0.0:
		modulate = Color("fff0d0")
	draw_set_transform(pos, 0.0, flip_scale)
	draw_texture_rect_region(texture, Rect2(Vector2(-draw_size.x * 0.5, local_y), draw_size), source_rect, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _enemy_sprite_scale(enemy_type: String) -> float:
	if enemy_type == "stone_beast" or enemy_type == "heartwood_boss":
		return 0.72
	if enemy_type in ["bat", "spore_bat", "ash_wisp", "night_ember"]:
		return 0.44
	if enemy_type in ["cave_worm", "root_crawler"]:
		return 0.56
	return 0.50


func _enemy_visual_size(enemy_type: String) -> Vector2:
	if not enemy_textures.has(enemy_type):
		return Vector2(24, 24)
	var texture: Texture2D = enemy_textures[enemy_type]
	return Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()) / 3.0) * _enemy_sprite_scale(enemy_type)

func _draw_world_loot_and_fx() -> void:
	for item in dropped_items:
		_draw_dropped_item(item)
	for particle in hit_particles:
		var particle_life := clampf(float(particle.get("life", 0.0)) / 0.48, 0.0, 1.0)
		var color: Color = particle.get("color", Color.WHITE)
		color.a = particle_life
		var pos: Vector2 = particle["pos"]
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), color)
	for number in damage_numbers:
		if ui_font == null:
			continue
		var number_life := clampf(float(number.get("life", 0.0)) / 0.75, 0.0, 1.0)
		var color: Color = number.get("color", Color.WHITE)
		color.a = number_life
		var pos: Vector2 = number["pos"]
		draw_string(ui_font, pos, str(number.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 12, color)


func _draw_dropped_item(item: Dictionary) -> void:
	var pos: Vector2 = item["pos"]
	var age := float(item.get("age", 0.0))
	var bob := sin(age * 7.0 + float(item.get("bob", 0.0))) * 2.0
	var draw_pos := pos + Vector2(0, bob)
	var to_player := player_position - pos
	var magnet := clampf(1.0 - to_player.length() / LOOT_MAGNET_RADIUS, 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(-7, 6), Vector2(14, 3)), Color("05070a", 0.22))
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


func _light_at_tile(x: int, y: int) -> float:
	var light := 0.02
	if x >= 0 and x < surface_heights.size() and y <= surface_heights[x] + 2:
		light = maxf(light, _daylight_factor())
	var sample_pos := Vector2(x + 0.5, y + 0.5)
	for source in visible_light_sources:
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
		if radius > 0.0:
			draw_circle(source_pos, radius * 0.65, Color("ffbd68", 0.055))


func _draw_player() -> void:
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
		var percent := int(clampf(mining_progress / float(tile_hardness.get(tile, 1.0)), 0.0, 1.0) * 100.0)
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
	if minimap_timer < 1.0:
		return
	minimap_timer = 0.0

	var local_image := _build_local_minimap_image(MINIMAP_WIDTH, MINIMAP_HEIGHT)
	minimap_rect.texture = ImageTexture.create_from_image(local_image)
	if full_map_open and full_map_rect != null:
		_rebuild_world_map_image()
		var large_image := world_map_image.duplicate()
		_draw_map_player_marker(large_image, 4)
		full_map_rect.texture = ImageTexture.create_from_image(large_image)


func _refresh_map_textures() -> void:
	if world.is_empty():
		return
	var local_image := _build_local_minimap_image(MINIMAP_WIDTH, MINIMAP_HEIGHT)
	if minimap_rect != null:
		minimap_rect.texture = ImageTexture.create_from_image(local_image)
	if full_map_rect != null:
		_rebuild_world_map_image()
		var large_image := world_map_image.duplicate()
		_draw_map_player_marker(large_image, 4)
		full_map_rect.texture = ImageTexture.create_from_image(large_image)


func _build_local_minimap_image(width: int, height: int) -> Image:
	# Show a useful neighborhood around the player instead of shrinking the full world.
	# This covers 68×30 tiles: wider than the visible camera, but still local.
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_x := floori(player_position.x / TILE_SIZE)
	var center_y := floori(player_position.y / TILE_SIZE)
	const VIEW_TILES_X := 68
	const VIEW_TILES_Y := 30
	for py in range(height):
		var world_y := center_y + int(floor((float(py) / float(maxi(1, height - 1)) - 0.5) * float(VIEW_TILES_Y)))
		for px in range(width):
			var world_x := center_x + int(floor((float(px) / float(maxi(1, width - 1)) - 0.5) * float(VIEW_TILES_X)))
			var color := Color("080a0b")
			if _in_bounds(world_x, world_y) and _is_tile_explored(world_x, world_y):
				var tile := _get_tile(world_x, world_y)
				color = Color("10151d") if tile == Tile.AIR else tile_colors.get(tile, Color.WHITE).darkened(0.15)
			image.set_pixel(px, py, color)
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


func _set_tile(x: int, y: int, tile: int) -> void:
	if _in_bounds(x, y):
		var key := "%d,%d" % [x, y]
		if int(world[y][x]) == Tile.SAPLING and tile != Tile.SAPLING:
			sapling_positions.erase(key)
		world[y][x] = tile
		world_map_dirty = true
		if tile == Tile.SAPLING:
			sapling_positions[key] = Vector2i(x, y)


func _is_solid(x: int, y: int) -> bool:
	if not _in_bounds(x, y):
		return true
	return bool(solid_tiles.get(_get_tile(x, y), false))


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < WORLD_WIDTH and y < WORLD_HEIGHT
