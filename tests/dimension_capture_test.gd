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
	if mode == "dimension" or mode == "altar":
		game.inventory["earth_shard"] = 3
		game.inventory["wind_shard"] = 3
		game._enter_dimension_1()
	var target: Vector2
	if mode == "portal":
		target = Vector2(float(game.dimension_portal_pos.x) * game.TILE_SIZE, float(game.dimension_portal_pos.y) * game.TILE_SIZE)
	elif mode == "dimension":
		target = Vector2(float(game.dimension_spawn_pos.x) * game.TILE_SIZE, float(game.dimension_spawn_pos.y) * game.TILE_SIZE)
	elif mode == "altar":
		target = Vector2(float(game.dimension_mana_altar_pos.x) * game.TILE_SIZE, float(game.dimension_mana_altar_pos.y) * game.TILE_SIZE)
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
