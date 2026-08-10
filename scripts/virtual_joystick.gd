extends Control

const BASE_RADIUS := 86.0
const KNOB_SIZE := 36.0
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


func _make_pad_style(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	return sb


func _draw() -> void:
	var pad_rect := Rect2(2, 2, size.x - 4, size.y - 4)
	var radius := int(minf(size.x, size.y) * 0.28)

	# ---- rounded pad (HUD chip style, not a hard square) ----
	# outer dark outline
	draw_style_box(_make_pad_style(Color(0.02, 0.03, 0.05, 1.0), radius), pad_rect)
	# bevel: light top-left rim
	draw_style_box(_make_pad_style(Color(0.23, 0.28, 0.37, 0.9), maxi(radius - 3, 4)), pad_rect.grow(-2))
	# body (translucent obsidian)
	draw_style_box(_make_pad_style(Color(0.10, 0.12, 0.18, 0.92), maxi(radius - 6, 4)), pad_rect.grow(-4))

	# ember corner studs
	var stud := Color(1.0, 0.42, 0.17, 1.0)
	var inset := 14.0
	draw_rect(Rect2(inset, inset, 4, 4), stud)
	draw_rect(Rect2(size.x - inset - 4, inset, 4, 4), stud)
	draw_rect(Rect2(inset, size.y - inset - 4, 4, 4), stud)
	draw_rect(Rect2(size.x - inset - 4, size.y - inset - 4, 4, 4), stud)

	# gold direction arrows
	var gold := Color(0.91, 0.71, 0.35, 1.0)
	_draw_pad_arrow(Vector2(size.x * 0.5, 16.0), Vector2(0, -1), gold, 14.0)
	_draw_pad_arrow(Vector2(size.x * 0.5, size.y - 16.0), Vector2(0, 1), gold, 14.0)
	_draw_pad_arrow(Vector2(16.0, size.y * 0.5), Vector2(-1, 0), gold, 14.0)
	_draw_pad_arrow(Vector2(size.x - 16.0, size.y * 0.5), Vector2(1, 0), gold, 14.0)

	# ---- knob: rounded ember block with gold core ----
	var c := size * 0.5
	var kc := c + axis * (BASE_RADIUS - 34.0)
	var ksize := Vector2(KNOB_SIZE, KNOB_SIZE)
	var krect := Rect2(kc - ksize * 0.5, ksize)
	draw_style_box(_make_pad_style(Color(0.05, 0.03, 0.02, 1.0), 10), krect)
	draw_style_box(_make_pad_style(Color(0.72, 0.30, 0.11, 1.0), 7), krect.grow(-3))
	draw_style_box(_make_pad_style(Color(0.95, 0.55, 0.25, 1.0), 5), krect.grow(-7))
	# highlight
	draw_rect(Rect2(krect.position + Vector2(8, 8), Vector2(12, 5)), Color(1.0, 0.78, 0.45, 0.9))


func _draw_pad_arrow(center: Vector2, dir: Vector2, color: Color, len: float) -> void:
	var tip := center + dir * len * 0.5
	var back := center - dir * len * 0.5
	var perp := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([tip, back + perp * 4.0, back - perp * 4.0])
	draw_colored_polygon(pts, color)
