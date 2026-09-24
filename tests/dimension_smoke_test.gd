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

	# Classic furniture recipes are back and placeable.
	var classic_ids: Array[String] = ["door", "platform", "ladder", "bed", "fence", "window", "trapdoor", "rope", "lantern", "table", "chair"]
	var found := 0
	for recipe in game.recipes:
		if str(recipe.get("id", "")) in classic_ids:
			found += 1
	_check(found == classic_ids.size(), "classic furniture recipes restored")
	_check(game.item_to_tile.has("bed") and game.item_to_tile.has("window"), "furniture items placeable")

	# Portal is locked behind the NPC magic path choice.
	_check(game.dimension_portal_pos.x < 0, "no portal before path choice")
	game.path_choice = "magic"
	game._add_dimension_portal()
	_check(game.dimension_portal_pos.x >= 0, "portal stamped after magic path")
	_check(game._get_tile(game.dimension_portal_pos.x, game.dimension_portal_pos.y) == game.Tile.DIM_PORTAL, "portal tile present")
	_check(game._get_tile(game.dimension_portal_pos.x - 3, game.dimension_portal_pos.y - 5) != game.Tile.RUIN, "no built structure around portal")

	# The shard gate still applies off the magic path.
	game.path_choice = ""
	_check(not game._check_dimension_portal_access(), "portal locked without shards")
	game.inventory["earth_shard"] = 1
	game.inventory["wind_shard"] = 1
	_check(game._check_dimension_portal_access(), "portal opens with both shards")
	game.path_choice = "magic"
	game.inventory["earth_shard"] = 0
	game.inventory["wind_shard"] = 0
	game.path_choice = ""
	_check(not game._check_dimension_portal_access(), "no shards + no magic path = locked")
	game.path_choice = "magic"
	_check(game._check_dimension_portal_access(), "magic path opens the portal")

	# Sky islands stay within honest reach of the surface.
	var islands_in_reach: bool = game.sky_island_positions.size() > 0
	for center in game.sky_island_positions:
		if int(game.surface_heights[center.x]) - center.y > 26:
			islands_in_reach = false
	_check(islands_in_reach, "sky islands within reach")

	# The tornado dissipates as soon as the herald is out.
	game.storm_active = true
	game.storm_tornado_phase = "active"
	game.storm_tornado_pos = game.player_position + Vector2(120.0, 0.0)
	game._trigger_storm_boss()
	_check(game._storm_boss_alive(), "storm herald spawned")
	_check(not game.storm_active and game.storm_tornado_phase == "", "storm calms when herald emerges")
	for i in range(game.enemies.size() - 1, -1, -1):
		if str((game.enemies[i] as Dictionary).get("type", "")) == "storm_herald":
			game.enemies.remove_at(i)

	# Portal travel cinematics: suck -> flash -> fall; landing deals no damage.
	var hp_before: int = game.health
	game._begin_portal_transition(false)
	_check(game.portal_transition_phase == "suck", "transition suck phase")
	game._update_portal_transition(2.0)
	_check(game.portal_transition_phase == "flash", "transition flash phase")
	game._update_portal_transition(0.8)
	_check(game.portal_transition_phase == "fall", "transition fall phase")
	_check(game.active_dimension == 1, "dimension switched mid-transition")
	_check(game.player_position.y < float(game.dimension_spawn_pos.y * game.TILE_SIZE), "dropping from the sky")
	for i in range(400):
		game._update_portal_transition(1.0 / 60.0)
		if game.portal_transition_phase == "":
			break
	_check(game.portal_transition_phase == "", "transition lands via real fall")
	# Safety net: a blocked descent still ends after 5 seconds.
	game._begin_portal_transition(true)
	game._update_portal_transition(2.0)
	game._update_portal_transition(0.8)
	_check(game.portal_transition_phase == "fall", "second transition reached fall")
	game.portal_transition_time = 6.0
	game._update_portal_transition(0.016)
	_check(game.portal_transition_phase == "", "fall safety net force-lands")
	_check(game.health == hp_before, "no fall damage on portal drop")

	# Direct entry remains available for tests/loads.
	game._exit_dimension_1()
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
