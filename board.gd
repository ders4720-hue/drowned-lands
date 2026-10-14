class_name HexBoard
extends Control

var game_state: Node = null
var anim_time_ms: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var _label_font: Font = null
var overlay_visible: bool = false

const LAND_STROKE_LIFT := Vector3(0.08, 0.06, 0.04)
const LAND_STROKE_ALPHA := 0.95
const SAIL_STROKE_LIFT := Vector3(0.08, 0.14, 0.18)
const SAIL_STROKE_ALPHA := 0.9
const FLOOD_FILL_ALPHA := 0.92
const FLOOD_STROKE_ALPHA := 0.9

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inter := load("res://assets/fonts/Inter-Variable.ttf") as Font
	if inter != null:
		var fv := FontVariation.new()
		fv.base_font = inter
		fv.variation_opentype = { "wght": 600 }
		_label_font = fv
	else:
		_label_font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	anim_time_ms += delta * 1000.0
	queue_redraw()

func _draw() -> void:
	if game_state == null:
		return
	var W: float = size.x
	var H: float = size.y
	_draw_sea_bg(W, H)
	var base_origin: Vector2 = Vector2(W * 0.5, H * 0.5 + Balance.MAP_OFFSET_Y) + camera_offset
	draw_set_transform(base_origin, 0.0, Vector2(zoom, zoom))
	_draw_cells()
	_draw_wind_arrows()
	_draw_storm_and_tower()
	_draw_ship(base_origin)
	draw_set_transform(Vector2.ZERO)
	_draw_island_labels(base_origin)
	_draw_vignette(W, H)

func toggle_overlay() -> void:
	overlay_visible = not overlay_visible
	queue_redraw()

func _draw_vignette(W: float, H: float) -> void:
	const BAND: float = 110.0
	const A_MAX: float = 0.65
	const SEGS: int = 8
	var base: Color = Palette.COL_SHADOW
	# top
	_vignette_edge(Vector2(0.0, 0.0), Vector2(W, 0.0),
			Vector2(0.0, BAND), Vector2(W, BAND), base, A_MAX, SEGS)
	# bottom
	_vignette_edge(Vector2(0.0, H), Vector2(W, H),
			Vector2(0.0, H - BAND), Vector2(W, H - BAND), base, A_MAX, SEGS)
	# left
	_vignette_edge(Vector2(0.0, 0.0), Vector2(0.0, H),
			Vector2(BAND, 0.0), Vector2(BAND, H), base, A_MAX, SEGS)
	# right
	_vignette_edge(Vector2(W, 0.0), Vector2(W, H),
			Vector2(W - BAND, 0.0), Vector2(W - BAND, H), base, A_MAX, SEGS)

func _vignette_edge(p_outer_a: Vector2, p_outer_b: Vector2,
		p_inner_a: Vector2, p_inner_b: Vector2,
		base: Color, a_max: float, segs: int) -> void:
	for s in range(segs):
		var t0: float = float(s) / float(segs)
		var t1: float = float(s + 1) / float(segs)
		var a0: float = a_max * (1.0 - t0) * (1.0 - t0)
		var a1: float = a_max * (1.0 - t1) * (1.0 - t1)
		var quad: PackedVector2Array = PackedVector2Array([
			p_outer_a.lerp(p_inner_a, t0),
			p_outer_b.lerp(p_inner_b, t0),
			p_outer_b.lerp(p_inner_b, t1),
			p_outer_a.lerp(p_inner_a, t1),
		])
		var cols: PackedColorArray = PackedColorArray([
			Color(base.r, base.g, base.b, a0),
			Color(base.r, base.g, base.b, a0),
			Color(base.r, base.g, base.b, a1),
			Color(base.r, base.g, base.b, a1),
		])
		draw_polygon(quad, cols)

func _draw_sea_bg(W: float, H: float) -> void:
	draw_rect(Rect2(0.0, 0.0, W, H), Palette.COL_BLUE)
	var step: float = 44.0
	var rows: int = int(ceil(H / step)) + 2
	for i in range(rows):
		var y_base: float = float(i) * step
		var pts: PackedVector2Array = PackedVector2Array()
		var x: float = -12.0
		while x <= W + 12.0:
			var phase: float = x * 0.008 + float(i) * 0.9 + anim_time_ms * 0.0006
			var y: float = y_base + sin(phase) * 4.0 + cos(phase * 1.7) * 1.5
			pts.append(Vector2(x, y))
			x += 12.0
		draw_polyline(pts, Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.10), 1.0)

func _hex_points(cx: float, cy: float, size: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * float(i) + 30.0)
		pts.append(Vector2(cx + size * cos(angle), cy + size * sin(angle)))
	return pts

func _draw_sail_weave(x0: float, y0: float, x1: float, y1: float) -> void:
	# Льняное плетение — 2×2 нити поверх заливки паруса
	var wcol: Color = Color(Palette.COL_LINEN_DK.r, Palette.COL_LINEN_DK.g, Palette.COL_LINEN_DK.b, 0.22)
	var lw: float = 0.6
	var th: float = (y1 - y0) / 3.0
	var tw: float = (x1 - x0) / 3.0
	draw_line(Vector2(x0 + 1.0, y0 + th), Vector2(x1 - 1.0, y0 + th), wcol, lw, true)
	draw_line(Vector2(x0 + 1.0, y0 + 2.0 * th), Vector2(x1 - 1.0, y0 + 2.0 * th), wcol, lw, true)
	draw_line(Vector2(x0 + tw, y0 + 1.0), Vector2(x0 + tw, y1 - 1.0), wcol, lw, true)
	draw_line(Vector2(x0 + 2.0 * tw, y0 + 1.0), Vector2(x0 + 2.0 * tw, y1 - 1.0), wcol, lw, true)

func _draw_hex(cx: float, cy: float, size: float, fill: Color, stroke: Color, lw: float) -> void:
	var pts: PackedVector2Array = _hex_points(cx, cy, size)
	if fill.a > 0.001:
		draw_colored_polygon(pts, fill)
	if stroke.a > 0.001:
		pts.append(pts[0])
		draw_polyline(pts, stroke, lw, true)

func _is_land(q: int, r: int) -> bool:
	var isl: Dictionary = game_state.island_at(q, r)
	if isl.is_empty():
		return false
	return float(isl["height"]) > game_state.water_level


func _draw_land_hex(cx: float, cy: float, size: float, fill: Color, stroke: Color, lw: float, q: int, r: int) -> void:
	var pts: PackedVector2Array = _hex_points(cx, cy, size)
	draw_colored_polygon(pts, fill)
	if stroke.a < 0.001:
		return
	var nbrs: Array[Vector2i] = HexGrid.neighbors(q, r)
	for i in range(6):
		# edge i sits between corner i and i+1 and faces neighbour (5 - i) % 6
		var n: Vector2i = nbrs[(5 - i) % 6]
		if _is_land(n.x, n.y):
			continue
		draw_line(pts[i], pts[(i + 1) % 6], stroke, lw, true)

func _draw_cells() -> void:
	var reach_map: Dictionary = {}
	for c in game_state.reachable:
		reach_map[Vector2i(int(c["q"]), int(c["r"]))] = c

	var landable_set: Dictionary = {}
	for lc in game_state.landable:
		landable_set[Vector2i(int(lc.x), int(lc.y))] = true

	var ship: Dictionary = game_state.ship

	for cell in game_state.cells:
		var p: Vector2 = HexGrid.hex_to_pixel(cell.x, cell.y, Balance.HEX_SIZE)
		var isl: Dictionary = game_state.island_at(cell.x, cell.y)
		var fill: Color = Color(0.0, 0.0, 0.0, 0.0)
		var stroke: Color = Color(Palette.COL_SEA_VOID.r, Palette.COL_SEA_VOID.g, Palette.COL_SEA_VOID.b, 0.15)
		var lw: float = 0.7

		if HexGrid.is_edge(cell.x, cell.y, Balance.R):
			continue
		elif HexGrid.is_storm(cell.x, cell.y) or HexGrid.is_tower(cell.x, cell.y):
			continue
		elif not isl.is_empty():
			var h: float = float(isl["height"])
			if h <= game_state.water_level:
				fill = Color(Palette.COL_FLOOD.r, Palette.COL_FLOOD.g, Palette.COL_FLOOD.b, FLOOD_FILL_ALPHA)
				stroke = Color(Palette.COL_FLOOD_EDGE.r, Palette.COL_FLOOD_EDGE.g, Palette.COL_FLOOD_EDGE.b, FLOOD_STROKE_ALPHA)
				lw = 1.0
			else:
				var t: float = float(min(1.0, (h - game_state.water_level) / 22.0))
				# Aegean fresco land: ochre ground → red-brown earth → pale rock
				var base: Color
				if t <= 0.6:
					base = Palette.COL_LAND_LOW.lerp(Palette.COL_LAND_EARTH, t / 0.6)
				else:
					base = Palette.COL_LAND_EARTH.lerp(Palette.COL_LAND_ROCK, (t - 0.6) / 0.4)
				fill = base
				stroke = Color(
					minf(1.0, base.r + LAND_STROKE_LIFT.x),
					minf(1.0, base.g + LAND_STROKE_LIFT.y),
					minf(1.0, base.b + LAND_STROKE_LIFT.z),
					LAND_STROKE_ALPHA)
				lw = 1.0
		else:
			fill = Color(0.0, 0.0, 0.0, 0.0)
			stroke = Color(Palette.COL_SEA_VOID.r, Palette.COL_SEA_VOID.g, Palette.COL_SEA_VOID.b, 0.12)
			lw = 0.7

		if reach_map.has(cell):
			var c: Dictionary = reach_map[cell]
			if bool(c["storm"]):
				fill = Color(Palette.COL_STORM_LT.r, Palette.COL_STORM_LT.g, Palette.COL_STORM_LT.b, 0.58)
				stroke = Color(Palette.COL_STORM_LT.r, Palette.COL_STORM_LT.g, Palette.COL_STORM_LT.b, 0.9)
				lw = 1.6
			elif ship["mode"] == "row":
				fill = Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, 0.58)
				stroke = Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, 0.9)
				lw = 1.4
			else:
				var cm: float = float(c["cm"])
				var base: Color = Palette.COL_SAIL_DK.lerp(Palette.COL_SAIL_LT, cm)
				var r2: float = base.r
				var g2: float = base.g
				var b2: float = base.b
				fill = Color(r2, g2, b2, 0.58)
				stroke = Color(
					minf(1.0, r2 + SAIL_STROKE_LIFT.x),
					minf(1.0, g2 + SAIL_STROKE_LIFT.y),
					minf(1.0, b2 + SAIL_STROKE_LIFT.z),
					SAIL_STROKE_ALPHA)
				lw = 1.4

		var draw_stroke: Color = stroke
		if overlay_visible and not reach_map.has(cell):
			draw_stroke = Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.20)
		elif not overlay_visible and not reach_map.has(cell):
			draw_stroke = Color(0.0, 0.0, 0.0, 0.0)
		if _is_land(cell.x, cell.y):
			_draw_land_hex(p.x, p.y, Balance.HEX_SIZE, fill, draw_stroke, lw, cell.x, cell.y)
		else:
			_draw_hex(p.x, p.y, Balance.HEX_SIZE - 1.0, fill, draw_stroke, lw)

		if landable_set.has(cell):
			var pulse: float = 0.55 + 0.45 * sin(anim_time_ms * 0.004)
			var lpts: PackedVector2Array = _hex_points(p.x, p.y, Balance.HEX_SIZE - 3.0)
			lpts.append(lpts[0])
			draw_polyline(lpts, Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, pulse), 2.4, true)

	_draw_bitter_river()

func _draw_bitter_river() -> void:
	var inner_r: float = float(Balance.R) * Balance.HEX_SIZE * 1.5
	var outer_r: float = float(Balance.R_MAP) * Balance.HEX_SIZE * 1.732
	if outer_r <= inner_r:
		return
	var band: float = outer_r - inner_r
	var ring_offsets: Array[float] = [0.10, 0.24, 0.38]
	for i in range(ring_offsets.size()):
		var rr: float = inner_r + band * ring_offsets[i]
		var pts: PackedVector2Array = PackedVector2Array()
		var seg: int = 120
		for j in range(seg + 1):
			var a: float = TAU * float(j) / float(seg)
			var wobble: float = sin(a * 9.0 + anim_time_ms * 0.0004 + float(i) * 1.3) * band * 0.06
			var r2: float = rr + wobble
			pts.append(Vector2(cos(a), sin(a)) * r2)
		var alpha: float = 0.20 - float(i) * 0.04
		draw_polyline(pts, Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, alpha), 1.4, true)

func _draw_island_labels(base_origin: Vector2) -> void:
	if not overlay_visible:
		return
	var font: Font = _label_font
	if font == null:
		font = ThemeDB.fallback_font
	var fsize: int = 13
	for isl in game_state.islands:
		var p: Vector2 = HexGrid.hex_to_pixel(int(isl["q"]), int(isl["r"]), Balance.HEX_SIZE)
		var screen_p: Vector2 = base_origin + p * zoom
		var col: Color
		if float(isl["height"]) <= game_state.water_level:
			col = Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, 0.5)
		elif bool(isl["has_fragment"]):
			col = Palette.COL_GOLD_LT
		else:
			col = Palette.COL_TEXT
		var text: String = str(int(isl["height"]))
		var tsz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var pos: Vector2 = screen_p + Vector2(-tsz.x * 0.5, 4.0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 2, Color(Palette.COL_NIGHT.r, Palette.COL_NIGHT.g, Palette.COL_NIGHT.b, 0.85))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)

func _draw_wind_arrows() -> void:
	if not overlay_visible:
		return
	var season: Dictionary = Balance.SEASONS[game_state.season_index]
	var s_str: float = float(season["strength"])
	if s_str < 0.03:
		return
	for cell in game_state.cells:
		if HexGrid.is_edge(cell.x, cell.y, Balance.R):
			continue
		if HexGrid.is_storm(cell.x, cell.y) or HexGrid.is_tower(cell.x, cell.y):
			continue
		var d: int = HexGrid.center_distance(cell.x, cell.y)
		if d == 0 or cell.x % 4 != 0 or cell.y % 4 != 0:
			continue
		var p: Vector2 = HexGrid.hex_to_pixel(cell.x, cell.y, Balance.HEX_SIZE)
		var w: Dictionary = Wind.wind_at(cell.x, cell.y, game_state.season_index, game_state.variable_offset)
		var angle: float = float(w["angle"])
		var L: float = 8.0 + s_str * 10.0
		var alpha: float = 0.12 + s_str * 0.3
		var col: Color = Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, alpha)
		var sx: float = p.x - cos(angle) * L
		var sy: float = p.y - sin(angle) * L
		var ex: float = p.x + cos(angle) * L
		var ey: float = p.y + sin(angle) * L
		draw_line(Vector2(sx, sy), Vector2(ex, ey), col, 1.2, true)
		var ah: float = 4.5
		var a1: float = angle + PI - 0.55
		var a2: float = angle + PI + 0.55
		draw_line(Vector2(ex, ey), Vector2(ex + cos(a1) * ah, ey + sin(a1) * ah), col, 1.2, true)
		draw_line(Vector2(ex, ey), Vector2(ex + cos(a2) * ah, ey + sin(a2) * ah), col, 1.2, true)

func _draw_storm_and_tower() -> void:
	var reach_map: Dictionary = {}
	for c in game_state.reachable:
		reach_map[Vector2i(int(c["q"]), int(c["r"]))] = c
	var has_all: bool = game_state.has_all_fragments()
	var seed: float = 0.0
	for cell in game_state.cells:
		if not HexGrid.is_storm(cell.x, cell.y):
			continue
		var p: Vector2 = HexGrid.hex_to_pixel(cell.x, cell.y, Balance.HEX_SIZE)
		var reachable: bool = reach_map.has(cell)
		_draw_storm_hex(p.x, p.y, Balance.HEX_SIZE - 1.0, seed, reachable, not has_all)
		seed += 0.37

	var tp: Vector2 = HexGrid.hex_to_pixel(0, 0, Balance.HEX_SIZE)
	var tower_reachable: bool = reach_map.has(Vector2i(0, 0))
	# Tower sits on ordinary land — same fill family as islands, coastline merged.
	_draw_land_hex(tp.x, tp.y, Balance.HEX_SIZE, Palette.COL_LAND_ROCK, Color(0.0, 0.0, 0.0, 0.0), 0.0, 0, 0)
	var tcol: Color = Palette.COL_GOLD if tower_reachable else Palette.COL_GOLD_DK
	var tpts: PackedVector2Array = _hex_points(tp.x, tp.y, Balance.HEX_SIZE - 2.0)
	tpts.append(tpts[0])
	draw_polyline(tpts, tcol, 1.6 if tower_reachable else 0.9, true)
	_draw_tower(tp.x, tp.y, Balance.HEX_SIZE - 1.0)

func _draw_storm_hex(cx: float, cy: float, size: float, seed: float, reachable: bool, fatal: bool) -> void:
	var pts: PackedVector2Array = _hex_points(cx, cy, size)
	draw_colored_polygon(pts, Color(Palette.COL_STORM.r, Palette.COL_STORM.g, Palette.COL_STORM.b, 0.85))
	var border: Color
	if reachable:
		border = Palette.COL_STORM_LT if fatal else Palette.COL_GOLD
	else:
		border = Palette.COL_STORM
	pts.append(pts[0])
	draw_polyline(pts, border, 2.0 if reachable else 1.4, true)
	var ring_count: int = 3
	for i in range(ring_count):
		var rr: float = size * (0.28 + float(i) * 0.18)
		var wobble: float = sin(anim_time_ms * 0.0008 + seed + float(i) * 0.7) * 0.06
		var col: Color = Color(Palette.COL_STORM_LT.r, Palette.COL_STORM_LT.g, Palette.COL_STORM_LT.b, 0.35 + 0.15 * sin(anim_time_ms * 0.004 + float(i) + seed))
		draw_arc(Vector2(cx, cy), rr * (1.0 + wobble), 0.0, TAU, 24, col, 1.4, true)

func _draw_tower(cx: float, cy: float, size: float) -> void:
	var glow: float = 0.5 + 0.5 * sin(anim_time_ms * 0.002)
	var copper: Color = Palette.COL_GOLD
	var outline: Color = Palette.COL_NIGHT
	var gloss_top: Color = Palette.COL_GOLD_LT
	var gloss_bottom: Color = Color(Palette.COL_NIGHT.r, Palette.COL_NIGHT.g, Palette.COL_NIGHT.b, 0.5)
	# Base ledge (deepest green)
	var base_w: float = 30.0
	var base_y: float = cy + 10.0
	draw_rect(Rect2(cx - base_w * 0.5, base_y, base_w, 3.0), Palette.COL_LAND_EARTH, true)
	draw_rect(Rect2(cx - base_w * 0.5, base_y, base_w, 3.0), outline, false, 0.9)
	# Seven tiers: saturated malachite, brighter toward the top
	var tier_fills: Array = []
	for i in range(7):
		tier_fills.append(Palette.COL_LAPIS.lerp(Palette.COL_LAPIS_LT, float(i) / 6.0))
	var tier_h: float = 3.0
	for i in range(7):
		var w: float = base_w - 2.0 - float(i) * 3.0
		var y: float = base_y - float(i + 1) * tier_h
		var x: float = cx - w * 0.5
		var r: Rect2 = Rect2(x, y, w, tier_h)
		draw_rect(r, tier_fills[i], true)
		draw_rect(r, outline, false, 0.85)
		draw_line(Vector2(x + 0.5, y + 0.8), Vector2(x + w - 0.5, y + 0.8), gloss_top, 1.0, true)
		draw_line(Vector2(x + 0.5, y + tier_h - 0.8), Vector2(x + w - 0.5, y + tier_h - 0.8), gloss_bottom, 1.0, true)
		draw_line(Vector2(x, y), Vector2(x + w, y), copper, 1.2, true)
	# Summit shrine (Marduk's temple) — copper cap
	var shrine_w: float = 7.0
	var shrine_h: float = 3.5
	var sx: float = cx - shrine_w * 0.5
	var sy: float = base_y - 7.0 * tier_h - shrine_h
	draw_rect(Rect2(sx, sy, shrine_w, shrine_h), Palette.COL_LAPIS_LT, true)
	draw_rect(Rect2(sx, sy, shrine_w, shrine_h), copper, false, 1.4)
	# Copper roof
	var roof: PackedVector2Array = PackedVector2Array([
		Vector2(sx - 1.5, sy),
		Vector2(sx + shrine_w + 1.5, sy),
		Vector2(cx, sy - 5.0),
	])
	draw_colored_polygon(roof, copper)
	draw_polyline(roof, Palette.COL_GOLD_DK, 0.8, true)
	# Pulsing star at the summit
	draw_circle(Vector2(cx, sy - 5.0), 1.8 + glow * 1.1, Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, 0.85 + glow * 0.15))



func _draw_ship(base_origin: Vector2) -> void:
	var ship: Dictionary = game_state.ship
	var sp: Vector2 = HexGrid.hex_to_pixel(int(ship["q"]), int(ship["r"]), Balance.HEX_SIZE)
	var bob: float = sin(anim_time_ms * 0.002) * 1.2
	var ship_def: Dictionary = game_state.current_ship()
	if ship_def.is_empty():
		return
	var sz: float = float(ship_def["size"])

	var heading: float = float(ship["heading"])
	var facing: float = -1.0 if cos(heading) < 0.0 else 1.0
	var origin: Vector2 = base_origin + sp * zoom + Vector2(0.0, bob)
	var xform: Transform2D = Transform2D(0.0, Vector2(zoom * facing, zoom), 0.0, origin)
	draw_set_transform_matrix(xform)
	var hull_id: String = "bark"
	if ship_def.has("hull"):
		hull_id = String(ship_def["hull"])
	_draw_ship_shape(sz, hull_id)
	draw_set_transform(base_origin, 0.0, Vector2(zoom, zoom))

func _draw_ship_shape(s: float, hull: String) -> void:
	match hull:
		"bark":
			_draw_hull_bark(s)
		"depet":
			_draw_hull_depet(s)
		"keftiu":
			_draw_hull_keftiu(s)
		"gishma":
			_draw_hull_gishma(s)
		_:
			_draw_hull_bark(s)


func _draw_hull_bark(s: float) -> void:
	# Ugaritic/Levantine merchantman (Uluburun, c. 1300 BCE):
	# low sturdy hull, roughly symmetric bow & stern, no high stern.
	var hull := PackedVector2Array([
		Vector2(-10.0 * s, -2.5 * s),
		Vector2(10.0 * s, -2.5 * s),
		Vector2(12.0 * s, 0.5 * s),
		Vector2(10.0 * s, 3.0 * s),
		Vector2(-10.0 * s, 3.0 * s),
		Vector2(-12.0 * s, 0.5 * s),
	])
	draw_colored_polygon(hull, Palette.COL_CEDAR)
	var c := hull.duplicate()
	c.append(hull[0])
	draw_polyline(c, Palette.COL_CEDAR_DK, 1.1, true)
	# Single mast amidships + square sail
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -10.5 * s), Palette.COL_CEDAR_DK, 1.0, true)
	var sail := PackedVector2Array([
		Vector2(-3.5 * s, -9.5 * s),
		Vector2(3.5 * s, -9.5 * s),
		Vector2(3.5 * s, -1.0 * s),
		Vector2(-3.5 * s, -1.0 * s),
	])
	draw_colored_polygon(sail, Palette.COL_LINEN)
	_draw_sail_weave(-3.5 * s, -9.5 * s, 3.5 * s, -1.0 * s)
	var sc := sail.duplicate()
	sc.append(sail[0])
	draw_polyline(sc, Palette.COL_LINEN_DK, 0.8, true)
	# 3 visible oar strokes below the hull line
	for i in range(3):
		var ox: float = -5.0 * s + float(i) * 5.0 * s
		draw_line(Vector2(ox, 3.0 * s), Vector2(ox - 2.0 * s, 7.0 * s), Palette.COL_CEDAR_DK, 0.9, true)


func _draw_hull_depet(s: float) -> void:
	# Egyptian (Rekhmire reliefs / Hatshepsut's ships, c. 1470 BCE):
	# long slender hull, both ends curled up as papyrus/lotus umbels.
	var hull := PackedVector2Array([
		Vector2(-12.0 * s, -5.5 * s),
		Vector2(-10.0 * s, -4.5 * s),
		Vector2(-8.0 * s, -2.5 * s),
		Vector2(-4.0 * s, -1.0 * s),
		Vector2(0.0, -0.5 * s),
		Vector2(4.0 * s, -1.5 * s),
		Vector2(8.0 * s, -3.0 * s),
		Vector2(10.0 * s, -4.5 * s),
		Vector2(12.0 * s, -5.5 * s),
		Vector2(11.0 * s, -1.0 * s),
		Vector2(6.0 * s, 2.0 * s),
		Vector2(0.0, 3.0 * s),
		Vector2(-6.0 * s, 2.0 * s),
		Vector2(-11.0 * s, -1.0 * s),
	])
	draw_colored_polygon(hull, Palette.COL_ACACIA)
	var c := hull.duplicate()
	c.append(hull[0])
	draw_polyline(c, Palette.COL_CEDAR_DK, 1.1, true)
	# Small deck cabin at the stern
	var cabin := PackedVector2Array([
		Vector2(-8.5 * s, -4.0 * s),
		Vector2(-5.5 * s, -4.0 * s),
		Vector2(-5.5 * s, -2.0 * s),
		Vector2(-8.5 * s, -2.0 * s),
	])
	draw_colored_polygon(cabin, Palette.COL_OAK)
	var cc := cabin.duplicate()
	cc.append(cabin[0])
	draw_polyline(cc, Palette.COL_CEDAR_DK, 0.8, true)
	# Single central mast + wide square sail
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -11.5 * s), Palette.COL_CEDAR_DK, 1.0, true)
	var sail := PackedVector2Array([
		Vector2(-5.5 * s, -11.0 * s),
		Vector2(5.5 * s, -11.0 * s),
		Vector2(5.5 * s, -1.0 * s),
		Vector2(-5.5 * s, -1.0 * s),
	])
	draw_colored_polygon(sail, Palette.COL_LINEN)
	_draw_sail_weave(-5.5 * s, -11.0 * s, 5.5 * s, -1.0 * s)
	var sc := sail.duplicate()
	sc.append(sail[0])
	draw_polyline(sc, Palette.COL_LINEN_DK, 0.8, true)
	# Many oar strokes along the side
	for i in range(6):
		var ox: float = -7.0 * s + float(i) * 2.8 * s
		draw_line(Vector2(ox, 1.0 * s), Vector2(ox - 1.8 * s, 6.0 * s), Palette.COL_CEDAR_DK, 0.9, true)


func _draw_hull_keftiu(s: float) -> void:
	# Minoan/Cretan (Akrotiri "Flotilla", c. 1600 BCE): long narrow hull,
	# high curved stern rising into a bird-head / flower terminal,
	# low pointed prow.
	var hull := PackedVector2Array([
		Vector2(-11.0 * s, -12.0 * s),
		Vector2(-9.5 * s, -11.0 * s),
		Vector2(-8.0 * s, -6.0 * s),
		Vector2(-6.0 * s, -1.5 * s),
		Vector2(0.0, 0.5 * s),
		Vector2(8.0 * s, -0.5 * s),
		Vector2(11.0 * s, -3.0 * s),
		Vector2(9.0 * s, 3.0 * s),
		Vector2(0.0, 4.5 * s),
		Vector2(-8.0 * s, 3.0 * s),
		Vector2(-11.0 * s, -3.0 * s),
	])
	draw_colored_polygon(hull, Palette.COL_CYPRESS)
	var c := hull.duplicate()
	c.append(hull[0])
	draw_polyline(c, Palette.COL_CEDAR_DK, 1.1, true)
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -13.0 * s), Palette.COL_CEDAR_DK, 1.0, true)
	var sail := PackedVector2Array([
		Vector2(-6.0 * s, -12.5 * s),
		Vector2(6.0 * s, -12.5 * s),
		Vector2(6.0 * s, -0.5 * s),
		Vector2(-6.0 * s, -0.5 * s),
	])
	draw_colored_polygon(sail, Palette.COL_LINEN)
	_draw_sail_weave(-6.0 * s, -12.5 * s, 6.0 * s, -0.5 * s)
	var sc := sail.duplicate()
	sc.append(sail[0])
	draw_polyline(sc, Palette.COL_LINEN_DK, 0.8, true)
	# Many oar strokes along the side
	for i in range(6):
		var ox: float = -7.0 * s + float(i) * 2.8 * s
		draw_line(Vector2(ox, 2.0 * s), Vector2(ox - 1.8 * s, 7.0 * s), Palette.COL_CEDAR_DK, 0.9, true)


func _draw_hull_gishma(s: float) -> void:
	# Hittite/Anatolian (Yazilikaya, Karatepe): stout heavy hull, high
	# bulwarks, pronounced ram at the prow — the heaviest silhouette.
	var hull := PackedVector2Array([
		Vector2(-13.0 * s, -5.5 * s),
		Vector2(-8.0 * s, -3.0 * s),
		Vector2(0.0, -2.0 * s),
		Vector2(8.0 * s, -3.0 * s),
		Vector2(13.0 * s, -4.5 * s),
		Vector2(16.0 * s, -2.5 * s),
		Vector2(13.5 * s, 0.5 * s),
		Vector2(9.0 * s, 4.0 * s),
		Vector2(0.0, 5.0 * s),
		Vector2(-10.0 * s, 4.5 * s),
		Vector2(-13.5 * s, -0.5 * s),
	])
	draw_colored_polygon(hull, Palette.COL_OAK)
	var c := hull.duplicate()
	c.append(hull[0])
	draw_polyline(c, Palette.COL_CEDAR_DK, 1.2, true)
	draw_line(Vector2(0.0, 0.0), Vector2(0.0, -13.0 * s), Palette.COL_CEDAR_DK, 1.0, true)
	var sail := PackedVector2Array([
		Vector2(-6.0 * s, -12.5 * s),
		Vector2(6.0 * s, -12.5 * s),
		Vector2(6.0 * s, -1.5 * s),
		Vector2(-6.0 * s, -1.5 * s),
	])
	draw_colored_polygon(sail, Palette.COL_LINEN)
	_draw_sail_weave(-6.0 * s, -12.5 * s, 6.0 * s, -1.5 * s)
	var sc := sail.duplicate()
	sc.append(sail[0])
	draw_polyline(sc, Palette.COL_LINEN_DK, 0.8, true)
	# Fewer oar strokes (heavy banks mostly hidden by high sides)
	for i in range(4):
		var ox: float = -7.0 * s + float(i) * 5.0 * s
		draw_line(Vector2(ox, 4.5 * s), Vector2(ox - 1.8 * s, 8.5 * s), Palette.COL_CEDAR_DK, 1.0, true)
