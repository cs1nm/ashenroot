extends Control
## Muted translucent PIXEL action button (JUMP / ATK) drawn with code.
## Circles are stepped pixel-art (Terraria style), not smooth.
## JUMP holds (button_down/button_up); ATK taps (button_pressed).

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
	var r := int(radius)
	# soft shadow
	_draw_pixel_circle(c + Vector2(0, 4), r, Color(0.0, 0.0, 0.0, 0.25))
	# outer dark outline
	_draw_pixel_circle(c, r, Color(0.05, 0.06, 0.09, 0.55))
	# dim ring
	_draw_pixel_circle(c, r - 4, Color(0.30, 0.34, 0.40, 0.45))
	# body (translucent dark)
	_draw_pixel_circle(c, r - 9, Color(0.045, 0.055, 0.085, 0.40))
	# pressed feedback
	if _active:
		_draw_pixel_circle(c, r - 12, Color(0.16, 0.18, 0.22, 0.35))
	# icon (muted gold, with dark outline)
	var icon_col := Color(0.66, 0.62, 0.54, 0.75)
	var dark := Color(0.08, 0.09, 0.12, 0.85)
	if kind == "jump":
		var ax := int(c.x)
		# outlined up-arrow: dark then light
		_draw_triangle(Vector2(ax, c.y - 23), Vector2(ax - 16, c.y + 5), Vector2(ax + 16, c.y + 5), dark)
		draw_rect(Rect2(ax - 6, c.y + 3, 12, 19), dark)
		_draw_triangle(Vector2(ax, c.y - 21), Vector2(ax - 14, c.y + 5), Vector2(ax + 14, c.y + 5), icon_col)
		draw_rect(Rect2(ax - 5, c.y + 4, 10, 16), icon_col)
	elif kind == "grapple":
		# hook: curved metal hook with a rope line
		var hx := int(c.x)
		draw_rect(Rect2(hx - 2, c.y - 30, 4, 18), dark)
		draw_rect(Rect2(hx - 2, c.y - 30, 3, 17), icon_col)
		# hook curve (right side J)
		draw_rect(Rect2(hx - 1, c.y - 12, 14, 4), dark)
		draw_rect(Rect2(hx, c.y - 12, 12, 3), icon_col)
		draw_rect(Rect2(hx + 10, c.y - 12, 4, 14), dark)
		draw_rect(Rect2(hx + 11, c.y - 11, 3, 12), icon_col)
		draw_rect(Rect2(hx + 10, c.y + 0, 4, 8), dark)
		draw_rect(Rect2(hx + 11, c.y + 0, 3, 7), icon_col)
		# tip pointing left
		draw_rect(Rect2(hx + 6, c.y + 6, 6, 3), dark)
		draw_rect(Rect2(hx + 7, c.y + 7, 5, 2), icon_col)
	else:
		var sx := int(c.x)
		draw_rect(Rect2(sx - 4, c.y - 27, 8, 32), dark)
		draw_rect(Rect2(sx - 15, c.y + 4, 30, 7), dark)
		draw_rect(Rect2(sx - 3, c.y + 27, 6, 7), dark)
		draw_rect(Rect2(sx - 3, c.y - 27, 6, 30), icon_col)
		_draw_triangle(Vector2(sx, c.y - 36), Vector2(sx - 6, c.y - 24), Vector2(sx + 6, c.y - 24), icon_col)
		draw_rect(Rect2(sx - 13, c.y + 4, 26, 5), Color(0.56, 0.52, 0.44, 0.7))
		draw_rect(Rect2(sx - 3, c.y + 9, 6, 10), Color(0.40, 0.36, 0.30, 0.6))
		draw_rect(Rect2(sx - 5, c.y + 21, 10, 5), Color(0.56, 0.52, 0.44, 0.7))
	# label under the circle
	if label_text != "":
		var font := label_font if label_font != null else ThemeDB.fallback_font
		draw_string(font, Vector2(0.0, radius + 16.0), label_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, Color(0.55, 0.53, 0.48, 0.6))


## Stepped pixel-art circle: rows of 1px-tall rects.
func _draw_pixel_circle(center: Vector2, radius: int, color: Color) -> void:
	if radius <= 0:
		return
	for y in range(-radius, radius + 1):
		var half := int(sqrt(float(radius * radius - y * y)))
		if half <= 0:
			continue
		draw_rect(Rect2(center.x - half, center.y + y, half * 2 + 1, 1), color)


func _draw_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c]), color)
