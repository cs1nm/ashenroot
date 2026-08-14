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

	game.enemies.clear()
	game.combat_impacts.clear()
	game.hit_particles.clear()
	game.damage_numbers.clear()
	game.combat_hit_stop_timer = 0.0
	game.camera_shake_strength = 0.0
	game.camera_shake_time = 0.0

	game._spawn_enemy("wild_slime", game.player_position + Vector2(24.0, 0.0))
	var enemy_hp := int(game.enemies[0].get("hp", 1))
	game._damage_enemy(0, 3, Vector2.RIGHT, "physical")
	_require(not game.enemies.is_empty() and int(game.enemies[0].get("hp", enemy_hp)) < enemy_hp, "Confirmed hit did not damage the enemy")
	_require(not game.combat_impacts.is_empty(), "Confirmed hit did not create a contact effect")
	_require(game.hit_particles.size() >= 7, "Confirmed hit did not create directional sparks")
	_require(not game.damage_numbers.is_empty(), "Confirmed hit did not create a damage number")
	_require(game.combat_hit_stop_timer > 0.0, "Confirmed close hit did not trigger hit-stop")
	_require(game.camera_shake_strength > 0.0 and game.camera_shake_time > 0.0, "Confirmed hit did not trigger camera trauma")

	game.combat_hit_stop_timer = 0.0
	game.player_hurt_timer = 0.0
	game.combat_impacts.clear()
	var player_hp: int = int(game.health)
	var applied: bool = game._damage_player(5, Vector2.LEFT, "physical")
	_require(applied and game.health == player_hp - 5, "Player hit feedback did not apply damage")
	_require(game.player_hurt_flash > 0.0, "Player hit did not trigger the edge flash")
	_require(not game.combat_impacts.is_empty(), "Player hit did not create a contact effect")
	var blocked: bool = game._damage_player(5, Vector2.LEFT, "physical")
	_require(not blocked and game.health == player_hp - 5, "Player i-frames allowed a duplicate hit")
	game.player_velocity = Vector2.ZERO
	game.player_statuses.clear()
	game._enemy_hit_player({"damage": 5, "damage_type": "poison"}, 1, "poison")
	_require(game.player_velocity == Vector2.ZERO, "Player i-frames allowed enemy knockback")
	_require(game.player_statuses.is_empty(), "Player i-frames allowed an enemy status effect")

	game._update_combat_impacts(1.0)
	_require(game.combat_impacts.is_empty(), "Combat impact effects did not expire")

	if failed:
		quit(1)
		return
	print("COMBAT_FEEDBACK_SMOKE_OK")
	game.queue_free()
	await process_frame
	quit()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
