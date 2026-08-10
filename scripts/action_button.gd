extends Control
## Muted translucent circular action button (JUMP / ATK) drawn with code.
## Holds or taps: jump emits button_down/button_up; atk emits button_pressed.

signal button_down
signal button_up
signal button_pressed

var kind := "jump"          # "jump" or "atk"
var radius := 66.0
var hold := false           # jump = hold, atk = tap
var label_text := ""
var label_font: Font

var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_set_active(true)
			accept_event()
		elif _active:
			_set_active(false)
			accept_event()
	elif event is InputEventScreenDrag and _active:
		if event.position.distance_to(size * 0.5) > radius + 24.0:
			_set_active(false)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_set_active(true)
			elif _active:
				_set_active(false)
			accept_event()


func _set_active(pressed: bool) -> void:
	_active = pressed
	queue_redraw()
	if hold:
		if pressed:
			button_down.emit()
		else:
			button_up.emit()
	elif pressed:
		button_pressed.emit()


func _draw() -> void:
	var c := size * 0.5
	var r := radius
	# soft shadow
	draw_circle(c + Vector2(0, 4), r, Color(0.0, 0.0, 0.0, 0.25))
	# base (translucent dark)
	draw_circle(c, r, Color(0.045, 0.055, 0.085, 0.40))
	# dim rings
	draw_arc(c, r - 3.0, 0.0, TAU, 48, Color(0.30, 0.34, 0.40, 0.5), 3.0)
	draw_arc(c, r - 9.0, 0.0, TAU, 48, Color(0.18, 0.22, 0.28, 0.45), 2.0)
	# pressed feedback
	if _active:
		draw_circle(c, r - 12.0, Color(0.16, 0.18, 0.22, 0.35))
	# icon (muted gold)
	var icon_col := Color(0.66, 0.62, 0.54, 0.75)
	var dark := Color(0.08, 0.09, 0.12, 0.85)
	if kind == "jump":
		var ax := c.x
		# outlined up-arrow: dark then light
		draw_colored_polygon(PackedVector2Array([
			Vector2(ax, c.y - 25.0), Vector2(ax - 16.0, c.y + 5.0), Vector2(ax + 16.0, c.y + 5.0)
		]), dark)
		draw_rect(Rect2(ax - 6.0, c.y + 3.0, 12.0, 19.0), dark)
		draw_colored_polygon(PackedVector2Array([
			Vector2(ax, c.y - 23.0), Vector2(ax - 14.0, c.y + 5.0), Vector2(ax + 14.0, c.y + 5.0)
		]), icon_col)
		draw_rect(Rect2(ax - 5.0, c.y + 4.0, 10.0, 16.0), icon_col)
	else:
		var sx := c.x
		draw_rect(Rect2(sx - 4.0, c.y - 27.0, 8.0, 32.0), dark)
		draw_rect(Rect2(sx - 15.0, c.y + 4.0, 30.0, 7.0), dark)
		draw_rect(Rect2(sx - 3.0, c.y + 27.0, 6.0, 7.0), dark)
		draw_rect(Rect2(sx - 3.0, c.y - 27.0, 6.0, 30.0), icon_col)
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx, c.y - 36.0), Vector2(sx - 6.0, c.y - 24.0), Vector2(sx + 6.0, c.y - 24.0)
		]), icon_col)
		draw_rect(Rect2(sx - 13.0, c.y + 4.0, 26.0, 5.0), Color(0.56, 0.52, 0.44, 0.7))
		draw_rect(Rect2(sx - 3.0, c.y + 9.0, 6.0, 10.0), Color(0.40, 0.36, 0.30, 0.6))
		draw_rect(Rect2(sx - 5.0, c.y + 21.0, 10.0, 5.0), Color(0.56, 0.52, 0.44, 0.7))
	# label under the circle
	if label_text != "":
		var font := label_font if label_font != null else ThemeDB.fallback_font
		draw_string(font, Vector2(0.0, r + 16.0), label_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, Color(0.55, 0.53, 0.48, 0.6))
