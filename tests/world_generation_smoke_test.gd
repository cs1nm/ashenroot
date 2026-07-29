extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_finite_liquid_flow()
	_test_water_lava_reaction()
	await _test_generated_world()
	if failed:
		quit(1)
		return
	print("WORLD_GENERATION_OK")
	quit()


func _test_finite_liquid_flow() -> void:
	var world := _make_test_world(7, 7, 3)
	world[1][3] = 1
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	for step in range(4):
		sim.process(0.11, world, 3, 3, {3: true})
	_require(_count_tile(world, 1) == 1, "Water volume changed while flowing")
	var lowest_water_y := -1
	for y in range(world.size()):
		if int(world[y][3]) == 1:
			lowest_water_y = y
	_require(lowest_water_y >= 4, "Water did not flow down under gravity")


func _test_water_lava_reaction() -> void:
	var world := _make_test_world(5, 5, 3)
	world[2][2] = 1
	world[3][2] = 2
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	sim.process(0.11, world, 2, 2, {3: true})
	_require(int(world[2][2]) == 3 and int(world[3][2]) == 3, "Water and lava did not solidify on contact")


func _test_generated_world() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_require(game.world.size() == game.WORLD_HEIGHT, "Generated world height is invalid")
	_require(game.world[0].size() == game.WORLD_WIDTH, "Generated world width is invalid")
	var density_ratio := float(game.WORLD_WIDTH) / 560.0
	var chest_count := _count_tile(game.world, game.Tile.CHEST)
	_require(chest_count >= int(16.0 * density_ratio), "Generated world has too few structure and cave chests")
	_require(chest_count <= int(48.0 * density_ratio), "Generated world still has too many chests")
	_test_surface_biomes(game)
	_require(_all_chests_are_grounded(game), "Generated world contains a floating chest")
	_require(_surface_chest_count(game) == 0, "Generated world contains a loose surface chest")
	_test_chest_settling(game)
	_require(_count_tile(game.world, game.Tile.WATER) > 0, "Generated world has no water")
	_require(_count_tile(game.world, game.Tile.LAVA) > 0, "Generated world has no lava")
	_require(_count_tile(game.world, game.Tile.BUBBLE_VENT) > 0, "Flooded cistern landmark was not generated")
	_require(_count_tile(game.world, game.Tile.DRAIN_VALVE) > 0, "Cistern drain landmark was not generated")
	game.queue_free()
	await process_frame


func _test_surface_biomes(game: Variant) -> void:
	_require(game.surface_biomes.size() == game.WORLD_WIDTH, "Surface biome map does not cover the full world width")
	var distinct := {}
	var band_runs := 0
	var previous := ""
	for biome_variant in game.surface_biomes:
		var biome := str(biome_variant)
		distinct[biome] = true
		if biome != previous:
			band_runs += 1
			previous = biome
	_require(distinct.size() == 5, "Not every surface biome type was generated")
	_require(band_runs >= 6, "Surface biome bands are too small or too few")
	var spawn_x := int(game.WORLD_WIDTH / 2)
	_require(str(game.surface_biomes[spawn_x]) == "forest", "Spawn column is not inside the forest biome")
	# Biomes own their topsoil below the first row, not only the surface tint.
	_require(_topsoil_matches(game, "ash_desert", game.Tile.ASH_SAND), "Ash desert lacks its ash sand surface")
	_require(_topsoil_matches(game, "ash_desert", game.Tile.ASH_SAND, 3), "Ash desert ash sand is not deep enough")
	_require(_topsoil_matches(game, "frost_wasteland", game.Tile.SNOW_BLOCK), "Frost wasteland lacks its snow surface")
	_require(_topsoil_matches(game, "frost_wasteland", game.Tile.FROZEN_DIRT, 1), "Frost wasteland lacks its frozen dirt topsoil")
	_require(_topsoil_matches(game, "marsh", game.Tile.MUD, 1), "Marsh lacks its mud topsoil")
	_require(_topsoil_matches(game, "ash_ruins", game.Tile.RUBBLE, 1), "Ash ruins lack their rubble topsoil")
	_require(_topsoil_matches(game, "forest", game.Tile.DIRT, 1), "Forest lacks its dirt topsoil")


func _topsoil_matches(game: Variant, biome: String, expected_tile: int, depth: int = 0) -> bool:
	var checked := 0
	for x in range(game.WORLD_WIDTH):
		if str(game.surface_biomes[x]) != biome:
			continue
		var surface_y := int(game.surface_heights[x])
		var surface_tile := int(game.world[surface_y][x])
		# Skip pond, moss rim and otherwise disturbed columns; this checks the
		# generator's base terrain rule, not later decorative passes.
		if surface_tile != game.Tile.GRASS and surface_tile != game.Tile.SNOW_BLOCK and surface_tile != game.Tile.ASH_SAND:
			continue
		if int(game.world[surface_y + depth][x]) != expected_tile:
			return false
		checked += 1
		if checked >= 12:
			break
	return checked > 0


func _all_chests_are_grounded(game: Variant) -> bool:
	for y in range(game.WORLD_HEIGHT - 1):
		for x in range(game.WORLD_WIDTH):
			if int(game.world[y][x]) == game.Tile.CHEST and not game._is_solid(x, y + 1):
				return false
	return true


func _surface_chest_count(game: Variant) -> int:
	var count := 0
	for x in range(game.WORLD_WIDTH):
		var surface_y := int(game.surface_heights[x])
		for y in range(maxi(0, surface_y - 4), mini(game.WORLD_HEIGHT, surface_y + 8)):
			if int(game.world[y][x]) == game.Tile.CHEST:
				count += 1
	return count


func _test_chest_settling(game: Variant) -> void:
	var chest_pos := Vector2i(3, 3)
	var landing_pos := chest_pos + Vector2i(0, 1)
	game._set_tile(chest_pos.x, chest_pos.y, game.Tile.CHEST)
	game._set_tile(landing_pos.x, landing_pos.y, game.Tile.AIR)
	game._set_tile(landing_pos.x, landing_pos.y + 1, game.Tile.STONE)
	var old_key: String = game._tile_key(chest_pos)
	var new_key: String = game._tile_key(landing_pos)
	game.chest_loot[old_key] = {"torch": 2}
	game._settle_unsupported_chest(chest_pos)
	_require(int(game.world[landing_pos.y][landing_pos.x]) == game.Tile.CHEST, "Unsupported chest did not settle onto the floor")
	_require(not game.chest_loot.has(old_key) and int(game.chest_loot.get(new_key, {}).get("torch", 0)) == 2, "Settled chest lost its stored loot")


func _make_test_world(width: int, height: int, solid_tile: int) -> Array:
	var world: Array = []
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			row.append(solid_tile if y == height - 1 else 0)
		world.append(row)
	return world


func _count_tile(world: Array, target_tile: int) -> int:
	var count := 0
	for row in world:
		for tile in row:
			if int(tile) == target_tile:
				count += 1
	return count


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
