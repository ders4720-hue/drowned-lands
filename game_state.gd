extends Node

var year: int = 1
var season_index: int = 0
var season_turn: int = 0
var water_level: float = 0.0
var variable_offset: float = 0.0
var deaths: int = 0
var fragments: int = 0
var total_turns: int = 0

var ship: Dictionary = {
	"q": 0,
	"r": 0,
	"heading": -PI / 2.0,
	"type_id": "bark",
	"mode": "sail",
	"crew": 2,
}

var cells: Array = []
var cells_set: Dictionary = {}
var islands: Array = []
var islands_by_key: Dictionary = {}
var reachable: Array = []
var landable: Array = []

var started: bool = false
var game_over: bool = false


func _ready() -> void:
	reset()


func reset() -> void:
	year = 1
	season_index = 0
	season_turn = 0
	water_level = 0.0
	variable_offset = 0.0
	deaths = 0
	fragments = 0
	total_turns = 0
	ship = {
		"q": 0,
		"r": 0,
		"heading": -PI / 2.0,
		"type_id": "bark",
		"mode": "sail",
		"crew": 2,
	}
	cells = []
	cells_set.clear()
	islands = []
	islands_by_key.clear()
	reachable = []
	landable = []
	started = false
	game_over = false


func start_new_game() -> void:
	reset()
	var map: Dictionary = MapGenerator.generate_map(Balance.R_MAP, Balance.R, Balance.ISLAND_COUNT)
	cells = map["cells"]
	cells_set.clear()
	for c in cells:
		cells_set[c] = true
	islands = map["islands"]
	islands_by_key.clear()
	for isl in islands:
		islands_by_key[Vector2i(int(isl["q"]), int(isl["r"]))] = isl

	if cells.is_empty():
		return

	var start_cell: Vector2i = Vector2i(0, 4)
	for attempt in range(300):
		var c: Vector2i = cells[randi() % cells.size()]
		if HexGrid.is_storm(c.x, c.y):
			continue
		if HexGrid.is_tower(c.x, c.y):
			continue
		if HexGrid.is_edge(c.x, c.y, Balance.R - Balance.R_MARGIN):
			continue
		if not island_at(c.x, c.y).is_empty():
			continue
		start_cell = c
		break

	var starter: Dictionary = Balance.ship_by_id("bark")
	var crew_min: int = int(starter["sailReq"])
	var crew_max: int = int(starter["crewMax"])
	var crew: int = crew_min + randi() % (crew_max - crew_min + 1)

	ship = {
		"q": start_cell.x,
		"r": start_cell.y,
		"heading": -PI / 2.0,
		"type_id": "bark",
		"mode": "sail",
		"crew": crew,
	}
	started = true
	game_over = false


func current_ship() -> Dictionary:
	return Balance.ship_by_id(ship["type_id"])


func is_ship_valid() -> bool:
	return not current_ship().is_empty()


func has_all_fragments() -> bool:
	return fragments >= Balance.FRAGMENTS_NEEDED


func island_at(q: int, r: int) -> Dictionary:
	return islands_by_key.get(Vector2i(q, r), {})
