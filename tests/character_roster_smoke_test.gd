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

	# Customization is DEFERRED for the classic wanderer sheet (player's
	# decision): CHAR_RECOLOR_ZONES still describe the old hero v5 palette,
	# so recoloring the classic sheet must be a SAFE NO-OP. Guardrails that
	# must hold forever regardless of the sheet:
	#  - recolor never crashes and returns a texture;
	#  - the alpha mask is preserved exactly (no pixels lost or invented).
	var recolored: Texture2D = game._recolor_player_sheet({"skin": "d9b47f", "hair": "a8763e", "tunic": "5d2f2f", "boots": "2f3a44"})
	if recolored == null:
		_fail("recolor returned null")
		return
	var base_tex: Texture2D = game._load_png_texture("res://assets/textures/player.png")
	if base_tex == null:
		_fail("base sheet failed to load")
		return
	var base_image: Image = base_tex.get_image()
	var recolored_image: Image = recolored.get_image()
	if base_image.is_compressed():
		base_image.decompress()
	if recolored_image.is_compressed():
		recolored_image.decompress()
	base_image.convert(Image.FORMAT_RGBA8)
	recolored_image.convert(Image.FORMAT_RGBA8)
	if base_image.get_size() != recolored_image.get_size():
		_fail("recolor changed sheet size")
		return
	for y in range(base_image.get_height()):
		for x in range(base_image.get_width()):
			var bp := base_image.get_pixel(x, y)
			var rp := recolored_image.get_pixel(x, y)
			if (bp.a > 0.5) != (rp.a > 0.5):
				_fail("recolor altered the alpha mask at (%d,%d)" % [x, y])
				return
	# NOTE: the old v5-based zone assertions (fixed colors survive, every
	# zone must change) were removed on purpose — the classic sheet does not
	# share the v5 palette and customization for it is deferred. When the
	# zones are re-mapped to the classic palette, bring those checks back.

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
