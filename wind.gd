class_name Wind
extends RefCounted


static func wind_at(q: int, r: int, season_index: int, variable_offset: float) -> Dictionary:
	if season_index < 0 or season_index >= Balance.SEASONS.size():
		return { "angle": 0.0, "strength": 0.0 }
	var season: Dictionary = Balance.SEASONS[season_index]
	if season["wind"] == "calm":
		return { "angle": 0.0, "strength": 0.0 }

	var p: Vector2 = HexGrid.hex_to_pixel(q, r, Balance.HEX_SIZE)
	var dx: float
	var dy: float
	match season["wind"]:
		"in":
			dx = -p.x
			dy = -p.y
		"out":
			dx = p.x
			dy = p.y
		"variable":
			var a: float = atan2(-p.y, -p.x) + variable_offset
			dx = cos(a)
			dy = sin(a)
		_:
			dx = 0.0
			dy = 0.0

	var len: float = sqrt(dx * dx + dy * dy)
	if len < 0.0001:
		len = 1.0
	return {
		"angle": atan2(dy / len, dx / len),
		"strength": float(season["strength"]),
	}


static func course_modifier(deg: float) -> float:
	return HexGrid.course_modifier(deg)


static func course_name(deg: float) -> String:
	return HexGrid.course_name(deg)


static func season_data(season_index: int) -> Dictionary:
	if season_index < 0 or season_index >= Balance.SEASONS.size():
		return {}
	return Balance.SEASONS[season_index]
