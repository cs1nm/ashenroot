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
	var result: int = int(game.network_session.join_server("127.0.0.1", port, "wrong-password", "Rejected Client"))
	_require(result == OK, "Auth test could not start ENet connection")
	var frames := 0
	while game.network_session.last_error == "" and frames < 900:
		await process_frame
		frames += 1
	_require(not game.network_session.joined, "Wrong password was accepted")
	_require("password" in game.network_session.last_error.to_lower(), "Server did not return a password rejection")
	if not failed:
		print("NETWORK_AUTH_SMOKE_OK")
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
