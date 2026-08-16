extends Control
## Minimal mobile action control: a thin amber ring and a high-contrast icon.
## JUMP emits hold events; ATK and GRAPPLE emit a tap event.
##
## Pointer rules (important for multitouch reliability):
## - The button remembers which finger pressed it and only that finger can
##   release it; a second finger tapping the same button never double-fires.
## - Emulated mouse events (device == DEVICE_ID_EMULATION) are ignored so a
##   touch is never processed twice on Android.
## - Touch cancellation, sliding far off the button, hiding the control and
##   leaving the tree all release a held button (no stuck JUMP after menus).

signal button_down
signal button_up
signal button_pressed

const MOUSE_TOUCH_INDEX := -2
const RELEASE_SLIP_MARGIN := 24.0

var kind := "jump"
var radius := 58.0
var hold := false
var label_text := ""
var label_font: Font
var forced_release_count := 0

var _active := false
var _touch_index := -1


func _exit_tree() -> void:
	force_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		force_release()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index == -1:
				_touch_index = touch.index
				_set_active(true)
			accept_event()
		elif touch.index == _touch_index:
			# Regular release and system cancellation both free the button.
			_touch_index = -1
			if _active:
				_set_active(false)
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index and _active:
			if drag.position.distance_to(size * 0.5) > radius + RELEASE_SLIP_MARGIN:
				_touch_index = -1
				_set_active(false)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed and _touch_index == -1:
				_touch_index = MOUSE_TOUCH_INDEX
				_set_active(true)
			elif not mouse.pressed and _touch_index == MOUSE_TOUCH_INDEX:
				_touch_index = -1
				if _active:
					_set_active(false)
			accept_event()


func force_release() -> void:
	## Clears the owning pointer; a held button emits button_up so the bound
	## input action cannot stay stuck when a menu opens or the app suspends.
	if _touch_index != -1 or _active:
		forced_release_count += 1
	_touch_index = -1
	if _active:
		_active = false
		queue_redraw()
		if hold:
			button_up.emit()


func is_held() -> bool:
	return _active


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
	var amber := Color(0.949, 0.639, 0.227, 0.82 if not _active else 1.0)
	var icon_col := Color(0.93, 0.95, 0.97, 0.88 if not _active else 1.0)
	var dark := Color(0.02, 0.03, 0.045, 0.9)

	# No opaque disk: only a shadow, two thin stepped rings and a faint press wash.
	_draw_pixel_ring(c + Vector2(0, 3), r, 2, Color(0.0, 0.0, 0.0, 0.24))
	_draw_pixel_ring(c, r, 2 if not _active else 3, amber)
	_draw_pixel_ring(c, r - 7, 1, Color(0.58, 0.64, 0.70, 0.22))
	if _active:
		_draw_pixel_circle(c, r - 10, Color(0.95, 0.64, 0.23, 0.10))

	if kind == "jump":
		var ax := int(c.x)
		_draw_triangle(Vector2(ax, c.y - 24), Vector2(ax - 17, c.y + 3), Vector2(ax + 17, c.y + 3), dark)
		draw_rect(Rect2(ax - 7, c.y + 1, 14, 23), dark)
		_draw_triangle(Vector2(ax, c.y - 21), Vector2(ax - 14, c.y + 3), Vector2(ax + 14, c.y + 3), icon_col)
		draw_rect(Rect2(ax - 5, c.y + 2, 10, 19), icon_col)
	elif kind == "grapple":
		var hx := int(c.x)
		draw_rect(Rect2(hx - 2, c.y - 27, 5, 20), dark)
		draw_rect(Rect2(hx - 1, c.y - 26, 3, 19), icon_col)
		draw_rect(Rect2(hx - 1, c.y - 9, 16, 4), dark)
		draw_rect(Rect2(hx, c.y - 8, 13, 2), icon_col)
		draw_rect(Rect2(hx + 11, c.y - 8, 4, 17), dark)
		draw_rect(Rect2(hx + 12, c.y - 7, 2, 14), icon_col)
		draw_rect(Rect2(hx + 5, c.y + 6, 9, 4), dark)
		draw_rect(Rect2(hx + 6, c.y + 7, 7, 2), icon_col)
	else:
		var sx := int(c.x)
		# Diagonal sword reads more clearly than the previous vertical text button.
		var blade := PackedVector2Array([
			Vector2(sx + 17, c.y - 29), Vector2(sx + 23, c.y - 23),
			Vector2(sx - 8, c.y + 14), Vector2(sx - 15, c.y + 7),
		])
		draw_colored_polygon(blade, dark)
		var blade_inner := PackedVector2Array([
			Vector2(sx + 17, c.y - 25), Vector2(sx + 20, c.y - 22),
			Vector2(sx - 8, c.y + 11), Vector2(sx - 12, c.y + 7),
		])
		draw_colored_polygon(blade_inner, icon_col)
		draw_line(Vector2(sx - 18, c.y + 5), Vector2(sx + 2, c.y + 24), dark, 7.0)
		draw_line(Vector2(sx - 17, c.y + 5), Vector2(sx + 1, c.y + 22), amber, 4.0)
		draw_line(Vector2(sx - 15, c.y + 25), Vector2(sx - 2, c.y + 12), dark, 8.0)
		draw_line(Vector2(sx - 14, c.y + 24), Vector2(sx - 3, c.y + 13), icon_col, 4.0)


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


func _draw_triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c]), color)
