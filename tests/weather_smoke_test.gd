extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	_require(game.WEATHER_TYPES.size() == 5, "Weather type list is incomplete")
	_require(game._weather_kind_is_valid(game.WEATHER_CLEAR), "Clear weather is rejected")
	_require(not game._weather_kind_is_valid("leviathan_weather"), "Unknown weather is accepted")

	var surface_x := int(game.WORLD_WIDTH / 2)
	var surface_y := int(game.surface_heights[surface_x])
	game.player_position = Vector2(
		surface_x * game.TILE_SIZE + game.TILE_SIZE * 0.5,
		(surface_y - 2) * game.TILE_SIZE
	)
	_require(game._weather_exposure() > 0.99, "Surface weather exposure is not full")

	game._start_weather(game.WEATHER_BLIZZARD, 60.0)
	var timer_before: float = float(game.weather_timer)
	game._update_weather(1.0, false, false)
	_require(is_equal_approx(game.weather_timer, timer_before), "A client-side weather update advanced the server timer")
	_require(game.weather_intensity > 0.0, "Weather intensity did not ease in")
	_require(game.weather_particles.is_empty(), "Dedicated/no-render weather created particles")

	game.weather_intensity = 1.0
	_require(game._weather_temperature_shift() < -5.0, "Surface blizzard does not lower ambient temperature")
	_require(game._weather_visibility_penalty_at(game.player_position) > 0.5, "Blizzard does not reduce surface visibility")
	_require(game._weather_noise_mask_at(game.player_position) < 1.0, "Blizzard does not mask movement noise")
	game.player_statuses.clear()
	game.weather_effect_timer = 0.0
	game._update_weather_player_effects(0.1)
	_require(game.player_statuses.has("slow"), "Unprotected player is not slowed by a blizzard")
	game._update_weather(0.016, false, true)
	_require(not game.weather_particles.is_empty(), "Visible surface weather created no particles")

	game.player_position.y = (surface_y + game.WEATHER_DEPTH_SILENT + 2) * game.TILE_SIZE
	_require(is_zero_approx(game._weather_exposure()), "Weather still reaches deep underground")
	_require(is_zero_approx(game._weather_temperature_shift()), "Underground weather still changes temperature")
	_require(is_zero_approx(game._weather_visibility_penalty_at(game.player_position)), "Underground weather still reduces visibility")
	game._update_weather(0.016, false, true)
	_require(game.weather_particles.is_empty(), "Underground weather particles were not cleared")

	game.player_position.y = (surface_y - 2) * game.TILE_SIZE
	game._start_weather(game.WEATHER_RAIN, 60.0)
	game.weather_intensity = 1.0
	game.player_statuses.clear()
	game.weather_effect_timer = 0.0
	game._update_weather_player_effects(0.1)
	_require(game.player_statuses.has("wet"), "Rain does not apply the wet status")
	_require(game._weather_noise_mask_at(game.player_position) < 1.0, "Rain does not mask movement noise")

	game._start_weather(game.WEATHER_ASHFALL, 60.0)
	game.weather_intensity = 1.0
	_require(game._weather_temperature_shift() > 5.0, "Ashfall does not raise ambient temperature")

	game._start_weather(game.WEATHER_FOG, 60.0)
	game.weather_intensity = 1.0
	_require(game._weather_noise_mask_at(game.player_position) > 1.0, "Fog does not carry movement noise further")

	game._start_weather(game.WEATHER_STORM, 75.0)
	game.weather_intensity = 0.8
	var save_data: Dictionary = game._build_save_data()
	for key in [
		"weather", "weather_timer", "weather_intensity",
		"weather_target_intensity", "weather_lightning_timer", "weather_rng_state"
	]:
		_require(save_data.has(key), "Save data is missing weather field: %s" % key)

	game.weather = game.WEATHER_CLEAR
	game.weather_intensity = 0.0
	game._restore_weather_state(save_data)
	_require(game.weather == game.WEATHER_STORM, "Saved weather kind was not restored")
	_require(is_equal_approx(game.weather_intensity, 0.8), "Saved weather intensity was not restored")

	var snapshot: Dictionary = game._network_build_entity_snapshot()
	for key in [
		"weather", "weather_timer", "weather_intensity",
		"weather_target_intensity", "weather_lightning_flash"
	]:
		_require(snapshot.has(key), "Network snapshot is missing weather field: %s" % key)
	game.weather = game.WEATHER_CLEAR
	game.weather_intensity = 0.0
	game._apply_weather_snapshot(snapshot)
	_require(game.weather == game.WEATHER_STORM, "Network snapshot did not apply weather kind")
	_require(is_equal_approx(game.weather_intensity, 0.8), "Network snapshot did not apply weather intensity")

	game._restore_weather_state({})
	_require(game.weather == game.WEATHER_CLEAR, "Legacy save does not default to clear weather")
	_require(is_zero_approx(game.weather_intensity), "Legacy save starts with active weather")

	game._start_weather(game.WEATHER_RAIN, 0.05)
	game.weather_intensity = 1.0
	game._update_weather(0.10, true, false)
	_require(game.weather == game.WEATHER_CLEAR, "Authoritative weather timer did not return to clear")

	game.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("WEATHER_SMOKE_OK")
	quit()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
