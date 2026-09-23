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
	var px: int = int(game.WORLD_WIDTH / 2)
	var pos := Vector2(float(px) * game.TILE_SIZE, float(game.surface_heights[px] - 4) * game.TILE_SIZE)
	game._spawn_enemy("storm_herald", pos)
	for enemy in game.enemies:
		if str(enemy.get("type", "")) == "storm_herald":
			enemy["hp"] = float(enemy.get("max_hp", 1)) * 0.55
			enemy["perception_state"] = game.PERCEPTION_COMBAT
	var target: Vector2 = pos
	game.player_position = target + Vector2(90.0, -20.0)
	game.camera.position_smoothing_enabled = false
	game._update_camera()
	for i in range(16):
		await process_frame
	root.get_texture().get_image().save_png("/home/user/shots/sh_look.png")
	print("SH saved; anim_textures=", "storm_herald" in game.enemy_animation_textures, " spec_count=", (game.enemy_animation_specs.get("storm_herald", {}) as Dictionary).size())
	game.queue_free()
	await process_frame
	quit()
