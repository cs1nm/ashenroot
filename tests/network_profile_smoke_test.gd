extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24680
	await _join(game, port)
	if not game.network_session.joined:
		await _finish(game)
		return
	var dirt_before := int(game.inventory.get("dirt", 0))
	_require(dirt_before > 0, "Restored profile has no starter dirt")
	game.network_session.request_game_action("drop", {"item_id": "dirt", "amount": 1})
	await _wait_for(func() -> bool: return int(game.inventory.get("dirt", 0)) == dirt_before - 1, 240)
	_require(int(game.inventory.get("dirt", 0)) == dirt_before - 1, "Authoritative drop did not update inventory")
	var persisted_dirt := int(game.inventory.get("dirt", 0))
	var wood_before := int(game.inventory.get("wood", 0))
	if wood_before >= 8:
		var bench_before := int(game.inventory.get("workbench", 0))
		game.network_session.request_game_action("craft", {"recipe_id": "workbench"})
		await _wait_for(func() -> bool: return int(game.inventory.get("workbench", 0)) == bench_before + 1, 240)
		_require(int(game.inventory.get("workbench", 0)) == bench_before + 1, "Server-authoritative crafting failed")
		_require(int(game.inventory.get("wood", 0)) == wood_before - 8, "Crafting cost was not deducted by server")
	game.network_session.shutdown("")
	for frame in range(12):
		await process_frame
	await _join(game, port)
	_require(game.network_session.joined, "Profile reconnect failed")
	_require(int(game.inventory.get("dirt", 0)) == persisted_dirt, "Inventory did not persist across reconnect")
	game.health = 0
	game.network_session.request_game_action("respawn", {"reported_health": 0})
	await _wait_for(func() -> bool: return int(game.health) == int(game.MAX_HEALTH), 240)
	_require(int(game.health) == int(game.MAX_HEALTH), "Server-authoritative respawn failed")
	if not failed:
		print("NETWORK_PROFILE_SMOKE_OK dirt=%d wood=%d" % [int(game.inventory.get("dirt", 0)), int(game.inventory.get("wood", 0))])
	await _finish(game)


func _join(game: Variant, port: int) -> void:
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "smoke", "Profile Smoke"))
	_require(result == OK, "Client could not start ENet connection")
	var frames := 0
	while not game.network_session.joined and frames < 900:
		await process_frame
		frames += 1
	_require(game.network_session.joined, "Profile handshake timed out")


func _wait_for(predicate: Callable, max_frames: int) -> void:
	for frame in range(max_frames):
		if predicate.call():
			return
		await process_frame


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
