extends Control
## Small hand-drawn pixel icon (▲ jump / sword attack) for the HUD action buttons.
## Drawn with code, not textures.

var kind := "jump"


func _draw() -> void:
	var c := size * 0.5
	if kind == "jump":
		var pts := PackedVector2Array([
			Vector2(c.x, 3.0),
			Vector2(3.0, size.y - 3.0),
			Vector2(size.x - 3.0, size.y - 3.0),
		])
		draw_colored_polygon(pts, Color("ffe9c4"))
		# dark outline (cheap trick: darker triangle slightly bigger underneath)
		var outline_pts := PackedVector2Array([
			Vector2(c.x, 1.0),
			Vector2(1.0, size.y - 1.0),
			Vector2(size.x - 1.0, size.y - 1.0),
		])
		draw_colored_polygon(outline_pts, Color("10141b"))
		draw_colored_polygon(pts, Color("ffe9c4"))
	elif kind == "atk":
		var blade := Color("e8edf3")
		var metal := Color("e8b45a")
		var dark := Color("10141b")
		# blade
		draw_rect(Rect2(c.x - 2.0, 2.0, 5.0, size.y - 12.0), blade)
		# blade tip (small triangle)
		var tip := PackedVector2Array([
			Vector2(c.x, 0.0),
			Vector2(c.x - 3.0, 4.0),
			Vector2(c.x + 3.0, 4.0),
		])
		draw_colored_polygon(tip, blade)
		# guard
		draw_rect(Rect2(c.x - 9.0, size.y - 12.0, 18.0, 4.0), metal)
		# grip
		draw_rect(Rect2(c.x - 2.0, size.y - 8.0, 5.0, 5.0), dark)
		# pommel
		draw_rect(Rect2(c.x - 3.0, size.y - 3.0, 6.0, 3.0), metal)
		# edge highlight
		draw_rect(Rect2(c.x - 1.0, 3.0, 2.0, size.y - 14.0), Color(1.0, 1.0, 1.0, 0.55))
