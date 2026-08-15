extends SceneTree

const NETWORK_SESSION_SCRIPT = preload("res://scripts/network_session.gd")

class BanClientGame:
	extends Node2D
	var player_position := Vector2.ZERO
	var rejection := ""

	func _network_local_player_state(display_name: String) -> Dictionary:
		return {"name": display_name, "pos": player_position, "vel": Vector2.ZERO, "facing": 1, "on_floor": true, "health": 100, "max_health": 100, "oxygen": 100.0, "body_temperature": 37.0, "flight_charge": 100.0, "class": "Warrior", "weapon": "", "attack_kind": "", "attack_ratio": 0.0}

	func _network_apply_world_data(_data: Dictionary, spawn: Vector2, _server_name: String) -> void:
		player_position = spawn

	func _network_apply_entity_snapshot(_snapshot: Dictionary) -> void:
		pass

	func _network_apply_player_profile(_profile: Dictionary, _initial: bool, _message: String) -> void:
		pass

	func _network_join_rejected(reason: String) -> void:
		rejection = reason

	func _network_return_to_menu(reason: String) -> void:
		rejection = reason


var failed := false
var session: Node
var game: BanClientGame
var port := 24567
var password := "admin"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	port = int(OS.get_environment("ASHENROOT_TEST_PORT")) if OS.get_environment("ASHENROOT_TEST_PORT").is_valid_int() else 24567
	password = OS.get_environment("ASHENROOT_TEST_PASSWORD")
	if password == "":
		password = "admin"
	game = BanClientGame.new()
	game.name = "Main"
	root.add_child(game)
	session = NETWORK_SESSION_SCRIPT.new()
	session.name = "NetworkSession"
	game.add_child(session)
	session.setup(game)
	await process_frame
	await _join(20000)
	if not session.joined:
		await _finish()
		return
	print("NETWORK_BAN_CLIENT_READY peer=%d" % session.local_peer_id())
	var deadline := Time.get_ticks_msec() + 30000
	var last_tick := Time.get_ticks_msec()
	while session.is_active() and Time.get_ticks_msec() < deadline:
		await create_timer(0.016).timeout
		var now := Time.get_ticks_msec()
		session.tick(clampf(float(now - last_tick) / 1000.0, 0.001, 0.1))
		last_tick = now
	_require(not session.is_active(), "Server did not disconnect the banned client")
	_require("banned" in game.rejection.to_lower(), "Ban disconnect reason was not delivered")
	for _frame in range(30):
		await create_timer(0.016).timeout
	game.rejection = ""
	await _join(8000)
	_require(not session.joined, "Persistently banned profile rejoined the server")
	_require("banned" in game.rejection.to_lower(), "Persistent ban rejection was not delivered")
	if not failed:
		print("NETWORK_BAN_CLIENT_OK")
	await _finish()


func _join(timeout_msec: int) -> void:
	var result: int = int(session.join_server("127.0.0.1", port, password, "Ban Smoke"))
	_require(result == OK, "Could not create ENet client")
	if result != OK:
		return
	var deadline := Time.get_ticks_msec() + timeout_msec
	var last_tick := Time.get_ticks_msec()
	while session.is_active() and not session.joined and Time.get_ticks_msec() < deadline:
		await create_timer(0.016).timeout
		var now := Time.get_ticks_msec()
		session.tick(clampf(float(now - last_tick) / 1000.0, 0.001, 0.1))
		last_tick = now


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _finish() -> void:
	if session != null:
		session.shutdown("")
	await process_frame
	quit(1 if failed else 0)
