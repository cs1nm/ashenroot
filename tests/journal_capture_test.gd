extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame
	game._hide_main_menu()
	game.world_loaded = true
	game._generate_world()
	game._close_inventory_screens()
	game._set_journal_open(true)
	game.known_recipes["door"] = true
	game.known_recipes["ash_charm_alt"] = true
	game.known_recipes["ash_sift"] = true
	game.known_recipes["bed"] = true
	game.known_recipes["lantern"] = true
	game.material_knowledge["sky_shard"] = {"stage": 1}
	game.material_knowledge["leviathan_scale"] = {"stage": 2}
	game._refresh_journal()
	for i in range(10):
		await process_frame
	root.get_texture().get_image().save_png("/home/user/shots/journal_look.png")
	print("JOURNAL saved")
	game.queue_free()
	await process_frame
	quit()
