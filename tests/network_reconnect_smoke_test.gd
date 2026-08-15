extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24679
	await _join(game, port)
	if not game.network_session.joined:
		await _finish(game)
		return
	var player_tile := Vector2i(int(game.player_position.x / game.TILE_SIZE), int(game.player_position.y / game.TILE_SIZE))
	var target := Vector2i(-1, -1)
	for y_offset in range(-3, 4):
		for x_offset in range(2, 6):
			var candidate := player_tile + Vector2i(x_offset, y_offset)
			if game._in_bounds(candidate.x, candidate.y) and game._get_tile(candidate.x, candidate.y) == game.Tile.AIR:
				target = candidate
				break
		if target.x >= 0:
			break
	_require(target.x >= 0, "No nearby air tile for authoritative placement")
	var tile_x := target.x
	var tile_y := target.y
	var changed_tile: int = int(game.Tile.DIRT)
	game.network_session.request_game_action("place", {"x": tile_x, "y": tile_y, "item_id": "dirt", "build_id": ""})
	var sync_frames := 0
	while game._get_tile(tile_x, tile_y) != changed_tile and sync_frames < 240:
		await process_frame
		sync_frames += 1
	_require(game._get_tile(tile_x, tile_y) == changed_tile, "Server did not replicate authoritative placement")
	game.network_session.shutdown("")
	for frame in range(12):
		await process_frame
	_require(not game.network_session.is_active(), "Client did not cleanly disconnect")
	await _join(game, port)
	_require(game.network_session.joined, "Reconnect handshake failed")
	if game.network_session.joined:
		_require(int(game.world[tile_y][tile_x]) == changed_tile, "Authoritative tile change was lost after reconnect")
	if not failed:
		print("NETWORK_RECONNECT_SMOKE_OK tile=%d,%d value=%d" % [tile_x, tile_y, changed_tile])
	await _finish(game)


func _join(game: Variant, port: int) -> void:
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "smoke", "Reconnect Smoke"))
	_require(result == OK, "Client could not start ENet connection")
	var frames := 0
	while not game.network_session.joined and frames < 900:
		await process_frame
		frames += 1
	_require(game.network_session.joined, "Handshake/world transfer timed out")
	_require(game.world_loaded, "Transferred server world was not activated")


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
