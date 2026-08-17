extends SceneTree
## Creature sprite fit regression test.
## Guards against two visual bugs introduced by wide/misaligned sprite packs:
##  1. Sprites clipping into walls: the visible idle silhouette must not
##     overhang the physics body by more than MAX_OVERHANG per side.
##  2. Grounded creatures "floating": the lowest opaque pixel of the idle
##     frame must sit exactly on the pack's ground anchor line.
## Run with:
##   Godot --headless --path . --script res://tests/creature_sprite_fit_smoke_test.gd

const MAX_OVERHANG := 12.0        # px per side in world units (< one 16px tile)
const GROUNDED := [
	"mossling", "root_crawler", "cave_worm", "cave_husk", "mushroom_beetle",
	"ash_sentinel", "drowned_guard", "ember_rootling",
]
const FLYING := [
	"bat", "spore_bat", "ash_phantom", "ash_wisp", "ruin_drone",
	"night_ember", "glass_wraith",
]

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	for enemy_type in GROUNDED + FLYING:
		_check_creature(game, str(enemy_type), enemy_type in GROUNDED)
		_check_attack_states_stay_in_pack(game, str(enemy_type))

	# Shared boss reskins must inherit full pack metadata, not just textures.
	for alias in ["storm_herald", "leviathan", "sky_herald", "depth_warden"]:
		if game.enemy_animation_textures.has(alias):
			if (game.enemy_animation_specs.get(alias, {}) as Dictionary).is_empty():
				_fail("%s shares textures but not animation specs" % alias)

	game.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("CREATURE_SPRITE_FIT_OK creatures=%d" % (GROUNDED.size() + FLYING.size()))
	quit()


func _check_creature(game: Variant, enemy_type: String, grounded: bool) -> void:
	var sets: Dictionary = game.enemy_animation_textures.get(enemy_type, {})
	var idle_texture: Texture2D = sets.get("idle", null)
	if idle_texture == null:
		_fail("%s has no idle animation texture" % enemy_type)
		return
	var spec: Dictionary = game._enemy_animation_spec(enemy_type, "idle")
	var frames := maxi(1, int(spec.get("frames", 1)))
	var image := idle_texture.get_image()
	if image == null or image.is_empty():
		_fail("%s idle image could not be read" % enemy_type)
		return
	if image.is_compressed():
		image.decompress()
	var frame_w := int(image.get_width() / frames)
	var bbox := _opaque_bbox(image, frame_w)
	if bbox.size == Vector2i.ZERO:
		_fail("%s idle frame is fully transparent" % enemy_type)
		return

	var sprite_scale := float(game._enemy_sprite_scale(enemy_type))
	var template: Dictionary = game._enemy_template(enemy_type)
	var physics_size: Vector2 = template.get("size", Vector2(16, 16))
	var visual_w := float(bbox.size.x) * sprite_scale
	var overhang := (visual_w - physics_size.x) * 0.5
	if overhang > MAX_OVERHANG:
		_fail("%s visual width %.1f overhangs physics %.0f by %.1f px/side (max %.0f)" % [
			enemy_type, visual_w, physics_size.x, overhang, MAX_OVERHANG])

	if grounded:
		var pack: Dictionary = game.enemy_animation_pack_specs.get(enemy_type, {})
		var anchor: Variant = pack.get("anchor", null)
		if not (anchor is Dictionary):
			_fail("%s pack has no anchor dictionary" % enemy_type)
			return
		var anchor_y := int((anchor as Dictionary).get("y", 0))
		var feet_row := bbox.position.y + bbox.size.y - 1
		var gap := anchor_y - 1 - feet_row
		if gap < 0 or gap > 1:
			_fail("%s feet row %d does not rest on anchor %d (gap %d)" % [
				enemy_type, feet_row, anchor_y, gap])


func _check_attack_states_stay_in_pack(game: Variant, enemy_type: String) -> void:
	## Every attack the creature can enter must resolve to a strip inside its
	## own animation pack. If a state fell through to the legacy static atlas
	## the creature visibly turned into "another mob" mid-attack.
	var sets: Dictionary = game.enemy_animation_textures.get(enemy_type, {})
	var attack_count := int(game._enemy_attack_count(enemy_type))
	for index in range(1, attack_count + 1):
		var state := "attack_%d" % index
		var resolved := str(game._enemy_animation_visual_state(enemy_type, state))
		if not sets.has(resolved):
			_fail("%s %s resolves to '%s' which is not in its pack (legacy atlas fallback)" % [
				enemy_type, state, resolved])


func _opaque_bbox(image: Image, frame_w: int) -> Rect2i:
	var min_x := frame_w
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(frame_w):
			if image.get_pixel(x, y).a > 0.5:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _fail(message: String) -> void:
	failed = true
	push_error(message)
