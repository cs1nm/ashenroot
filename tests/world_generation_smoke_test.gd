extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_finite_liquid_flow()
	_test_water_lava_reaction()
	_test_partial_fill_levels()
	_test_pool_settles_without_jitter()
	_test_multiple_liquid_centers()
	_test_liquid_level_serialization()
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


func _test_partial_fill_levels() -> void:
	var world := _make_test_world(7, 7, 3)
	world[1][3] = 1
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	_require(sim.get_level(3, 1) == sim.LEVEL_MAX, "A fresh liquid tile is not full")
	var saw_runtime_changes := false
	for step in range(6):
		sim.process(0.11, world, 3, 3, {3: true})
		if not sim.consume_state_changes(world).is_empty():
			saw_runtime_changes = true
	var total_level := 0
	for y in range(world.size()):
		for x in range(world[y].size()):
			if int(world[y][x]) == 1:
				total_level += sim.get_level(x, y)
	_require(total_level == sim.LEVEL_MAX, "Partial flow changed total liquid volume")
	_require(sim.get_level(0, 0) == 0, "An empty tile reports a fill level")
	_require(saw_runtime_changes, "Liquid simulation did not expose runtime state changes")


func _test_pool_settles_without_jitter() -> void:
	var width := 12
	var height := 8
	var world := _make_test_world(width, height, 3)
	for x in range(width):
		world[height - 1][x] = 3
	for y in range(height - 4, height - 1):
		for x in range(1, width - 1):
			world[y][x] = 1
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	var water_before := _liquid_volume(world, sim, 1)
	var quiet_steps := 0
	for step in range(60):
		if sim.process(0.11, world, width / 2, height - 2, {3: true}) == 0:
			quiet_steps += 1
			if quiet_steps >= 3:
				break
		else:
			quiet_steps = 0
	_require(quiet_steps >= 3, "Pool never stopped moving; liquids still jitter")
	_require(_liquid_volume(world, sim, 1) == water_before, "Settled pool changed its water volume")


func _test_multiple_liquid_centers() -> void:
	var world := _make_test_world(120, 7, 3)
	world[1][10] = 1
	world[1][105] = 1
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	var centers: Array[Vector2i] = [Vector2i(10, 2), Vector2i(105, 2)]
	sim.process_centers(0.11, world, centers, {3: true})
	_require(int(world[2][10]) == 1, "Liquid near the first multiplayer center did not update")
	_require(int(world[2][105]) == 1, "Liquid near the second multiplayer center did not update")


func _test_liquid_level_serialization() -> void:
	var world := _make_test_world(5, 5, 3)
	world[2][2] = 1
	world[2][3] = 1
	var sim := LiquidSim.new()
	sim.setup(1, 2, 0, 3)
	sim.rebuild(world)
	sim.set_level(2, 2, 3)
	var saved: Dictionary = sim.serialize_levels()
	_require(saved.size() == 1 and int(saved.get("2,2", 0)) == 3, "Save did not compact partial liquid levels")
	var restored := LiquidSim.new()
	restored.setup(1, 2, 0, 3)
	restored.rebuild(world)
	restored.restore_levels(saved)
	_require(restored.get_level(2, 2) == 3, "Partial liquid level did not survive restore")
	_require(restored.get_level(3, 2) == restored.LEVEL_MAX, "Full liquid tile did not keep its implicit level")


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
	_test_game_liquid_save(game)
	_require(_count_tile(game.world, game.Tile.BUBBLE_VENT) > 0, "Flooded cistern landmark was not generated")
	_require(_count_tile(game.world, game.Tile.DRAIN_VALVE) > 0, "Cistern drain landmark was not generated")
	game.queue_free()
	await process_frame


func _test_game_liquid_save(game: Variant) -> void:
	var water_pos := Vector2i(-1, -1)
	for y in range(game.WORLD_HEIGHT):
		for x in range(game.WORLD_WIDTH):
			if int(game.world[y][x]) == game.Tile.WATER:
				water_pos = Vector2i(x, y)
				break
		if water_pos.x >= 0:
			break
	_require(water_pos.x >= 0, "Could not find water for save-level test")
	if water_pos.x < 0:
		return
	game.liquid_sim.set_level(water_pos.x, water_pos.y, 3)
	var surface_rect: Rect2 = game._liquid_surface_rect(water_pos.x, water_pos.y, Rect2(0, 0, game.TILE_SIZE, game.TILE_SIZE))
	_require(is_equal_approx(surface_rect.size.y, 6.0) and is_equal_approx(surface_rect.position.y, 10.0), "Partial liquid render rect has the wrong height")
	var fill_top: float = float(water_pos.y + 1) * game.TILE_SIZE - surface_rect.size.y
	game.player_position = Vector2(
		float(water_pos.x) * game.TILE_SIZE + game.TILE_SIZE * 0.5,
		fill_top - 1.0 + game.PLAYER_SIZE.y * 0.38
	)
	_require(not game._player_head_submerged(), "Player drowns above a partial waterline")
	game.player_position.y += 2.0
	_require(game._player_head_submerged(), "Player can breathe below a partial waterline")
	var data: Dictionary = game._build_save_data()
	var level_key := "%d,%d" % [water_pos.x, water_pos.y]
	_require(int((data.get("liquid_levels", {}) as Dictionary).get(level_key, 0)) == 3, "World save omitted a partial liquid level")
	var network_data: Dictionary = game._build_network_world_data()
	_require(int((network_data.get("liquid_levels", {}) as Dictionary).get(level_key, 0)) == 3, "Network world snapshot omitted a partial liquid level")
	game.liquid_sim.set_level(water_pos.x, water_pos.y, game.liquid_sim.LEVEL_MAX)
	game._apply_save_data(data)
	_require(game.liquid_sim.get_level(water_pos.x, water_pos.y) == 3, "World load did not restore a partial liquid level")


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
	_require(_border_metadata_is_sane(game), "Surface biome border metadata does not match the biome map")
	_require(_border_blend_mixes_biomes(game), "Surface biome borders are hard lines instead of blended strips")
	# Biomes own their topsoil below the first row, not only the surface tint.
	_require(_topsoil_matches(game, "ash_desert", game.Tile.ASH_SAND), "Ash desert lacks its ash sand surface")
	_require(_topsoil_matches(game, "ash_desert", game.Tile.ASH_SAND, 3), "Ash desert ash sand is not deep enough")
	_require(_topsoil_matches(game, "frost_wasteland", game.Tile.SNOW_BLOCK), "Frost wasteland lacks its snow surface")
	_require(_topsoil_matches(game, "frost_wasteland", game.Tile.FROZEN_DIRT, 1), "Frost wasteland lacks its frozen dirt topsoil")
	_require(_topsoil_matches(game, "marsh", game.Tile.MUD, 1), "Marsh lacks its mud topsoil")
	_require(_topsoil_matches(game, "ash_ruins", game.Tile.RUBBLE, 1), "Ash ruins lack their rubble topsoil")
	_require(_topsoil_matches(game, "forest", game.Tile.DIRT, 1), "Forest lacks its dirt topsoil")


func _border_metadata_is_sane(game: Variant) -> bool:
	if game.border_distances.size() != game.WORLD_WIDTH:
		return false
	if game.border_neighbors.size() != game.WORLD_WIDTH:
		return false
	for x in range(game.WORLD_WIDTH):
		var distance := int(game.border_distances[x])
		if distance >= game.SURFACE_BORDER_BLEND:
			continue
		var neighbor := str(game.border_neighbors[x])
		if neighbor.is_empty() or neighbor == str(game.surface_biomes[x]):
			return false
	return true


func _border_blend_mixes_biomes(game: Variant) -> bool:
	for x in range(game.WORLD_WIDTH):
		if int(game.border_distances[x]) >= game.SURFACE_BORDER_BLEND:
			continue
		var column_biome := str(game.surface_biomes[x])
		var surface_y := int(game.surface_heights[x])
		for y in range(surface_y, mini(game.WORLD_HEIGHT, surface_y + 8)):
			if str(game._blended_biome_at(x, y, column_biome)) != column_biome:
				return true
	return false


func _topsoil_matches(game: Variant, biome: String, expected_tile: int, depth: int = 0) -> bool:
	var matching := 0
	for x in range(game.WORLD_WIDTH):
		if str(game.surface_biomes[x]) != biome:
			continue
		# Border columns deliberately borrow the neighboring biome's topsoil.
		if int(game.border_distances[x]) < game.SURFACE_BORDER_BLEND:
			continue
		var surface_y := int(game.surface_heights[x])
		var surface_tile := int(game.world[surface_y][x])
		# Later ponds and biome decorations can disturb individual columns, so
		# sample several untouched columns instead of treating the first one as
		# representative of the entire band.
		if surface_tile != game.Tile.GRASS and surface_tile != game.Tile.SNOW_BLOCK and surface_tile != game.Tile.ASH_SAND:
			continue
		if int(game.world[surface_y + depth][x]) == expected_tile:
			matching += 1
			if matching >= 8:
				return true
	return false


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


func _liquid_volume(world: Array, sim: LiquidSim, target_tile: int) -> int:
	var volume := 0
	for y in range(world.size()):
		for x in range(world[y].size()):
			if int(world[y][x]) == target_tile:
				volume += sim.get_level(x, y)
	return volume


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
