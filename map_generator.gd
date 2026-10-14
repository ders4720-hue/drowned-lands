class_name MapGenerator
extends RefCounted


static func generate_cells(radius: int) -> Array:
	var result: Array = []
	var pixel_radius: float = float(radius) * 1.732 + 0.7
	var qr: int = int(ceil(float(radius) * 1.8)) + 1
	for q in range(-qr, qr + 1):
		for r in range(-qr, qr + 1):
			var p: Vector2 = HexGrid.hex_to_pixel(q, r, 1.0)
			if p.length() <= pixel_radius:
				result.append(Vector2i(q, r))
	return result


static func _make_island(q: int, r: int, height: int) -> Dictionary:
	return {
		"q": q,
		"r": r,
		"height": height,
		"flooded": false,
		"has_fragment": false,
		"ship_id": null,
		"explored": false,
	}


static func generate_islands(cells: Array, radius: int, island_count: int) -> Array:
	var used: Dictionary = {}
	var islands: Array = []
	var pool: Array = []
	for c in cells:
		if HexGrid.is_storm(c.x, c.y):
			continue
		if HexGrid.is_tower(c.x, c.y):
			continue
		if HexGrid.is_edge(c.x, c.y, radius):
			continue
		pool.append(c)

	if pool.is_empty():
		return islands

	for i in range(island_count):
		var c: Variant = null
		for attempt in range(100):
			var candidate: Vector2i = pool[randi() % pool.size()]
			if not used.has(HexGrid.key(candidate.x, candidate.y)):
				c = candidate
				break
		if c == null:
			continue
		used[HexGrid.key(c.x, c.y)] = true
		var h: int = 2 + randi() % 19
		islands.append(_make_island(c.x, c.y, h))

		if randf() < 0.55:
			var valid: Array = []
			for n in HexGrid.neighbors(c.x, c.y):
				if HexGrid.is_edge(n.x, n.y, radius):
					continue
				if used.has(HexGrid.key(n.x, n.y)):
					continue
				if HexGrid.is_storm(n.x, n.y) or HexGrid.is_tower(n.x, n.y):
					continue
				valid.append(n)
			if not valid.is_empty():
				var nv: Vector2i = valid[randi() % valid.size()]
				used[HexGrid.key(nv.x, nv.y)] = true
				var h2: int = maxi(2, h - 3 - randi() % 5)
				islands.append(_make_island(nv.x, nv.y, h2))

	var candidates: Array = []
	for isl in islands:
		if isl["height"] >= 8:
			candidates.append(isl)
	if candidates.size() < 4:
		candidates = islands.duplicate()
	candidates.shuffle()
	for i in range(mini(4, candidates.size())):
		candidates[i]["has_fragment"] = true

	var ship_candidates: Array = []
	for isl in islands:
		if isl["has_fragment"] == false:
			ship_candidates.append(isl)
	ship_candidates.shuffle()
	var ship_pool: Array = Balance.SHIP_POOL_BASE.duplicate()
	ship_pool.shuffle()
	var n: int = mini(ship_pool.size(), ship_candidates.size())
	for i in range(n):
		ship_candidates[i]["ship_id"] = ship_pool[i]

	return islands


static func generate_map(map_radius: int, play_radius: int, island_count: int) -> Dictionary:
	var cells: Array = generate_cells(map_radius)
	var safe_radius: int = play_radius - Balance.R_MARGIN
	var islands: Array = generate_islands(cells, safe_radius, island_count)
	return {
		"cells": cells,
		"islands": islands,
	}
