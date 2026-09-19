extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var out := OS.get_environment("ASHEN_CAPTURE_PATH")
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame
	game._hide_main_menu()
	game.world_loaded = true
	game._generate_world()
	game.inventory["wooden_axe"] = 1
	game.inventory["copper_axe"] = 1
	game.inventory["iron_axe"] = 1
	game.current_tool = "wooden_axe"
	game.equipped_weapon = "wooden_axe"
	var px: int = game.WORLD_WIDTH / 2
	var target := Vector2(float(px) * game.TILE_SIZE, float(game.surface_heights[px]) * game.TILE_SIZE)
	game.player_position = target + Vector2(0.0, -30.0)
	game.player_velocity = Vector2.ZERO
	game.attack_anim_kind = "slash"
	game.attack_anim_duration = 60.0
	game.attack_anim_time = 3.0
	game.camera.position_smoothing_enabled = false
	game._update_camera()
	game._update_hud()
	for i in range(14):
		await process_frame
	var image := root.get_texture().get_image()
	var err := image.save_png(out)
	print("CAPTURE axe -> %s (%s)" % [out, error_string(err)])
	game.queue_free()
	await process_frame
	quit()
