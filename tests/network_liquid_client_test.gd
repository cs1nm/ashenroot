extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24710
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "liquid", "Liquid Client"))
	_require(result == OK, "Liquid test client could not start connection")
	var join_frames := 0
	while not game.network_session.joined and join_frames < 900:
		await process_frame
		join_frames += 1
	_require(game.network_session.joined and game.world_loaded, "Liquid test world transfer timed out")
	if failed:
		await _finish(game)
		return

	var source_x := int(game.WORLD_WIDTH / 2) + 8
	var target_x := source_x + 1
	var y := int(game.surface_heights[source_x]) - 6
	var sync_frames := 0
	while sync_frames < 900:
		var source_ready: bool = game._get_tile(source_x, y) == game.Tile.WATER and game.liquid_sim.get_level(source_x, y) == 4
		var target_ready: bool = game._get_tile(target_x, y) == game.Tile.WATER and game.liquid_sim.get_level(target_x, y) == 4
		if source_ready and target_ready:
			break
		await process_frame
		sync_frames += 1
	_require(game._get_tile(source_x, y) == game.Tile.WATER, "Client did not receive the liquid source tile")
	_require(game._get_tile(target_x, y) == game.Tile.WATER, "Client did not receive the flowed liquid tile")
	_require(game.liquid_sim.get_level(source_x, y) == 4, "Client source fill level differs from server")
	_require(game.liquid_sim.get_level(target_x, y) == 4, "Client target fill level differs from server")
	_require(game.liquid_sim.get_level(source_x, y) + game.liquid_sim.get_level(target_x, y) == game.liquid_sim.LEVEL_MAX, "Network liquid volume was not preserved")
	var diagnostics: Dictionary = game.network_session.get_diagnostics()
	_require(int(diagnostics.get("liquid_states_in", 0)) >= 2, "Client diagnostics did not record liquid states")
	_require(int(diagnostics.get("liquid_batches_rejected", 0)) == 0, "Client rejected a liquid state batch")
	if not failed:
		print("NETWORK_LIQUID_CLIENT_OK x=%d y=%d" % [source_x, y])
	await _finish(game)


func _finish(game: Variant) -> void:
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
