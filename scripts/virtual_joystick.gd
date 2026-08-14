extends Control
## Minimal fixed/touch joystick. Its visual language matches the action buttons:
## thin amber rings, no opaque disk, no text.

const BASE_RADIUS := 82.0
const KNOB_RADIUS := 27.0
const MAX_TRAVEL := 52.0
const DEAD_ZONE := 0.14

var touch_index := -1
var axis := Vector2.ZERO
var base_center := Vector2.ZERO
var static_mode := false
var aim_mode := false
var joy_scale := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _exit_tree() -> void:
	_release_actions()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_index < 0:
			touch_index = touch.index
			base_center = size * 0.5 if static_mode else touch.position
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
				base_center = size * 0.5 if static_mode else mouse.position
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
	if aim_mode:
		return
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
	if touch_index < 0 and not static_mode:
		return
	var c := base_center if touch_index >= 0 else size * 0.5
	var br := int(BASE_RADIUS * joy_scale)
	var kr := int(KNOB_RADIUS * joy_scale)
	var travel := MAX_TRAVEL * joy_scale
	var amber := Color(0.949, 0.639, 0.227, 0.62)

	_draw_pixel_ring(c + Vector2(0, 3), br, 2, Color(0.0, 0.0, 0.0, 0.22))
	_draw_pixel_ring(c, br, 2, amber)
	_draw_pixel_ring(c, br - 7, 1, Color(0.58, 0.64, 0.70, 0.18))
	# Four tiny direction ticks retain orientation without arrow clutter.
	draw_rect(Rect2(c.x - 1, c.y - br + 9, 3, 7), amber)
	draw_rect(Rect2(c.x - 1, c.y + br - 15, 3, 7), amber)
	draw_rect(Rect2(c.x - br + 9, c.y - 1, 7, 3), amber)
	draw_rect(Rect2(c.x + br - 15, c.y - 1, 7, 3), amber)

	var knob_center := c + axis * travel
	_draw_pixel_circle(knob_center, kr, Color(0.04, 0.055, 0.075, 0.42))
	_draw_pixel_ring(knob_center, kr, 2, Color(0.95, 0.64, 0.23, 0.82))
	_draw_pixel_ring(knob_center, kr - 7, 1, Color(0.91, 0.93, 0.96, 0.30))
	_draw_pixel_circle(knob_center, 3, Color(0.95, 0.64, 0.23, 0.80))


func _draw_pixel_ring(center: Vector2, radius_px: int, thickness: int, color: Color) -> void:
	if radius_px <= thickness:
		return
	var inner := radius_px - thickness
	for y in range(-radius_px, radius_px + 1):
		var outer_half := int(sqrt(float(radius_px * radius_px - y * y)))
		var inner_half := -1
		if abs(y) <= inner:
			inner_half = int(sqrt(float(inner * inner - y * y)))
		if inner_half < 0:
			draw_rect(Rect2(center.x - outer_half, center.y + y, outer_half * 2 + 1, 1), color)
		else:
			var segment := maxi(1, outer_half - inner_half)
			draw_rect(Rect2(center.x - outer_half, center.y + y, segment, 1), color)
			draw_rect(Rect2(center.x + inner_half + 1, center.y + y, segment, 1), color)


func _draw_pixel_circle(center: Vector2, radius_px: int, color: Color) -> void:
	if radius_px <= 0:
		return
	for y in range(-radius_px, radius_px + 1):
		var half := int(sqrt(float(radius_px * radius_px - y * y)))
		draw_rect(Rect2(center.x - half, center.y + y, half * 2 + 1, 1), color)
