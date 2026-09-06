extends SceneTree

# Character roster: several heroes with independent progression/appearance.
# Verifies: default roster bootstrap, creation, per-character inventory
# isolation across switches, appearance recolor, persistence round-trip.

func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("CHARACTER_ROSTER_FAIL: %s" % message)
	quit(1)


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame

	# Clean slate for the roster file.
	if FileAccess.file_exists(game.CHARACTERS_PATH):
		DirAccess.remove_absolute(game.CHARACTERS_PATH)
	game._load_characters()
	if game.characters.size() != 1:
		_fail("default roster should bootstrap exactly one hero, got %d" % game.characters.size())
		return
	if int(game.active_character_index) != 0:
		_fail("default active index should be 0")
		return

	# Create a second hero with distinct colors.
	game.char_new_colors = {"skin": "d9b47f", "hair": "a8763e", "tunic": "5d2f2f", "boots": "2f3a44"}
	game.characters.append(game._default_character("Ember", game.char_new_colors))
	game.active_character_index = 1
	game._save_characters()
	if game.characters.size() != 2:
		_fail("expected 2 heroes after creation")
		return

	# Hero 2 plays: give loot, capture.
	game._apply_character_profile()
	game.inventory["copper_bar"] = 7
	game.health = 55
	game._capture_character_profile()

	# Switch to hero 1: must NOT see hero 2's loot.
	game.active_character_index = 0
	game._apply_character_profile()
	if int(game.inventory.get("copper_bar", 0)) != 0:
		_fail("hero 1 inherited hero 2 inventory")
		return
	if int(game.health) != game.MAX_HEALTH:
		_fail("hero 1 health should be full, got %d" % int(game.health))
		return

	# Switch back: loot must survive.
	game.active_character_index = 1
	game._apply_character_profile()
	if int(game.inventory.get("copper_bar", 0)) != 7:
		_fail("hero 2 lost captured inventory")
		return
	if int(game.health) != 55:
		_fail("hero 2 health not restored, got %d" % int(game.health))
		return

	#

	# Persistence round-trip through disk.
	game._save_characters()
	game.characters = []
	game._load_characters()
	if game.characters.size() != 2:
		_fail("roster did not survive disk round-trip")
		return
	if str(game.characters[1].get("name", "")) != "Ember":
		_fail("hero name lost in round-trip")
		return

	# Recolor produces a texture different from the base sheet.
	var recolored: Texture2D = game._recolor_player_sheet({"skin": "d9b47f", "hair": "a8763e", "tunic": "5d2f2f", "boots": "2f3a44"})
	if recolored == null:
		_fail("recolor returned null")
		return
	var base_texture: Texture2D = game._load_png_texture("res://assets/textures/player.png")
	var base_image := base_texture.get_image()
	var recolored_image := recolored.get_image()
	if base_image.is_compressed():
		base_image.decompress()
	if recolored_image.is_compressed():
		recolored_image.decompress()
	base_image.convert(Image.FORMAT_RGBA8)
	recolored_image.convert(Image.FORMAT_RGBA8)
	if base_image.get_data() == recolored_image.get_data():
		_fail("recolored sheet is identical to base sheet")
		return

	# Hero v5 face guardrail (player complaint on v3: the face was hidden
	# behind the fringe and recolor could damage it). Fixed sheet colors —
	# eye white, buckle, outline — must survive ANY palette swap, so the
	# face can never be destroyed. Values mirror the v5 palette (see
	# tools/creature_pipeline/animate_hero.py PROTECTED).
	var base := base_image
	var recolored2 := recolored_image
	var fixed_colors := {
		"eye_white": Color8(236, 238, 240),
		"buckle": Color8(203, 150, 68),
		"outline": Color8(10, 8, 16),
	}
	for fixed_name in fixed_colors.keys():
		var fixed: Color = fixed_colors[fixed_name]
		var unchanged := 0
		var total := 0
		for y in range(base.get_height()):
			for x in range(base.get_width()):
				var p := base.get_pixel(x, y)
				if p.a > 0.5 and absf(p.r - fixed.r) < 0.02 and absf(p.g - fixed.g) < 0.02 and absf(p.b - fixed.b) < 0.02:
					total += 1
					var rp := recolored2.get_pixel(x, y)
					if absf(rp.r - fixed.r) < 0.02 and absf(rp.g - fixed.g) < 0.02 and absf(rp.b - fixed.b) < 0.02:
						unchanged += 1
		if total == 0:
			_fail("palette moved: no %s pixels found on the v4 sheet" % fixed_name)
			return
		if unchanged != total:
			_fail("recolor damaged %s: %d/%d pixels changed" % [fixed_name, total - unchanged, total])
			return
	# Every recolor zone must actually change (tunic/ boots/ hair/ skin all
	# take part) — dead zones mean the customization is lying to the player.
	var zone_check := {
		"skin": Color8(216, 158, 114),
		"hair": Color8(89, 38, 38),
		"tunic": Color8(112, 119, 130),
		"boots": Color8(101, 66, 61),
	}
	for zone_name in zone_check.keys():
		var ref: Color = zone_check[zone_name]
		var changed := 0
		for y in range(base.get_height()):
			for x in range(base.get_width()):
				var p := base.get_pixel(x, y)
				if p.a > 0.5 and absf(p.r - ref.r) < 0.02 and absf(p.g - ref.g) < 0.02 and absf(p.b - ref.b) < 0.02:
					var rp := recolored2.get_pixel(x, y)
					if absf(rp.r - ref.r) >= 0.02 or absf(rp.g - ref.g) >= 0.02 or absf(rp.b - ref.b) >= 0.02:
						changed += 1
		if changed == 0:
			_fail("zone %s never changes when recolored (dead customization)" % zone_name)
			return

	# Deletion guardrail: roster never goes empty.
	game.characters = [game.characters[0]]
	game.active_character_index = 0
	game._on_delete_character()
	if game.characters.size() != 1:
		_fail("last hero must never be deletable")
		return

	print("CHARACTER_ROSTER_OK heroes=%d" % game.characters.size())
	game.queue_free()
	await process_frame
	quit()
