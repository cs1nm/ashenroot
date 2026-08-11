extends Control
## Joystick. Supports two modes:
##  - movement (default): drives move_left/move_right/jump actions
##  - aim (aim_mode=true): stores axis only, game reads it to move a reticle
##  - static_mode=true: base is drawn fixed at the control's center and always
##    visible; touches anywhere in the control move the knob from the center.
## PIXEL circle (stepped, not smooth) — muted style.

const BASE_RADIUS := 96.0
const KNOB_RADIUS := 32.0
const MAX_TRAVEL := 58.0
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
			if static_mode:
				base_center = size * 0.5
			else:
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
				if static_mode:
					base_center = size * 0.5
				else:
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
	# In static mode the base is always drawn (fixed on screen).
	if touch_index < 0 and not static_mode:
		return
	var c := base_center if touch_index >= 0 else size * 0.5
	var br := BASE_RADIUS * joy_scale
	var kr := KNOB_RADIUS * joy_scale
	var mt := MAX_TRAVEL * joy_scale
	# soft shadow (pixel circle, slightly offset down)
	_draw_pixel_circle(c + Vector2(0, 4), int(br), Color(0.0, 0.0, 0.0, 0.25))
	# outer dark outline
	_draw_pixel_circle(c, int(br), Color(0.05, 0.06, 0.09, 0.55))
	# dim ring
	_draw_pixel_circle(c, int(br - 4), Color(0.30, 0.34, 0.40, 0.45))
	# body (translucent dark)
	_draw_pixel_circle(c, int(br - 9), Color(0.045, 0.055, 0.085, 0.40))
	# center dot
	_draw_pixel_circle(c, 4, Color(0.58, 0.54, 0.46, 0.5))
	# dim gold direction arrows
	var gold := Color(0.58, 0.54, 0.46, 0.55)
	_draw_pad_arrow(c + Vector2(0.0, -br + 20.0), Vector2(0, -1), gold)
	_draw_pad_arrow(c + Vector2(0.0, br - 20.0), Vector2(0, 1), gold)
	_draw_pad_arrow(c + Vector2(-br + 20.0, 0.0), Vector2(-1, 0), gold)
	_draw_pad_arrow(c + Vector2(br - 20.0, 0.0), Vector2(1, 0), gold)
	# knob (pixel circle)
	var kc := c + axis * (mt - 4.0)
	_draw_pixel_circle(kc, int(kr), Color(0.0, 0.0, 0.0, 0.3))
	_draw_pixel_circle(kc, int(kr - 3), Color(0.20, 0.19, 0.16, 0.55))
	_draw_pixel_circle(kc, int(kr - 6), Color(0.42, 0.38, 0.32, 0.6))
	_draw_pixel_circle(kc, 8, Color(0.60, 0.56, 0.48, 0.6))


## Draw a STEPPED (pixel-art) circle — rows of 1px-tall rects, like Terraria.
func _draw_pixel_circle(center: Vector2, radius: int, color: Color) -> void:
	if radius <= 0:
		return
	for y in range(-radius, radius + 1):
		var half := int(sqrt(float(radius * radius - y * y)))
		if half <= 0:
			continue
		draw_rect(Rect2(center.x - half, center.y + y, half * 2 + 1, 1), color)


func _draw_pad_arrow(center: Vector2, dir: Vector2, color: Color) -> void:
	var tip := center + dir * 9.0
	var back := center - dir * 7.0
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([tip, back + perp * 4.0, back - perp * 4.0])
	draw_colored_polygon(pts, color)
