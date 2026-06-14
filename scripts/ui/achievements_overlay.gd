extends CanvasLayer

# Achievements list — opened from PauseMenu's "Achievements" entry. Mirrors
# pause_menu.gd's programmatic CanvasLayer construction (same colors,
# layering, Engine.time_scale-paused-friendly PROCESS_MODE_ALWAYS, and
# _unhandled_input + accept_event()/set_input_as_handled() pattern).

signal closed

const PANEL_RECT := Rect2(340.0, 24.0, 600.0, 672.0)
const BORDER_COLOR: Color = UITheme.GOLD_DIM
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const LOCKED_COLOR: Color = Color(0.45, 0.45, 0.55)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)
const UNLOCKED_TAG_COLOR: Color = Color(0.4, 0.85, 0.5)
const LOCKED_TAG_COLOR: Color = Color(0.55, 0.45, 0.45)

const ROW_HEIGHT: float = 26.0
const ROW_START_Y: float = 76.0
const ICON_SIZE: float = 16.0

var _ids: Array[String] = []
var _cursor: int = 0

var _row_icons: Array = []
var _row_name_labels: Array = []
var _row_status_labels: Array = []
var _progress_label: Label = null
var _description_label: Label = null

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ids = AchievementManager.get_ordered_ids()
	_build_ui()
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func open() -> void:
	_cursor = 0
	visible = true
	_refresh()

func close() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.size = Vector2(1280.0, 720.0)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = UITheme.PANEL_BG
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	add_child(panel)

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
	title.text = "ACHIEVEMENTS"
	title.position = PANEL_RECT.position + Vector2(0.0, 16.0)
	title.size = Vector2(PANEL_RECT.size.x, 36.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	_progress_label = Label.new()
	_progress_label.position = PANEL_RECT.position + Vector2(0.0, 48.0)
	_progress_label.size = Vector2(PANEL_RECT.size.x, 22.0)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_progress_label)

	for i in _ids.size():
		var row_y: float = PANEL_RECT.position.y + ROW_START_Y + float(i) * ROW_HEIGHT
		var icon := ColorRect.new()
		icon.position = Vector2(PANEL_RECT.position.x + 24.0, row_y + 5.0)
		icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		add_child(icon)
		_row_icons.append(icon)

		var name_lbl := Label.new()
		name_lbl.position = Vector2(PANEL_RECT.position.x + 50.0, row_y)
		name_lbl.size = Vector2(390.0, ROW_HEIGHT)
		name_lbl.add_theme_font_size_override("font_size", 16)
		add_child(name_lbl)
		_row_name_labels.append(name_lbl)

		var status_lbl := Label.new()
		status_lbl.position = Vector2(PANEL_RECT.position.x + 440.0, row_y)
		status_lbl.size = Vector2(136.0, ROW_HEIGHT)
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_lbl.add_theme_font_size_override("font_size", 13)
		add_child(status_lbl)
		_row_status_labels.append(status_lbl)

	_description_label = Label.new()
	_description_label.position = Vector2(PANEL_RECT.position.x + 24.0, PANEL_RECT.position.y + PANEL_RECT.size.y - 64.0)
	_description_label.size = Vector2(PANEL_RECT.size.x - 48.0, 36.0)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_description_label.add_theme_font_size_override("font_size", 14)
	_description_label.add_theme_color_override("font_color", NORMAL_COLOR)
	add_child(_description_label)

	var hint := Label.new()
	hint.text = "UP / DOWN  Select     ESC  Back"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 26.0)
	hint.size = Vector2(PANEL_RECT.size.x, 22.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)

func _refresh() -> void:
	var unlocked_count: int = 0
	for i in _ids.size():
		var id: String = _ids[i]
		var is_unlocked: bool = AchievementManager.is_unlocked(id)
		if is_unlocked:
			unlocked_count += 1
		var icon: ColorRect = _row_icons[i]
		icon.color = AchievementManager.get_icon_color(id)
		var name_lbl: Label = _row_name_labels[i]
		var is_selected: bool = (i == _cursor)
		name_lbl.text = (">  " if is_selected else "    ") + AchievementManager.get_display_name(id)
		if is_selected:
			name_lbl.add_theme_color_override("font_color", SELECTED_COLOR)
		elif is_unlocked:
			name_lbl.add_theme_color_override("font_color", NORMAL_COLOR)
		else:
			name_lbl.add_theme_color_override("font_color", LOCKED_COLOR)
		var status_lbl: Label = _row_status_labels[i]
		status_lbl.text = "UNLOCKED" if is_unlocked else "LOCKED"
		status_lbl.add_theme_color_override("font_color", UNLOCKED_TAG_COLOR if is_unlocked else LOCKED_TAG_COLOR)
	_progress_label.text = "%d / %d unlocked" % [unlocked_count, _ids.size()]
	_description_label.text = AchievementManager.get_description(_ids[_cursor])

func _on_achievement_unlocked(_id: String) -> void:
	if visible:
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_cursor = (_cursor - 1 + _ids.size()) % _ids.size()
		_refresh()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_cursor = (_cursor + 1) % _ids.size()
		_refresh()
		Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		close()
		get_viewport().set_input_as_handled()
