extends Node2D

const GEAR_COUNT: int = 4
const MOTE_COUNT: int = 28

const BORDER_COLOR: Color = Color(0.55, 0.45, 0.75)
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const DIMMED_COLOR: Color = Color(0.32, 0.32, 0.40)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)
const SLIDER_COLOR: Color = Color(0.55, 0.45, 0.75)
const SLIDER_BG_COLOR: Color = Color(0.18, 0.16, 0.28)
const OPT_RECT := Rect2(380.0, 180.0, 520.0, 360.0)
const CONFIRM_RECT := Rect2(440.0, 220.0, 400.0, 280.0)
const SLOT_RECT := Rect2(390.0, 110.0, 500.0, 500.0)
const SLIDER_STEPS: int = 10

# Main menu
const MENU_ITEMS: Array[String] = ["Continue", "New Game", "Load", "Options", "Gimme Dat Spoon"]
const IDX_CONTINUE: int = 0
const IDX_NEW: int = 1
const IDX_LOAD: int = 2
const IDX_OPTIONS: int = 3
const IDX_SPOON: int = 4

# Layout — sized to fit MENU_ITEMS.size() rows between the subtitle and the
# controls hint without overlap.
const MENU_START_Y: float = 350.0
const MENU_ROW_HEIGHT: float = 60.0
const MENU_ITEM_HEIGHT: float = 50.0
const CONTROLS_Y: float = 672.0

var _menu_canvas: CanvasLayer = null
var _menu_labels: Array = []
var _menu_cursor: int = 0
var _can_continue: bool = false
var _can_load: bool = false

# Save-slot picker overlay (New Game / Load)
var _slot_open: bool = false
var _slot_mode: String = "new"   # "new" or "load"
var _slot_cursor: int = 0
var _pending_new_slot: int = -1
var _slot_canvas: CanvasLayer = null
var _slot_title_label: Label = null
var _slot_main_labels: Array = []
var _slot_sub_labels: Array = []
var _slot_back_label: Label = null

# New-game confirmation overlay
var _confirming: bool = false
var _confirm_cursor: int = 1   # default to Cancel — safer
var _confirm_canvas: CanvasLayer = null
var _confirm_labels: Array = []

# Options overlay
var _opt_open: bool = false
var _opt_cursor: int = 0
var _opt_canvas: CanvasLayer = null
var _opt_name_labels: Array = []
var _opt_bar_fills: Array = []
var _opt_pct_labels: Array = []

var _time: float = 0.0
var _gears: Array = []
var _motes: Array = []

func _ready() -> void:
	Audio.play_music("overworld")
	var last_slot: int = SaveManager.get_last_slot()
	_can_continue = last_slot >= 0 and SaveManager.has_save(last_slot)
	_can_load = false
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		if SaveManager.has_save(slot):
			_can_load = true
			break
	_menu_cursor = IDX_CONTINUE if _can_continue else IDX_NEW
	_build_background()
	_build_main_ui()
	_build_slot_overlay()
	_build_confirm_overlay()
	_build_options_overlay()

# ---------------------------------------------------------------------------
# Background (gears + floating motes)
# ---------------------------------------------------------------------------

func _build_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for spec: Dictionary in [
		{"pos": Vector2(150.0, 560.0), "radius": 90.0, "teeth": 10, "speed": 0.18},
		{"pos": Vector2(1130.0, 580.0), "radius": 120.0, "teeth": 12, "speed": -0.13},
		{"pos": Vector2(60.0, 130.0), "radius": 60.0, "teeth": 8, "speed": -0.24},
		{"pos": Vector2(1220.0, 110.0), "radius": 75.0, "teeth": 9, "speed": 0.2},
	]:
		_gears.append({"pos": spec["pos"], "radius": spec["radius"],
			"teeth": spec["teeth"], "speed": spec["speed"], "angle": rng.randf() * TAU})
	for i in MOTE_COUNT:
		_motes.append({"pos": Vector2(rng.randf() * 1280.0, rng.randf() * 720.0),
			"speed": rng.randf_range(8.0, 26.0), "size": rng.randf_range(1.5, 3.5)})

# ---------------------------------------------------------------------------
# Main menu UI
# ---------------------------------------------------------------------------

func _build_main_ui() -> void:
	_menu_canvas = CanvasLayer.new()
	_menu_canvas.layer = 1
	add_child(_menu_canvas)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.position = Vector2(0.0, 150.0)
	title.size = Vector2(1280.0, 110.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	_menu_canvas.add_child(title)

	var sub := Label.new()
	sub.text = "Find Uncle Doug"
	sub.position = Vector2(0.0, 270.0)
	sub.size = Vector2(1280.0, 40.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.65, 0.6, 0.9))
	_menu_canvas.add_child(sub)

	# Menu items — left-aligned in a 360px column centered at x=640
	var col_x: float = 460.0
	var col_w: float = 360.0
	for i in MENU_ITEMS.size():
		var lbl := Label.new()
		lbl.position = Vector2(col_x, MENU_START_Y + float(i) * MENU_ROW_HEIGHT)
		lbl.size = Vector2(col_w, MENU_ITEM_HEIGHT)
		lbl.add_theme_font_size_override("font_size", 28)
		_menu_canvas.add_child(lbl)
		_menu_labels.append(lbl)
	_refresh_menu()

	var controls := Label.new()
	controls.text = "WASD Move  F Attack  V Dash  G Special  Tab Swap  B Bies"
	controls.position = Vector2(0.0, CONTROLS_Y)
	controls.size = Vector2(1280.0, 28.0)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(0.30, 0.30, 0.36))
	_menu_canvas.add_child(controls)

# ---------------------------------------------------------------------------
# Save-slot picker overlay (New Game / Load)
# ---------------------------------------------------------------------------

func _build_slot_overlay() -> void:
	_slot_canvas = CanvasLayer.new()
	_slot_canvas.layer = 4
	_slot_canvas.visible = false
	add_child(_slot_canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.size = Vector2(1280.0, 720.0)
	_slot_canvas.add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.14, 0.97)
	panel.position = SLOT_RECT.position
	panel.size = SLOT_RECT.size
	_slot_canvas.add_child(panel)

	var border_w: float = 2.0
	for r: Rect2 in [
		Rect2(SLOT_RECT.position, Vector2(SLOT_RECT.size.x, border_w)),
		Rect2(SLOT_RECT.position + Vector2(0.0, SLOT_RECT.size.y - border_w), Vector2(SLOT_RECT.size.x, border_w)),
		Rect2(SLOT_RECT.position, Vector2(border_w, SLOT_RECT.size.y)),
		Rect2(SLOT_RECT.position + Vector2(SLOT_RECT.size.x - border_w, 0.0), Vector2(border_w, SLOT_RECT.size.y)),
	]:
		var b := ColorRect.new()
		b.color = BORDER_COLOR
		b.position = r.position
		b.size = r.size
		_slot_canvas.add_child(b)

	_slot_title_label = Label.new()
	_slot_title_label.position = SLOT_RECT.position + Vector2(0.0, 20.0)
	_slot_title_label.size = Vector2(SLOT_RECT.size.x, 40.0)
	_slot_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_title_label.add_theme_font_size_override("font_size", 26)
	_slot_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_slot_canvas.add_child(_slot_title_label)

	for i in SaveManager.SAVE_SLOT_COUNT:
		var row_y: float = 90.0 + float(i) * 100.0
		var main_lbl := Label.new()
		main_lbl.position = SLOT_RECT.position + Vector2(40.0, row_y)
		main_lbl.size = Vector2(SLOT_RECT.size.x - 80.0, 32.0)
		main_lbl.add_theme_font_size_override("font_size", 22)
		_slot_canvas.add_child(main_lbl)
		_slot_main_labels.append(main_lbl)

		var sub_lbl := Label.new()
		sub_lbl.position = SLOT_RECT.position + Vector2(64.0, row_y + 32.0)
		sub_lbl.size = Vector2(SLOT_RECT.size.x - 104.0, 24.0)
		sub_lbl.add_theme_font_size_override("font_size", 14)
		sub_lbl.add_theme_color_override("font_color", HINT_COLOR)
		_slot_canvas.add_child(sub_lbl)
		_slot_sub_labels.append(sub_lbl)

	_slot_back_label = Label.new()
	_slot_back_label.position = SLOT_RECT.position + Vector2(40.0, 90.0 + float(SaveManager.SAVE_SLOT_COUNT) * 100.0)
	_slot_back_label.size = Vector2(SLOT_RECT.size.x - 80.0, 32.0)
	_slot_back_label.add_theme_font_size_override("font_size", 22)
	_slot_canvas.add_child(_slot_back_label)

	var shint := Label.new()
	shint.text = "ESC to cancel"
	shint.position = SLOT_RECT.position + Vector2(0.0, SLOT_RECT.size.y - 30.0)
	shint.size = Vector2(SLOT_RECT.size.x, 22.0)
	shint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shint.add_theme_font_size_override("font_size", 14)
	shint.add_theme_color_override("font_color", HINT_COLOR)
	_slot_canvas.add_child(shint)

# ---------------------------------------------------------------------------
# New-game confirmation overlay
# ---------------------------------------------------------------------------

func _build_confirm_overlay() -> void:
	_confirm_canvas = CanvasLayer.new()
	_confirm_canvas.layer = 3
	_confirm_canvas.visible = false
	add_child(_confirm_canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.size = Vector2(1280.0, 720.0)
	_confirm_canvas.add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.14, 0.97)
	panel.position = CONFIRM_RECT.position
	panel.size = CONFIRM_RECT.size
	_confirm_canvas.add_child(panel)

	var border_w: float = 2.0
	for r: Rect2 in [
		Rect2(CONFIRM_RECT.position, Vector2(CONFIRM_RECT.size.x, border_w)),
		Rect2(CONFIRM_RECT.position + Vector2(0.0, CONFIRM_RECT.size.y - border_w), Vector2(CONFIRM_RECT.size.x, border_w)),
		Rect2(CONFIRM_RECT.position, Vector2(border_w, CONFIRM_RECT.size.y)),
		Rect2(CONFIRM_RECT.position + Vector2(CONFIRM_RECT.size.x - border_w, 0.0), Vector2(border_w, CONFIRM_RECT.size.y)),
	]:
		var b := ColorRect.new()
		b.color = Color(0.85, 0.25, 0.25)
		b.position = r.position
		b.size = r.size
		_confirm_canvas.add_child(b)

	var ttl := Label.new()
	ttl.text = "NEW GAME"
	ttl.position = CONFIRM_RECT.position + Vector2(0.0, 20.0)
	ttl.size = Vector2(CONFIRM_RECT.size.x, 40.0)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_size_override("font_size", 28)
	ttl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	_confirm_canvas.add_child(ttl)

	var warn := Label.new()
	warn.text = "This will erase your\nsaved progress."
	warn.position = CONFIRM_RECT.position + Vector2(40.0, 80.0)
	warn.size = Vector2(CONFIRM_RECT.size.x - 80.0, 80.0)
	warn.add_theme_font_size_override("font_size", 18)
	warn.add_theme_color_override("font_color", NORMAL_COLOR)
	_confirm_canvas.add_child(warn)

	for i in 2:
		var lbl := Label.new()
		lbl.position = CONFIRM_RECT.position + Vector2(44.0, 180.0 + float(i) * 50.0)
		lbl.size = Vector2(CONFIRM_RECT.size.x - 80.0, 40.0)
		lbl.add_theme_font_size_override("font_size", 22)
		_confirm_canvas.add_child(lbl)
		_confirm_labels.append(lbl)

	var chint := Label.new()
	chint.text = "ESC to cancel"
	chint.position = CONFIRM_RECT.position + Vector2(0.0, CONFIRM_RECT.size.y - 30.0)
	chint.size = Vector2(CONFIRM_RECT.size.x, 22.0)
	chint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chint.add_theme_font_size_override("font_size", 14)
	chint.add_theme_color_override("font_color", HINT_COLOR)
	_confirm_canvas.add_child(chint)

# ---------------------------------------------------------------------------
# Options overlay (volume sliders)
# ---------------------------------------------------------------------------

func _build_options_overlay() -> void:
	_opt_canvas = CanvasLayer.new()
	_opt_canvas.layer = 2
	_opt_canvas.visible = false
	add_child(_opt_canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.size = Vector2(1280.0, 720.0)
	_opt_canvas.add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.14, 0.97)
	panel.position = OPT_RECT.position
	panel.size = OPT_RECT.size
	_opt_canvas.add_child(panel)

	var border_w: float = 2.0
	for r: Rect2 in [
		Rect2(OPT_RECT.position, Vector2(OPT_RECT.size.x, border_w)),
		Rect2(OPT_RECT.position + Vector2(0.0, OPT_RECT.size.y - border_w), Vector2(OPT_RECT.size.x, border_w)),
		Rect2(OPT_RECT.position, Vector2(border_w, OPT_RECT.size.y)),
		Rect2(OPT_RECT.position + Vector2(OPT_RECT.size.x - border_w, 0.0), Vector2(border_w, OPT_RECT.size.y)),
	]:
		var b := ColorRect.new()
		b.color = BORDER_COLOR
		b.position = r.position
		b.size = r.size
		_opt_canvas.add_child(b)

	var ottl := Label.new()
	ottl.text = "OPTIONS"
	ottl.position = OPT_RECT.position + Vector2(0.0, 22.0)
	ottl.size = Vector2(OPT_RECT.size.x, 44.0)
	ottl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ottl.add_theme_font_size_override("font_size", 32)
	ottl.add_theme_color_override("font_color", TITLE_COLOR)
	_opt_canvas.add_child(ottl)

	for i in 3:
		var row_y: float = OPT_RECT.position.y + 90.0 + float(i) * 82.0
		var name_lbl := Label.new()
		name_lbl.position = Vector2(OPT_RECT.position.x + 28.0, row_y)
		name_lbl.size = Vector2(OPT_RECT.size.x - 56.0, 28.0)
		name_lbl.add_theme_font_size_override("font_size", 18)
		_opt_canvas.add_child(name_lbl)
		_opt_name_labels.append(name_lbl)

		if i < 2:
			var bar_bg := ColorRect.new()
			bar_bg.position = Vector2(OPT_RECT.position.x + 28.0, row_y + 32.0)
			bar_bg.size = Vector2(340.0, 16.0)
			bar_bg.color = SLIDER_BG_COLOR
			_opt_canvas.add_child(bar_bg)

			var bar_fill := ColorRect.new()
			bar_fill.position = Vector2(OPT_RECT.position.x + 28.0, row_y + 32.0)
			bar_fill.size = Vector2(0.0, 16.0)
			_opt_canvas.add_child(bar_fill)
			_opt_bar_fills.append(bar_fill)

			var pct_lbl := Label.new()
			pct_lbl.position = Vector2(OPT_RECT.position.x + 378.0, row_y + 28.0)
			pct_lbl.size = Vector2(80.0, 26.0)
			pct_lbl.add_theme_font_size_override("font_size", 16)
			_opt_canvas.add_child(pct_lbl)
			_opt_pct_labels.append(pct_lbl)
		else:
			_opt_bar_fills.append(null)
			_opt_pct_labels.append(null)

	var ohint := Label.new()
	ohint.text = "← → Adjust     UP / DN Select"
	ohint.position = OPT_RECT.position + Vector2(0.0, OPT_RECT.size.y - 34.0)
	ohint.size = Vector2(OPT_RECT.size.x, 24.0)
	ohint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ohint.add_theme_font_size_override("font_size", 13)
	ohint.add_theme_color_override("font_color", HINT_COLOR)
	_opt_canvas.add_child(ohint)

# ---------------------------------------------------------------------------
# Process / draw
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	for gear: Dictionary in _gears:
		gear["angle"] += gear["speed"] * delta
	for mote: Dictionary in _motes:
		var pos: Vector2 = mote["pos"]
		pos.y -= mote["speed"] * delta
		if pos.y < -4.0:
			pos.y = 724.0
			pos.x = randf() * 1280.0
		mote["pos"] = pos
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.04, 0.13))
	for gear: Dictionary in _gears:
		_draw_gear(gear["pos"], gear["radius"], gear["teeth"], gear["angle"])
	for mote: Dictionary in _motes:
		draw_circle(mote["pos"], mote["size"], Color(0.5, 0.45, 0.75, 0.35))

func _draw_gear(center: Vector2, radius: float, teeth: int, angle: float) -> void:
	var rim_col := Color(0.18, 0.16, 0.3, 0.55)
	draw_arc(center, radius, 0.0, TAU, 48, rim_col, 6.0, true)
	draw_circle(center, radius * 0.22, rim_col)
	var tooth_len: float = radius * 0.18
	for i in teeth:
		var a: float = angle + TAU * float(i) / float(teeth)
		var dir := Vector2(cos(a), sin(a))
		draw_line(center + dir * radius, center + dir * (radius + tooth_len), rim_col, 7.0, true)
	for i in 6:
		var a2: float = angle * 1.6 + TAU * float(i) / 6.0
		draw_line(center, center + Vector2(cos(a2), sin(a2)) * radius * 0.7, rim_col, 4.0, true)

# ---------------------------------------------------------------------------
# Input routing
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _opt_open:
		_handle_options_input(event)
	elif _confirming:
		_handle_confirm_input(event)
	elif _slot_open:
		_handle_slot_input(event)
	else:
		_handle_menu_input(event)

func _handle_menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_menu_cursor = _prev_enabled(_menu_cursor)
		_refresh_menu()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_menu_cursor = _next_enabled(_menu_cursor)
		_refresh_menu()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		_select_menu()
		get_viewport().set_input_as_handled()

func _handle_confirm_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		_confirm_cursor = 1 - _confirm_cursor
		_refresh_confirm()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		if _confirm_cursor == 0:
			_start_new_game()
		else:
			_close_confirm()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close_confirm()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()

func _handle_slot_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_slot_cursor = _prev_slot_enabled(_slot_cursor)
		_refresh_slot_overlay()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_slot_cursor = _next_slot_enabled(_slot_cursor)
		_refresh_slot_overlay()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		_select_slot()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close_slot_overlay()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()

func _handle_options_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_opt_cursor = (_opt_cursor - 1 + 3) % 3
		_refresh_sliders()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_opt_cursor = (_opt_cursor + 1) % 3
		_refresh_sliders()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") and _opt_cursor < 2:
		_adjust_volume(_opt_cursor, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") and _opt_cursor < 2:
		_adjust_volume(_opt_cursor, +1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		if _opt_cursor == 2:
			_close_options()
			Audio.play("ui_select")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close_options()
		Audio.play("ui_select")
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Menu logic
# ---------------------------------------------------------------------------

func _is_enabled(idx: int) -> bool:
	match idx:
		IDX_CONTINUE:
			return _can_continue
		IDX_LOAD:
			return _can_load
		IDX_SPOON:
			return _can_continue and SaveManager.get_slot_summary(SaveManager.get_last_slot()).get("doug_found", false)
		_:
			return true

func _next_enabled(from: int) -> int:
	var n: int = MENU_ITEMS.size()
	for i in n:
		var candidate: int = (from + 1 + i) % n
		if _is_enabled(candidate):
			return candidate
	return from

func _prev_enabled(from: int) -> int:
	var n: int = MENU_ITEMS.size()
	for i in n:
		var candidate: int = (from - 1 - i + n * 2) % n
		if _is_enabled(candidate):
			return candidate
	return from

func _select_menu() -> void:
	match _menu_cursor:
		IDX_CONTINUE:
			Audio.play("ui_select")
			SaveManager.load_game(SaveManager.get_last_slot())
			TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")
		IDX_NEW:
			_open_slot_select("new")
		IDX_LOAD:
			_open_slot_select("load")
		IDX_OPTIONS:
			_open_options()
		IDX_SPOON:
			Audio.play("ui_select")
			SaveManager.load_game(SaveManager.get_last_slot())
			TransitionManager.change_scene("res://scenes/levels/GimmeDatSpoon.tscn")

func _start_new_game() -> void:
	SaveManager.start_new_game(_pending_new_slot)
	Audio.play("ui_select")
	TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _close_confirm() -> void:
	_confirming = false
	_confirm_canvas.visible = false
	_slot_canvas.visible = true
	_slot_open = true

func _refresh_menu() -> void:
	for i in _menu_labels.size():
		var lbl: Label = _menu_labels[i]
		var enabled: bool = _is_enabled(i)
		var sel: bool = (i == _menu_cursor)
		# The arcade shortcut is obfuscated until Doug is found, mirroring
		# AchievementsOverlay's "???" treatment of locked secret entries.
		var item_text: String = "???" if (i == IDX_SPOON and not enabled) else MENU_ITEMS[i]
		lbl.text = (">  " if sel else "    ") + item_text
		var col: Color = SELECTED_COLOR if sel else (NORMAL_COLOR if enabled else DIMMED_COLOR)
		lbl.add_theme_color_override("font_color", col)

func _refresh_confirm() -> void:
	var texts: Array[String] = ["Yes, start over", "Cancel"]
	for i in 2:
		var lbl: Label = _confirm_labels[i]
		var sel: bool = (i == _confirm_cursor)
		lbl.text = (">  " if sel else "    ") + texts[i]
		var col: Color = (Color(0.95, 0.35, 0.35) if sel else NORMAL_COLOR) if i == 0 else (SELECTED_COLOR if sel else NORMAL_COLOR)
		lbl.add_theme_color_override("font_color", col)

# ---------------------------------------------------------------------------
# Save-slot picker
# ---------------------------------------------------------------------------

func _open_slot_select(mode: String) -> void:
	_slot_mode = mode
	_slot_cursor = 0 if mode == "new" else _next_slot_enabled(-1)
	_slot_open = true
	_slot_canvas.visible = true
	_refresh_slot_overlay()
	Audio.play("ui_select")

func _close_slot_overlay() -> void:
	_slot_open = false
	_slot_canvas.visible = false

func _slot_is_enabled(idx: int) -> bool:
	if idx == SaveManager.SAVE_SLOT_COUNT:
		return true  # Back
	if _slot_mode == "load":
		return SaveManager.has_save(idx + 1)
	return true

func _next_slot_enabled(from: int) -> int:
	var n: int = SaveManager.SAVE_SLOT_COUNT + 1
	for i in n:
		var candidate: int = (from + 1 + i) % n
		if _slot_is_enabled(candidate):
			return candidate
	return from

func _prev_slot_enabled(from: int) -> int:
	var n: int = SaveManager.SAVE_SLOT_COUNT + 1
	for i in n:
		var candidate: int = (from - 1 - i + n * 2) % n
		if _slot_is_enabled(candidate):
			return candidate
	return from

func _select_slot() -> void:
	if _slot_cursor == SaveManager.SAVE_SLOT_COUNT:
		_close_slot_overlay()
		Audio.play("ui_move")
		return
	if not _slot_is_enabled(_slot_cursor):
		return
	var slot: int = _slot_cursor + 1
	if _slot_mode == "new":
		if SaveManager.has_save(slot):
			_pending_new_slot = slot
			_open_confirm()
		else:
			SaveManager.start_new_game(slot)
			Audio.play("ui_select")
			TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")
	else:
		SaveManager.load_game(slot)
		Audio.play("ui_select")
		TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")

func _open_confirm() -> void:
	_confirming = true
	_confirm_cursor = 1
	_slot_canvas.visible = false
	_slot_open = false
	_confirm_canvas.visible = true
	_refresh_confirm()
	Audio.play("ui_select")

func _refresh_slot_overlay() -> void:
	_slot_title_label.text = "NEW GAME — SELECT SLOT" if _slot_mode == "new" else "LOAD GAME — SELECT SLOT"
	for i in SaveManager.SAVE_SLOT_COUNT:
		var slot: int = i + 1
		var summary: Dictionary = SaveManager.get_slot_summary(slot)
		var sel: bool = (i == _slot_cursor)
		var enabled: bool = _slot_is_enabled(i)
		var main_lbl: Label = _slot_main_labels[i]
		var sub_lbl: Label = _slot_sub_labels[i]
		main_lbl.text = (">  " if sel else "    ") + "Slot %d" % slot
		var col: Color = SELECTED_COLOR if sel else (NORMAL_COLOR if enabled else DIMMED_COLOR)
		main_lbl.add_theme_color_override("font_color", col)
		if summary.get("exists", false):
			var loc_count: int = summary.get("completed_count", 0)
			var char_count: int = (summary.get("unlocked_characters", []) as Array).size()
			sub_lbl.text = "    %d/13 locations · %d heroes" % [loc_count, char_count]
		else:
			sub_lbl.text = "    Empty"
		sub_lbl.add_theme_color_override("font_color", HINT_COLOR if enabled else DIMMED_COLOR)

	var back_sel: bool = (_slot_cursor == SaveManager.SAVE_SLOT_COUNT)
	_slot_back_label.text = (">  " if back_sel else "    ") + "Back"
	_slot_back_label.add_theme_color_override("font_color", SELECTED_COLOR if back_sel else NORMAL_COLOR)

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

func _open_options() -> void:
	_opt_open = true
	_opt_cursor = 0
	_opt_canvas.visible = true
	_refresh_sliders()
	Audio.play("ui_select")

func _close_options() -> void:
	_opt_open = false
	_opt_canvas.visible = false

func _adjust_volume(slot: int, delta: int) -> void:
	if slot == 0:
		var s: int = roundi(Audio.sfx_volume * SLIDER_STEPS)
		Audio.set_sfx_volume(float(clampi(s + delta, 0, SLIDER_STEPS)) / float(SLIDER_STEPS))
	else:
		var s: int = roundi(Audio.music_volume * SLIDER_STEPS)
		Audio.set_music_volume(float(clampi(s + delta, 0, SLIDER_STEPS)) / float(SLIDER_STEPS))
	Audio.save_settings()
	Audio.play("ui_move")
	_refresh_sliders()

func _refresh_sliders() -> void:
	var volumes: Array = [Audio.sfx_volume, Audio.music_volume]
	var row_names: Array[String] = ["SFX Volume", "Music Volume", "Back"]
	for i in 3:
		var name_lbl: Label = _opt_name_labels[i]
		var sel: bool = (i == _opt_cursor)
		name_lbl.text = (">  " if sel else "    ") + row_names[i]
		name_lbl.add_theme_color_override("font_color", SELECTED_COLOR if sel else NORMAL_COLOR)
		if i < 2:
			var fill: ColorRect = _opt_bar_fills[i]
			var pct_lbl: Label = _opt_pct_labels[i]
			fill.size.x = volumes[i] * 340.0
			fill.color = SLIDER_COLOR if sel else SLIDER_COLOR.darkened(0.3)
			pct_lbl.text = str(roundi(volumes[i] * 100.0)) + "%"
			pct_lbl.add_theme_color_override("font_color", SELECTED_COLOR if sel else NORMAL_COLOR)
