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
	game.seed = 424242
	game._generate_world()
	game.inventory["earth_shard"] = 3
	game.inventory["wind_shard"] = 3
	game._enter_dimension_1()
	game.mobile_ui_enabled = false
	game._update_mobile_controls_visibility()
	var bands: Array = [[92, 30, 0], [212, 26, 1], [344, 31, 2], [500, 39, 3], [640, 30, 4], [788, 35, 5], [940, 33, 6], [1092, 30, 7]]
	for band in bands:
		game.player_position = Vector2(float(band[0]) * game.TILE_SIZE, float(band[1]) * game.TILE_SIZE)
		game.camera.position_smoothing_enabled = false
		game._update_camera()
		game._update_hud()
		for i in range(10):
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("/tmp/pan_%d.png" % int(band[2]))
		print("BAND %d done" % int(band[2]))
	quit()
