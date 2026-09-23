extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame
	game._hide_main_menu()
	game.world_loaded = true
	game._generate_world()
	game.path_choice = "magic"
	game._add_dimension_portal()
	game._spawn_moon_altar()
	game.inventory["sky_compass"] = 1
	game.hotbar[2] = "sky_compass"
	game.selected_slot = 2
	game.npc_wanderer_active = true
	var px: int = int(game.WORLD_WIDTH / 2)
	game.npc_wanderer_pos = Vector2(float(px + 3) * game.TILE_SIZE, (float(game.surface_heights[px + 3]) - 1.0) * game.TILE_SIZE)
	game.player_position = Vector2(float(px) * game.TILE_SIZE, (float(game.surface_heights[px]) - 2.0) * game.TILE_SIZE)
	game.camera.position_smoothing_enabled = false
	game._update_camera()
	for i in range(12):
		await process_frame
	game._update_hud()
	for i in range(6):
		await process_frame
	root.get_texture().get_image().save_png("/home/user/shots/npc_compass.png")
	print("NPC+COMPASS saved; altar=", game.moon_altar_pos)
	game.queue_free()
	await process_frame
	quit()
