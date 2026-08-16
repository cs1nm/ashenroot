extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._hide_main_menu()
	game.world_loaded = true
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24710
	var result: int = int(game.network_session.host_server(port, "liquid", "Liquid Sync", "Host", false, false))
	_require(result == OK, "Liquid test server could not start")
	if result == OK:
		print("NETWORK_LIQUID_SERVER_READY port=%d" % port)
	var join_frames := 0
	while game.network_session.player_count() < 2 and join_frames < 900:
		await process_frame
		join_frames += 1
	_require(game.network_session.player_count() >= 2, "Liquid test client did not join")
	if failed:
		await _finish(game)
		return

	var source_x := int(game.WORLD_WIDTH / 2) + 8
	var target_x := source_x + 1
	var y := int(game.surface_heights[source_x]) - 6
	# Build a sealed two-cell trough after the client has joined. The full source
	# must settle into two half-filled cells, which exercises tile and level RPCs.
	for x in range(source_x - 1, target_x + 2):
		game._set_tile(x, y - 1, game.Tile.AIR)
		game._set_tile(x, y, game.Tile.AIR)
		game._set_tile(x, y + 1, game.Tile.STONE)
	game._set_tile(source_x - 1, y, game.Tile.STONE)
	game._set_tile(target_x + 1, y, game.Tile.STONE)
	game._set_tile(source_x, y, game.Tile.WATER)

	var settle_frames := 0
	while settle_frames < 600:
		if game._get_tile(source_x, y) == game.Tile.WATER and game._get_tile(target_x, y) == game.Tile.WATER:
			if game.liquid_sim.get_level(source_x, y) == 4 and game.liquid_sim.get_level(target_x, y) == 4:
				break
		await process_frame
		settle_frames += 1
	_require(game.liquid_sim.get_level(source_x, y) == 4, "Server source did not settle to half full")
	_require(game.liquid_sim.get_level(target_x, y) == 4, "Server target did not settle to half full")
	if not failed:
		print("NETWORK_LIQUID_SERVER_SETTLED x=%d y=%d" % [source_x, y])

	var disconnect_frames := 0
	while game.network_session.player_count() >= 2 and disconnect_frames < 900:
		await process_frame
		disconnect_frames += 1
	await _finish(game)


func _finish(game: Variant) -> void:
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	if not failed:
		print("NETWORK_LIQUID_SERVER_OK")
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
