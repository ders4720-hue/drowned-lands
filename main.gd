extends Control


var board: HexBoard
var font_title: Font
var font_ui: Font
var font_ui_bold: Font
var menu_screen: Control
var controls_screen: Control
var menu_buttons: Array[Button] = []
var menu_continue_btn: Button
var menu_new_btn: Button
var menu_controls_btn: Button
var menu_exit_btn: Button
var menu_focus_index: int = 0
var controls_back_btn: Button
var modal_primary_btn: Button = null
var hud_panel: PanelContainer
var hud_year_label: Label
var hud_turn_label: Label
var hud_pips: HBoxContainer
var hud_ship_label: Label
var hud_crew_label: Label
var hud_crew_bar: Control
var hud_crew_bar_bg: Panel
var hud_crew_bar_fill: Panel
var hud_crew_bar_ticks: Array = []
var hud_btns_panel: PanelContainer
var hud_sail_btn: Button
var hud_row_btn: Button
var hud_wait_btn: Button
var hud_center_btn: Button
var hud_overlay_btn: Button
var _pip_style_filled: StyleBoxFlat
var _pip_style_empty: StyleBoxFlat

const SIZE_TITLE := 16
const SIZE_BODY := 14
const SIZE_CAPTION := 12

const VERSION := "0.2.0"

var log_panel: PanelContainer
var log_label: RichTextLabel
var modal_root: Control
var modal_title: Label
var modal_body: RichTextLabel
var modal_extra: RichTextLabel
var modal_buttons: HBoxContainer
var start_screen: Control
var end_screen: Control
var end_bg: MenuBackground
var end_title: Label
var end_cause: Label
var end_stats: RichTextLabel
var _pan_active: bool = false
var _modal_focus_backup: Dictionary = {}


func _ready() -> void:
	_pip_style_filled = _make_pip_style(true)
	_pip_style_empty = _make_pip_style(false)
	_full_rect(self)
	get_viewport().msaa_2d = Viewport.MSAA_4X
	_load_fonts()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_board()
	_build_hud()
	_build_log()
	_build_modal()
	_build_start_screen()
	_build_end_screen()
	_build_menu_screen()
	_build_controls_screen()
	menu_screen.visible = true
	controls_screen.visible = false
	start_screen.visible = false
	end_screen.visible = false
	modal_root.move_to_front()
	_refresh_menu_continue()
	gui_input.connect(_on_gui_input)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT \
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
		or what == NOTIFICATION_WM_MOUSE_EXIT:
		_pan_active = false


func _process(delta: float) -> void:
	if _pan_active and not (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		_pan_active = false
	if menu_screen.visible or controls_screen.visible:
		return
	if modal_root.visible or start_screen.visible or end_screen.visible:
		return
	if board == null:
		return
	var dir: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir.x -= 1.0
	if dir == Vector2.ZERO:
		return
	_apply_pan(dir.normalized() * Balance.PAN_SPEED * delta)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.pressed and not ke.echo:
			if _handle_key(ke.keycode):
				get_viewport().set_input_as_handled()
				return
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _any_overlay_visible() or board == null or not mb.pressed:
				return
			var dir: float = 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			_zoom_at(mb.position, dir * Balance.ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if _any_overlay_visible():
				_pan_active = false
				return
			_pan_active = mb.pressed
		return
	if event is InputEventMouseMotion and _pan_active:
		_apply_pan((event as InputEventMouseMotion).relative)


func _apply_pan(delta: Vector2) -> void:
	if board == null:
		return
	board.camera_offset += delta
	board.camera_offset = board.camera_offset.clamp(
		Vector2(-Balance.PAN_LIMIT, -Balance.PAN_LIMIT),
		Vector2(Balance.PAN_LIMIT, Balance.PAN_LIMIT)
	)


func _zoom_at(screen_pos: Vector2, delta_zoom: float) -> void:
	if board == null:
		return
	var old_zoom: float = board.zoom
	var new_zoom: float = clampf(old_zoom + delta_zoom, Balance.ZOOM_MIN, Balance.ZOOM_MAX)
	if is_equal_approx(new_zoom, old_zoom):
		return
	var c0: Vector2 = Vector2(size.x * 0.5, size.y * 0.5 + Balance.MAP_OFFSET_Y)
	var world: Vector2 = (screen_pos - c0 - board.camera_offset) / old_zoom
	board.zoom = new_zoom
	board.camera_offset = (screen_pos - c0 - world * new_zoom).clamp(
		Vector2(-Balance.PAN_LIMIT, -Balance.PAN_LIMIT),
		Vector2(Balance.PAN_LIMIT, Balance.PAN_LIMIT))


func _load_fonts() -> void:
	var forum := load("res://assets/fonts/Forum-Regular.ttf") as Font
	if forum != null:
		font_title = FontVariation.new()
		font_title.base_font = forum
		font_title.variation_opentype = { "wght": 700 }
	else:
		font_title = null
	var inter := load("res://assets/fonts/Inter-Variable.ttf") as Font
	if inter != null:
		font_ui = FontVariation.new()
		font_ui.base_font = inter
		font_ui.variation_opentype = { "wght": 400 }
		font_ui_bold = FontVariation.new()
		font_ui_bold.base_font = inter
		font_ui_bold.variation_opentype = { "wght": 700 }
	else:
		font_ui = null
		font_ui_bold = null
	_build_theme()


func _build_theme() -> void:
	var th := Theme.new()
	# ─── Type defaults ───
	th.set_font("font", "Label", font_ui)
	th.set_font_size("font_size", "Label", SIZE_BODY)
	th.set_font("font", "Button", font_ui_bold)
	th.set_font_size("font_size", "Button", SIZE_BODY)
	th.set_font("normal_font", "RichTextLabel", font_ui)
	th.set_font_size("normal_font_size", "RichTextLabel", SIZE_BODY)
	th.set_font("bold_font", "RichTextLabel", font_ui_bold)
	th.set_font_size("bold_font_size", "RichTextLabel", SIZE_BODY)
	th.set_font("italics_font", "RichTextLabel", font_ui)
	th.set_font_size("italics_font_size", "RichTextLabel", SIZE_BODY)
	th.set_font("bold_italics_font", "RichTextLabel", font_ui_bold)
	th.set_font_size("bold_italics_font_size", "RichTextLabel", SIZE_BODY)
	# ─── Label variations ───
	th.set_type_variation("HudTitle", "Label")
	th.set_font("font", "HudTitle", font_ui)
	th.set_font_size("font_size", "HudTitle", SIZE_TITLE)
	th.set_type_variation("HudTitleBold", "Label")
	th.set_font("font", "HudTitleBold", font_ui_bold)
	th.set_font_size("font_size", "HudTitleBold", SIZE_TITLE)
	th.set_type_variation("Bold", "Label")
	th.set_font("font", "Bold", font_ui_bold)
	th.set_font_size("font_size", "Bold", SIZE_BODY)
	th.set_type_variation("Caption", "Label")
	th.set_font("font", "Caption", font_ui)
	th.set_font_size("font_size", "Caption", SIZE_CAPTION)
	th.set_type_variation("TitleSmall", "Label")
	th.set_font("font", "TitleSmall", font_title)
	th.set_font_size("font_size", "TitleSmall", 18)
	th.set_type_variation("Title", "Label")
	th.set_font("font", "Title", font_title)
	th.set_font_size("font_size", "Title", 28)
	th.set_type_variation("TitleLarge", "Label")
	th.set_font("font", "TitleLarge", font_title)
	th.set_font_size("font_size", "TitleLarge", 32)
	th.set_type_variation("TitleHelp", "Label")
	th.set_font("font", "TitleHelp", font_title)
	th.set_font_size("font_size", "TitleHelp", 16)
	# ─── Button variation ───
	th.set_type_variation("Secondary", "Button")
	th.set_font("font", "Secondary", font_ui)
	th.set_font_size("font_size", "Secondary", SIZE_BODY)
	# ─── RichTextLabel variation ───
	th.set_type_variation("CaptionRTL", "RichTextLabel")
	th.set_font("normal_font", "CaptionRTL", font_ui)
	th.set_font_size("normal_font_size", "CaptionRTL", SIZE_CAPTION)
	th.set_font("bold_font", "CaptionRTL", font_ui_bold)
	th.set_font_size("bold_font_size", "CaptionRTL", SIZE_CAPTION)
	th.set_font("italics_font", "CaptionRTL", font_ui)
	th.set_font_size("italics_font_size", "CaptionRTL", SIZE_CAPTION)
	th.set_font("bold_italics_font", "CaptionRTL", font_ui_bold)
	th.set_font_size("bold_italics_font_size", "CaptionRTL", SIZE_CAPTION)
	theme = th


func _make_panel_style(bg: Color, border: Color, pad: float = 12.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.75
	sb.content_margin_bottom = pad * 0.75
	sb.shadow_color = Color(Palette.COL_SHADOW.r, Palette.COL_SHADOW.g, Palette.COL_SHADOW.b, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0.0, 2.0)
	return sb


func _full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _build_board() -> void:
	board = HexBoard.new()
	board.name = "Board"
	board.game_state = GameState
	add_child(board)
	_full_rect(board)
	move_child(board, 0)


func _build_hud() -> void:
	hud_panel = PanelContainer.new()
	hud_panel.name = "HUD"
	hud_panel.custom_minimum_size = Vector2(260.0, 0.0)
	add_child(hud_panel)
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud_panel.offset_left = 16.0
	hud_panel.offset_top = 16.0
	hud_panel.offset_right = 280.0
	hud_panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 14))
	hud_panel.resized.connect(_place_hud_btns)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	hud_panel.add_child(v)

	var row1 := HBoxContainer.new()
	v.add_child(row1)
	hud_year_label = Label.new()
	hud_year_label.text = "1 · Ахет"
	hud_year_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_year_label.theme_type_variation = "HudTitle"
	hud_year_label.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	row1.add_child(hud_year_label)
	hud_turn_label = Label.new()
	hud_turn_label.text = "1/4"
	hud_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_turn_label.theme_type_variation = "HudTitleBold"
	hud_turn_label.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	row1.add_child(hud_turn_label)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	v.add_child(row2)
	hud_pips = HBoxContainer.new()
	hud_pips.add_theme_constant_override("separation", 4)
	row2.add_child(hud_pips)
	for i in range(Balance.FRAGMENTS_NEEDED):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(13.0, 13.0)
		pip.add_theme_stylebox_override("panel", _pip_style_empty)
		hud_pips.add_child(pip)
	var frag_label := Label.new()
	frag_label.name = "FragCount"
	frag_label.text = "0/4"
	frag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frag_label.theme_type_variation = "Bold"
	frag_label.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	row2.add_child(frag_label)

	hud_ship_label = Label.new()
	hud_ship_label.text = "Бар"
	hud_ship_label.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	v.add_child(hud_ship_label)

	hud_crew_label = Label.new()
	hud_crew_label.text = "2 / 3"
	hud_crew_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_crew_label.theme_type_variation = "Bold"
	hud_crew_label.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	v.add_child(hud_crew_label)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	v.add_child(bar)
	hud_crew_bar = bar
	hud_crew_bar_bg = Panel.new()
	var bg_sb: StyleBoxFlat = _make_panel_style(Palette.COL_PANEL_DK, Palette.COL_BORDER_GOLD, 0.0)
	bg_sb.shadow_size = 0
	hud_crew_bar_bg.add_theme_stylebox_override("panel", bg_sb)
	bar.add_child(hud_crew_bar_bg)
	_full_rect(hud_crew_bar_bg)
	hud_crew_bar_fill = Panel.new()
	var fill_sb: StyleBoxFlat = _make_panel_style(Palette.COL_GOLD_DK, Palette.COL_GOLD_LT, 0.0)
	fill_sb.set_corner_radius_all(4)
	fill_sb.shadow_size = 0
	hud_crew_bar_fill.add_theme_stylebox_override("panel", fill_sb)
	bar.add_child(hud_crew_bar_fill)
	hud_crew_bar_fill.position = Vector2(2.0, 2.0)
	hud_crew_bar_fill.size = Vector2(0.0, 8.0)
	hud_crew_bar.resized.connect(_refresh_crew_bar)

	hud_btns_panel = PanelContainer.new()
	hud_btns_panel.name = "HUDBtns"
	add_child(hud_btns_panel)
	hud_btns_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud_btns_panel.offset_left = 16.0
	hud_btns_panel.offset_top = 16.0
	hud_btns_panel.offset_right = 280.0
	hud_btns_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	hud_btns_panel.add_child(bv)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_child(hb)

	hud_sail_btn = _make_icon_button(IconGlyph.Kind.SAIL)
	hud_sail_btn.toggle_mode = true
	hud_sail_btn.pressed.connect(_on_sail_pressed)
	hb.add_child(hud_sail_btn)
	hud_row_btn = _make_icon_button(IconGlyph.Kind.OAR)
	hud_row_btn.toggle_mode = true
	hud_row_btn.pressed.connect(_on_row_pressed)
	hb.add_child(hud_row_btn)
	hud_wait_btn = _make_icon_button(IconGlyph.Kind.HOURGLASS)
	hud_wait_btn.pressed.connect(_on_wait_pressed)
	hb.add_child(hud_wait_btn)
	hud_center_btn = _make_icon_button(IconGlyph.Kind.IMAGO_MUNDI)
	hud_center_btn.pressed.connect(_on_center_pressed)
	hb.add_child(hud_center_btn)
	hud_overlay_btn = _make_icon_button(IconGlyph.Kind.GRID)
	hud_overlay_btn.toggle_mode = true
	hud_overlay_btn.pressed.connect(_on_overlay_pressed)
	hb.add_child(hud_overlay_btn)
	hud_sail_btn.tooltip_text = "Парус"
	hud_row_btn.tooltip_text = "Вёсла"
	hud_wait_btn.tooltip_text = "Ждать день (Space)"
	hud_center_btn.tooltip_text = "Центр карты (C)"
	hud_overlay_btn.tooltip_text = "Сетка и ветер"
	call_deferred("_place_hud_btns")


func _build_log() -> void:
	log_panel = PanelContainer.new()
	log_panel.name = "Log"
	add_child(log_panel)
	log_panel.anchor_left = 0.5
	log_panel.anchor_right = 0.5
	log_panel.anchor_top = 1.0
	log_panel.anchor_bottom = 1.0
	log_panel.offset_left = -400.0
	log_panel.offset_top = -84.0
	log_panel.offset_right = 400.0
	log_panel.offset_bottom = -16.0
	log_panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL_DK, Palette.COL_BORDER_GOLD, 12))
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.fit_content = false
	log_label.custom_minimum_size = Vector2(0.0, 56.0)
	log_label.add_theme_color_override("default_color", Palette.COL_TEXT)
	var log_sb := log_label.get_v_scroll_bar()
	log_sb.add_theme_stylebox_override("scroll", _make_panel_style(Palette.COL_PANEL_DK, Palette.COL_PANEL_DK, 2.0))
	log_sb.add_theme_stylebox_override("grabber", _make_panel_style(Palette.COL_GOLD_DK, Palette.COL_GOLD_DK, 0.0))
	log_sb.add_theme_stylebox_override("grabber_highlight", _make_panel_style(Palette.COL_GOLD, Palette.COL_GOLD, 0.0))
	log_sb.add_theme_stylebox_override("grabber_pressed", _make_panel_style(Palette.COL_GOLD_LT, Palette.COL_GOLD_LT, 0.0))
	log_panel.add_child(log_label)


func _build_modal() -> void:
	modal_root = Control.new()
	modal_root.name = "Modal"
	modal_root.visible = false
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_root)
	_full_rect(modal_root)
	var veil := ColorRect.new()
	veil.color = Palette.COL_VEIL
	modal_root.add_child(veil)
	_full_rect(veil)
	var center := CenterContainer.new()
	modal_root.add_child(center)
	_full_rect(center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(480.0, 0.0)
	var sbm := _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 22.0)
	sbm.set_corner_radius_all(4)
	box.add_theme_stylebox_override("panel", sbm)
	center.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	modal_title = Label.new()
	modal_title.theme_type_variation = "TitleSmall"
	modal_title.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	
	v.add_child(modal_title)
	modal_body = RichTextLabel.new()
	modal_body.bbcode_enabled = true
	modal_body.fit_content = true
	modal_body.custom_minimum_size = Vector2(0.0, 40.0)
	modal_body.add_theme_color_override("default_color", Palette.COL_TEXT)
	v.add_child(modal_body)
	modal_extra = RichTextLabel.new()
	modal_extra.bbcode_enabled = true
	modal_extra.fit_content = true
	modal_extra.custom_minimum_size = Vector2(0.0, 40.0)
	modal_extra.theme_type_variation = "CaptionRTL"
	modal_extra.add_theme_color_override("default_color", Palette.COL_TEXT)
	v.add_child(modal_extra)
	modal_buttons = HBoxContainer.new()
	modal_buttons.alignment = BoxContainer.ALIGNMENT_END
	modal_buttons.add_theme_constant_override("separation", 8)
	v.add_child(modal_buttons)
	modal_root.move_to_front()


func _build_start_screen() -> void:
	start_screen = Control.new()
	start_screen.name = "StartScreen"
	start_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(start_screen)
	_full_rect(start_screen)
	var bg := MenuBackground.new()
	start_screen.add_child(bg)
	_full_rect(bg)
	var center := CenterContainer.new()
	start_screen.add_child(center)
	_full_rect(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 40.0))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var title := Label.new()
	title.text = "THE DROWNED LANDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = "TitleLarge"
	title.add_theme_color_override("font_color", Palette.COL_BLUE_LT)
	v.add_child(title)
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.text = (
		"[color=%s]Мир[/color]\n" % Palette.COL_GOLD.to_html(false)
		+ "Мир плоский. Он тонет — медленно, но безвозвратно. В сердце карты — Вавилонская башня, скрытая кольцом вечных бурь.\n\n"
		+ "[color=%s]Цель[/color]\n" % Palette.COL_GOLD.to_html(false)
		+ "Найти четыре обрывка древней карты. Пройти сквозь бурю и подняться по ступеням башни."
	)
	desc.add_theme_color_override("default_color", Palette.COL_TEXT)
	v.add_child(desc)
	var go := Button.new()
	go.text = "ОТЧАЛИТЬ"
	go.custom_minimum_size = Vector2(0.0, 40.0)
	go.pressed.connect(_on_start_pressed)
	_apply_primary_button_style(go)
	v.add_child(go)


func _build_end_screen() -> void:
	end_screen = Control.new()
	end_screen.name = "EndScreen"
	end_screen.visible = false
	end_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(end_screen)
	_full_rect(end_screen)
	end_bg = MenuBackground.new()
	end_screen.add_child(end_bg)
	_full_rect(end_bg)
	var center := CenterContainer.new()
	end_screen.add_child(center)
	_full_rect(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 40.0))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.theme_type_variation = "Title"
	
	v.add_child(end_title)
	end_cause = Label.new()
	end_cause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_cause.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_cause.custom_minimum_size = Vector2(540.0, 0.0)
	end_cause.add_theme_color_override("font_color", Palette.COL_TEXT_MID)
	v.add_child(end_cause)
	end_stats = RichTextLabel.new()
	end_stats.bbcode_enabled = true
	end_stats.fit_content = true
	end_stats.custom_minimum_size = Vector2(360.0, 0.0)
	end_stats.theme_type_variation = "CaptionRTL"
	end_stats.add_theme_color_override("default_color", Palette.COL_TEXT)
	v.add_child(end_stats)
	var nb := Button.new()
	nb.text = "В МЕНЮ"
	nb.custom_minimum_size = Vector2(0.0, 40.0)
	nb.pressed.connect(_on_end_to_menu)
	_apply_primary_button_style(nb)
	v.add_child(nb)
	end_screen.move_to_front()


func _on_start_pressed() -> void:
	GameState.start_new_game()
	Reachability.refresh(GameState)
	log_label.text = ""
	_initial_log()
	_refresh_hud()
	start_screen.visible = false
	_log_add("Отчалили.", "ship")


func _on_sail_pressed() -> void:
	GameState.ship["mode"] = "sail"
	Reachability.refresh(GameState)
	_refresh_hud()


func _on_row_pressed() -> void:
	GameState.ship["mode"] = "row"
	Reachability.refresh(GameState)
	_refresh_hud()


func _on_wait_pressed() -> void:
	var res: Dictionary = Actions.wait_day(GameState)
	_process_result(res)
	Reachability.refresh(GameState)
	_refresh_hud()


func _on_center_pressed() -> void:
	if board == null:
		return
	board.zoom = 1.0
	var sp: Vector2 = HexGrid.hex_to_pixel(
		int(GameState.ship["q"]), int(GameState.ship["r"]), Balance.HEX_SIZE)
	board.camera_offset = (-sp).clamp(
		Vector2(-Balance.PAN_LIMIT, -Balance.PAN_LIMIT),
		Vector2(Balance.PAN_LIMIT, Balance.PAN_LIMIT))


func _on_overlay_pressed() -> void:
	if board != null:
		board.toggle_overlay()
		hud_overlay_btn.button_pressed = board.overlay_visible


func _confirm_new_game() -> void:
	if GameState.started and not GameState.game_over:
		_show_modal({
			"title": "Новая партия",
			"body": "Текущий забег будет потерян. Начать заново?",
			"extra": "",
			"buttons": [
				{"label": "Оставить", "primary": false, "action": "close", "action_arg": ""},
				{"label": "Начать заново", "primary": true, "action": "new_game", "action_arg": ""},
			]
		})
	else:
		_on_new_pressed()


func _on_new_pressed() -> void:
	modal_root.visible = false
	end_screen.visible = false
	log_label.text = ""
	start_screen.visible = false
	GameState.start_new_game()
	Reachability.refresh(GameState)
	_initial_log()
	_refresh_hud()


func _on_end_to_menu() -> void:
	modal_root.visible = false
	end_screen.visible = false
	menu_screen.visible = true
	_refresh_menu_continue()


func _on_gui_input(event: InputEvent) -> void:
	if menu_screen.visible or controls_screen.visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _pan_active:
		return
	if not GameState.started or GameState.game_over:
		return
	if modal_root.visible or end_screen.visible:
		return
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5 + Balance.MAP_OFFSET_Y) + board.camera_offset
	var local_pos: Vector2 = (mb.position - center) / board.zoom
	var cell: Vector2i = HexGrid.pixel_to_hex(local_pos.x, local_pos.y, Balance.HEX_SIZE)
	var res: Dictionary = Actions.try_move(GameState, cell.x, cell.y)
	_process_result(res)
	Reachability.refresh(GameState)
	_refresh_hud()


func _process_result(res: Dictionary) -> void:
	var evs: Array = res.get("events", [])
	for ev in evs:
		_log_add(String(ev["text"]), String(ev["cls"]))
	if bool(res.get("island_action", false)):
		var ires: Dictionary = IslandActions.explore_island(GameState, int(res["island_q"]), int(res["island_r"]))
		var ievs: Array = ires.get("events", [])
		for ev in ievs:
			_log_add(String(ev["text"]), String(ev["cls"]))
		var modal: Dictionary = ires.get("modal", {})
		if not modal.is_empty():
			_show_modal(modal)
		if String(ires.get("end", "")) != "":
			res["end"] = String(ires["end"])
			res["end_text"] = String(ires["end_text"])
	var end_kind: String = String(res.get("end", ""))
	if end_kind != "":
		_show_end(end_kind, String(res.get("end_text", "")))


func _show_modal(data: Dictionary) -> void:
	modal_title.text = String(data["title"])
	modal_body.text = String(data["body"])
	var extra: String = String(data.get("extra", ""))
	modal_extra.text = extra
	modal_extra.visible = extra != ""
	for c in modal_buttons.get_children():
		modal_buttons.remove_child(c)
		c.queue_free()
	var buttons: Array = data.get("buttons", [])
	var primary: Button = null
	for b in buttons:
		var btn := Button.new()
		btn.text = String(b["label"])
		if bool(b.get("primary", false)):
			_apply_primary_button_style(btn)
			primary = btn
		else:
			_apply_secondary_button_style(btn)
		var action: String = String(b.get("action", "close"))
		var arg: String = String(b.get("action_arg", ""))
		btn.pressed.connect(_on_modal_button.bind(action, arg))
		modal_buttons.add_child(btn)
	modal_primary_btn = primary
	if primary != null:
		call_deferred("_focus_modal_primary")
	for btn in [hud_sail_btn, hud_row_btn, hud_wait_btn, hud_center_btn, hud_overlay_btn]:
		if btn != null:
			_modal_focus_backup[btn.name] = btn.focus_mode
			btn.focus_mode = Control.FOCUS_NONE
	modal_root.visible = true


func _on_modal_button(action: String, arg: String) -> void:
	modal_root.visible = false
	_restore_focus_after_modal()
	if action == "new_game":
		_on_new_pressed()
	if action == "swap_ship":
		var sres: Dictionary = IslandActions.swap_ship(GameState, arg)
		var evs: Array = sres.get("events", [])
		for ev in evs:
			_log_add(String(ev["text"]), String(ev["cls"]))
		Reachability.refresh(GameState)
		_refresh_hud()


func _restore_focus_after_modal() -> void:
	for btn in [hud_sail_btn, hud_row_btn, hud_wait_btn, hud_center_btn, hud_overlay_btn]:
		if btn != null and _modal_focus_backup.has(btn.name):
			btn.focus_mode = _modal_focus_backup[btn.name]
	_modal_focus_backup.clear()


func _show_end(kind: String, text: String) -> void:
	_apply_end_visuals(kind)
	end_cause.text = text
	var sh: Dictionary = GameState.current_ship()
	var sh_name: String = "—"
	if not sh.is_empty():
		sh_name = String(sh["name"])
	var stats: String = (
		"[color=%s]Корабль[/color] [color=%s]%s[/color]\n" % [Palette.COL_TEXT_MID.to_html(false), Palette.COL_GOLD.to_html(false), sh_name]
		+ "[color=%s]Прожито[/color] [color=%s]%d лет · %d дней пути[/color]\n" % [Palette.COL_TEXT_MID.to_html(false), Palette.COL_GOLD.to_html(false), GameState.year, GameState.total_turns]
		+ "[color=%s]Обрывков карты[/color] [color=%s]%d / %d[/color]\n" % [Palette.COL_TEXT_MID.to_html(false), Palette.COL_GOLD.to_html(false), GameState.fragments, Balance.FRAGMENTS_NEEDED]
		+ "[color=%s]Потери команды[/color] [color=%s]%d[/color]\n" % [Palette.COL_TEXT_MID.to_html(false), Palette.COL_GOLD.to_html(false), GameState.deaths]
		+ "[color=%s]Уровень воды[/color] [color=%s]%.1f локтя[/color]" % [Palette.COL_TEXT_MID.to_html(false), Palette.COL_GOLD.to_html(false), GameState.water_level]
	)
	end_stats.text = stats
	end_screen.visible = true


func _apply_end_visuals(kind: String) -> void:
	match kind:
		"victory":
			end_title.text = "ВАВИЛОНСКАЯ БАШНЯ"
			end_title.modulate = Palette.COL_GOLD
			end_bg.base_color = Palette.COL_LAPIS
			end_bg.wave_color = Color(Palette.COL_LAPIS_LT.r, Palette.COL_LAPIS_LT.g, Palette.COL_LAPIS_LT.b, 0.08)
			end_bg.stars_enabled = true
			end_bg.pattern = "stars"
		"edge":
			end_title.text = "КРАЙ МИРА"
			end_title.modulate = Palette.COL_BLUE_LT
			end_bg.base_color = Palette.COL_BLUE_DK
			end_bg.wave_color = Color(Palette.COL_BLUE_LT.r, Palette.COL_BLUE_LT.g, Palette.COL_BLUE_LT.b, 0.06)
			end_bg.stars_enabled = false
			end_bg.pattern = "horizon"
		"storm":
			end_title.text = "БУРЯ ПОГЛОТИЛА"
			end_title.modulate = Palette.COL_STORM_LT
			end_bg.base_color = Palette.COL_STORM_DK
			end_bg.wave_color = Color(Palette.COL_STORM_LT.r, Palette.COL_STORM_LT.g, Palette.COL_STORM_LT.b, 0.08)
			end_bg.stars_enabled = false
			end_bg.pattern = "vortex"
		"tower":
			end_title.text = "БАШНЯ НЕ ПУСТИЛА"
			end_title.modulate = Palette.COL_STORM_LT
			end_bg.base_color = Palette.COL_NIGHT
			end_bg.wave_color = Color(Palette.COL_GOLD_LT.r, Palette.COL_GOLD_LT.g, Palette.COL_GOLD_LT.b, 0.08)
			end_bg.stars_enabled = false
			end_bg.pattern = "halo"
		"crew":
			end_title.text = "КОМАНДА ПОГИБЛА"
			end_title.modulate = Palette.COL_OCHRE_LT
			end_bg.base_color = Palette.COL_OCHRE_DK
			end_bg.wave_color = Color(Palette.COL_OCHRE_LT.r, Palette.COL_OCHRE_LT.g, Palette.COL_OCHRE_LT.b, 0.06)
			end_bg.stars_enabled = false
			end_bg.pattern = "meteors"
		_:
			end_title.text = "КОРАБЛЬ ПОГИБ"
			end_title.modulate = Palette.COL_OCHRE_LT
			end_bg.base_color = Palette.COL_OCHRE_DK
			end_bg.wave_color = Color(Palette.COL_OCHRE_LT.r, Palette.COL_OCHRE_LT.g, Palette.COL_OCHRE_LT.b, 0.06)
			end_bg.stars_enabled = false
			end_bg.pattern = "clouds"


func _initial_log() -> void:
	var arr: Array = Flavor.START_FLAVOR as Array
	var fl: Dictionary = Flavor.pick(arr)
	var crew: int = int(GameState.ship["crew"])
	var word: String = "матрос" if crew == 1 else "матроса"
	_log_add("%s %d %s на борту." % [String(fl["ship"]), crew, word], "ship")
	_log_add(String(fl["season"]), "season")
	_log_add("Найди 4 обрывка карты — тогда буря пропустит к башне.", "fragment")


func _refresh_crew_bar() -> void:
	if hud_crew_bar == null or hud_crew_bar_fill == null:
		return
	var sh: Dictionary = GameState.current_ship()
	if sh.is_empty():
		return
	var crew_max: int = int(sh["crewMax"])
	var crew: int = int(GameState.ship["crew"])
	var bar_w: float = hud_crew_bar.size.x
	var px: float = maxf(0.0, bar_w - 4.0) * float(crew) / float(maxi(1, crew_max))
	hud_crew_bar_fill.size = Vector2(px, maxf(0.0, hud_crew_bar.size.y - 4.0))
	var fill_box: StyleBoxFlat = hud_crew_bar_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if fill_box != null:
		var full: bool = px >= bar_w - 4.5
		fill_box.corner_radius_top_right = 4 if full else 0
		fill_box.corner_radius_bottom_right = 4 if full else 0
		hud_crew_bar_fill.queue_redraw()
	var sail_req: int = int(sh["sailReq"])
	var row_req: int = int(sh["req"])
	for old_tick in hud_crew_bar_ticks:
		if is_instance_valid(old_tick):
			hud_crew_bar.remove_child(old_tick)
			old_tick.queue_free()
	hud_crew_bar_ticks.clear()
	var bar_h: float = hud_crew_bar.size.y
	var pad: float = 2.0
	var span: float = maxf(0.0, bar_w - 4.0)
	for i in range(1, crew_max):
		var tick := ColorRect.new()
		if i == sail_req:
			tick.color = Palette.COL_GOLD
		elif i == row_req:
			tick.color = Palette.COL_LAPIS_LT
		else:
			tick.color = Color(Palette.COL_TEXT_MID.r, Palette.COL_TEXT_MID.g, Palette.COL_TEXT_MID.b, 0.28)
		tick.size = Vector2(1.0, 5.0)
		hud_crew_bar.add_child(tick)
		hud_crew_bar_ticks.append(tick)
		var tx: float = pad + span * float(i) / float(crew_max) - tick.size.x * 0.5
		var ty: float = bar_h - tick.size.y - 1.0
		tick.position = Vector2(tx, ty)



func _make_pip_style(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if filled:
		sb.bg_color = Palette.COL_GOLD_DK
		sb.border_color = Palette.COL_GOLD_LT
	else:
		sb.bg_color = Palette.COL_PANEL_DK
		sb.border_color = Palette.COL_GOLD_DK
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 1
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 4
	return sb


func _make_icon_button(glyph_kind: IconGlyph.Kind) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(42.0, 42.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.COL_GOLD
	sb.border_color = Palette.COL_GOLD_DK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(21)
	sb.content_margin_left = 0.0
	sb.content_margin_right = 0.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.border_color = Palette.COL_GOLD_LT
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Palette.COL_GOLD_DK
	sb_pressed.border_color = Palette.COL_GOLD
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	var sb_disabled := sb.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = Palette.COL_PANEL_DK
	sb_disabled.border_color = Palette.COL_TEXT_DIM
	sb_disabled.set_border_width_all(1)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.border_color = Palette.COL_TEXT
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", sb_focus)
	var glyph := IconGlyph.new()
	glyph.set_kind(glyph_kind)
	glyph.set_icon_color(Palette.COL_NIGHT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(glyph)
	glyph.anchor_left = 0.0
	glyph.anchor_top = 0.0
	glyph.anchor_right = 1.0
	glyph.anchor_bottom = 1.0
	glyph.offset_left = 8.0
	glyph.offset_top = 8.0
	glyph.offset_right = -8.0
	glyph.offset_bottom = -8.0
	return btn


func _place_hud_btns() -> void:
	if hud_panel == null or hud_btns_panel == null:
		return
	var bottom: float = hud_panel.offset_top + hud_panel.size.y + 8.0
	hud_btns_panel.offset_top = bottom
func _refresh_hud() -> void:
	var s: Dictionary = Balance.SEASONS[GameState.season_index]
	hud_year_label.text = "%d · %s" % [GameState.year, String(s["name"])]
	hud_turn_label.text = "%d/%d" % [GameState.season_turn + 1, int(s["turns"])]
	var sh: Dictionary = GameState.current_ship()
	var ship_name: String = "—"
	var crew_max: int = 1
	if not sh.is_empty():
		ship_name = String(sh["name"])
		crew_max = int(sh["crewMax"])
	hud_ship_label.text = ship_name
	var crew: int = int(GameState.ship["crew"])
	hud_crew_label.text = "%d / %d" % [crew, crew_max]
	var pips: Array = hud_pips.get_children()
	for i in range(pips.size()):
		var pip: Panel = pips[i] as Panel
		if pip != null:
			pip.add_theme_stylebox_override("panel", _pip_style_filled if i < GameState.fragments else _pip_style_empty)
	var frag_label: Label = hud_panel.find_child("FragCount", true, false) as Label
	if frag_label != null:
		frag_label.text = "%d/%d" % [GameState.fragments, Balance.FRAGMENTS_NEEDED]
	var mode: String = String(GameState.ship["mode"])
	hud_sail_btn.button_pressed = mode == "sail"
	hud_row_btn.button_pressed = mode == "row"
	hud_overlay_btn.button_pressed = board != null and board.overlay_visible
	_refresh_crew_bar()


func _log_add(text: String, cls: String) -> void:
	var col: Color = Palette.COL_TEXT_MID
	match cls:
		"season":
			col = Palette.COL_BLUE_LT
		"death":
			col = Palette.COL_OCHRE_LT
		"fragment":
			col = Palette.COL_LAPIS_LT
		"flavor":
			col = Palette.COL_TEXT_MID
		"ship":
			col = Palette.COL_GOLD_LT
		"crew":
			col = Palette.COL_MALACHITE_LT
		"storm":
			col = Palette.COL_STORM_LT
		_:
			pass
	log_label.append_text("[color=%s]%s[/color]\n" % [col.to_html(true), text])
	log_label.scroll_to_line(log_label.get_line_count())


func _apply_primary_button_style(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.COL_GOLD
	sb.border_color = Palette.COL_GOLD_DK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Palette.COL_GOLD_DK
	sb_hover.border_color = Palette.COL_GOLD_LT
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Palette.COL_GOLD_DK
	sb_pressed.border_color = Palette.COL_GOLD
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	var sb_disabled := sb.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = Palette.COL_PANEL_DK
	sb_disabled.border_color = Palette.COL_TEXT_DIM
	sb_disabled.set_border_width_all(1)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	var sb_focus: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	sb_focus.border_color = Palette.COL_TEXT
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_color_override("font_color", Palette.COL_NIGHT)
	btn.add_theme_color_override("font_hover_color", Palette.COL_NIGHT)
	btn.add_theme_color_override("font_pressed_color", Palette.COL_NIGHT)
	btn.add_theme_color_override("font_focus_color", Palette.COL_NIGHT)
	btn.add_theme_color_override("font_disabled_color", Palette.COL_TEXT_DIM)


func _apply_secondary_button_style(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.COL_PANEL_DK
	sb.border_color = Palette.COL_BORDER_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Palette.COL_PANEL
	sb_hover.border_color = Palette.COL_GOLD_LT
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Palette.COL_PANEL_DK
	sb_pressed.border_color = Palette.COL_GOLD
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	var sb_disabled := sb.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = Palette.COL_PANEL_DK
	sb_disabled.border_color = Palette.COL_TEXT_DIM
	sb_disabled.set_border_width_all(1)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	var sb_focus: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	sb_focus.border_color = Palette.COL_TEXT
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_color_override("font_color", Palette.COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Palette.COL_TEXT)
	btn.add_theme_color_override("font_pressed_color", Palette.COL_TEXT)
	btn.add_theme_color_override("font_focus_color", Palette.COL_TEXT)
	btn.add_theme_color_override("font_disabled_color", Palette.COL_TEXT_DIM)
	btn.theme_type_variation = "Secondary"

func _build_menu_screen() -> void:
	menu_screen = Control.new()
	menu_screen.name = "MenuScreen"
	menu_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_screen)
	_full_rect(menu_screen)

	var bg := MenuBackground.new()
	menu_screen.add_child(bg)
	_full_rect(bg)

	var center := CenterContainer.new()
	menu_screen.add_child(center)
	_full_rect(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 36.0))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "THE DROWNED LANDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.COL_BLUE_LT)
	title.theme_type_variation = "TitleLarge"
	v.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 20.0)
	v.add_child(spacer)

	menu_buttons.clear()
	menu_continue_btn = Button.new()
	menu_continue_btn.text = "ПРОДОЛЖИТЬ"
	menu_continue_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_apply_primary_button_style(menu_continue_btn)
	menu_continue_btn.pressed.connect(_on_menu_continue)
	v.add_child(menu_continue_btn)
	var labels: Array = ["НОВАЯ ИГРА", "УПРАВЛЕНИЕ", "ВЫХОД"]
	for i in range(labels.size()):
		var btn := Button.new()
		btn.text = String(labels[i])
		btn.custom_minimum_size = Vector2(0.0, 40.0)
		_apply_secondary_button_style(btn)
		v.add_child(btn)
		menu_buttons.append(btn)
		if i == 0:
			menu_new_btn = btn
		elif i == 1:
			menu_controls_btn = btn
		elif i == 2:
			menu_exit_btn = btn
	menu_buttons.insert(0, menu_continue_btn)

	menu_new_btn.pressed.connect(_on_menu_new_game)
	menu_controls_btn.pressed.connect(_on_menu_controls)
	menu_exit_btn.pressed.connect(_on_menu_exit)

	var sig := Label.new()
	sig.text = "cyberprimitives"
	sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sig.add_theme_color_override("font_color", Palette.COL_TEXT_DIM)
	sig.theme_type_variation = "Caption"
	menu_screen.add_child(sig)
	sig.anchor_left = 0.0
	sig.anchor_right = 1.0
	sig.anchor_top = 1.0
	sig.anchor_bottom = 1.0
	sig.offset_left = 0.0
	sig.offset_right = 0.0
	sig.offset_top = -32.0
	sig.offset_bottom = -12.0

	var ver := Label.new()
	ver.text = "v" + VERSION
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_color_override("font_color", Palette.COL_TEXT_DIM)
	ver.theme_type_variation = "Caption"
	menu_screen.add_child(ver)
	ver.anchor_left = 0.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = 0.0
	ver.offset_right = 0.0
	ver.offset_top = -56.0
	ver.offset_bottom = -36.0
	menu_screen.move_to_front()


func _build_controls_screen() -> void:
	controls_screen = Control.new()
	controls_screen.name = "ControlsScreen"
	controls_screen.visible = false
	controls_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(controls_screen)
	_full_rect(controls_screen)

	var bg := MenuBackground.new()
	controls_screen.add_child(bg)
	_full_rect(bg)

	var center := CenterContainer.new()
	controls_screen.add_child(center)
	_full_rect(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Palette.COL_PANEL, Palette.COL_BORDER_GOLD, 22.0))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.text = "УПРАВЛЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.COL_BLUE_LT)
	title.theme_type_variation = "Title"
	v.add_child(title)

	var grid_v := VBoxContainer.new()
	grid_v.add_theme_constant_override("separation", 12)
	grid_v.custom_minimum_size = Vector2(0.0, 180.0)
	v.add_child(grid_v)

	_build_help_section(grid_v, "Карта", [
		["Пробел", "ждать день"],
		["1", "парус"],
		["2", "вёсла"],
		["C", "центр карты"],
		["G", "сетка и ветер"],
		["Колесо / + −", "приблизить · отдалить"],
		["N", "новая партия"],
	])

	controls_back_btn = Button.new()
	controls_back_btn.text = "Назад"
	controls_back_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_apply_primary_button_style(controls_back_btn)
	controls_back_btn.pressed.connect(_on_controls_back)
	v.add_child(controls_back_btn)

	controls_screen.move_to_front()


func _on_menu_new_game() -> void:
	menu_screen.visible = false
	controls_screen.visible = false
	start_screen.visible = true


func _on_menu_controls() -> void:
	menu_screen.visible = false
	controls_screen.visible = true
	call_deferred("_focus_controls_back")


func _on_menu_exit() -> void:
	get_tree().quit()


func _on_menu_continue() -> void:
	menu_screen.visible = false


func _on_controls_back() -> void:
	controls_screen.visible = false
	menu_screen.visible = true
	_refresh_menu_continue()


func _focus_controls_back() -> void:
	if controls_back_btn != null:
		controls_back_btn.grab_focus()



func _focus_modal_primary() -> void:
	if modal_primary_btn != null and modal_root.visible:
		modal_primary_btn.grab_focus()



func _build_help_section(parent: VBoxContainer, title: String, rows: Array) -> void:
	var head := Label.new()
	head.text = title
	head.add_theme_color_override("font_color", Palette.COL_BLUE_LT)
	head.theme_type_variation = "TitleHelp"
	parent.add_child(head)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	for row in rows:
		var k := Label.new()
		k.text = String(row[0])
		k.custom_minimum_size = Vector2(160.0, 0.0)
		k.add_theme_color_override("font_color", Palette.COL_GOLD)
		k.theme_type_variation = "Bold"
		grid.add_child(k)

		var a := Label.new()
		a.text = String(row[1])
		a.add_theme_color_override("font_color", Palette.COL_TEXT)
		grid.add_child(a)


func _refresh_menu_continue() -> void:
	var active: bool = GameState.started and not GameState.game_over
	menu_continue_btn.visible = active
	if active:
		_apply_primary_button_style(menu_continue_btn)
		_apply_secondary_button_style(menu_new_btn)
	else:
		_apply_primary_button_style(menu_new_btn)
	menu_focus_index = 0
	_update_menu_focus()


func _update_menu_focus() -> void:
	if menu_buttons.is_empty():
		return
	menu_focus_index = clampi(menu_focus_index, 0, menu_buttons.size() - 1)
	for i in range(menu_buttons.size()):
		var idx: int = (menu_focus_index + i) % menu_buttons.size()
		var btn: Button = menu_buttons[idx]
		if btn != null and btn.visible:
			menu_focus_index = idx
			btn.grab_focus()
			return

func _any_overlay_visible() -> bool:
	return (menu_screen.visible or controls_screen.visible
		or modal_root.visible or start_screen.visible or end_screen.visible)


func _menu_move(dir: int) -> void:
	if menu_buttons.is_empty():
		return
	for i in range(menu_buttons.size()):
		menu_focus_index = (menu_focus_index + dir + menu_buttons.size()) % menu_buttons.size()
		var btn: Button = menu_buttons[menu_focus_index]
		if btn != null and btn.visible:
			btn.grab_focus()
			return



func _modal_move(dir: int) -> void:
	var n: int = modal_buttons.get_child_count()
	if n == 0:
		return
	var cur: int = -1
	for i in range(n):
		var b: Button = modal_buttons.get_child(i) as Button
		if b != null and b.has_focus():
			cur = i
			break
	if cur < 0:
		cur = 0
	var next: int = (cur + dir + n) % n
	var nb: Button = modal_buttons.get_child(next) as Button
	if nb != null:
		nb.grab_focus()


func _handle_key(keycode: int) -> bool:
	if keycode == KEY_ESCAPE:
		return _handle_escape()
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		return _handle_enter()
	if modal_root.visible:
		if keycode == KEY_LEFT or keycode == KEY_A:
			_modal_move(-1)
			return true
		if keycode == KEY_RIGHT or keycode == KEY_D:
			_modal_move(1)
			return true
	if menu_screen.visible or controls_screen.visible:
		if keycode == KEY_UP or keycode == KEY_W:
			_menu_move(-1)
			return true
		if keycode == KEY_DOWN or keycode == KEY_S:
			_menu_move(1)
			return true
	if _any_overlay_visible():
		return false
	if not GameState.started or GameState.game_over:
		return false
	match keycode:
		KEY_SPACE:
			_on_wait_pressed()
			return true
		KEY_1:
			_on_sail_pressed()
			return true
		KEY_2:
			_on_row_pressed()
			return true
		KEY_C:
			_on_center_pressed()
			return true
		KEY_N:
			_confirm_new_game()
			return true
		KEY_G:
			_on_overlay_pressed()
			return true
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_zoom_at(get_viewport().get_mouse_position(), Balance.ZOOM_STEP)
			return true
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom_at(get_viewport().get_mouse_position(), -Balance.ZOOM_STEP)
			return true
	return false


func _handle_escape() -> bool:
	if modal_root.visible:
		modal_root.visible = false
		_restore_focus_after_modal()
		return true
	if controls_screen.visible:
		_on_controls_back()
		return true
	if menu_screen.visible:
		if GameState.started and not GameState.game_over:
			menu_screen.visible = false
		return true
	if start_screen.visible:
		start_screen.visible = false
		menu_screen.visible = true
		_refresh_menu_continue()
		return true
	if end_screen.visible:
		end_screen.visible = false
		menu_screen.visible = true
		_refresh_menu_continue()
		return true
	if GameState.started and not GameState.game_over:
		menu_screen.visible = true
		_refresh_menu_continue()
		return true
	return false


func _handle_enter() -> bool:
	if modal_root.visible:
		var focused: Button = null
		for c in modal_buttons.get_children():
			var b: Button = c as Button
			if b != null and b.has_focus():
				focused = b
				break
		if focused != null:
			focused.pressed.emit()
		elif modal_primary_btn != null:
			modal_primary_btn.pressed.emit()
		return true
	if controls_screen.visible:
		_on_controls_back()
		return true
	if menu_screen.visible:
		if menu_focus_index >= 0 and menu_focus_index < menu_buttons.size():
			var mb: Button = menu_buttons[menu_focus_index]
			if mb != null and mb.visible:
				mb.pressed.emit()
		return true
	if start_screen.visible:
		_on_start_pressed()
		return true
	if end_screen.visible:
		_on_end_to_menu()
		return true
	return false
