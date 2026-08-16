extends SceneTree
## Mobile controls & Android lifecycle regression test.
## Covers: multitouch pointer ownership for the virtual joystick and action
## buttons, forced release on menu/lifecycle transitions, safe-area inset
## application, hotbar touch targets, long-press tooltips and the debounced
## background autosave. Run with:
##   ASHEN_FORCE_MOBILE_UI=1 Godot --headless --path . --script res://tests/mobile_controls_smoke_test.gd

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Variant = load("res://Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.mobile_ui_enabled = true

	_test_joystick_pointer_ownership(game)
	_test_joystick_cancel_and_force_release(game)
	_test_action_button_pointer_ownership(game)
	_test_action_button_slide_off(game)
	_test_action_button_emulated_mouse_filter(game)
	_test_lifecycle_transient_input_reset(game)
	_test_background_save_debounce(game)
	_test_resume_recovers_render_state(game)
	_test_safe_area_insets(game)
	_test_hotbar_touch_targets(game)
	_test_longpress_tooltip(game)
	_test_pause_releases_input(game)

	var releases := int(game.transient_input_release_count)
	var resumes := int(game.lifecycle_resume_count)
	var safe_area_applies := int(game.safe_area_apply_count)
	game.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("MOBILE_CONTROLS_SMOKE_OK releases=%d resumes=%d safe_area_applies=%d" % [
		releases, resumes, safe_area_applies
	])
	quit()


func _touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = pos
	return event


func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	return event


func _test_joystick_pointer_ownership(game: Variant) -> void:
	var joystick: Control = game.mobile_joystick
	_require(joystick != null, "Virtual joystick is missing")
	joystick.force_release()
	var center: Vector2 = joystick.size * 0.5

	joystick._gui_input(_touch(0, true, center))
	_require(int(joystick.touch_index) == 0, "Joystick did not capture finger 0")
	# A second finger must not steal or reset the stick.
	joystick._gui_input(_touch(1, true, center + Vector2(10, 0)))
	_require(int(joystick.touch_index) == 0, "Second finger stole the joystick")
	# Drag with the owning finger moves the axis; a foreign drag is ignored.
	joystick._gui_input(_drag(1, center + Vector2(60, 0)))
	_require((joystick.axis as Vector2).is_zero_approx(), "Foreign drag moved the joystick axis")
	joystick._gui_input(_drag(0, center + Vector2(60, 0)))
	_require(float(joystick.axis.x) > 0.5, "Owning finger drag did not move the axis")
	_require(Input.is_action_pressed("move_right"), "Joystick right drag did not press move_right")
	# Releasing the foreign finger must not release the stick.
	joystick._gui_input(_touch(1, false, center))
	_require(int(joystick.touch_index) == 0, "Foreign release freed the joystick")
	_require(Input.is_action_pressed("move_right"), "Foreign release dropped move_right")
	# Releasing the owner frees everything.
	joystick._gui_input(_touch(0, false, center))
	_require(int(joystick.touch_index) == -1, "Owner release did not free the joystick")
	_require(not Input.is_action_pressed("move_right"), "move_right stayed pressed after release")


func _test_joystick_cancel_and_force_release(game: Variant) -> void:
	var joystick: Control = game.mobile_joystick
	var center: Vector2 = joystick.size * 0.5
	joystick._gui_input(_touch(0, true, center))
	joystick._gui_input(_drag(0, center + Vector2(-60, 0)))
	_require(Input.is_action_pressed("move_left"), "Setup: move_left not pressed")
	# A cancelled touch arrives as pressed == false with canceled == true.
	var cancel := _touch(0, false, center)
	cancel.canceled = true
	joystick._gui_input(cancel)
	_require(int(joystick.touch_index) == -1, "Cancelled touch left the joystick captured")
	_require(not Input.is_action_pressed("move_left"), "Cancelled touch left move_left stuck")

	joystick._gui_input(_touch(0, true, center))
	joystick._gui_input(_drag(0, center + Vector2(60, 0)))
	joystick.force_release()
	_require(not Input.is_action_pressed("move_right"), "force_release left move_right stuck")
	_require(int(joystick.forced_release_count) > 0, "Forced release was not counted")


func _test_action_button_pointer_ownership(game: Variant) -> void:
	var jump: Control = game.jump_button
	_require(jump != null, "Jump button is missing")
	jump.force_release()
	var center: Vector2 = jump.size * 0.5

	jump._gui_input(_touch(2, true, center))
	_require(bool(jump.is_held()), "Jump did not activate on touch")
	# Another finger pressing the active button must not double-fire or steal.
	jump._gui_input(_touch(3, true, center))
	_require(bool(jump.is_held()), "Second finger broke the held jump button")
	# The foreign finger's release must not release the button.
	jump._gui_input(_touch(3, false, center))
	_require(bool(jump.is_held()), "Foreign release freed the jump button")
	jump._gui_input(_touch(2, false, center))
	_require(not bool(jump.is_held()), "Owner release did not free the jump button")


func _test_action_button_slide_off(game: Variant) -> void:
	var jump: Control = game.jump_button
	jump.force_release()
	var center: Vector2 = jump.size * 0.5
	jump._gui_input(_touch(0, true, center))
	_require(bool(jump.is_held()), "Setup: jump not held")
	# A foreign drag far away must not release the button...
	jump._gui_input(_drag(1, center + Vector2(500, 0)))
	_require(bool(jump.is_held()), "Foreign drag released the jump button")
	# ...but the owning finger sliding far off must.
	jump._gui_input(_drag(0, center + Vector2(500, 0)))
	_require(not bool(jump.is_held()), "Owning slide-off did not release the jump button")


func _test_action_button_emulated_mouse_filter(game: Variant) -> void:
	var atk: Control = game.atk_button
	atk.force_release()
	var pressed_count := [0]
	var handler := func() -> void: pressed_count[0] += 1
	atk.button_pressed.connect(handler)
	var center: Vector2 = atk.size * 0.5
	# Real touch fires once.
	atk._gui_input(_touch(0, true, center))
	atk._gui_input(_touch(0, false, center))
	# The synthetic mouse event Android emits for the same touch must be ignored.
	var emulated := InputEventMouseButton.new()
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.position = center
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	atk._gui_input(emulated)
	atk.button_pressed.disconnect(handler)
	_require(pressed_count[0] == 1, "ATK fired %d times for one touch (emulated mouse not filtered)" % pressed_count[0])


func _test_lifecycle_transient_input_reset(game: Variant) -> void:
	var joystick: Control = game.mobile_joystick
	var jump: Control = game.jump_button
	var center: Vector2 = joystick.size * 0.5
	joystick._gui_input(_touch(0, true, center))
	joystick._gui_input(_drag(0, center + Vector2(60, 0)))
	jump._gui_input(_touch(1, true, jump.size * 0.5))
	game.physical_move_left_held = true
	game.mouse_mine_held = true
	game.mobile_world_touch_index = 4
	Input.action_press("mine")

	var releases_before := int(game.transient_input_release_count)
	game._release_all_transient_input()
	_require(int(game.transient_input_release_count) == releases_before + 1, "Transient release was not counted")
	_require(not Input.is_action_pressed("move_right"), "Suspend left move_right stuck")
	_require(not Input.is_action_pressed("jump"), "Suspend left jump stuck")
	_require(not Input.is_action_pressed("mine"), "Suspend left mine stuck")
	_require(not bool(jump.is_held()), "Suspend left the jump button held")
	_require(int(joystick.touch_index) == -1, "Suspend left the joystick captured")
	_require(not bool(game.physical_move_left_held), "Suspend left keyboard movement flag set")
	_require(not bool(game.mouse_mine_held), "Suspend left mouse mining flag set")
	_require(int(game.mobile_world_touch_index) == -1, "Suspend left the world touch captured")


func _test_background_save_debounce(game: Variant) -> void:
	# Focus-out and application-pause typically arrive back to back on
	# Android; the world must be saved once, not twice.
	game.in_main_menu = false
	game.world_loaded = true
	game.current_world_index = -1  # keep _save_game from touching real files
	game.last_background_save_msec = -100000
	var saves_before := int(game.background_save_count)
	game._autopause_and_save()
	game._autopause_and_save()
	_require(int(game.background_save_count) == saves_before + 1, "Background save was not debounced")
	_require(bool(game.game_paused), "Backgrounding did not pause the game")
	game.game_paused = false
	if game.pause_panel != null:
		game.pause_panel.visible = false
	game.world_loaded = false
	game.in_main_menu = true


func _test_resume_recovers_render_state(game: Variant) -> void:
	var resumes_before := int(game.lifecycle_resume_count)
	game._handle_application_resumed()
	_require(int(game.lifecycle_resume_count) == resumes_before + 1, "Resume was not counted")
	_require(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"), "Resume left movement actions pressed")


func _test_safe_area_insets(game: Variant) -> void:
	_require(int(game.safe_area_apply_count) > 0, "Safe-area insets were never applied at startup")
	_require(game.safe_area_registry.size() >= 6, "Too few HUD controls registered for safe-area handling")
	var minimap: Control = game.minimap_panel
	var base_right := 0.0
	var found := false
	for entry in game.safe_area_registry:
		if entry.get("control") == minimap:
			base_right = float(entry["base_right"])
			found = true
			break
	_require(found, "Minimap is not safe-area registered")

	# Simulate a display cutout on the right edge and a status bar on top.
	game.safe_area_insets = {"left": 0.0, "top": 24.0, "right": 32.0, "bottom": 0.0}
	game._apply_current_safe_area()
	_require(is_equal_approx(minimap.offset_right, base_right - 32.0), "Right inset did not shift the minimap")
	var joystick: Control = game.mobile_joystick
	var def: Dictionary = game.ui_layout.get("move_joystick", {})
	_require(is_equal_approx(joystick.offset_top, float(def.get("oy", 0.0)) - 0.0), "Bottom-left joystick moved for a bottom inset of 0")

	# A bottom inset (gesture bar) must lift the joystick and the hotbar.
	game.safe_area_insets = {"left": 10.0, "top": 0.0, "right": 0.0, "bottom": 20.0}
	game._apply_current_safe_area()
	_require(is_equal_approx(joystick.offset_left, float(def.get("ox", 0.0)) + 10.0), "Left inset did not shift the joystick")
	_require(is_equal_approx(joystick.offset_bottom, float(def.get("oh", 0.0)) - 20.0), "Bottom inset did not lift the joystick")

	# Restore the clean state and confirm the layout returns to its base.
	game.safe_area_insets = {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	game._apply_current_safe_area()
	_require(is_equal_approx(minimap.offset_right, base_right), "Clearing insets did not restore the minimap offset")

	# Insane inset values (buggy vendor ROMs) must be clamped, not applied raw.
	var computed: Dictionary = game._compute_safe_area_insets()
	for edge in ["left", "top", "right", "bottom"]:
		_require(float(computed[edge]) <= float(game.SAFE_AREA_MAX_INSET), "Computed %s inset exceeds the clamp" % edge)


func _test_hotbar_touch_targets(game: Variant) -> void:
	_require(game.hotbar_buttons.size() == int(game.HOTBAR_SIZE), "Hotbar slot count mismatch")
	for slot in game.hotbar_buttons:
		var button := slot as Button
		_require(button.size.x >= 72.0 and button.size.y >= 72.0, "Mobile hotbar slot is below the 72px touch target")
	# Slots must not overlap even at the larger size.
	for i in range(game.hotbar_buttons.size() - 1):
		var a := game.hotbar_buttons[i] as Button
		var b := game.hotbar_buttons[i + 1] as Button
		_require(a.position.x + a.size.x <= b.position.x + 0.01, "Hotbar slots %d and %d overlap" % [i, i + 1])


func _test_longpress_tooltip(game: Variant) -> void:
	# Give the player a known item in hotbar slot 0.
	game.inventory["wooden_pickaxe"] = maxi(1, int(game.inventory.get("wooden_pickaxe", 0)))
	game.hotbar[0] = "wooden_pickaxe"
	var slot := game.hotbar_buttons[0] as Button
	var slot_origin: Vector2 = slot.get_global_rect().position

	game._track_slot_longpress_event(_touch(0, true, Vector2(10, 10)), "hotbar", 0)
	_require(str(game.slot_longpress_kind) == "hotbar", "Long-press tracking did not start")
	# Holding still for the threshold shows the detailed tooltip.
	game._update_slot_longpress(float(game.SLOT_LONG_PRESS_TIME) + 0.05)
	_require(bool(game.touch_tooltip_panel.visible), "Long press did not open the touch tooltip")
	_require(str(game.touch_tooltip_label.text).contains("Wooden Pickaxe"), "Touch tooltip lacks the item name")
	_require(str(game.touch_tooltip_label.text).contains("Mining power"), "Touch tooltip lacks item details")
	# Lifting the finger hides it again.
	game._track_slot_longpress_event(_touch(0, false, Vector2(10, 10)), "hotbar", 0)
	_require(not bool(game.touch_tooltip_panel.visible), "Tooltip stayed open after release")

	# Moving the finger past the slop cancels the pending long press.
	game._track_slot_longpress_event(_touch(0, true, Vector2(10, 10)), "hotbar", 0)
	game._slot_longpress_pointer_moved(0, slot_origin + Vector2(200, 0))
	game._update_slot_longpress(float(game.SLOT_LONG_PRESS_TIME) + 0.05)
	_require(not bool(game.touch_tooltip_panel.visible), "Tooltip opened despite the finger moving away")
	game._cancel_slot_longpress()


func _test_pause_releases_input(game: Variant) -> void:
	game.in_main_menu = false
	game.game_paused = false
	var joystick: Control = game.mobile_joystick
	var center: Vector2 = joystick.size * 0.5
	joystick._gui_input(_touch(0, true, center))
	joystick._gui_input(_drag(0, center + Vector2(60, 0)))
	_require(Input.is_action_pressed("move_right"), "Setup: move_right not pressed before pause")
	game._toggle_pause()
	_require(not Input.is_action_pressed("move_right"), "Opening pause left move_right stuck")
	game._toggle_pause()
	game.in_main_menu = true
	game.game_paused = false
	if game.pause_panel != null:
		game.pause_panel.visible = false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
