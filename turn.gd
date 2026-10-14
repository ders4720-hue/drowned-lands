class_name Turn
extends RefCounted


static func end_turn(state: Node) -> Array:
	if state.game_over:
		return []

	state.total_turns += 1

	var s: Dictionary = Balance.SEASONS[state.season_index]
	var events: Array = []

	state.season_turn += 1

	if s["wind"] == "variable" and randf() < 0.6:
		state.variable_offset = (randf() - 0.5) * PI / 2.0

	var old_season_name: String = String(s["name"])
	if state.season_turn >= int(s["turns"]):
		_apply_season_end(state, s, events)
		state.season_index += 1
		state.season_turn = 0
		if state.season_index >= Balance.SEASONS.size():
			state.season_index = 0
			state.year += 1
			events.append(_event("Год %d" % state.year, "season"))
		var ns: Dictionary = Balance.SEASONS[state.season_index]
		var name: String = ns["name"]
		var season_dict: Dictionary = Flavor.FLAVOR["seasonChange"]
		var flavor_arr: Array = season_dict.get(name, [])
		if not flavor_arr.is_empty():
			events.append(_event(Flavor.pick(flavor_arr), "season"))
		else:
			events.append(_event("Сезон: %s." % name, "season"))

	_daily_mortality(state, old_season_name, events)

	if state.ship["mode"] == "sail":
		var w: Dictionary = Wind.wind_at(
			int(state.ship["q"]), int(state.ship["r"]),
			state.season_index, state.variable_offset)
		if float(w["strength"]) < 0.03:
			state.ship["mode"] = "row"
			events.append(_event(Flavor.pick(Flavor.FLAVOR["calmSwitch"]), ""))

	return events


static func _apply_season_end(state: Node, s: Dictionary, events: Array) -> void:
	var year_bonus: float = 0.0
	if state.year >= 5:
		year_bonus = 1.0
	if state.year >= 9:
		year_bonus = 2.0

	var rise: float = float(s["rise"])
	if rise != 0.0:
		var amount: float = rise + year_bonus
		state.water_level += amount
		events.append(_event(
			"%s +%.1f → %.1f локтя." % [Flavor.pick(Flavor.FLAVOR["waterRise"]), amount, state.water_level],
			""
		))
		for i in state.islands:
			if not i["flooded"] and float(i["height"]) <= state.water_level:
				i["flooded"] = true
				events.append(_event(
					"%s (выс. %d)" % [Flavor.pick(Flavor.FLAVOR["islandFlood"]), int(i["height"])],
					""
				))

	var fall: float = float(s["fall"])
	if fall != 0.0:
		var amount2: float = absf(fall)
		state.water_level = maxf(0.0, state.water_level - amount2)
		events.append(_event(
			"%s −%.1f → %.1f локтя." % [Flavor.pick(Flavor.FLAVOR["waterFall"]), amount2, state.water_level],
			""
		))
		for i in state.islands:
			if i["flooded"] and float(i["height"]) > state.water_level:
				i["flooded"] = false
				events.append(_event(
					"%s (выс. %d)" % [Flavor.pick(Flavor.FLAVOR["islandRise"]), int(i["height"])],
					""
				))


static func _daily_mortality(state: Node, season_name: String, events: Array) -> void:
	var mult: float = float(Balance.MORTALITY_BY_SEASON.get(season_name, 1.0))
	var chance: float = Balance.MORTALITY_BASE * mult

	var alive: int = int(state.ship["crew"])
	var deaths: int = 0
	for i in range(alive):
		if randf() < chance:
			deaths += 1
	if deaths == 0:
		return

	state.ship["crew"] = alive - deaths
	state.deaths += deaths

	if state.ship["crew"] <= 0:
		state.game_over = true
		events.append({
			"text": Flavor.pick(Flavor.END_CREW),
			"cls": "death",
			"end": "crew",
		})
		return

	var reasons_dict: Dictionary = Flavor.DEATH_REASONS
	var reasons: Array = reasons_dict.get(season_name, reasons_dict["Перет"])
	var reason: String = Flavor.pick(reasons)
	var tail: String = ("%d матроса погибли" % deaths) if deaths > 1 else "матрос погиб"
	events.append(_event(
		"%s — %s. Осталось %d." % [tail, reason, int(state.ship["crew"])],
		"death"
	))


static func _event(text: String, cls: String) -> Dictionary:
	return { "text": text, "cls": cls }
