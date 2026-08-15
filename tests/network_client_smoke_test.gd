extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var port := int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24678
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "smoke", "Client Smoke"))
	_require(result == OK, "Client could not start ENet connection")
	var frames := 0
	while not game.network_session.joined and frames < 900:
		await process_frame
		frames += 1
	_require(game.network_session.joined, "Client handshake/world transfer timed out")
	_require(game.world_loaded, "Transferred server world was not activated")
	_require(game.world.size() == game.WORLD_HEIGHT, "Transferred world has invalid height")
	_require(game.network_session.player_count() >= 1, "Joined roster is empty")
	_require(game.current_world_index == -1, "Client must not overwrite a local world slot")
	var expected_players := int(OS.get_environment("ASHENROOT_TEST_EXPECT_PLAYERS")) if OS.get_environment("ASHENROOT_TEST_EXPECT_PLAYERS").is_valid_int() else 1
	var roster_frames := 0
	while game.network_session.player_count() < expected_players and roster_frames < 900:
		await process_frame
		roster_frames += 1
	_require(game.network_session.player_count() >= expected_players, "Roster replication timed out")
	var received_chat: Array[String] = []
	game.network_session.chat_received.connect(func(_peer_id: int, sender_name: String, message: String) -> void: received_chat.append("%s:%s" % [sender_name, message]))
	game.network_session.send_chat("network smoke hello")
	var chat_frames := 0
	while received_chat.is_empty() and chat_frames < 240:
		await process_frame
		chat_frames += 1
	_require(not received_chat.is_empty(), "Reliable network chat did not echo")
	var ping_frames := 0
	while str(game.network_session.connection_quality) not in ["good", "fair", "poor"] and ping_frames < 300:
		await process_frame
		ping_frames += 1
	_require(str(game.network_session.connection_quality) in ["good", "fair", "poor"], "Latency quality was not measured")
	for frame in range(30):
		await process_frame
	_require(game.network_session.joined, "Client dropped after entity synchronization")
	if not failed:
		print("NETWORK_CLIENT_SMOKE_OK players=%d rows=%d" % [game.network_session.player_count(), game.world.size()])
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
