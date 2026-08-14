extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame
	game._hide_main_menu()
	game._observe_enemy("cave_worm")
	for i in range(3):
		game._record_enemy_kill("cave_worm")
	game._record_material_found("copper_ore", 15)
	game._record_alchemy_result("acid_flasks", {"ash": 4, "copper_ore": 2})
	var capture_mode := OS.get_environment("ASHENROOT_CAPTURE_MODE")
	if capture_mode == "multiplayer":
		game._show_main_menu()
		game._show_multiplayer_panel()
	elif capture_mode == "inventory":
		game._open_inventory_screen("inventory")
		game._update_hud()
	elif capture_mode == "crafting":
		game._open_inventory_screen("crafting")
		game._update_hud()
	elif capture_mode == "mobile":
		game.mobile_ui_enabled = true
		game._update_mobile_controls_visibility()
		game._update_hud()
	elif capture_mode == "combat":
		game.mobile_ui_enabled = true
		game._update_mobile_controls_visibility()
		var preview_x := int(game.WORLD_WIDTH / 2)
		var preview_y := int(game.surface_heights[preview_x])
		game.player_position = Vector2(preview_x * game.TILE_SIZE, (preview_y - 2) * game.TILE_SIZE)
		game.camera.position_smoothing_enabled = false
		game.camera.position = game.player_position
		game.enemies.clear()
		game._spawn_enemy("mossling", game.player_position + Vector2(82.0, -4.0))
		var preview_enemy: Dictionary = game.enemies[0]
		preview_enemy["hp"] = maxi(1, int(preview_enemy.get("max_hp", 20)) - 7)
		preview_enemy["attack_windup"] = 0.18
		preview_enemy["attack_total"] = 0.60
		preview_enemy["perception_state"] = game.PERCEPTION_COMBAT
		game.enemies[0] = preview_enemy
		game._spawn_combat_impact(game.player_position + Vector2(45.0, -4.0), Vector2.RIGHT, "physical", true)
		game._spawn_damage_number(game.player_position + Vector2(52.0, -34.0), 17, Color("ffd77a"), true)
		game._update_hud()
	elif capture_mode != "gameplay":
		game._set_journal_open(true)
		game._select_journal_tab("Bestiary")
		game._select_journal_entry("cave_worm")
	for i in range(3):
		await process_frame
	var capture_path := OS.get_environment("ASHENROOT_CAPTURE_PATH")
	if capture_path == "":
		capture_path = ProjectSettings.globalize_path("user://journal_preview.png")
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	if error != OK:
		push_error("Could not save UI capture: %s" % error_string(error))
		quit(1)
		return
	print("UI_CAPTURE_OK %s" % capture_path)
	game.queue_free()
	await process_frame
	quit()
