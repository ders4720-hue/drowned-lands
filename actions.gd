class_name Actions
extends RefCounted


static func _empty() -> Dictionary:
	return {
		"events": [],
		"end": "",
		"end_text": "",
		"island_action": false,
		"island_q": -99999,
		"island_r": -99999,
	}


static func try_move(state: Node, q: int, r: int) -> Dictionary:
	if not state.started or state.game_over:
		return _empty()

	var isl: Dictionary = state.island_at(q, r)
	if not isl.is_empty() and float(isl["height"]) > state.water_level:
		var d: int = HexGrid.distance(int(state.ship["q"]), int(state.ship["r"]), q, r)
		var can_land: bool = false
		for c in state.landable:
			if int(c.x) == q and int(c.y) == r:
				can_land = true
				break
		if not can_land:
			if d > 1:
				return _flavor(Flavor.FLAVOR["tooFar"] as Array)
			return _empty()
		var res: Dictionary = _empty()
		res["island_action"] = true
		res["island_q"] = q
		res["island_r"] = r
		return res

	var target: Dictionary = _find_reachable(state, q, r)
	if target.is_empty():
		if state.ship["mode"] == "row":
			return _flavor(Flavor.FLAVOR["tooFarRow"] as Array)
		var w: Dictionary = Wind.wind_at(int(state.ship["q"]), int(state.ship["r"]), state.season_index, state.variable_offset)
		var w_strength: float = float(w["strength"])
		if w_strength < 0.03:
			return _flavor(Flavor.FLAVOR["calm"] as Array)
		var sh: Dictionary = state.current_ship()
		if not sh.is_empty():
			var max_mp: float = Balance.sail_mp(sh, int(state.ship["crew"]), w_strength)
			if max_mp < 1.0:
				return _flavor(Flavor.FLAVOR["sailWeak"] as Array)
		return _flavor(Flavor.FLAVOR["unreachable"] as Array)

	var p1: Vector2 = HexGrid.hex_to_pixel(int(state.ship["q"]), int(state.ship["r"]), Balance.HEX_SIZE)
	var p2: Vector2 = HexGrid.hex_to_pixel(q, r, Balance.HEX_SIZE)
	state.ship["heading"] = atan2(p2.y - p1.y, p2.x - p1.x)
	state.ship["q"] = q
	state.ship["r"] = r

	if HexGrid.is_edge(q, r, Balance.R):
		state.game_over = true
		var res_edge: Dictionary = _empty()
		res_edge["end"] = "edge"
		res_edge["end_text"] = Flavor.pick(Flavor.END_EDGE)
		return res_edge

	var is_storm: bool = HexGrid.is_storm(q, r)
	var is_tower: bool = HexGrid.is_tower(q, r)
	var has_all: bool = state.has_all_fragments()

	if (is_storm or is_tower) and not has_all:
		state.game_over = true
		var res2: Dictionary = _empty()
		res2["end"] = "tower" if is_tower else "storm"
		res2["end_text"] = Flavor.pick(Flavor.END_TOWER) if is_tower else Flavor.pick(Flavor.END_STORM)
		return res2

	if is_tower and has_all:
		state.game_over = true
		var res3: Dictionary = _empty()
		res3["end"] = "victory"
		res3["end_text"] = Flavor.pick(Flavor.END_VICTORY)
		return res3

	var events: Array = []
	var sh: Dictionary = state.current_ship()

	if state.ship["mode"] == "sail":
		var deg: float = float(target["deg"])
		var flavor_key: String = _course_flavor_key(deg)
		var fl_arr: Array = Flavor.FLAVOR[flavor_key] as Array
		var fl: String = Flavor.pick(fl_arr)
		var course: String = HexGrid.course_name(deg)
		var d: int = int(target["d"])
		events.append(_event("%s %d гекс. · %s" % [fl, d, course], ""))
	else:
		var fl_arr: Array = Flavor.FLAVOR["row"] as Array
		var fl: String = Flavor.pick(fl_arr)
		var d: int = int(target["d"])
		var crew: int = int(state.ship["crew"])
		var req: int = int(sh["req"])
		events.append(_event("%s %d гекс. (гребцы %d/%d)" % [fl, d, crew, req], ""))

	events.append_array(Turn.end_turn(state))

	var res4: Dictionary = _empty()
	res4["events"] = events
	if state.game_over:
		for ev in events:
			if ev.has("end") and String(ev["end"]) != "":
				res4["end"] = String(ev["end"])
				res4["end_text"] = String(ev["text"])
				break
	return res4


static func wait_day(state: Node) -> Dictionary:
	if not state.started or state.game_over:
		return _empty()
	var events: Array = []
	var wait_arr: Array = Flavor.FLAVOR["wait"] as Array
	events.append(_event(Flavor.pick(wait_arr), ""))
	events.append_array(Turn.end_turn(state))
	var res: Dictionary = _empty()
	res["events"] = events
	if state.game_over:
		for ev in events:
			if ev.has("end") and String(ev["end"]) != "":
				res["end"] = String(ev["end"])
				res["end_text"] = String(ev["text"])
				break
	return res


static func _flavor(arr: Array) -> Dictionary:
	var res: Dictionary = _empty()
	res["events"] = [_event(Flavor.pick(arr), "")]
	return res


static func _event(text: String, cls: String) -> Dictionary:
	return { "text": text, "cls": cls }


static func _find_reachable(state: Node, q: int, r: int) -> Dictionary:
	for c in state.reachable:
		if int(c["q"]) == q and int(c["r"]) == r:
			return c
	return {}


static func _course_flavor_key(deg: float) -> String:
	var a: float = minf(deg, 360.0 - deg)
	if a <= 30.0:
		return "sailFair"
	if a <= 90.0:
		return "sailClose"
	return "sailBeam"
