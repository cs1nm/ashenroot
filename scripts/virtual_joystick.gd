extends Control

const BASE_RADIUS := 86.0
const KNOB_RADIUS := 36.0
const DEAD_ZONE := 0.16
const JOY_BASE_TEX := preload("res://assets/ui/joy_base.png")
const JOY_KNOB_TEX := preload("res://assets/ui/joy_knob.png")

var touch_index := -1
var axis := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(BASE_RADIUS * 2.0, BASE_RADIUS * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	# Pixel-art base texture
	draw_texture_rect(JOY_BASE_TEX, Rect2(Vector2.ZERO, size), false)
	# Jump hint label above the top tick
	var jump_color := Color(0.95, 0.8, 0.45, 0.95)
	draw_string(ThemeDB.fallback_font, size * 0.5 + Vector2(-22.0, -BASE_RADIUS + 2.0), "JUMP", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 7, jump_color)
	# Knob follows the stick
	var knob_center := size * 0.5 + axis * (BASE_RADIUS - KNOB_RADIUS - 8.0)
	var knob_size := Vector2(KNOB_RADIUS * 2.0, KNOB_RADIUS * 2.0)
	draw_texture_rect(JOY_KNOB_TEX, Rect2(knob_center - knob_size * 0.5, knob_size), false)
