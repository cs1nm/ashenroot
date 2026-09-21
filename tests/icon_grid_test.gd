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
	var ids: Array[String] = ["bed", "chair", "cloudstone", "door", "earth_shard", "fence", "lantern", "ladder", "leviathan_scale", "platform", "rope", "sky_crystal", "sky_feather", "sky_fragment", "sky_shard", "snow_block", "star_dust", "table", "trapdoor", "wind_shard", "window", "zephyr_feather", "wooden_axe", "iron_axe", "ash_charm_alt", "ash_sift"]
	var cl := CanvasLayer.new()
	cl.layer = 100
	root.add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.07)
	bg.size = Vector2(1280, 720)
	cl.add_child(bg)
	var k := 0
	for id in ids:
		var b := Button.new()
		b.text = id.substr(0, 10)
		b.icon = game._item_icon(id)
		b.expand_icon = true
		b.custom_minimum_size = Vector2(150, 60)
		b.position = Vector2(20 + (k % 6) * 205, 20 + (k / 6) * 80)
		cl.add_child(b)
		k += 1
	for i in range(8):
		await process_frame
	root.get_texture().get_image().save_png("/home/user/shots/icon_grid.png")
	print("GRID saved, k=", k)
	game.queue_free()
	await process_frame
	quit()
