class_name HexGrid
extends RefCounted


enum Orientation { POINTY, FLAT }

const ORIENTATION := Orientation.POINTY

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

const COURSE_MOD: Dictionary = { 0: 1.0, 60: 0.8, 120: 0.45, 180: 0.0 }


static func key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]


static func neighbors(q: int, r: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for off in NEIGHBOR_OFFSETS:
		result.append(Vector2i(q + off.x, r + off.y))
	return result


static func distance(q1: int, r1: int, q2: int, r2: int) -> int:
	return (absi(q1 - q2) + absi(q1 + r1 - q2 - r2) + absi(r1 - r2)) / 2


static func hex_to_pixel(q: int, r: int, size: float) -> Vector2:
	if ORIENTATION == Orientation.POINTY:
		return Vector2(size * sqrt(3.0) * (q + r / 2.0), size * 1.5 * r)
	return Vector2(size * 1.5 * q, size * sqrt(3.0) * (r + q / 2.0))


static func pixel_to_hex(px: float, py: float, size: float) -> Vector2i:
	var fq: float
	var fr: float
	if ORIENTATION == Orientation.POINTY:
		fq = (sqrt(3.0) / 3.0 * px - 1.0 / 3.0 * py) / size
		fr = (2.0 / 3.0 * py) / size
	else:
		fq = (2.0 / 3.0 * px) / size
		fr = (-1.0 / 3.0 * px + sqrt(3.0) / 3.0 * py) / size
	return _cube_round(fq, fr)


static func _cube_round(fq: float, fr: float) -> Vector2i:
	var fs: float = -fq - fr
	var rq: int = roundi(fq)
	var rr: int = roundi(fr)
	var rs: int = roundi(fs)
	var dq: float = abs(rq - fq)
	var dr: float = abs(rr - fr)
	var ds: float = abs(rs - fs)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(rq, rr)


static func cells_in_radius(radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1: int = maxi(-radius, -q - radius)
		var r2: int = mini(radius, -q + radius)
		for r in range(r1, r2 + 1):
			result.append(Vector2i(q, r))
	return result


static func center_distance(q: int, r: int) -> int:
	return distance(q, r, 0, 0)


static func is_tower(q: int, r: int) -> bool:
	return center_distance(q, r) == 0


static func is_edge(q: int, r: int, radius: int) -> bool:
	var p: Vector2 = hex_to_pixel(q, r, 1.0)
	return p.length() >= float(radius) * 1.5


static func is_storm(q: int, r: int, inner: int = 1, outer: int = 2) -> bool:
	var d: int = center_distance(q, r)
	return d >= inner and d <= outer


static func course_from_angle_deg(deg: float) -> int:
	var a: float = minf(deg, 360.0 - deg)
	if a <= 30.0:
		return 0
	if a <= 90.0:
		return 60
	if a <= 150.0:
		return 120
	return 180


static func course_modifier(deg: float) -> float:
	return COURSE_MOD[course_from_angle_deg(deg)]


static func course_name(deg: float) -> String:
	match course_from_angle_deg(deg):
		0:
			return "попутный"
		60:
			return "косой"
		120:
			return "боковой"
		_:
			return "против ветра"
