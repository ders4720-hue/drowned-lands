class_name MenuBackground
extends Control

## Процедурный анимированный фон для экранов, закрывающих карту
## (меню, управление, старт, финал). Рисует то же, что и board._draw_sea_bg.

var anim_time_ms: float = 0.0
var base_color: Color = Palette.COL_BLUE
var wave_color: Color = Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.10)
var stars_enabled: bool = false
var star_count: int = 90
var pattern: String = "waves"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	anim_time_ms += delta * 1000.0
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 1.0 or h < 1.0:
		return
	draw_rect(Rect2(0.0, 0.0, w, h), base_color)
	match pattern:
		"stars":
			_draw_stars(w, h)
		"horizon":
			_draw_horizon(w, h)
		"vortex":
			_draw_vortex(w, h)
		"halo":
			_draw_halo(w, h)
		"meteors":
			_draw_meteors(w, h)
		"clouds":
			_draw_clouds(w, h)
		_:
			if stars_enabled:
				_draw_stars(w, h)
			_draw_waves(w, h)


func _draw_waves(w: float, h: float) -> void:
	var step: float = 44.0
	var rows: int = int(ceil(h / step)) + 2
	for i in range(rows):
		var y_base: float = float(i) * step
		var pts: PackedVector2Array = PackedVector2Array()
		var x: float = -12.0
		while x <= w + 12.0:
			var phase: float = x * 0.008 + float(i) * 0.9 + anim_time_ms * 0.0006
			var y: float = y_base + sin(phase) * 4.0 + cos(phase * 1.7) * 1.5
			pts.append(Vector2(x, y))
			x += 12.0
		draw_polyline(pts, wave_color, 1.0)


func _draw_horizon(w: float, h: float) -> void:
	var hz: float = h * 0.62
	for i in range(60):
		var t: float = float(i) / 60.0
		var y: float = hz - float(60 - i) * 1.2
		var a: float = 0.10 * (1.0 - t) * (1.0 - t)
		draw_rect(Rect2(0.0, y, w, 1.4), Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, a), true)
	draw_line(Vector2(0.0, hz), Vector2(w, hz), Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.22), 1.0, true)


func _draw_vortex(w: float, h: float) -> void:
	var c: Vector2 = Vector2(w * 0.5, h * 0.5)
	var max_r: float = maxf(w, h) * 0.7
	for k in range(8):
		var pts: PackedVector2Array = PackedVector2Array()
		var rot: float = anim_time_ms * 0.0004 + float(k) * TAU / 8.0
		for j in range(46):
			var t: float = float(j) / 45.0
			var r: float = max_r * t
			var a: float = rot + t * PI * 3.5
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		var alpha: float = 0.10 - float(k) * 0.008
		draw_polyline(pts, Color(Palette.COL_STORM_LT.r, Palette.COL_STORM_LT.g, Palette.COL_STORM_LT.b, alpha), 1.2, true)


func _draw_halo(w: float, h: float) -> void:
	var c: Vector2 = Vector2(w * 0.5, h * 0.5)
	var max_r: float = maxf(w, h) * 0.6
	for k in range(6):
		var phase: float = fmod(anim_time_ms * 0.0003 + float(k) / 6.0, 1.0)
		var r: float = max_r * phase
		var a: float = (1.0 - phase) * 0.22
		draw_arc(c, r, 0.0, TAU, 64, Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, a), 1.4, true)


func _draw_meteors(w: float, h: float) -> void:
	for i in range(24):
		var h1: float = float(i) * 12.9898
		var sx: float = fmod(abs(h1 * 1.7), 1.0) * w
		var phase: float = fmod(anim_time_ms * 0.0005 + fmod(abs(h1 * 0.91), 1.0), 1.0)
		var y: float = phase * (h + 120.0) - 60.0
		var a: float = 0.35 * (1.0 - abs(phase - 0.5) * 2.0)
		if a <= 0.0:
			continue
		var col: Color = Color(Palette.COL_OCHRE_LT.r, Palette.COL_OCHRE_LT.g, Palette.COL_OCHRE_LT.b, a)
		draw_line(Vector2(sx, y), Vector2(sx - 22.0, y - 60.0), col, 1.4, true)


func _draw_clouds(w: float, h: float) -> void:
	for i in range(7):
		var h1: float = float(i) * 7.31
		var cx: float = fmod(abs(h1 * 1.7), 1.0) * w + sin(anim_time_ms * 0.0002 + h1) * 20.0
		var cy: float = h * (0.2 + 0.6 * fmod(abs(h1 * 0.53), 1.0))
		var rw: float = w * (0.10 + 0.12 * fmod(abs(h1 * 0.31), 1.0))
		var rh: float = rw * 0.35
		for k in range(5):
			var kt: float = float(k) / 4.0
			var rr: float = rh * (0.6 + 0.4 * sin(kt * PI))
			draw_circle(Vector2(cx + (kt - 0.5) * rw, cy), rr, Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.06))


func _draw_stars(w: float, h: float) -> void:
	var cx: float = w * 0.5
	var cy: float = h * 0.5
	var breath: float = 1.0 + 0.035 * sin(anim_time_ms * 0.0008)
	for i in range(star_count):
		var h1: float = float(i) * 12.9898
		var h2: float = float(i) * 78.233
		var bx: float = fmod(abs(h1 * 1.7), 1.0) * w
		var by: float = fmod(abs(h2 * 2.3), 1.0) * h
		var x: float = cx + (bx - cx) * breath
		var y: float = cy + (by - cy) * breath
		var phase: float = fmod(abs(h1 * 0.91), 1.0) * TAU
		var pulse: float = 0.5 + 0.5 * sin(anim_time_ms * 0.0009 + phase)
		var beacon_roll: float = fmod(abs(h1 * 0.61803398875), 1.0)
		if beacon_roll > 0.85:
			var a: float = 0.35 + 0.65 * pulse
			draw_circle(Vector2(x, y), 3.0, Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, a * 0.12))
			draw_circle(Vector2(x, y), 1.6, Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, a))
		else:
			var a: float = 0.45 + 0.55 * pulse
			draw_circle(Vector2(x, y), 1.0, Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, a))
