extends Control
## «Ashen Archive» health ring: obsidian disc with an ember progress arc.
##
## Drawn vector-style (no textures): a blurred-looking ember halo, a dark
## obsidian disc with a thin slate outline, and a clockwise arc that starts
## at 12 o'clock and lerps from bright ember to deep red as it fills.
## Matches `ui_concept/preview/gameplay.png`.


var frac := 1.0:
	set(value):
		frac = clampf(value, 0.0, 1.0)
		queue_redraw()

var radius := 36.0
var ring_width := 7.0
var disc_color := Color(0.063, 0.078, 0.106, 0.94)
var inner_disc_color := Color(0.039, 0.051, 0.071, 0.98)
var outline_color := Color(0.227, 0.259, 0.306, 1.0)
var fill_from := Color(1.0, 0.624, 0.263, 1.0)   # bright ember at 12 o'clock
var fill_to := Color(0.839, 0.204, 0.204, 1.0)   # deep ember red at the tail
var glow_color := Color(1.0, 0.416, 0.169, 1.0)


func _draw() -> void:
	var center := size * 0.5
	var ring_r := radius - ring_width * 0.5 - 1.0
	# Halo: a few wide, faint arcs under everything fake the glow.
	var glow_layers := [
		{"width": ring_width + 15.0, "alpha": 0.05},
		{"width": ring_width + 10.0, "alpha": 0.08},
		{"width": ring_width + 5.0, "alpha": 0.12},
	]
	for layer in glow_layers:
		draw_arc(center, ring_r, 0.0, TAU, 64, Color(glow_color, layer["alpha"]), layer["width"], true)
	# Obsidian disc + slate outline + darker core.
	draw_circle(center, radius, disc_color)
	draw_arc(center, radius - 1.0, 0.0, TAU, 96, outline_color, 2.0, true)
	draw_circle(center, radius - 8.0, inner_disc_color)
	# Progress arc: segmented gradient sweep from 12 o'clock, clockwise.
	if frac <= 0.003:
		return
	var start := -PI * 0.5
	var sweep := TAU * frac
	var segs := 36
	for i in range(segs):
		var a0 := start + sweep * float(i) / float(segs)
		var a1 := start + sweep * float(i + 1) / float(segs) + 0.02
		var col := fill_from.lerp(fill_to, float(i) / float(segs - 1))
		draw_arc(center, ring_r, a0, a1, 6, col, ring_width, true)
