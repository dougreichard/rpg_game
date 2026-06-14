extends CanvasLayer

# Pause menu — shown/hidden via GameManager.paused/unpaused signals.
# Uses Engine.time_scale=0.0 (not get_tree().paused) so _process still runs;
# input is handled in _unhandled_input with accept_event() to prevent the
# same keypress reaching level scripts (e.g. the clear-overlay ui_accept check).

const OPTIONS_LEVEL: Array[String] = ["Resume", "Inventory", "Quests", "Achievements", "Options", "How to Play", "Quit to Map", "Quit to Title"]
const OPTIONS_OVERWORLD: Array[String] = ["Resume", "Inventory", "Quests", "Achievements", "Options", "How to Play", "Quit to Title"]
const PANEL_RECT := Rect2(440.0, 90.0, 400.0, 540.0)
# Cozy-warm palette (UITheme) replaces the old cool purple/grey scheme.
const BORDER_COLOR: Color = UITheme.GOLD_DIM
const TITLE_COLOR: Color = UITheme.GOLD
const SELECTED_COLOR: Color = UITheme.ACCENT
const NORMAL_COLOR: Color = UITheme.TEXT_DIM
const HINT_COLOR: Color = UITheme.TEXT_DIM
const SLIDER_COLOR: Color = UITheme.GOLD
const SLIDER_BG_COLOR: Color = Color(0.18, 0.14, 0.11)
const PANEL_COLOR: Color = UITheme.PANEL_BG

# Options panel — wider to accommodate sliders
const OPT_RECT := Rect2(380.0, 180.0, 520.0, 360.0)
# Rows: 0=SFX, 1=Music, 2=Back
const OPT_ROW_COUNT: int = 3
const SLIDER_STEPS: int = 10

# Set true (before _ready, e.g. right after instantiating) when this menu is
# placed in the overworld rather than a level — drops "Quit to Map" since
# there's no level to quit out of.
@export var in_overworld: bool = false

const HowToPlayOverlayScript: Script = preload("res://scripts/ui/how_to_play_overlay.gd")

var _options: Array[String] = []
var _option_labels: Array = []
var _cursor: int = 0
var _in_options: bool = false
var _in_achievements: bool = false
var _in_inventory: bool = false
var _in_quest_log: bool = false
var _in_travel: bool = false
var _in_how_to_play: bool = false
var _how_to_play_overlay = null
var _opt_cursor: int = 0

@onready var _achievements_overlay: Node = get_node("../AchievementsOverlay")
@onready var _inventory_overlay: Node = get_node("../InventoryOverlay")
@onready var _quest_log_overlay: Node = get_node("../QuestLogOverlay")
@onready var _travel_overlay: Node = get_node("../TravelOverlay") if in_overworld else null

# Options panel nodes
var _main_panel_nodes: Array = []
var _opt_panel_nodes: Array = []
var _opt_name_labels: Array = []
var _opt_bar_fills: Array = []
var _opt_pct_labels: Array = []

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_options = (OPTIONS_OVERWORLD if in_overworld else OPTIONS_LEVEL).duplicate()
	# Fast travel + the arcade shortcut only make sense once Doug is found
	# (all 13 main locations are then unlocked) and only from the overworld.
	if in_overworld and GameManager.completed_locations.has("grand_marquee"):
		var insert_idx: int = _options.find("Quit to Title")
		_options.insert(insert_idx, "Travel")
		_options.insert(insert_idx + 1, "Gimme Dat Spoon")
	_build_ui()
	_how_to_play_overlay = HowToPlayOverlayScript.new()
	_how_to_play_overlay.layer = 27
	add_child(_how_to_play_overlay)
	_how_to_play_overlay.closed.connect(_on_how_to_play_closed)
	GameManager.paused.connect(_on_paused)
	GameManager.unpaused.connect(_on_unpaused)
	GameManager.register_pause_menu(self)
	_achievements_overlay.closed.connect(_on_achievements_closed)
	_inventory_overlay.closed.connect(_on_inventory_closed)
	_quest_log_overlay.closed.connect(_on_quest_log_closed)
	if _travel_overlay != null:
		_travel_overlay.closed.connect(_on_travel_closed)

func _exit_tree() -> void:
	GameManager.unregister_pause_menu(self)

func _build_ui() -> void:
	_build_main_panel()
	_build_options_panel()

func _build_main_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.size = Vector2(1280.0, 720.0)
	add_child(bg)
	_main_panel_nodes.append(bg)

	var panel := ColorRect.new()
	panel.color = PANEL_COLOR
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	add_child(panel)
	_main_panel_nodes.append(panel)

	var border_w: float = 2.0
	for side_rect: Rect2 in [
		Rect2(PANEL_RECT.position, Vector2(PANEL_RECT.size.x, border_w)),
		Rect2(PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - border_w), Vector2(PANEL_RECT.size.x, border_w)),
		Rect2(PANEL_RECT.position, Vector2(border_w, PANEL_RECT.size.y)),
		Rect2(PANEL_RECT.position + Vector2(PANEL_RECT.size.x - border_w, 0.0), Vector2(border_w, PANEL_RECT.size.y)),
	]:
		var border := ColorRect.new()
		border.color = BORDER_COLOR
		border.position = side_rect.position
		border.size = side_rect.size
		add_child(border)
		_main_panel_nodes.append(border)

	var title := Label.new()
	title.text = "PAUSED"
	title.position = PANEL_RECT.position + Vector2(0.0, 22.0)
	title.size = Vector2(PANEL_RECT.size.x, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)
	_main_panel_nodes.append(title)

	for i in _options.size():
		var lbl := Label.new()
		lbl.position = PANEL_RECT.position + Vector2(40.0, 96.0 + float(i) * 44.0)
		lbl.size = Vector2(PANEL_RECT.size.x - 80.0, 38.0)
		lbl.add_theme_font_size_override("font_size", 18)
		add_child(lbl)
		_option_labels.append(lbl)
		_main_panel_nodes.append(lbl)

	var hint := Label.new()
	hint.text = "ESC  to  resume"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 30.0)
	hint.size = Vector2(PANEL_RECT.size.x, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)
	_main_panel_nodes.append(hint)

	_refresh_options()

func _build_options_panel() -> void:
	var bg2 := ColorRect.new()
	bg2.color = Color(0.0, 0.0, 0.0, 0.55)
	bg2.size = Vector2(1280.0, 720.0)
	bg2.visible = false
	add_child(bg2)
	_opt_panel_nodes.append(bg2)

	var panel := ColorRect.new()
	panel.color = PANEL_COLOR
	panel.position = OPT_RECT.position
	panel.size = OPT_RECT.size
	panel.visible = false
	add_child(panel)
	_opt_panel_nodes.append(panel)

	var border_w: float = 2.0
	for side_rect: Rect2 in [
		Rect2(OPT_RECT.position, Vector2(OPT_RECT.size.x, border_w)),
		Rect2(OPT_RECT.position + Vector2(0.0, OPT_RECT.size.y - border_w), Vector2(OPT_RECT.size.x, border_w)),
		Rect2(OPT_RECT.position, Vector2(border_w, OPT_RECT.size.y)),
		Rect2(OPT_RECT.position + Vector2(OPT_RECT.size.x - border_w, 0.0), Vector2(border_w, OPT_RECT.size.y)),
	]:
		var border := ColorRect.new()
		border.color = BORDER_COLOR
		border.position = side_rect.position
		border.size = side_rect.size
		border.visible = false
		add_child(border)
		_opt_panel_nodes.append(border)

	var title := Label.new()
	title.text = "OPTIONS"
	title.position = OPT_RECT.position + Vector2(0.0, 22.0)
	title.size = Vector2(OPT_RECT.size.x, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.visible = false
	add_child(title)
	_opt_panel_nodes.append(title)

	# Two slider rows + Back
	var row_names: Array[String] = ["SFX Volume", "Music Volume", "Back"]
	for i in OPT_ROW_COUNT:
		var row_y: float = OPT_RECT.position.y + 90.0 + float(i) * 82.0
		var name_lbl := Label.new()
		name_lbl.position = Vector2(OPT_RECT.position.x + 28.0, row_y)
		name_lbl.size = Vector2(OPT_RECT.size.x - 56.0, 28.0)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.visible = false
		add_child(name_lbl)
		_opt_name_labels.append(name_lbl)
		_opt_panel_nodes.append(name_lbl)

		if i < 2:
			# Slider track background
			var bar_bg := ColorRect.new()
			bar_bg.position = Vector2(OPT_RECT.position.x + 28.0, row_y + 32.0)
			bar_bg.size = Vector2(340.0, 16.0)
			bar_bg.color = SLIDER_BG_COLOR
			bar_bg.visible = false
			add_child(bar_bg)
			_opt_panel_nodes.append(bar_bg)

			# Slider fill — width set dynamically
			var bar_fill := ColorRect.new()
			bar_fill.position = Vector2(OPT_RECT.position.x + 28.0, row_y + 32.0)
			bar_fill.size = Vector2(0.0, 16.0)
			bar_fill.color = SLIDER_COLOR
			bar_fill.visible = false
			add_child(bar_fill)
			_opt_bar_fills.append(bar_fill)
			_opt_panel_nodes.append(bar_fill)

			# Percentage label
			var pct_lbl := Label.new()
			pct_lbl.position = Vector2(OPT_RECT.position.x + 378.0, row_y + 28.0)
			pct_lbl.size = Vector2(80.0, 26.0)
			pct_lbl.add_theme_font_size_override("font_size", 16)
			pct_lbl.add_theme_color_override("font_color", NORMAL_COLOR)
			pct_lbl.visible = false
			add_child(pct_lbl)
			_opt_pct_labels.append(pct_lbl)
			_opt_panel_nodes.append(pct_lbl)
		else:
			_opt_bar_fills.append(null)
			_opt_pct_labels.append(null)

	var hint: Label = UIFactory.make_label(
		"← → Adjust     UP / DN Select",
		OPT_RECT.position + Vector2(0.0, OPT_RECT.size.y - 34.0),
		Vector2(OPT_RECT.size.x, 24.0),
		13, HINT_COLOR, HORIZONTAL_ALIGNMENT_CENTER, true)
	hint.visible = false
	add_child(hint)
	_opt_panel_nodes.append(hint)

func _show_main() -> void:
	for n: Node in _main_panel_nodes:
		n.visible = true
	for n: Node in _opt_panel_nodes:
		n.visible = false
	_in_options = false

func _show_options() -> void:
	for n: Node in _main_panel_nodes:
		n.visible = false
	for n: Node in _opt_panel_nodes:
		n.visible = true
	_in_options = true
	_opt_cursor = 0
	_refresh_sliders()

func _on_paused() -> void:
	_cursor = 0
	_refresh_options()
	_show_main()
	visible = true

func _on_unpaused() -> void:
	visible = false
	_in_options = false
	if _in_achievements:
		_achievements_overlay.close()
		_in_achievements = false
	if _in_inventory:
		_inventory_overlay.close()
		_in_inventory = false
	if _in_quest_log:
		_quest_log_overlay.close()
		_in_quest_log = false
	if _in_travel:
		_travel_overlay.close()
		_in_travel = false
	if _in_how_to_play:
		_how_to_play_overlay.close()
		_in_how_to_play = false

func _on_achievements_closed() -> void:
	_in_achievements = false
	_show_main()
	_refresh_options()

func _on_inventory_closed() -> void:
	_in_inventory = false
	_show_main()
	_refresh_options()

func _on_quest_log_closed() -> void:
	_in_quest_log = false
	_show_main()
	_refresh_options()

func _on_travel_closed() -> void:
	_in_travel = false
	_show_main()
	_refresh_options()

func _on_how_to_play_closed() -> void:
	_in_how_to_play = false
	_show_main()
	_refresh_options()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _in_achievements or _in_inventory or _in_quest_log or _in_travel or _in_how_to_play:
		return
	if _in_options:
		_handle_options_input(event)
	else:
		_handle_main_input(event)

func _handle_main_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_cursor = (_cursor - 1 + _options.size()) % _options.size()
		_refresh_options()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_cursor = (_cursor + 1) % _options.size()
		_refresh_options()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_select_main()
		get_viewport().set_input_as_handled()

func _handle_options_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_opt_cursor = (_opt_cursor - 1 + OPT_ROW_COUNT) % OPT_ROW_COUNT
		_refresh_sliders()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_opt_cursor = (_opt_cursor + 1) % OPT_ROW_COUNT
		_refresh_sliders()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif (event.is_action_pressed("move_left") or event.is_action_pressed("ui_left")) and _opt_cursor < 2:
		_adjust_volume(_opt_cursor, -1)
		get_viewport().set_input_as_handled()
	elif (event.is_action_pressed("move_right") or event.is_action_pressed("ui_right")) and _opt_cursor < 2:
		_adjust_volume(_opt_cursor, +1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if _opt_cursor == 2 or event.is_action_pressed("ui_cancel"):
			_show_main()
			_cursor = 1  # return cursor to "Options"
			_refresh_options()
			Audio.play("ui_select")
		get_viewport().set_input_as_handled()

func _adjust_volume(slot: int, delta: int) -> void:
	if slot == 0:
		var steps: int = roundi(Audio.sfx_volume * SLIDER_STEPS)
		steps = clampi(steps + delta, 0, SLIDER_STEPS)
		Audio.set_sfx_volume(float(steps) / float(SLIDER_STEPS))
	else:
		var steps: int = roundi(Audio.music_volume * SLIDER_STEPS)
		steps = clampi(steps + delta, 0, SLIDER_STEPS)
		Audio.set_music_volume(float(steps) / float(SLIDER_STEPS))
	Audio.save_settings()
	Audio.play("ui_move")
	_refresh_sliders()

func _select_main() -> void:
	match _options[_cursor]:
		"Resume":
			GameManager.toggle_pause()
		"Inventory":
			_in_inventory = true
			for n: Node in _main_panel_nodes:
				n.visible = false
			_inventory_overlay.open()
			Audio.play("ui_select")
		"Quests":
			_in_quest_log = true
			for n: Node in _main_panel_nodes:
				n.visible = false
			_quest_log_overlay.open()
			Audio.play("ui_select")
		"Achievements":
			_in_achievements = true
			for n: Node in _main_panel_nodes:
				n.visible = false
			_achievements_overlay.open()
			Audio.play("ui_select")
		"Options":
			_show_options()
			Audio.play("ui_select")
		"How to Play":
			_in_how_to_play = true
			for n: Node in _main_panel_nodes:
				n.visible = false
			_how_to_play_overlay.open()
			Audio.play("ui_select")
		"Travel":
			_in_travel = true
			for n: Node in _main_panel_nodes:
				n.visible = false
			_travel_overlay.open()
			Audio.play("ui_select")
		"Gimme Dat Spoon":
			GameManager.toggle_pause()
			TransitionManager.change_scene("res://scenes/levels/GimmeDatSpoon.tscn")
		"Quit to Map":
			GameManager.toggle_pause()
			TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")
		"Quit to Title":
			GameManager.toggle_pause()
			TransitionManager.change_scene("res://scenes/ui/TitleScreen.tscn")

func _refresh_options() -> void:
	for i in _option_labels.size():
		var lbl: Label = _option_labels[i]
		lbl.text = (">  " if i == _cursor else "    ") + _options[i]
		lbl.add_theme_color_override("font_color", SELECTED_COLOR if i == _cursor else NORMAL_COLOR)

func _refresh_sliders() -> void:
	var volumes: Array = [Audio.sfx_volume, Audio.music_volume]
	var row_names: Array[String] = ["SFX Volume", "Music Volume", "Back"]
	for i in OPT_ROW_COUNT:
		var name_lbl: Label = _opt_name_labels[i]
		var is_sel: bool = (i == _opt_cursor)
		name_lbl.text = (">  " if is_sel else "    ") + row_names[i]
		name_lbl.add_theme_color_override("font_color", SELECTED_COLOR if is_sel else NORMAL_COLOR)
		if i < 2:
			var fill: ColorRect = _opt_bar_fills[i]
			var pct_lbl: Label = _opt_pct_labels[i]
			var vol: float = volumes[i]
			fill.size.x = vol * 340.0
			fill.color = SLIDER_COLOR if is_sel else SLIDER_COLOR.darkened(0.3)
			var pct_int: int = roundi(vol * 100.0)
			pct_lbl.text = str(pct_int) + "%"
			pct_lbl.add_theme_color_override("font_color", SELECTED_COLOR if is_sel else NORMAL_COLOR)
