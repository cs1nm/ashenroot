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
	var port := 24720 + int(Time.get_ticks_msec() % 200)
	var result: int = int(game.network_session.host_server(port, "", "Rules Smoke", "Host", true, false))
	_require(result == OK, "Listen server could not start")
	game.network_session.players[1] = game._network_local_player_state("Host")
	game.network_session.players[2] = {
		"name": "Attacker",
		"pos": game.player_position - Vector2(30.0, 0.0),
		"vel": Vector2.ZERO,
		"facing": 1,
		"on_floor": true,
		"health": 100,
		"max_health": 100
	}
	game.network_session.authenticated_peers[2] = true
	game.player_hurt_timer = 0.0
	var original_health: int = int(game.health)
	game.network_session._apply_pvp_melee(2, 58.0, 5, 1, "physical")
	_require(game.health < original_health, "Enabled PvP did not apply a validated melee hit")
	game.player_hurt_timer = 0.0
	game.network_session._last_damage_msec.clear()
	game.network_session.set_pvp_enabled(false)
	var pve_health: int = int(game.health)
	game.network_session._apply_pvp_melee(2, 58.0, 5, 1, "physical")
	_require(game.health == pve_health, "PvE mode allowed player damage")
	_require(game.network_session.player_count() == 2, "Listen-server roster is inconsistent")
	game._spawn_loot_with_velocity(game.player_position, "dirt", 2, Vector2.ZERO, 0.0)
	var loot_id := int(game.dropped_items[-1].get("network_id", -1))
	var dirt_before := int(game.inventory.get("dirt", 0))
	game.network_session._apply_loot_pickup(1, loot_id)
	_require(game.dropped_items.is_empty(), "Authoritative loot was not removed after pickup")
	_require(int(game.inventory.get("dirt", 0)) == dirt_before + 2, "Server did not grant validated loot")
	if not failed:
		print("NETWORK_RULES_SMOKE_OK")
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
