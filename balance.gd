class_name Balance
extends RefCounted


const R: int = 13
const R_MAP: int = 16
const R_MARGIN: int = 2
const HEX_SIZE: float = 26.0
const STORM_INNER: int = 1
const STORM_OUTER: int = 2
const FRAGMENTS_NEEDED: int = 4
const ISLAND_COUNT: int = 22
const MAP_OFFSET_Y: float = -60.0
const PAN_SPEED: float = 420.0
const PAN_LIMIT: float = 900.0
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 2.5
const ZOOM_STEP: float = 0.2

const SEASONS: Array = [
	{
		"name": "Ахет",
		"label": "Наводнение",
		"wind": "in",
		"strength": 0.85,
		"turns": 4,
		"rise": 2.0,
		"fall": 0.0,
		"hint": "вдох — к центру",
	},
	{
		"name": "Перет",
		"label": "Рост",
		"wind": "variable",
		"strength": 0.55,
		"turns": 4,
		"rise": 0.0,
		"fall": 0.0,
		"hint": "затишье",
	},
	{
		"name": "Шему",
		"label": "Жатва",
		"wind": "out",
		"strength": 0.55,
		"turns": 4,
		"rise": 0.0,
		"fall": -1.0,
		"hint": "выдох — от центра",
	},
	{
		"name": "Эпагомены",
		"label": "5 дней",
		"wind": "calm",
		"strength": 0.0,
		"turns": 1,
		"rise": 0.0,
		"fall": 0.0,
		"hint": "штиль",
	},
]

const SHIPS: Array = [
	{
		"id": "bark",
		"name": "Бар",
		"sail": 2,
		"row": 2,
		"sailReq": 1,
		"req": 2,
		"crewMax": 5,
		"size": 0.92,
		"hull": "bark",
	},
	{
		"id": "depet",
		"name": "Депет",
		"sail": 4,
		"row": 3,
		"sailReq": 5,
		"req": 6,
		"crewMax": 12,
		"size": 1.00,
		"hull": "depet",
	},
	{
		"id": "keftiu",
		"name": "Кефтиу",
		"sail": 6,
		"row": 4,
		"sailReq": 12,
		"req": 14,
		"crewMax": 24,
		"size": 1.06,
		"hull": "keftiu",
	},
	{
		"id": "gishma",
		"name": "Гишма",
		"sail": 7,
		"row": 5,
		"sailReq": 24,
		"req": 28,
		"crewMax": 40,
		"size": 1.14,
		"hull": "gishma",
	},
]
const SHIP_POOL_BASE: Array = ["depet", "keftiu", "gishma"]

const MORTALITY_BASE: float = 0.012
const MORTALITY_BY_SEASON: Dictionary = {
	"Ахет": 1.0,
	"Перет": 1.0,
	"Шему": 1.5,
	"Эпагомены": 0.4,
}


static func ship_by_id(id: String) -> Dictionary:
	for ship in SHIPS:
		if ship["id"] == id:
			return ship
	return {}


static func sail_mp(ship_def: Dictionary, crew: int, strength: float) -> float:
	if ship_def.is_empty():
		return 0.0
	var sail_req: int = maxi(1, int(ship_def["sailReq"]))
	var ratio: float = minf(1.0, float(crew) / float(sail_req))
	return float(ship_def["sail"]) * ratio * strength
