extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.health = 100000

	var enemy_types := [
		"wild_slime", "mossling", "root_crawler", "cave_worm", "bat", "cave_husk",
		"spore_bat", "mushroom_beetle", "ash_phantom", "ash_wisp", "ash_sentinel",
		"ruin_drone", "drowned_guard", "ember_rootling", "night_ember", "glass_wraith",
		"stone_beast", "heartwood_boss"
	]
	var attacks_checked := 0
	for enemy_type in enemy_types:
		var enemy: Dictionary = game._enemy_template(enemy_type)
		enemy["type"] = enemy_type
		enemy["pos"] = game.player_position + Vector2(36, -12)
		enemy["vel"] = Vector2.ZERO
		enemy["facing"] = -1
		enemy["statuses"] = {}
		for attack_index in range(1, game._enemy_attack_count(enemy_type) + 1):
			enemy["attack_index"] = attack_index
			game._execute_enemy_attack(enemy, enemy["pos"], -1, 24.0, 160.0)
			attacks_checked += 1
		game.enemy_projectiles.clear()
		game.enemies.clear()

	for enemy_type in enemy_types:
		var flying := bool(game._enemy_template(enemy_type).get("flying", false))
		game._spawn_enemy(enemy_type, game.player_position + Vector2(80, -36 if flying else -8))
	for frame in range(180):
		game._update_enemy_ai(1.0 / 60.0)

	print("ENEMY_SMOKE_OK creatures=%d attacks=%d" % [enemy_types.size(), attacks_checked])
	game.queue_free()
	await process_frame
	quit()
