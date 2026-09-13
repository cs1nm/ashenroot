extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(cond: bool, label: String) -> void:
	if not cond:
		failed = true
		printerr("DIMENSION_SMOKE_FAIL: " + label)


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	if game == null:
		printerr("DIMENSION_SMOKE_FAIL: Main.tscn failed to load (script parse error?)")
		quit(1)
		return
	root.add_child(game)
	await process_frame
	await process_frame
	game._generate_world()

	# Overworld portal exists and is wired to a real tile.
	_check(game.dimension_portal_pos.x >= 0, "portal position stamped")
	_check(game._get_tile(game.dimension_portal_pos.x, game.dimension_portal_pos.y) == game.Tile.DIM_PORTAL, "portal tile present")

	# The portal refuses travelers without both shards.
	_check(not game._check_dimension_portal_access(), "portal locked without shards")
	game.inventory["earth_shard"] = 1
	game.inventory["wind_shard"] = 1
	_check(game._check_dimension_portal_access(), "portal opens with both shards")

	# Enter the dimension.
	game._enter_dimension_1()
	_check(game.active_dimension == 1, "active dimension flag")
	_check(game.world.size() == game.WORLD_HEIGHT, "dimension map height")
	_check(not game.world.is_empty() and (game.world[0] as Array).size() == game.WORLD_WIDTH, "dimension map width")
	_check(game._get_tile(game.dimension_spawn_pos.x, game.dimension_spawn_pos.y) == game.Tile.DIM_PORTAL, "return portal at spawn")
	_check(game._get_tile(game.dimension_mana_altar_pos.x, game.dimension_mana_altar_pos.y) == game.Tile.MANA_ALTAR, "mana altar placed")
	_check(game.enemies.is_empty(), "enemies cleared on travel")
	_check(game.overworld_tiles_backup.size() == game.WORLD_HEIGHT, "overworld parked")
	var void_tiles := 0
	for y in range(0, game.WORLD_HEIGHT, 7):
		var row: Array = game.world[y]
		for x in range(0, game.WORLD_WIDTH, 11):
			if int(row[x]) == game.Tile.VOID_STONE or int(row[x]) == game.Tile.VOID_SOIL:
				void_tiles += 1
	_check(void_tiles > 50, "dimension terrain generated (void_tiles=%d)" % void_tiles)
	var stalks := 0
	var vines := 0
	for y in range(game.WORLD_HEIGHT):
		var flora_row: Array = game.world[y]
		for x in range(game.WORLD_WIDTH):
			var t := int(flora_row[x])
			if t == game.Tile.FLORA_STALK:
				stalks += 1
			elif t == game.Tile.FLORA_VINE:
				vines += 1
	_check(stalks > 40, "giant flora generated (stalks=%d)" % stalks)
	_check(vines > 5, "vines generated (vines=%d)" % vines)
	_check(game._compute_current_biome() == "dimension_1", "biome override")
	_check(absf(game._daylight_factor() - game.DIMENSION_DAYLIGHT) < 0.001, "twilight daylight")

	# The mana altar raises the pool.
	var before := int(game.max_mana)
	game._interact_mana_altar()
	_check(int(game.max_mana) == before + game.MANA_ALTAR_MAX_INCREASE, "altar raises max mana")

	# Save roundtrip while inside the dimension.
	var data: Dictionary = game._build_save_data()
	_check(int(data.get("active_dimension", -1)) == 1, "save keeps dimension flag")
	_check((data.get("dimension_world", []) as Array).size() == game.WORLD_HEIGHT, "save stores dimension map")
	_check((data.get("world", []) as Array).size() == game.WORLD_HEIGHT, "save stores parked overworld")
	game._apply_save_data(data)
	_check(game.active_dimension == 1, "load restores dimension travel")
	_check(game._get_tile(game.dimension_spawn_pos.x, game.dimension_spawn_pos.y) == game.Tile.DIM_PORTAL, "dimension intact after load")
	_check(game.overworld_tiles_backup.size() == game.WORLD_HEIGHT, "overworld parked after load")

	# Exit restores the overworld.
	game._exit_dimension_1()
	_check(game.active_dimension == 0, "back in overworld")
	_check(game._get_tile(game.dimension_portal_pos.x, game.dimension_portal_pos.y) == game.Tile.DIM_PORTAL, "overworld portal intact")
	_check(game.enemies.is_empty(), "enemies cleared on return")

	if failed:
		quit(1)
		return
	print("DIMENSION_SMOKE_OK")
	quit()
