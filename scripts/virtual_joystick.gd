extends Control

const BASE_RADIUS := 86.0
const KNOB_RADIUS := 37.0
const DEAD_ZONE := 0.16

var touch_index := -1
var axis := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(BASE_RADIUS * 2.0, BASE_RADIUS * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _exit_tree() -> void:
	_release_actions()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index < 0:
			touch_index = touch.index
			_update_axis(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == touch_index:
			touch_index = -1
			axis = Vector2.ZERO
			_apply_actions()
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_index:
			_update_axis(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				touch_index = -2
				_update_axis(mouse.position)
			elif touch_index == -2:
				touch_index = -1
				axis = Vector2.ZERO
				_apply_actions()
				queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion and touch_index == -2:
		_update_axis((event as InputEventMouseMotion).position)
		accept_event()


func _update_axis(local_position: Vector2) -> void:
	var center := size * 0.5
	axis = (local_position - center) / BASE_RADIUS
	if axis.length() > 1.0:
		axis = axis.normalized()
	if axis.length() < DEAD_ZONE:
		axis = Vector2.ZERO
	_apply_actions()
	queue_redraw()


func _apply_actions() -> void:
	if axis.x < -DEAD_ZONE:
		Input.action_press("move_left", -axis.x)
	else:
		Input.action_release("move_left")
	if axis.x > DEAD_ZONE:
		Input.action_press("move_right", axis.x)
	else:
		Input.action_release("move_right")
	if axis.y < -0.52:
		Input.action_press("jump", -axis.y)
	else:
		Input.action_release("jump")


func _release_actions() -> void:
	touch_index = -1
	axis = Vector2.ZERO
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")


func _draw() -> void:
	var center := size * 0.5
	# Pixel-style base: obsidian disc with bevel ring
	draw_circle(center, BASE_RADIUS, Color(0.06, 0.08, 0.12, 0.62))
	draw_circle(center, BASE_RADIUS - 3.0, Color(0.10, 0.13, 0.19, 0.5))
	# Ember outer ring
	draw_arc(center, BASE_RADIUS - 2.0, 0.0, TAU, 48, Color(0.50, 0.26, 0.10, 0.95), 4.0, true)
	draw_arc(center, BASE_RADIUS - 5.0, 0.0, TAU, 48, Color(1.0, 0.42, 0.17, 0.85), 2.0, true)
	# Direction ticks
	var tick_color := Color(0.85, 0.65, 0.30, 0.9)
	_draw_tick(center, Vector2.UP, tick_color)
	_draw_tick(center, Vector2.DOWN, tick_color)
	_draw_tick(center, Vector2.LEFT, tick_color)
	_draw_tick(center, Vector2.RIGHT, tick_color)
	# Jump hint (small up arrow label under top tick)
	var jump_color := Color(0.95, 0.8, 0.45, 0.95)
	draw_string(ThemeDB.fallback_font, center + Vector2(-22.0, -BASE_RADIUS + 4.0), "JUMP", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 7, jump_color)
	draw_string(ThemeDB.fallback_font, center + Vector2(-14.0, -BASE_RADIUS - 8.0), "▲", HORIZONTAL_ALIGNMENT_CENTER, 28.0, 9, jump_color)
	# Knob: ember with dark outline + gold highlight
	var knob_center := center + axis * (BASE_RADIUS - KNOB_RADIUS - 6.0)
	draw_circle(knob_center, KNOB_RADIUS, Color(0.08, 0.05, 0.04, 0.95))
	draw_circle(knob_center, KNOB_RADIUS - 2.0, Color(0.72, 0.30, 0.11, 1.0))
	draw_circle(knob_center, KNOB_RADIUS - 8.0, Color(0.95, 0.55, 0.25, 1.0))
	draw_arc(knob_center, KNOB_RADIUS - 10.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.45, 0.9), 2.0, true)


func _draw_tick(center: Vector2, dir: Vector2, color: Color) -> void:
	var tip := center + dir * (BASE_RADIUS - 10.0)
	var back := center + dir * (BASE_RADIUS - 22.0)
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([
		tip,
		back + perp * 5.0,
		back - perp * 5.0,
	])
	draw_colored_polygon(pts, color)
