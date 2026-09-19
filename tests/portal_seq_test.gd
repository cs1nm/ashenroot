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
	game.inventory["earth_shard"] = 3
	game.inventory["wind_shard"] = 3
	game.path_choice = "magic"
	game._add_dimension_portal()
	game.player_position = Vector2(float(game.dimension_portal_pos.x - 3) * game.TILE_SIZE, float(game.dimension_portal_pos.y - 2) * game.TILE_SIZE)
	game.camera.position_smoothing_enabled = false
	game._update_camera()
	for i in range(10):
		await process_frame
	game._begin_portal_transition(false)
	for i in range(300):
		await process_frame
		if game.portal_transition_time >= 0.55:
			break
	root.get_texture().get_image().save_png("/tmp/seq_suck.png")
	print("SEQ suck phase=", game.portal_transition_phase)
	for i in range(140):
		await process_frame
		if game.portal_transition_phase == "flash" and game.portal_transition_time >= 0.5:
			break
	root.get_texture().get_image().save_png("/tmp/seq_flash.png")
	print("SEQ flash")
	for i in range(300):
		await process_frame
		if game.portal_transition_phase == "fall" and game.portal_transition_time > 0.35:
			break
	game._update_camera()
	for i in range(3):
		await process_frame
	root.get_texture().get_image().save_png("/tmp/seq_fall.png")
	print("SEQ fall phase=", game.portal_transition_phase)
	for i in range(900):
		await process_frame
		if game.portal_transition_phase == "":
			break
	game._update_camera()
	game._update_hud()
	for i in range(10):
		await process_frame
	root.get_texture().get_image().save_png("/tmp/seq_land.png")
	print("SEQ land hp=", game.health, " dim=", game.active_dimension)
	game.queue_free()
	await process_frame
	quit()
