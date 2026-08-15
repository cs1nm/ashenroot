extends SceneTree

const NETWORK_SESSION_SCRIPT = preload("res://scripts/network_session.gd")
const TILE_SIZE := 16.0

class BotGame:
	extends Node2D

	var player_position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var target_tile := Vector2i(-1, -1)
	var snapshots_received := 0
	var tile_updates_received := 0
	var profile_updates_received := 0
	var disconnected_reason := ""

	func _network_local_player_state(display_name: String) -> Dictionary:
		return {
			"name": display_name,
			"pos": player_position,
			"vel": velocity,
			"facing": 1 if velocity.x >= 0.0 else -1,
			"on_floor": true,
			"health": 100,
			"max_health": 100,
			"oxygen": 100.0,
			"body_temperature": 37.0,
			"flight_charge": 100.0,
			"class": "Warrior",
			"weapon": "",
			"attack_kind": "",
			"attack_ratio": 0.0,
		}

	func _network_apply_world_data(data: Dictionary, spawn: Vector2, _server_name: String) -> void:
		player_position = spawn
		target_tile = _find_action_tile(data.get("world", []), spawn)

	func _find_action_tile(world: Array, spawn: Vector2) -> Vector2i:
		if world.is_empty():
			return Vector2i(-1, -1)
		var center := Vector2i(int(spawn.x / TILE_SIZE), int(spawn.y / TILE_SIZE))
		for radius in range(2, 6):
			for y in range(center.y - radius, center.y + radius + 1):
				if y < 1 or y >= world.size() - 1:
					continue
				var row: Array = world[y]
				for x in range(center.x - radius, center.x + radius + 1):
					if x < 1 or x >= row.size() - 1:
						continue
					if int(row[x]) == 0 and Vector2(x, y).distance_to(Vector2(center)) >= 1.8:
						return Vector2i(x, y)
		return Vector2i(-1, -1)

	func _network_apply_player_profile(_profile: Dictionary, _initial: bool, _message: String) -> void:
		profile_updates_received += 1

	func _network_apply_entity_snapshot(_snapshot: Dictionary) -> void:
		snapshots_received += 1

	func _network_apply_tile_change(x: int, y: int, _tile: int) -> void:
		tile_updates_received += 1
		if target_tile.x < 0:
			target_tile = Vector2i(x, y)

	func _network_return_to_menu(reason: String) -> void:
		disconnected_reason = reason

	func _network_join_rejected(reason: String) -> void:
		disconnected_reason = reason


var failed := false
var bot_index := 0
var bot_count := 4
var duration_seconds := 30.0
var port := 24567
var password := "stress"
var session: Node
var bot_game: BotGame
var chat_received := 0
var actions_sent := 0
var reconnects := 0
var peak_roster := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	bot_index = _environment_int("ASHENROOT_BOT_INDEX", 0)
	bot_count = clampi(_environment_int("ASHENROOT_BOT_COUNT", 4), 1, 8)
	duration_seconds = maxf(8.0, float(OS.get_environment("ASHENROOT_BOT_DURATION")) if OS.get_environment("ASHENROOT_BOT_DURATION").is_valid_float() else 30.0)
	port = clampi(_environment_int("ASHENROOT_TEST_PORT", 24567), 1, 65535)
	password = OS.get_environment("ASHENROOT_TEST_PASSWORD")
	if password == "":
		password = "stress"
	bot_game = BotGame.new()
	bot_game.name = "Main"
	root.add_child(bot_game)
	session = NETWORK_SESSION_SCRIPT.new()
	session.name = "NetworkSession"
	bot_game.add_child(session)
	session.setup(bot_game)
	session.chat_received.connect(func(_peer_id: int, _name: String, _message: String) -> void: chat_received += 1)
	await process_frame
	await _join()
	if not session.joined:
		await _finish()
		return
	var started := Time.get_ticks_msec()
	var last_tick := started
	var action_due := started + 700 + bot_index * 80
	var chat_due := started + 1200 + bot_index * 100
	var reconnect_done := false
	while Time.get_ticks_msec() - started < int(duration_seconds * 1000.0):
		await create_timer(0.016).timeout
		var now := Time.get_ticks_msec()
		var delta := clampf(float(now - last_tick) / 1000.0, 0.001, 0.1)
		last_tick = now
		_move_bot(now, delta)
		session.tick(delta)
		peak_roster = maxi(peak_roster, session.player_count())
		if session.joined and now >= action_due:
			action_due = now + 900 + bot_index * 13
			_send_world_action()
		if session.joined and now >= chat_due:
			chat_due = now + 4000 + bot_index * 37
			session.send_chat("soak bot %d tick %d" % [bot_index + 1, actions_sent])
		if not reconnect_done and now - started >= int(duration_seconds * 500.0):
			reconnect_done = true
			session.shutdown("")
			for _frame in range(25):
				await create_timer(0.016).timeout
			await _join()
			if session.joined:
				reconnects += 1
				last_tick = Time.get_ticks_msec()
			else:
				break
	_require(session.joined, "Bot was disconnected before the soak test ended")
	_require(reconnects == 1, "Bot reconnect did not complete")
	_require(bot_game.snapshots_received > 0, "Bot did not receive compressed entity snapshots")
	_require(chat_received > 0, "Bot did not receive reliable chat")
	_require(actions_sent >= 3, "Bot did not send enough world actions")
	_require(str(session.connection_quality) in ["good", "fair", "poor"], "Bot did not measure latency")
	if not failed:
		print("NETWORK_STRESS_BOT_OK %s" % JSON.stringify({
			"bot": bot_index,
			"peak_roster": peak_roster,
			"reconnects": reconnects,
			"snapshots": bot_game.snapshots_received,
			"tile_updates": bot_game.tile_updates_received,
			"profile_updates": bot_game.profile_updates_received,
			"chat_received": chat_received,
			"actions_sent": actions_sent,
			"ping_ms": session.ping_ms,
			"diagnostics": session.get_diagnostics(),
		}))
	await _finish()


func _join() -> void:
	bot_game.disconnected_reason = ""
	var result: int = int(session.join_server("127.0.0.1", port, password, "Soak Bot %d" % (bot_index + 1)))
	_require(result == OK, "Bot could not create an ENet client")
	if result != OK:
		return
	var deadline := Time.get_ticks_msec() + 20000
	var last_tick := Time.get_ticks_msec()
	while not session.joined and session.is_active() and Time.get_ticks_msec() < deadline:
		await create_timer(0.016).timeout
		var now := Time.get_ticks_msec()
		session.tick(clampf(float(now - last_tick) / 1000.0, 0.001, 0.1))
		last_tick = now
	_require(session.joined, "Bot handshake/world transfer timed out: %s" % bot_game.disconnected_reason)


func _move_bot(now_msec: int, delta: float) -> void:
	if not session.joined:
		return
	var phase := float(now_msec % 12000) / 12000.0 * TAU + float(bot_index) * 0.61
	velocity = Vector2(cos(phase) * 44.0, sin(phase * 0.5) * 8.0)
	bot_game.velocity = velocity
	bot_game.player_position += velocity * delta


var velocity := Vector2.ZERO


func _send_world_action() -> void:
	var target := bot_game.target_tile
	match actions_sent % 5:
		0:
			session.request_game_action("craft", {"recipe_id": "workbench"})
		1:
			if target.x >= 0:
				session.request_game_action("place", {"x": target.x, "y": target.y, "item_id": "dirt", "build_id": ""})
		2:
			if target.x >= 0:
				session.request_game_action("mine", {"x": target.x, "y": target.y})
		3:
			session.request_game_action("loadout", {"selected_slot": actions_sent % 5, "current_tool": "wooden_pickaxe", "equipped_weapon": ""})
		_:
			if target.x >= 0:
				session.request_game_action("interact", {"x": target.x, "y": target.y})
	actions_sent += 1


func _environment_int(name: String, fallback: int) -> int:
	var value := OS.get_environment(name)
	return int(value) if value.is_valid_int() else fallback


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BOT_%d %s" % [bot_index, message])


func _finish() -> void:
	if session != null:
		session.shutdown("")
	if bot_game != null:
		bot_game.queue_free()
	await process_frame
	quit(1 if failed else 0)
