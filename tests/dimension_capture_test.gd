extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mode := OS.get_environment("ASHEN_CAPTURE_MODE")
	var out := OS.get_environment("ASHEN_CAPTURE_PATH")
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame
	game._hide_main_menu()
	game.world_loaded = true
	game._generate_world()
	var seed_env := OS.get_environment("ASHEN_CAPTURE_SEED")
	if seed_env != "":
		game.seed = seed_env.to_int()
	if mode == "dimension" or mode == "altar" or mode == "dim_pos" or mode == "dim_tree":
		game.inventory["earth_shard"] = 3
		game.inventory["wind_shard"] = 3
		game._enter_dimension_1()
	var target: Vector2
	if mode == "portal":
		if game.dimension_portal_pos.x < 0:
			game.path_choice = "magic"
			game._add_dimension_portal()
		target = Vector2(float(game.dimension_portal_pos.x) * game.TILE_SIZE, float(game.dimension_portal_pos.y) * game.TILE_SIZE)
	elif mode == "dimension":
		target = Vector2(float(game.dimension_spawn_pos.x) * game.TILE_SIZE, float(game.dimension_spawn_pos.y) * game.TILE_SIZE)
	elif mode == "altar":
		target = Vector2(float(game.dimension_mana_altar_pos.x) * game.TILE_SIZE, float(game.dimension_mana_altar_pos.y) * game.TILE_SIZE)
	elif mode == "dim_pos":
		target = Vector2(float(OS.get_environment("ASHEN_CAPTURE_X").to_int()) * game.TILE_SIZE, float(OS.get_environment("ASHEN_CAPTURE_Y").to_int()) * game.TILE_SIZE)
	elif mode == "dim_tree":
		var found_x := -1
		var found_y := 0
		var sx := 12
		while sx < game.WORLD_WIDTH - 12 and found_x < 0:
			var stalk_count := 0
			var first_y := 0
			for sy in range(6, 70):
				if int(game.world[sy][sx]) == game.Tile.FLORA_STALK:
					stalk_count += 1
					if first_y == 0:
						first_y = sy
				if stalk_count >= 6:
					found_x = sx
					found_y = first_y
					break
			sx += 1
		if found_x < 0:
			printerr("no tall tree found")
			quit(1)
			return
		target = Vector2(float(found_x) * game.TILE_SIZE, float(found_y + 3) * game.TILE_SIZE)
	elif mode == "biome":
		var wanted := OS.get_environment("ASHEN_CAPTURE_BIOME")
		var found := false
		var scan_x := 8
		while scan_x < game.WORLD_WIDTH - 8 and not found:
			if game._surface_biome_at_column(scan_x) == wanted:
				found = true
				target = Vector2(float(scan_x) * game.TILE_SIZE, float(game.surface_heights[scan_x]) * game.TILE_SIZE)
			scan_x += 4
		if not found:
			printerr("biome not found: " + wanted)
			quit(1)
			return
	elif mode == "cave":
		target = Vector2(float(game.depth_sanctum_pos.x) * game.TILE_SIZE, float(game.depth_sanctum_pos.y) * game.TILE_SIZE)
	elif mode == "sky":
		target = Vector2(float(game.sky_arena_pos.x) * game.TILE_SIZE, float(game.sky_arena_pos.y) * game.TILE_SIZE)
	elif mode == "pos":
		target = Vector2(float(OS.get_environment("ASHEN_CAPTURE_X").to_int()) * game.TILE_SIZE, float(OS.get_environment("ASHEN_CAPTURE_Y").to_int()) * game.TILE_SIZE)
	else:
		printerr("unknown mode")
		quit(1)
		return
	game.player_position = target + Vector2(-48.0, -26.0)
	game.player_velocity = Vector2.ZERO
	game.camera.position_smoothing_enabled = false
	game._update_camera()
	game._update_hud()
	for i in range(14):
		await process_frame
	var image := root.get_texture().get_image()
	var err := image.save_png(out)
	print("CAPTURE %s -> %s (%s)" % [mode, out, error_string(err)])
	game.queue_free()
	await process_frame
	quit()
