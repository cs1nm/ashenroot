extends Control
## Dynamic joystick (Terraria-style): appears at the point of touch on the
## left side of the screen, muted translucent style. Draws with code.

const BASE_RADIUS := 96.0
const KNOB_RADIUS := 32.0
const MAX_TRAVEL := 58.0
const DEAD_ZONE := 0.14

var touch_index := -1
var axis := Vector2.ZERO
var base_center := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _exit_tree() -> void:
	_release_actions()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index < 0:
			touch_index = touch.index
			base_center = touch.position
			axis = Vector2.ZERO
			_apply_actions()
			queue_redraw()
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
				base_center = mouse.position
				axis = Vector2.ZERO
				_apply_actions()
				queue_redraw()
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
	axis = (local_position - base_center) / MAX_TRAVEL
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
	if touch_index < 0:
		return
	var c := base_center
	# translucent base
	draw_circle(c, BASE_RADIUS, Color(0.045, 0.055, 0.085, 0.42))
	# dim rings
	draw_arc(c, BASE_RADIUS - 3.0, 0.0, TAU, 48, Color(0.30, 0.34, 0.40, 0.5), 3.0)
	draw_arc(c, BASE_RADIUS - 9.0, 0.0, TAU, 48, Color(0.18, 0.22, 0.28, 0.45), 2.0)
	# center dot
	draw_circle(c, 4.0, Color(0.58, 0.54, 0.46, 0.5))
	# dim gold direction arrows
	var gold := Color(0.58, 0.54, 0.46, 0.55)
	_draw_pad_arrow(c + Vector2(0.0, -BASE_RADIUS + 20.0), Vector2(0, -1), gold)
	_draw_pad_arrow(c + Vector2(0.0, BASE_RADIUS - 20.0), Vector2(0, 1), gold)
	_draw_pad_arrow(c + Vector2(-BASE_RADIUS + 20.0, 0.0), Vector2(-1, 0), gold)
	_draw_pad_arrow(c + Vector2(BASE_RADIUS - 20.0, 0.0), Vector2(1, 0), gold)
	# knob
	var kc := c + axis * (MAX_TRAVEL - 4.0)
	draw_circle(kc, KNOB_RADIUS, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(kc, KNOB_RADIUS - 2.0, Color(0.20, 0.19, 0.16, 0.55))
	draw_arc(kc, KNOB_RADIUS - 4.0, 0.0, TAU, 32, Color(0.50, 0.46, 0.40, 0.6), 2.0)
	draw_circle(kc, 8.0, Color(0.60, 0.56, 0.48, 0.6))


func _draw_pad_arrow(center: Vector2, dir: Vector2, color: Color) -> void:
	var tip := center + dir * 9.0
	var back := center - dir * 7.0
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([tip, back + perp * 4.0, back - perp * 4.0])
	draw_colored_polygon(pts, color)
