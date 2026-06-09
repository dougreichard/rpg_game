extends CanvasLayer

# Pause menu — shown/hidden via GameManager.paused/unpaused signals.
# Uses Engine.time_scale=0.0 (not get_tree().paused) so _process still runs;
# input is handled in _unhandled_input with accept_event() to prevent the
# same keypress reaching level scripts (e.g. the clear-overlay ui_accept check).

const OPTIONS: Array[String] = ["Resume", "Quit to Map", "Quit to Title"]
const PANEL_RECT := Rect2(440.0, 240.0, 400.0, 260.0)
const BORDER_COLOR: Color = Color(0.55, 0.45, 0.75)
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)

var _option_labels: Array = []
var _cursor: int = 0

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	GameManager.paused.connect(_on_paused)
	GameManager.unpaused.connect(_on_unpaused)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.size = Vector2(1280.0, 720.0)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.07, 0.14, 0.97)
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	add_child(panel)

	# Border — four thin ColorRects around the panel
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

	var title := Label.new()
	title.text = "PAUSED"
	title.position = PANEL_RECT.position + Vector2(0.0, 22.0)
	title.size = Vector2(PANEL_RECT.size.x, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	for i in OPTIONS.size():
		var lbl := Label.new()
		lbl.position = PANEL_RECT.position + Vector2(40.0, 96.0 + float(i) * 50.0)
		lbl.size = Vector2(PANEL_RECT.size.x - 80.0, 40.0)
		lbl.add_theme_font_size_override("font_size", 24)
		add_child(lbl)
		_option_labels.append(lbl)

	var hint := Label.new()
	hint.text = "ESC  to  resume"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 30.0)
	hint.size = Vector2(PANEL_RECT.size.x, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)

	_refresh_options()

func _on_paused() -> void:
	_cursor = 0
	_refresh_options()
	visible = true

func _on_unpaused() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + OPTIONS.size()) % OPTIONS.size()
		_refresh_options()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % OPTIONS.size()
		_refresh_options()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_select()
		get_viewport().set_input_as_handled()

func _select() -> void:
	match _cursor:
		0:
			GameManager.toggle_pause()
		1:
			GameManager.toggle_pause()
			TransitionManager.change_scene("res://scenes/overworld/OverworldMap.tscn")
		2:
			GameManager.toggle_pause()
			TransitionManager.change_scene("res://scenes/ui/TitleScreen.tscn")

func _refresh_options() -> void:
	for i in _option_labels.size():
		var lbl: Label = _option_labels[i]
		lbl.text = (">  " if i == _cursor else "    ") + OPTIONS[i]
		lbl.add_theme_color_override("font_color", SELECTED_COLOR if i == _cursor else NORMAL_COLOR)
