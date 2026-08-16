extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var settings_path := "user://settings_mobile_qol_smoke.cfg"
	var old_volume: float = float(game.settings_volume)
	game.settings_volume = 0.35
	_require(game._save_settings(settings_path) == OK, "Audio settings could not be saved")
	game.settings_volume = 0.9
	game._load_settings(settings_path)
	_require(is_equal_approx(float(game.settings_volume), 0.35), "Saved audio volume was not restored")

	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", 5.0)
	_require(config.save(settings_path) == OK, "Invalid-value settings fixture could not be saved")
	game._load_settings(settings_path)
	_require(is_equal_approx(float(game.settings_volume), 1.0), "Loaded audio volume was not clamped")

	game.settings_volume = 0.0
	game._apply_master_volume()
	for player_variant in game.sound_players.values():
		var player := player_variant as AudioStreamPlayer
		_require(player != null and player.volume_db <= -79.0, "Zero volume does not mute generated sounds")

	var pickaxe_text := "\n".join(game._item_characteristic_lines("iron_pickaxe"))
	_require(pickaxe_text.contains("Mining power") and pickaxe_text.contains("mining speed"), "Tool details are incomplete")
	var boots_text := "\n".join(game._item_characteristic_lines("wind_boots"))
	_require(boots_text.contains("Movement speed +10%"), "Movement bonus is missing from item details")
	var diving_text := "\n".join(game._item_characteristic_lines("diving_charm"))
	_require(diving_text.contains("breathing underwater") and diving_text.contains("Cold protection"), "Diving charm details are incomplete")
	_require("powered flight" in "\n".join(game._item_characteristic_lines("jetpack")), "Jetpack flight detail is missing")
	_require("grappling hook" in "\n".join(game._item_characteristic_lines("grappling_hook")), "Grappling hook detail is missing")
	_require("Restores 25 health" in "\n".join(game._item_characteristic_lines("fungal_salve")), "Consumable healing detail is missing")
	_require(game._item_tooltip_text("wind_boots", 2).contains("Wind Boots x2"), "Detailed tooltip lost item quantity")

	var expected_icons := {
		"wet": "status_wet",
		"root_bind": "status_root_bind",
		"fragile": "status_fragile",
		"armor_break": "status_armor_break"
	}
	for status in expected_icons:
		var icon_id := str(game._status_icon_id(status))
		_require(icon_id == str(expected_icons[status]), "Wrong status icon mapping for %s" % status)
		var icon_path := "res://assets/ui/%s.png" % icon_id
		_require(FileAccess.file_exists(icon_path), "Missing status icon asset: %s" % icon_id)
		_require(game._ui_tex(icon_path) != null, "Status icon could not be loaded: %s" % icon_id)

	game.settings_volume = old_volume
	game._apply_master_volume()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	game.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("MOBILE_QOL_SMOKE_OK")
	quit()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
