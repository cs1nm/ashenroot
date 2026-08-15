extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24683
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "smoke", "Disconnect Smoke"))
	_require(result == OK, "Client could not start connection")
	var join_frames := 0
	while not game.network_session.joined and join_frames < 900:
		await process_frame
		join_frames += 1
	_require(game.network_session.joined, "Disconnect smoke handshake timed out")
	if not game.network_session.joined:
		await _finish(game)
		return
	print("NETWORK_DISCONNECT_CLIENT_READY")
	var disconnect_frames := 0
	while game.network_session.is_active() and disconnect_frames < 1800:
		await process_frame
		disconnect_frames += 1
	for frame in range(5):
		await process_frame
	_require(not game.network_session.is_active(), "Client did not detect the stopped server")
	_require(game.in_main_menu, "Disconnected client did not return to main menu")
	if not failed:
		print("NETWORK_DISCONNECT_SMOKE_OK")
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
