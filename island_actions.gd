class_name IslandActions
extends RefCounted


static func _empty() -> Dictionary:
	return {
		"events": [],
		"modal": {},
		"end": "",
		"end_text": "",
		"spend_turn": true,
	}


static func _event(text: String, cls: String) -> Dictionary:
	return { "text": text, "cls": cls }


static func _explore_island_impl(state: Node, q: int, r: int) -> Dictionary:
	var res: Dictionary = _empty()

	var isl: Dictionary = state.island_at(q, r)
	if isl.is_empty():
		res["events"].append(_event("Остров не найден.", ""))
		res["spend_turn"] = false
		return res

	if isl["flooded"]:
		res["events"].append(_event("Остров под водой.", ""))
		res["spend_turn"] = false
		return res

	if isl["has_fragment"]:
		isl["has_fragment"] = false
		isl["explored"] = true
		state.fragments += 1
		var done: bool = state.fragments >= Balance.FRAGMENTS_NEEDED
		var frag_arr: Array = Flavor.FLAVOR["findFragment"] as Array
		var frag_text: String = Flavor.pick(frag_arr)
		res["events"].append(_event("%s Всего: %d/4." % [frag_text, state.fragments], "fragment"))
		if done:
			var all_arr: Array = Flavor.FLAVOR["allFragments"] as Array
			res["events"].append(_event(Flavor.pick(all_arr), "fragment"))
		var extra: String = "Собрано: %d / %d" % [state.fragments, Balance.FRAGMENTS_NEEDED]
		if done:
			extra += "\nКольцо бурь теперь проходимо."
		res["modal"] = {
			"title": "Обрывок карты",
			"body": "%s На нём проступает часть кольца бурь." % frag_text,
			"extra": extra,
			"buttons": [{"label": "Взять", "primary": true, "action": "close", "action_arg": ""}],
		}
		return res

	if isl["ship_id"] != null:
		var found_id: String = String(isl["ship_id"])
		var found_sh: Dictionary = Balance.ship_by_id(found_id)
		var cur_sh: Dictionary = state.current_ship()
		if found_sh.is_empty() or cur_sh.is_empty():
			res["events"].append(_event("Корабль повреждён — не разобрать.", ""))
			return res

		var can_control: bool = int(state.ship["crew"]) >= int(found_sh["sailReq"])
		var find_ship_arr: Array = Flavor.FLAVOR["findShip"] as Array
		var find_ship_text: String = Flavor.pick(find_ship_arr)

		if not can_control:
			var nec_arr: Array = Flavor.FLAVOR["notEnoughCrew"] as Array
			var nec_text: String = Flavor.pick(nec_arr)
			var extra_ne: String = (
				"Твой корабль: %s · команда %d / %d\n" % [cur_sh["name"], int(state.ship["crew"]), int(cur_sh["crewMax"])]
				+ "Найден: %s · нужно минимум %d матросов для паруса\n\n" % [found_sh["name"], int(found_sh["sailReq"])]
				+ "Корабль остаётся на острове. Вернись, когда команда подрастёт."
			)
			res["modal"] = {
				"title": "Корабль не по силам",
				"body": "%s Это %s. %s" % [find_ship_text, found_sh["name"], nec_text],
				"extra": extra_ne,
				"buttons": [{"label": "Уйти", "primary": true, "action": "close", "action_arg": ""}],
			}
			return res

		isl["ship_id"] = null
		isl["explored"] = true

		if found_sh["id"] == cur_sh["id"]:
			var same_arr: Array = Flavor.FLAVOR["sameShip"] as Array
			var same_text: String = Flavor.pick(same_arr)
			res["modal"] = {
				"title": "Брошенный корабль",
				"body": "%s Это — %s." % [same_text, found_sh["name"]],
				"extra": "",
				"buttons": [{"label": "Уйти", "primary": true, "action": "close", "action_arg": ""}],
			}
			return res

		var extra_swap: String = (
			"Твой: %s · парус %d / вёсла %d · команда %d–%d\n" % [cur_sh["name"], int(cur_sh["sail"]), int(cur_sh["row"]), int(cur_sh["sailReq"]), int(cur_sh["crewMax"])]
			+ "Найден: %s · парус %d / вёсла %d · команда %d–%d\n" % [found_sh["name"], int(found_sh["sail"]), int(found_sh["row"]), int(found_sh["sailReq"]), int(found_sh["crewMax"])]
			+ "Сейчас у тебя %d матросов." % int(state.ship["crew"])
		)
		res["modal"] = {
			"title": "Найден корабль",
			"body": "%s Это %s. Ещё крепкий — можно перейти на него." % [find_ship_text, found_sh["name"]],
			"extra": extra_swap,
			"buttons": [
				{"label": "Оставить", "primary": false, "action": "close", "action_arg": ""},
				{"label": "Обменять", "primary": true, "action": "swap_ship", "action_arg": found_id},
			],
		}
		return res

	if isl["explored"]:
		var empty_arr: Array = Flavor.FLAVOR["empty"] as Array
		res["modal"] = {
			"title": "Пусто",
			"body": Flavor.pick(empty_arr),
			"extra": "",
			"buttons": [{"label": "Уйти", "primary": true, "action": "close", "action_arg": ""}],
		}
		return res

	isl["explored"] = true
	var roll: float = randf()
	var sh_cur: Dictionary = state.current_ship()

	if roll < 0.30:
		var new_crew: int = 1 + randi() % 3
		var crew_before: int = int(state.ship["crew"])
		var crew_max: int = int(sh_cur["crewMax"])
		var available: int = crew_max - crew_before
		var find_crew_arr: Array = Flavor.FLAVOR["findCrew"] as Array
		var find_crew_text: String = Flavor.pick(find_crew_arr)
		if available <= 0:
			var overflow_arr: Array = Flavor.FLAVOR["crewOverflow"] as Array
			var overflow_text: String = Flavor.pick(overflow_arr)
			res["events"].append(_event("%s Их %d — %s" % [find_crew_text, new_crew, overflow_text], "crew"))
			res["modal"] = {
				"title": "Уцелевшие моряки",
				"body": "%s Их %d — %s" % [find_crew_text, new_crew, overflow_text],
				"extra": "Команда: %d / %d" % [crew_before, crew_max],
				"buttons": [{"label": "Уйти", "primary": true, "action": "close", "action_arg": ""}],
			}
			return res
		var taken: int = mini(new_crew, available)
		var left_behind: int = new_crew - taken
		state.ship["crew"] = crew_before + taken
		if left_behind <= 0:
			res["events"].append(_event("%s +%d матросов. Всего: %d." % [find_crew_text, taken, int(state.ship["crew"])], "crew"))
			res["modal"] = {
				"title": "Уцелевшие моряки",
				"body": "%s %d человек присоединяются к команде." % [find_crew_text, taken],
				"extra": "Команда: %d → %d (лимит %d)" % [crew_before, int(state.ship["crew"]), crew_max],
				"buttons": [{"label": "Взять на борт", "primary": true, "action": "close", "action_arg": ""}],
			}
		else:
			res["events"].append(_event("%s +%d матросов. Всего: %d. %d остались на берегу." % [find_crew_text, taken, int(state.ship["crew"]), left_behind], "crew"))
			res["modal"] = {
				"title": "Уцелевшие моряки",
				"body": "%s Мест хватило на %d из %d — остальные остаются на острове." % [find_crew_text, taken, new_crew],
				"extra": "Команда: %d → %d (лимит %d)\nОсталось на острове: %d" % [crew_before, int(state.ship["crew"]), crew_max, left_behind],
				"buttons": [{"label": "Взять на борт", "primary": true, "action": "close", "action_arg": ""}],
			}
		return res

	var empty_arr2: Array = Flavor.FLAVOR["empty"] as Array
	res["modal"] = {
		"title": "Пусто",
		"body": Flavor.pick(empty_arr2),
		"extra": "",
		"buttons": [{"label": "Вернуться на корабль", "primary": true, "action": "close", "action_arg": ""}],
	}
	return res


static func explore_island(state: Node, q: int, r: int) -> Dictionary:
	var res: Dictionary = _explore_island_impl(state, q, r)
	if bool(res.get("spend_turn", true)):
		res["events"].append_array(Turn.end_turn(state))
	if state.game_over:
		for ev in res["events"]:
			if ev.has("end") and String(ev["end"]) != "":
				res["end"] = String(ev["end"])
				res["end_text"] = String(ev["text"])
				break
	return res


static func swap_ship(state: Node, new_id: String) -> Dictionary:
	var res: Dictionary = _empty()
	var new_sh: Dictionary = Balance.ship_by_id(new_id)
	if new_sh.is_empty():
		return res
	var crew: int = int(state.ship["crew"])
	if crew < int(new_sh["sailReq"]):
		var nec_arr: Array = Flavor.FLAVOR["notEnoughCrew"] as Array
		var nec: String = Flavor.pick(nec_arr)
		res["events"].append(_event("%s %s требует минимум %d матросов." % [nec, new_sh["name"], int(new_sh["sailReq"])], "death"))
		return res
	var capped: int = mini(crew, int(new_sh["crewMax"]))
	state.ship["type_id"] = new_id
	state.ship["crew"] = capped
	var swap_arr: Array = Flavor.FLAVOR["shipSwap"] as Array
	var swap_text: String = Flavor.pick(swap_arr)
	res["events"].append(_event("%s Теперь твой корабль — %s." % [swap_text, new_sh["name"]], "ship"))
	if capped < crew:
		res["events"].append(_event("%d матросов остались на берегу — не влезли." % (crew - capped), "death"))
	return res
