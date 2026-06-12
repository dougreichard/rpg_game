extends CanvasLayer

# Fast-travel ("Navigation") overlay — opened from PauseMenu's "Travel" entry,
# overworld only, gated on the Grand Marquee being completed (see
# pause_menu.gd). Mirrors quest_log_overlay.gd's programmatic CanvasLayer
# construction (same colors, layering, PROCESS_MODE_ALWAYS, and
# _unhandled_input + set_input_as_handled() pattern).
#
# Lists every currently-unlocked location; selecting one emits
# location_chosen(loc_id) so overworld_map.gd can teleport the duo + camera
# to that location's door.

signal location_chosen(loc_id: String)
signal closed

const PANEL_RECT := Rect2(340.0, 24.0, 600.0, 672.0)
const BORDER_COLOR: Color = Color(0.55, 0.45, 0.75)
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)

const ROW_HEIGHT: float = 26.0
const ROW_START_Y: float = 76.0
const ROWS_VISIBLE: int = 14

# Set via setup() — the overworld's LOCS array.
var _locs: Array = []
# Subset of _locs that are currently unlocked, each {id, name}.
var _entries: Array = []
var _cursor: int = 0

var _row_labels: Array = []
var _empty_label: Label = null

func setup(locs: Array) -> void:
	_locs = locs

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

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
	panel.color = Color(0.08, 0.07, 0.14, 0.97)
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
	title.text = "TRAVEL"
	title.position = PANEL_RECT.position + Vector2(0.0, 16.0)
	title.size = Vector2(PANEL_RECT.size.x, 36.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	for i in ROWS_VISIBLE:
		var row_y: float = PANEL_RECT.position.y + ROW_START_Y + float(i) * ROW_HEIGHT
		var lbl := Label.new()
		lbl.position = Vector2(PANEL_RECT.position.x + 24.0, row_y)
		lbl.size = Vector2(PANEL_RECT.size.x - 48.0, ROW_HEIGHT)
		lbl.add_theme_font_size_override("font_size", 16)
		add_child(lbl)
		_row_labels.append(lbl)

	_empty_label = Label.new()
	_empty_label.text = "(no locations unlocked yet)"
	_empty_label.position = Vector2(PANEL_RECT.position.x, PANEL_RECT.position.y + ROW_START_Y)
	_empty_label.size = Vector2(PANEL_RECT.size.x, ROW_HEIGHT)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 14)
	_empty_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_empty_label)

	var hint := Label.new()
	hint.text = "UP / DOWN  Select     ENTER  Travel     ESC  Back"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 26.0)
	hint.size = Vector2(PANEL_RECT.size.x, 22.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)

func _is_unlocked(loc: Dictionary) -> bool:
	var req: String = loc["requires"]
	return req == "" or req in GameManager.completed_locations

func _refresh() -> void:
	_entries = []
	for loc: Dictionary in _locs:
		if _is_unlocked(loc):
			_entries.append({"id": loc["id"], "name": loc["name"]})
	_cursor = clampi(_cursor, 0, maxi(_entries.size() - 1, 0))

	_empty_label.visible = _entries.is_empty()

	for i in ROWS_VISIBLE:
		var lbl: Label = _row_labels[i]
		if i >= _entries.size():
			lbl.visible = false
			continue
		var is_selected: bool = (i == _cursor)
		lbl.visible = true
		lbl.text = (">  " if is_selected else "    ") + _entries[i]["name"]
		lbl.add_theme_color_override("font_color", SELECTED_COLOR if is_selected else NORMAL_COLOR)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		if not _entries.is_empty():
			_cursor = (_cursor - 1 + _entries.size()) % _entries.size()
			_refresh()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		if not _entries.is_empty():
			_cursor = (_cursor + 1) % _entries.size()
			_refresh()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if not _entries.is_empty():
			Audio.play("ui_select")
			var loc_id: String = _entries[_cursor]["id"]
			close()
			location_chosen.emit(loc_id)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		close()
		get_viewport().set_input_as_handled()
