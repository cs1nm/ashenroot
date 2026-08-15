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
	var port := 24900 + int(Time.get_ticks_msec() % 200)
	var result: int = int(game.network_session.host_server(port, "", "World Actions", "Host", true, false))
	_require(result == OK, "Listen server could not start")
	var peer_id := 2
	var profile_id := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	var tile_x := clampi(int(game.player_position.x / game.TILE_SIZE) + 2, 2, game.WORLD_WIDTH - 3)
	var tile_y := clampi(int(game.player_position.y / game.TILE_SIZE), 2, game.WORLD_HEIGHT - 3)
	var peer_pos := Vector2(float(tile_x - 2) * game.TILE_SIZE + game.TILE_SIZE * 0.5, float(tile_y) * game.TILE_SIZE + game.TILE_SIZE * 0.5)
	game.network_session.authenticated_peers[peer_id] = true
	game.network_session.peer_profile_ids[peer_id] = profile_id
	game.network_session.players[peer_id] = {
		"name": "Builder",
		"pos": peer_pos,
		"vel": Vector2.ZERO,
		"facing": 1,
		"on_floor": true,
		"health": 100,
		"max_health": 100,
		"class": "Warrior",
		"weapon": ""
	}
	game._network_prepare_player_profile(profile_id, "Builder", peer_pos)
	game._update_pause_player_list()
	_require(game.pause_players_box.get_child_count() >= 3, "Pause-menu player roster was not built")
	game.world[tile_y][tile_x] = game.Tile.AIR
	game.world[tile_y + 1][tile_x] = game.Tile.DIRT
	var dirt_before := int((game.network_player_profiles[profile_id] as Dictionary).get("inventory", {}).get("dirt", 0))
	game._network_server_game_action(peer_id, "place", {"x": tile_x, "y": tile_y, "item_id": "dirt", "build_id": ""})
	_require(game._get_tile(tile_x, tile_y) == game.Tile.DIRT, "Server did not place validated block")
	var profile: Dictionary = game.network_player_profiles[profile_id]
	_require(int((profile.get("inventory", {}) as Dictionary).get("dirt", 0)) == dirt_before - 1, "Placed block did not consume profile inventory")
	game.network_mine_ready_msec.erase(peer_id)
	game._network_server_game_action(peer_id, "mine", {"x": tile_x, "y": tile_y})
	_require(game._get_tile(tile_x, tile_y) == game.Tile.AIR, "Server did not mine validated block")
	_require(not game.dropped_items.is_empty(), "Mining did not create authoritative world loot")
	game.world[tile_y][tile_x] = game.Tile.CHEST
	var chest_key: String = str(game._tile_key(Vector2i(tile_x, tile_y)))
	game.chest_loot[chest_key] = {"wood": 5}
	profile = game.network_player_profiles[profile_id]
	var wood_before := int((profile.get("inventory", {}) as Dictionary).get("wood", 0))
	game._network_server_game_action(peer_id, "chest_take", {"chest_key": chest_key, "item_id": "wood", "amount": 2})
	profile = game.network_player_profiles[profile_id]
	_require(int((profile.get("inventory", {}) as Dictionary).get("wood", 0)) == wood_before + 2, "Chest take did not grant profile item")
	_require(int((game.chest_loot[chest_key] as Dictionary).get("wood", 0)) == 3, "Chest take did not update shared chest")
	game._network_server_game_action(peer_id, "chest_store", {"chest_key": chest_key, "item_id": "wood", "amount": 3})
	profile = game.network_player_profiles[profile_id]
	_require(int((profile.get("inventory", {}) as Dictionary).get("wood", 0)) == wood_before - 1, "Chest store did not deduct profile item")
	_require(int((game.chest_loot[chest_key] as Dictionary).get("wood", 0)) == 6, "Chest store did not update shared chest")
	_require(int(game._network_validated_attack_damage(peer_id, 999, "melee")) == 5, "Server accepted impossible guest melee damage")
	_require(not bool(game._network_validate_projectile_kind(peer_id, "cannon")), "Server accepted a projectile without the required weapon")
	var damage_result: Dictionary = game._network_server_apply_player_damage(peer_id, 12, "physical", "")
	_require(int(damage_result.get("health", 100)) < 100, "Authoritative remote damage was not recorded")
	profile = game.network_player_profiles[profile_id]
	var damaged_health := int(profile.get("health", 100))
	profile["regen_ready_msec"] = 0
	game.network_player_profiles[profile_id] = profile
	game._network_update_remote_regeneration()
	profile = game.network_player_profiles[profile_id]
	_require(int(profile.get("health", 0)) == damaged_health + 1, "Server-authoritative regeneration failed")
	var save_data: Dictionary = game._build_save_data()
	_require((save_data.get("network_player_profiles", {}) as Dictionary).has(profile_id), "Guest profile is missing from host save")
	if not failed:
		print("NETWORK_WORLD_ACTIONS_SMOKE_OK")
	game.network_session.shutdown("")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
