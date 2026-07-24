extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game._execute_debug_command("give wood 7")
	assert(int(game.inventory.get("wood", 0)) >= 19)
	game._execute_debug_command("give_all 2")
	assert(int(game.inventory.get("heartwood_core", 0)) >= 2)

	game._execute_debug_command("spawn wild_slime 2")
	assert(game.enemies.size() >= 2)
	game._execute_debug_command("killall")
	assert(game.enemies.is_empty())

	game._execute_debug_command("noclip on")
	assert(game.noclip_unlocked and game.noclip_enabled)
	var start_x: float = game.player_position.x
	game.physical_move_right_held = true
	game._update_player(0.5)
	game.physical_move_right_held = false
	assert(game.player_position.x > start_x)
	game._execute_debug_command("noclip off")
	assert(not game.noclip_enabled)
	var space_press := InputEventKey.new()
	space_press.keycode = KEY_SPACE
	space_press.physical_keycode = KEY_SPACE
	space_press.pressed = true
	game._input(space_press)
	game._input(space_press)
	assert(game.noclip_enabled)
	game._set_noclip_enabled(false)

	game._execute_debug_command("god on")
	game.health = 1
	game._damage_player(999)
	assert(game.health == game.MAX_HEALTH)
	game._execute_debug_command("god off")
	game._set_debug_console_open(true)
	assert(game.debug_console_open and game.debug_console_panel.visible)
	game._set_debug_console_open(false)

	print("DEBUG_CONSOLE_OK")
	game.queue_free()
	await process_frame
	quit()
