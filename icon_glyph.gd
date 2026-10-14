class_name IconGlyph
extends Control

## Векторные иконки HUD в стиле бронзового века.
## Заменяют цветные эмодзи (⛵🚣⏳🧭) на процедурно нарисованные глифы.

enum Kind { SAIL, OAR, HOURGLASS, IMAGO_MUNDI, GRID }

var kind: Kind = Kind.SAIL
var icon_color: Color = Palette.COL_TEXT
var line_width: float = 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_kind(k: Kind) -> void:
	kind = k
	queue_redraw()

func set_icon_color(c: Color) -> void:
	icon_color = c
	queue_redraw()

func _draw() -> void:
	var saved_color: Color = icon_color
	if get_parent() is BaseButton and (get_parent() as BaseButton).disabled:
		icon_color = Palette.COL_TEXT_DIM
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - line_width
	match kind:
		Kind.SAIL:
			_draw_sail(c, r)
		Kind.OAR:
			_draw_oar(c, r)
		Kind.HOURGLASS:
			_draw_hourglass(c, r)
		Kind.IMAGO_MUNDI:
			_draw_imago_mundi(c, r)
		Kind.GRID:
			_draw_grid(c, r)
	icon_color = saved_color

func _draw_sail(c: Vector2, r: float) -> void:
	# Aegean Bronze Age sailing profile (Akrotiri "Flotilla" fresco, c. 1600 BCE):
	# low four-point hull with a few oar strokes below.
	var hull: PackedVector2Array = PackedVector2Array([
		Vector2(c.x - r, c.y + r * 0.35),
		Vector2(c.x + r, c.y + r * 0.35),
		Vector2(c.x + r * 0.7, c.y + r * 0.7),
		Vector2(c.x - r * 0.7, c.y + r * 0.7),
	])
	hull.append(hull[0])
	draw_polyline(hull, icon_color, line_width, true)
	draw_line(Vector2(c.x, c.y + r * 0.35), Vector2(c.x, c.y - r * 0.9), icon_color, line_width, true)
	var sail: PackedVector2Array = PackedVector2Array([
		Vector2(c.x, c.y - r * 0.9),
		Vector2(c.x + r * 0.85, c.y - r * 0.1),
		Vector2(c.x, c.y + r * 0.2),
	])
	sail.append(sail[0])
	draw_polyline(sail, icon_color, line_width, true)
	draw_line(Vector2(c.x - r * 0.8, c.y + r * 0.35), Vector2(c.x + r * 0.8, c.y + r * 0.35), icon_color, line_width * 0.6, true)
	# Short diagonal oar strokes below the hull baseline
	for i in range(3):
		var ox: float = c.x - r * 0.55 + float(i) * r * 0.35
		draw_line(Vector2(ox, c.y + r * 0.7), Vector2(ox - r * 0.18, c.y + r * 0.95), icon_color, line_width * 0.6, true)

func _draw_oar(c: Vector2, r: float) -> void:
	draw_line(Vector2(c.x - r * 0.8, c.y + r * 0.9), Vector2(c.x + r * 0.6, c.y - r * 0.9), icon_color, line_width, true)
	draw_line(Vector2(c.x + r * 0.8, c.y + r * 0.9), Vector2(c.x - r * 0.6, c.y - r * 0.9), icon_color, line_width, true)
	draw_line(Vector2(c.x + r * 0.6, c.y - r * 0.9), Vector2(c.x + r * 0.85, c.y - r * 0.65), icon_color, line_width, true)
	draw_line(Vector2(c.x - r * 0.6, c.y - r * 0.9), Vector2(c.x - r * 0.85, c.y - r * 0.65), icon_color, line_width, true)

func _draw_hourglass(c: Vector2, r: float) -> void:
	var top: float = c.y - r * 0.8
	var bot: float = c.y + r * 0.8
	var half: float = r * 0.6
	draw_line(Vector2(c.x - half, top), Vector2(c.x + half, top), icon_color, line_width, true)
	draw_line(Vector2(c.x - half, bot), Vector2(c.x + half, bot), icon_color, line_width, true)
	draw_line(Vector2(c.x - half, top), Vector2(c.x, c.y), icon_color, line_width, true)
	draw_line(Vector2(c.x + half, top), Vector2(c.x, c.y), icon_color, line_width, true)
	draw_line(Vector2(c.x - half, bot), Vector2(c.x, c.y), icon_color, line_width, true)
	draw_line(Vector2(c.x + half, bot), Vector2(c.x, c.y), icon_color, line_width, true)

func _draw_grid(c: Vector2, r: float) -> void:
	# Surveyor's lattice: a hexagonal cell and a smaller concentric hex —
	# the hex map read as a "measured world" overlay (double grid).
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var a: float = deg_to_rad(60.0 * float(i) + 30.0)
		pts.append(Vector2(c.x + r * 0.85 * cos(a), c.y + r * 0.85 * sin(a)))
	pts.append(pts[0])
	draw_polyline(pts, icon_color, line_width, true)
	# Inner lattice — a smaller concentric hex, second "measure"
	var inner: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var a2: float = deg_to_rad(60.0 * float(i) + 30.0)
		inner.append(Vector2(c.x + r * 0.5 * cos(a2), c.y + r * 0.5 * sin(a2)))
	inner.append(inner[0])
	draw_polyline(inner, icon_color, line_width * 0.6, true)

func _draw_imago_mundi(c: Vector2, r: float) -> void:
	# Babylonian Imago Mundi (c. 6th c. BCE) — disc world with
	# Babylon at the centre and the Bitter River around it.
	# Replaces the European wind rose (which is anachronistic
	# for the Bronze Age setting).
	draw_arc(c, r * 0.9, 0.0, TAU, 40, icon_color, line_width, true)
	# Inner "Bitter River" ring
	draw_arc(c, r * 0.55, 0.0, TAU, 32, icon_color, line_width * 0.7, true)
	# Centre mark (Babylon)
	draw_circle(c, r * 0.12, icon_color)
	# 7 triangular islands around the rim
	for i in range(7):
		var a: float = TAU * float(i) / 7.0 - PI / 2.0
		var p0: Vector2 = c + Vector2(cos(a), sin(a)) * (r * 0.72)
		var p1: Vector2 = c + Vector2(cos(a - 0.15), sin(a - 0.15)) * (r * 0.88)
		var p2: Vector2 = c + Vector2(cos(a + 0.15), sin(a + 0.15)) * (r * 0.88)
		var tri: PackedVector2Array = PackedVector2Array([p0, p1, p2])
		draw_colored_polygon(tri, icon_color)
	# 4 cardinal rays (simplified, as on the tablet)
	draw_line(Vector2(c.x, c.y - r * 0.9), Vector2(c.x, c.y - r * 0.55), icon_color, line_width * 0.5, true)
	draw_line(Vector2(c.x, c.y + r * 0.55), Vector2(c.x, c.y + r * 0.9), icon_color, line_width * 0.5, true)
	draw_line(Vector2(c.x - r * 0.9, c.y), Vector2(c.x - r * 0.55, c.y), icon_color, line_width * 0.5, true)
	draw_line(Vector2(c.x + r * 0.55, c.y), Vector2(c.x + r * 0.9, c.y), icon_color, line_width * 0.5, true)
