extends SceneTree

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.mobile_ui_enabled = true

	_test_static_light_cache(game)
	_test_mobile_minimap_budget(game)
	_test_mobile_fx_budget(game)
	_test_draw_culling(game)

	if not failed:
		print("MOBILE_PERFORMANCE_SMOKE_OK light_scans=%d minimap_rebuilds=%d" % [
			game.static_light_scan_count, game.minimap_rebuild_count
		])
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _test_static_light_cache(game: Variant) -> void:
	game.cached_light_revision = -1
	game._collect_visible_light_sources()
	var scans_after_first := int(game.static_light_scan_count)
	_require(scans_after_first > 0, "Initial static light scan did not run")
	game.player_position += Vector2(1.0, 0.0)
	game._collect_visible_light_sources()
	_require(int(game.static_light_scan_count) == scans_after_first, "Static lights were rescanned without a bounds or terrain change")
	_require((game.visible_light_sources[0] as Dictionary).get("pos", Vector2.ZERO).is_equal_approx(game.player_position / game.TILE_SIZE), "Cached lights froze the moving player light")

	var bounds_center: Vector2i = game.cached_light_bounds.get_center()
	var test_tile := Vector2i(clampi(bounds_center.x, 1, game.WORLD_WIDTH - 2), clampi(bounds_center.y, 1, game.WORLD_HEIGHT - 2))
	var original_tile: int = game._get_tile(test_tile.x, test_tile.y)
	game._set_tile(test_tile.x, test_tile.y, game.Tile.TORCH)
	game._collect_visible_light_sources()
	_require(int(game.static_light_scan_count) == scans_after_first + 1, "Terrain edit did not invalidate static light cache")
	var torch_found := false
	for source_variant in game.visible_light_sources:
		var source: Dictionary = source_variant
		if str(source.get("kind", "")) == "torch" and (source.get("pos", Vector2.ZERO) as Vector2).distance_to(Vector2(test_tile) + Vector2(0.5, 0.5)) < 0.1:
			torch_found = true
			break
	_require(torch_found, "Rebuilt static light cache omitted a new torch")
	game._set_tile(test_tile.x, test_tile.y, original_tile)


func _test_mobile_minimap_budget(game: Variant) -> void:
	var center := Vector2i(floori(game.player_position.x / game.TILE_SIZE), floori(game.player_position.y / game.TILE_SIZE))
	game.minimap_rebuild_count = 0
	game.minimap_rendered_center = center
	game.minimap_rendered_revision = game.world_tile_revision
	game.minimap_timer = 0.0
	game._update_minimap(1.0)
	_require(game.minimap_rebuild_count == 0, "Mobile minimap ignored its longer refresh interval")
	game._update_minimap(0.5)
	_require(game.minimap_rebuild_count == 0, "Unchanged stationary minimap was rebuilt")
	game.minimap_rendered_revision = -1
	game.minimap_timer = 99.0
	game._update_minimap(0.0)
	_require(game.minimap_rebuild_count == 1, "Dirty minimap was not rebuilt")


func _test_mobile_fx_budget(game: Variant) -> void:
	game.hit_particles.clear()
	game.damage_numbers.clear()
	game.combat_impacts.clear()
	for i in range(120):
		game.hit_particles.append({"pos": game.player_position})
		game.damage_numbers.append({"pos": game.player_position})
		game.combat_impacts.append({"pos": game.player_position})
	game._trim_mobile_transient_fx()
	_require(game.hit_particles.size() == game.MOBILE_MAX_HIT_PARTICLES, "Mobile hit-particle cap failed")
	_require(game.damage_numbers.size() == game.MOBILE_MAX_DAMAGE_NUMBERS, "Mobile damage-number cap failed")
	_require(game.combat_impacts.size() == game.MOBILE_MAX_COMBAT_IMPACTS, "Mobile combat-impact cap failed")


func _test_draw_culling(game: Variant) -> void:
	var visible_rect: Rect2 = game._visible_world_draw_rect()
	_require(visible_rect.has_point(game.camera.get_screen_center_position()), "Draw culling excludes the camera center")
	_require(not visible_rect.has_point(game.camera.get_screen_center_position() + Vector2(100000.0, 100000.0)), "Draw culling accepts distant effects")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
