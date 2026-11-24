class_name SurvivalGlyph
extends Control

## Small, original tactical-survival glyph renderer.
##
## The HUD deliberately owns these marks in code rather than baking unreadable
## text into a texture atlas. They scale cleanly at every resolution and keep
## the information hierarchy visual: a flame means warmth, a can means fuel,
## a bolt means ammunition, a wedge means direction.

var glyph := "arrow":
	set(value):
		glyph = value
		queue_redraw()
var tint := Color(1.0, 0.67, 0.28, 1.0):
	set(value):
		tint = value
		queue_redraw()
var accent := Color(0.42, 0.83, 0.86, 0.95):
	set(value):
		accent = value
		queue_redraw()
var value := 1.0:
	set(amount):
		value = clampf(amount, 0.0, 1.0)
		queue_redraw()
var direction := 0.0:
	set(angle):
		direction = angle
		queue_redraw()
var active := true:
	set(enabled):
		active = enabled
		queue_redraw()

var stroke := 2.4


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(5.0, minf(size.x, size.y) * 0.39)
	var primary := tint if active else Color(tint, tint.a * 0.28)
	var secondary := Color(accent, accent.a * (0.95 if active else 0.26))
	match glyph:
		"warmth": _draw_warmth(center, radius, primary)
		"fuel": _draw_fuel(center, radius, primary, secondary)
		"bolt": _draw_bolt(center, radius, primary)
		"driver": _draw_driver(center, radius, primary, secondary)
		"compass": _draw_compass(center, radius, primary, secondary)
		"objective": _draw_objective(center, radius, primary, secondary)
		"warning": _draw_warning(center, radius, primary)
		"furnace": _draw_furnace(center, radius, primary, secondary)
		"gear": _draw_gear(center, radius, primary)
		"water": _draw_water(center, radius, primary, secondary)
		"chitin": _draw_chitin(center, radius, primary, secondary)
		"hide": _draw_hide(center, radius, primary)
		"snare": _draw_snare(center, radius, primary, secondary)
		"patch": _draw_patch(center, radius, primary, secondary)
		"storage": _draw_storage(center, radius, primary, secondary)
		"antidote": _draw_antidote(center, radius, primary, secondary)
		"play": _draw_play(center, radius, primary)
		"save": _draw_save(center, radius, primary, secondary)
		"load": _draw_load(center, radius, primary)
		"exit": _draw_exit(center, radius, primary)
		"cave": _draw_cave(center, radius, primary, secondary)
		"hook": _draw_hook(center, radius, primary)
		"light": _draw_light(center, radius, primary, secondary)
		"machete": _draw_machete(center, radius, primary, secondary)
		"torch": _draw_torch(center, radius, primary, secondary)
		"use": _draw_use(center, radius, primary, secondary)
		"cricket": _draw_cricket(center, radius, primary, secondary)
		"chain": _draw_chain(center, radius, primary, secondary)
		"cooking": _draw_cooking(center, radius, primary, secondary)
		"ration": _draw_ration(center, radius, primary, secondary)
		"hunger": _draw_hunger(center, radius, primary, secondary)
		_: _draw_arrow(center, radius, primary, direction)


func _draw_ration(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# A wrapped block: two straps over a brick, which is what the crate holds.
	var brick := Rect2(center.x - radius * 0.82, center.y - radius * 0.56, radius * 1.64, radius * 1.12)
	draw_rect(brick, color, false, stroke)
	_line(Vector2(center.x - radius * 0.34, brick.position.y), Vector2(center.x - radius * 0.34, brick.end.y), color)
	_line(Vector2(center.x + radius * 0.34, brick.position.y), Vector2(center.x + radius * 0.34, brick.end.y), color)
	_line(Vector2(brick.position.x, center.y), Vector2(brick.end.x, center.y), detail)


func _draw_hunger(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# An hourglass: appetite, measured in hours left, not a bar.
	_line(Vector2(center.x - radius * 0.52, center.y - radius * 0.92), Vector2(center.x + radius * 0.52, center.y - radius * 0.92), color)
	_line(Vector2(center.x - radius * 0.52, center.y + radius * 0.92), Vector2(center.x + radius * 0.52, center.y + radius * 0.92), color)
	_line(Vector2(center.x - radius * 0.46, center.y - radius * 0.86), Vector2(center.x, center.y), color)
	_line(Vector2(center.x + radius * 0.46, center.y - radius * 0.86), Vector2(center.x, center.y), color)
	_line(Vector2(center.x - radius * 0.46, center.y + radius * 0.86), Vector2(center.x, center.y), color)
	_line(Vector2(center.x + radius * 0.46, center.y + radius * 0.86), Vector2(center.x, center.y), color)
	draw_circle(Vector2(center.x, center.y + radius * 0.56), radius * 0.16, detail)


func _draw_cricket(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# A blunt little farm insect: oval abdomen, round head, two antennae and
	# three legs a side, so the culture readout is not another generic token.
	var body := PackedVector2Array()
	for index in 12:
		var angle := TAU * float(index) / 12.0
		body.append(center + Vector2(cos(angle) * radius * 0.60, sin(angle) * radius * 0.90))
	draw_colored_polygon(body, color)
	draw_circle(center + Vector2(0.0, -radius * 0.92), radius * 0.30, color)
	_line(center + Vector2(-radius * 0.12, -radius * 1.06), center + Vector2(-radius * 0.60, -radius * 1.62), detail)
	_line(center + Vector2(radius * 0.12, -radius * 1.06), center + Vector2(radius * 0.60, -radius * 1.62), detail)
	for index in 3:
		var y: float = center.y + radius * (-0.42 + float(index) * 0.44)
		_line(Vector2(center.x - radius * 0.44, y), Vector2(center.x - radius * 1.12, y + radius * 0.34), detail)
		_line(Vector2(center.x + radius * 0.44, y), Vector2(center.x + radius * 1.12, y + radius * 0.34), detail)


func _draw_cooking(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# A pot with steam: the same silhouette the kitchen bench uses.
	var pot := Rect2(center.x - radius * 0.76, center.y - radius * 0.06, radius * 1.52, radius * 0.94)
	draw_rect(pot, color, false, stroke)
	_line(Vector2(center.x - radius * 0.92, center.y - radius * 0.06), Vector2(center.x + radius * 0.92, center.y - radius * 0.06), color)
	_line(Vector2(center.x - radius * 0.76, center.y + radius * 0.20), Vector2(center.x - radius * 1.08, center.y + radius * 0.20), color)
	_line(Vector2(center.x + radius * 0.76, center.y + radius * 0.20), Vector2(center.x + radius * 1.08, center.y + radius * 0.20), color)
	for index in 3:
		var x: float = center.x - radius * 0.42 + float(index) * radius * 0.42
		_line(Vector2(x, center.y - radius * 0.30), Vector2(x + radius * 0.16, center.y - radius * 0.78), detail)


func _line(from: Vector2, to: Vector2, color: Color, width: float = -1.0) -> void:
	draw_line(from, to, color, stroke if width < 0.0 else width, true)


func _rotated(point: Vector2, angle: float) -> Vector2:
	return point.rotated(angle)


func _draw_ring(center: Vector2, radius: float, color: Color, amount: float = 1.0) -> void:
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * clampf(amount, 0.0, 1.0), 36, color, stroke, true)


func _draw_warmth(center: Vector2, radius: float, color: Color) -> void:
	_draw_ring(center, radius, Color(color, color.a * 0.22))
	_draw_ring(center, radius, color, value)
	var flame := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.73),
		center + Vector2(radius * 0.38, -radius * 0.12),
		center + Vector2(radius * 0.16, radius * 0.65),
		center + Vector2(0.0, radius * 0.84),
		center + Vector2(-radius * 0.26, radius * 0.42),
		center + Vector2(-radius * 0.31, -radius * 0.12),
	])
	draw_colored_polygon(flame, Color(color, color.a * 0.35))
	draw_polyline(flame + PackedVector2Array([flame[0]]), color, stroke, true)
	_line(center + Vector2(0.0, radius * 0.42), center + Vector2(radius * 0.08, -radius * 0.22), color, stroke * 0.75)


func _draw_fuel(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var can := Rect2(center + Vector2(-radius * 0.52, -radius * 0.55), Vector2(radius * 1.04, radius * 1.22))
	draw_rect(can, Color(color, color.a * 0.14), true)
	draw_rect(can, color, false, stroke, true)
	_line(center + Vector2(-radius * 0.22, -radius * 0.56), center + Vector2(-radius * 0.22, -radius * 0.83), color)
	_line(center + Vector2(-radius * 0.22, -radius * 0.83), center + Vector2(radius * 0.30, -radius * 0.83), color)
	_line(center + Vector2(radius * 0.30, -radius * 0.83), center + Vector2(radius * 0.32, -radius * 0.55), color)
	_line(center + Vector2(-radius * 0.32, -radius * 0.08), center + Vector2(radius * 0.30, -radius * 0.08), detail, stroke * 0.8)
	_line(center + Vector2(-radius * 0.20, radius * 0.30), center + Vector2(radius * 0.23, radius * 0.30), detail, stroke * 0.8)


func _draw_water(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var drop := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.91),
		center + Vector2(radius * 0.56, radius * 0.05),
		center + Vector2(radius * 0.34, radius * 0.67),
		center + Vector2(0.0, radius * 0.86),
		center + Vector2(-radius * 0.34, radius * 0.67),
		center + Vector2(-radius * 0.56, radius * 0.05),
	])
	draw_colored_polygon(drop, Color(color, color.a * 0.24))
	draw_polyline(drop + PackedVector2Array([drop[0]]), color, stroke, true)
	_line(center + Vector2(-radius * 0.22, radius * 0.26), center + Vector2(radius * 0.24, radius * 0.26), detail, stroke * 0.72)


func _draw_chain(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# Two interlocked links, one upright and one across it, as the shutter carries them.
	draw_arc(center + Vector2(-radius * 0.22, 0.0), radius * 0.42, 0.0, TAU, 20, color, stroke, true)
	draw_arc(center + Vector2(radius * 0.22, 0.0), radius * 0.42, 0.0, TAU, 20, detail, stroke, true)


func _draw_chitin(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var shell := PackedVector2Array()
	for index in 12:
		var angle := TAU * float(index) / 12.0
		shell.append(center + Vector2(cos(angle) * radius * 0.54, sin(angle) * radius * 0.72))
	draw_colored_polygon(shell, Color(color, color.a * 0.17))
	draw_polyline(shell + PackedVector2Array([shell[0]]), color, stroke, true)
	_line(center + Vector2(0.0, -radius * 0.62), center + Vector2(0.0, radius * 0.62), detail, stroke * 0.74)
	_line(center + Vector2(-radius * 0.40, -radius * 0.15), center + Vector2(radius * 0.40, -radius * 0.15), color, stroke * 0.66)
	_line(center + Vector2(-radius * 0.33, radius * 0.26), center + Vector2(radius * 0.33, radius * 0.26), color, stroke * 0.66)


func _draw_hide(center: Vector2, radius: float, color: Color) -> void:
	var hide := PackedVector2Array([
		center + Vector2(-radius * 0.64, -radius * 0.50),
		center + Vector2(-radius * 0.16, -radius * 0.73),
		center + Vector2(radius * 0.61, -radius * 0.42),
		center + Vector2(radius * 0.46, radius * 0.56),
		center + Vector2(-radius * 0.16, radius * 0.72),
		center + Vector2(-radius * 0.66, radius * 0.32),
	])
	draw_colored_polygon(hide, Color(color, color.a * 0.17))
	draw_polyline(hide + PackedVector2Array([hide[0]]), color, stroke, true)
	_line(center + Vector2(-radius * 0.25, -radius * 0.34), center + Vector2(radius * 0.26, radius * 0.36), color, stroke * 0.70)


func _draw_snare(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	draw_arc(center, radius * 0.61, deg_to_rad(26.0), deg_to_rad(332.0), 26, color, stroke, true)
	_line(center + Vector2(radius * 0.28, -radius * 0.52), center + Vector2(radius * 0.83, -radius * 0.83), color, stroke)
	_line(center + Vector2(radius * 0.45, -radius * 0.70), center + Vector2(radius * 0.69, -radius * 0.46), detail, stroke * 0.75)
	draw_circle(center + Vector2(-radius * 0.20, radius * 0.57), radius * 0.09, detail)


func _draw_patch(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var patch := Rect2(center - Vector2(radius * 0.61, radius * 0.53), Vector2(radius * 1.22, radius * 1.06))
	draw_rect(patch, Color(color, color.a * 0.16), true)
	draw_rect(patch, color, false, stroke, true)
	_line(center + Vector2(-radius * 0.40, -radius * 0.35), center + Vector2(radius * 0.40, radius * 0.35), detail, stroke * 0.82)
	_line(center + Vector2(radius * 0.40, -radius * 0.35), center + Vector2(-radius * 0.40, radius * 0.35), detail, stroke * 0.82)


func _draw_storage(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var frame := Rect2(center - Vector2(radius * 0.66, radius * 0.70), Vector2(radius * 1.32, radius * 1.40))
	draw_rect(frame, Color(color, color.a * 0.11), true)
	draw_rect(frame, color, false, stroke, true)
	_line(center + Vector2(-radius * 0.56, -radius * 0.18), center + Vector2(radius * 0.56, -radius * 0.18), detail, stroke * 0.78)
	_line(center + Vector2(-radius * 0.56, radius * 0.35), center + Vector2(radius * 0.56, radius * 0.35), detail, stroke * 0.78)


func _draw_antidote(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var vial := Rect2(center + Vector2(-radius * 0.39, -radius * 0.32), Vector2(radius * 0.78, radius * 0.93))
	draw_rect(vial, Color(color, color.a * 0.14), true)
	draw_rect(vial, color, false, stroke, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.24, -radius * 0.67), Vector2(radius * 0.48, radius * 0.28)), color, false, stroke, true)
	_line(center + Vector2(-radius * 0.31, radius * 0.26), center + Vector2(radius * 0.31, radius * 0.26), detail, stroke * 0.80)


func _draw_bolt(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.13, -radius * 0.88),
		center + Vector2(radius * 0.50, -radius * 0.12),
		center + Vector2(radius * 0.12, -radius * 0.12),
		center + Vector2(radius * 0.12, radius * 0.82),
		center + Vector2(-radius * 0.52, radius * 0.05),
		center + Vector2(-radius * 0.12, radius * 0.05),
	])
	draw_colored_polygon(points, Color(color, color.a * 0.38))
	draw_polyline(points + PackedVector2Array([points[0]]), color, stroke, true)


func _draw_driver(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	draw_arc(center, radius * 0.66, deg_to_rad(205.0), deg_to_rad(335.0), 18, color, stroke, true)
	_line(center + Vector2(-radius * 0.72, -radius * 0.10), center + Vector2(radius * 0.68, -radius * 0.10), color)
	_line(center + Vector2(-radius * 0.35, -radius * 0.10), center + Vector2(-radius * 0.52, radius * 0.50), color)
	_line(center + Vector2(radius * 0.24, -radius * 0.10), center + Vector2(radius * 0.42, radius * 0.46), color)
	_line(center + Vector2(-radius * 0.12, -radius * 0.50), center + Vector2(radius * 0.52, -radius * 0.10), detail, stroke * 0.75)
	draw_circle(center + Vector2(radius * 0.52, -radius * 0.10), radius * 0.08, detail)


func _draw_compass(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# The rim ticks are the widest thing in this glyph; keeping them off the box edge
	# stops the compass crowding whatever label sits beside it.
	radius *= 0.86
	_draw_ring(center, radius, Color(color, color.a * 0.55))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var outer := center + Vector2(0.0, -radius).rotated(angle)
		var inner := center + Vector2(0.0, -radius * (0.70 if index % 2 == 0 else 0.80)).rotated(angle)
		_line(inner, outer, color, stroke * 0.72)
	_draw_arrow(center, radius * 0.72, detail, direction)


func _draw_objective(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.84), center + Vector2(radius * 0.84, 0.0),
		center + Vector2(0.0, radius * 0.84), center + Vector2(-radius * 0.84, 0.0),
	])
	draw_colored_polygon(diamond, Color(color, color.a * 0.16))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), color, stroke, true)
	draw_rect(Rect2(center - Vector2(radius * 0.27, radius * 0.20), Vector2(radius * 0.54, radius * 0.46)), detail, false, stroke * 0.76, true)
	_line(center + Vector2(-radius * 0.12, -radius * 0.31), center + Vector2(radius * 0.12, -radius * 0.31), detail, stroke * 0.76)


func _draw_warning(center: Vector2, radius: float, color: Color) -> void:
	var triangle := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.90), center + Vector2(radius * 0.84, radius * 0.68),
		center + Vector2(-radius * 0.84, radius * 0.68),
	])
	draw_colored_polygon(triangle, Color(color, color.a * 0.14))
	draw_polyline(triangle + PackedVector2Array([triangle[0]]), color, stroke, true)
	_line(center + Vector2(0.0, -radius * 0.32), center + Vector2(0.0, radius * 0.22), color, stroke * 1.2)
	draw_circle(center + Vector2(0.0, radius * 0.43), stroke * 0.58, color)


func _draw_furnace(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var body := Rect2(center + Vector2(-radius * 0.62, -radius * 0.54), Vector2(radius * 1.24, radius * 1.15))
	draw_rect(body, Color(color, color.a * 0.13), true)
	draw_rect(body, color, false, stroke, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.35, -radius * 0.18), Vector2(radius * 0.70, radius * 0.56)), detail, false, stroke * 0.85, true)
	_line(center + Vector2(-radius * 0.42, -radius * 0.74), center + Vector2(radius * 0.42, -radius * 0.74), color, stroke)
	_line(center + Vector2(radius * 0.28, -radius * 0.74), center + Vector2(radius * 0.28, -radius * 1.05), color, stroke)
	draw_circle(center + Vector2(0.0, radius * 0.08), radius * 0.13, Color(detail, detail.a * 0.9))


func _draw_gear(center: Vector2, radius: float, color: Color) -> void:
	_draw_ring(center, radius * 0.50, color)
	draw_circle(center, radius * 0.16, color, false, stroke, true)
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var inner := center + Vector2(0.0, -radius * 0.54).rotated(angle)
		var outer := center + Vector2(0.0, -radius * 0.84).rotated(angle)
		_line(inner, outer, color, stroke * 1.6)


func _draw_play(center: Vector2, radius: float, color: Color) -> void:
	var triangle := PackedVector2Array([
		center + Vector2(-radius * 0.45, -radius * 0.70), center + Vector2(radius * 0.74, 0.0),
		center + Vector2(-radius * 0.45, radius * 0.70),
	])
	draw_colored_polygon(triangle, Color(color, color.a * 0.28))
	draw_polyline(triangle + PackedVector2Array([triangle[0]]), color, stroke, true)


func _draw_save(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var disk := Rect2(center + Vector2(-radius * 0.64, -radius * 0.72), Vector2(radius * 1.28, radius * 1.44))
	draw_rect(disk, Color(color, color.a * 0.13), true)
	draw_rect(disk, color, false, stroke, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.31, -radius * 0.58), Vector2(radius * 0.62, radius * 0.42)), detail, false, stroke * 0.80, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.36, radius * 0.10), Vector2(radius * 0.72, radius * 0.44)), color, false, stroke * 0.80, true)


func _draw_load(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center, radius * 0.66, deg_to_rad(-45.0), deg_to_rad(250.0), 24, color, stroke, true)
	var tip := center + Vector2(radius * 0.58, -radius * 0.34)
	var arrow := PackedVector2Array([tip, tip + Vector2(-radius * 0.08, radius * 0.38), tip + Vector2(-radius * 0.40, radius * 0.10)])
	draw_colored_polygon(arrow, color)


func _draw_exit(center: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(center + Vector2(-radius * 0.62, -radius * 0.72), Vector2(radius * 0.78, radius * 1.44)), color, false, stroke, true)
	_line(center + Vector2(-radius * 0.12, 0.0), center + Vector2(radius * 0.80, 0.0), color, stroke)
	_draw_arrow(center + Vector2(radius * 0.54, 0.0), radius * 0.32, color, PI * 0.5)


func _draw_cave(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var arch := PackedVector2Array([
		center + Vector2(-radius * 0.78, radius * 0.66), center + Vector2(-radius * 0.48, -radius * 0.42),
		center + Vector2(0.0, -radius * 0.82), center + Vector2(radius * 0.50, -radius * 0.38),
		center + Vector2(radius * 0.78, radius * 0.66),
	])
	draw_polyline(arch, color, stroke, true)
	draw_arc(center + Vector2(0.0, radius * 0.62), radius * 0.34, PI, TAU, 14, detail, stroke, true)
	_line(center + Vector2(-radius * 0.80, radius * 0.66), center + Vector2(radius * 0.80, radius * 0.66), color, stroke)


func _draw_hook(center: Vector2, radius: float, color: Color) -> void:
	_line(center + Vector2(-radius * 0.45, -radius * 0.78), center + Vector2(radius * 0.10, radius * 0.08), color, stroke)
	draw_arc(center + Vector2(radius * 0.12, radius * 0.10), radius * 0.42, deg_to_rad(-20.0), deg_to_rad(168.0), 16, color, stroke, true)
	var tip := center + Vector2(-radius * 0.28, radius * 0.20)
	_draw_arrow(tip, radius * 0.23, color, deg_to_rad(-120.0))


func _draw_machete(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# Long blade on the diagonal with a guard and a working grip.
	var direction := Vector2(0.62, -0.78)
	var across := Vector2(0.78, 0.62)
	var heel := center + Vector2(-radius * 0.16, radius * 0.20)
	var tip := heel + direction * radius * 1.42
	var width := across * radius * 0.15
	var blade := PackedVector2Array([heel + width, tip, heel - width])
	draw_colored_polygon(blade, Color(color, color.a * 0.34))
	draw_polyline(blade + PackedVector2Array([heel + width]), color, stroke, true)
	_line(heel + width * 1.9, heel - width * 1.9, detail, stroke)
	_line(heel, heel - direction * radius * 0.78, color, stroke * 2.0)
	draw_circle(heel - direction * radius * 0.86, radius * 0.10, detail)


func _draw_torch(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	# A hand torch held at an angle, with a lit lens and a short beam.
	var direction := Vector2(0.55, -0.83)
	var back := center + Vector2(-radius * 0.42, radius * 0.58)
	var lens := back + direction * radius * 1.30
	_line(back, lens, color, stroke * 2.4)
	_line(back + Vector2(-radius * 0.10, radius * 0.16), back + Vector2(radius * 0.10, -radius * 0.06), color, stroke * 1.1)
	draw_arc(lens, radius * 0.20, 0.0, TAU, 20, detail, stroke, true)
	for offset in [-0.42, 0.0, 0.42]:
		var ray: Vector2 = direction.rotated(offset)
		_line(lens + ray * radius * 0.34, lens + ray * radius * 0.64, detail, stroke * 0.8)


func _draw_light(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	var body := Rect2(center + Vector2(-radius * 0.68, -radius * 0.25), Vector2(radius * 0.68, radius * 0.50))
	draw_rect(body, Color(color, color.a * 0.16), true)
	draw_rect(body, color, false, stroke, true)
	var beam := PackedVector2Array([
		center + Vector2(0.0, -radius * 0.42), center + Vector2(radius * 0.90, -radius * 0.72),
		center + Vector2(radius * 0.90, radius * 0.72), center + Vector2(0.0, radius * 0.42),
	])
	draw_colored_polygon(beam, Color(detail, detail.a * 0.20))
	draw_polyline(beam, detail, stroke * 0.70, true)


func _draw_use(center: Vector2, radius: float, color: Color, detail: Color) -> void:
	_draw_ring(center, radius, Color(color, color.a * 0.65))
	var chevron := PackedVector2Array([
		center + Vector2(-radius * 0.44, -radius * 0.28), center + Vector2(0.0, radius * 0.32),
		center + Vector2(radius * 0.44, -radius * 0.28),
	])
	draw_polyline(chevron, detail, stroke * 1.25, true)
	_line(center + Vector2(0.0, -radius * 0.70), center + Vector2(0.0, -radius * 0.20), color, stroke)


func _draw_arrow(center: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var points := PackedVector2Array([
		_rotated(Vector2(0.0, -radius), angle) + center,
		_rotated(Vector2(radius * 0.62, radius * 0.62), angle) + center,
		_rotated(Vector2(0.0, radius * 0.26), angle) + center,
		_rotated(Vector2(-radius * 0.62, radius * 0.62), angle) + center,
	])
	draw_colored_polygon(points, Color(color, color.a * 0.75))
	draw_polyline(points + PackedVector2Array([points[0]]), color, stroke, true)
