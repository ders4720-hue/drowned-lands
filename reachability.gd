class_name Reachability
extends RefCounted


const MAX_RANGE: int = 8
const EPSILON: float = 0.000001


static func refresh(state: Node) -> void:
	var ship: Dictionary = state.ship
	var sh: Dictionary = state.current_ship()
	if sh.is_empty():
		state.reachable = []
		state.landable = []
		return

	var out: Array = []
	var landable: Array = []
	var ship_q: int = int(ship["q"])
	var ship_r: int = int(ship["r"])
	var p1: Vector2 = HexGrid.hex_to_pixel(ship_q, ship_r, Balance.HEX_SIZE)

	var candidates: Array = _candidates(ship_q, ship_r, state.cells_set)

	if ship["mode"] == "row":
		var mp_max: float = float(sh["row"]) * _row_ratio(state)
		for cell in candidates:
			var d: int = HexGrid.distance(ship_q, ship_r, cell.x, cell.y)
			if d == 0 or d > MAX_RANGE:
				continue
			var isl: Dictionary = state.island_at(cell.x, cell.y)
			if not isl.is_empty() and isl["height"] > state.water_level:
				if d == 1 and not isl["flooded"]:
					landable.append(cell)
				continue
			if mp_max < 0.05:
				continue
			if float(d) > mp_max + EPSILON:
				continue
			var is_storm_cell: bool = HexGrid.is_storm(cell.x, cell.y) or HexGrid.is_tower(cell.x, cell.y)
			var storm: bool = is_storm_cell and not state.has_all_fragments()
			out.append(_cell(cell, d, mp_max, 1.0, NAN, storm))
		state.reachable = out
		state.landable = landable
		return

	var w: Dictionary = Wind.wind_at(ship_q, ship_r, state.season_index, state.variable_offset)
	var w_strength: float = float(w["strength"])
	if w_strength < 0.03:
		state.reachable = out
		state.landable = landable
		return

	var sail_mp_base: float = Balance.sail_mp(sh, int(ship["crew"]), w_strength)
	if sail_mp_base < 0.05:
		state.reachable = out
		state.landable = landable
		return

	var w_angle: float = float(w["angle"])
	for cell in candidates:
		var d: int = HexGrid.distance(ship_q, ship_r, cell.x, cell.y)
		if d == 0 or d > MAX_RANGE:
			continue
		var isl: Dictionary = state.island_at(cell.x, cell.y)
		if not isl.is_empty() and isl["height"] > state.water_level:
			if d == 1 and not isl["flooded"]:
				landable.append(cell)
			continue
		var p2: Vector2 = HexGrid.hex_to_pixel(cell.x, cell.y, Balance.HEX_SIZE)
		var move_angle: float = atan2(p2.y - p1.y, p2.x - p1.x)
		var da: float = absf(move_angle - w_angle)
		if da > PI:
			da = 2.0 * PI - da
		var deg: float = da * 180.0 / PI
		var cm: float = HexGrid.course_modifier(deg)
		var mp: float = sail_mp_base * cm
		if float(d) > mp + EPSILON:
			continue
		var is_storm_cell: bool = HexGrid.is_storm(cell.x, cell.y) or HexGrid.is_tower(cell.x, cell.y)
		var storm: bool = is_storm_cell and not state.has_all_fragments()
		out.append(_cell(cell, d, mp, cm, deg, storm))

	state.reachable = out
	state.landable = landable


static func _candidates(ship_q: int, ship_r: int, cell_set: Dictionary) -> Array:
	var result: Array = []
	for off in HexGrid.cells_in_radius(MAX_RANGE):
		var c: Vector2i = Vector2i(ship_q + off.x, ship_r + off.y)
		if cell_set.has(c):
			result.append(c)
	return result


static func _cell(cell: Vector2i, d: int, mp: float, cm: float, deg: float, storm: bool) -> Dictionary:
	return {
		"q": cell.x,
		"r": cell.y,
		"d": d,
		"mp": mp,
		"cm": cm,
		"deg": deg,
		"storm": storm,
	}


static func _row_ratio(state: Node) -> float:
	var sh: Dictionary = state.current_ship()
	if sh.is_empty():
		return 0.0
	return minf(1.0, float(state.ship["crew"]) / float(sh["req"]))
