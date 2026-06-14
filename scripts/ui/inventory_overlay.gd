extends CanvasLayer

# Full inventory list — opened from PauseMenu's "Inventory" entry. Mirrors
# achievements_overlay.gd's programmatic CanvasLayer construction (same
# colors, layering, Engine.time_scale-paused-friendly PROCESS_MODE_ALWAYS,
# and _unhandled_input + set_input_as_handled() pattern). Replaces squinting
# at the small always-on InventoryPanel icon row in the HUD with a readable,
# scrollable list of names/descriptions for each duo member.

signal closed

const PANEL_RECT := Rect2(340.0, 24.0, 600.0, 672.0)
const BORDER_COLOR: Color = UITheme.GOLD_DIM
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)
const FUNCTIONAL_TAG_COLOR: Color = Color(1.0, 0.85, 0.3)
const JUNK_TAG_COLOR: Color = Color(0.55, 0.55, 0.6)
const TAB_ACTIVE_COLOR: Color = Color(0.95, 0.85, 0.2)
const TAB_IDLE_COLOR: Color = Color(0.5, 0.5, 0.58)

const ROW_HEIGHT: float = 26.0
const ROW_START_Y: float = 110.0
const ROWS_VISIBLE: int = 14
const ICON_SIZE: float = 16.0

var _name_a: String = ""
var _name_b: String = ""
var _char_index: int = 0
var _ids: Array = []
var _cursor: int = 0
var _scroll: int = 0
var _icon_cache: Dictionary = {}

var _tab_labels: Array = []
var _count_label: Label = null
var _row_icons: Array = []
var _row_name_labels: Array = []
var _row_tag_labels: Array = []
var _description_label: Label = null
var _empty_label: Label = null

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

# Character names are pushed in once by whoever builds this overlay (hud.gd
# for levels, overworld_map.gd for the town) — the overlay itself has no
# reliable way to discover the duo, since GameManager.active_player/
# standby_player are level-Player-only and unset in the overworld (see
# [[feedback-godot-technical]]).
func setup(name_a: String, name_b: String) -> void:
	_name_a = name_a
	_name_b = name_b

func open() -> void:
	_char_index = 0
	_cursor = 0
	_scroll = 0
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
	title.text = "INVENTORY"
	title.position = PANEL_RECT.position + Vector2(0.0, 16.0)
	title.size = Vector2(PANEL_RECT.size.x, 36.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	# Character tabs — left/right switches between duo members.
	var tab_width: float = PANEL_RECT.size.x * 0.5
	for i in 2:
		var tab := Label.new()
		tab.position = PANEL_RECT.position + Vector2(float(i) * tab_width, 52.0)
		tab.size = Vector2(tab_width, 28.0)
		tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.add_theme_font_size_override("font_size", 18)
		add_child(tab)
		_tab_labels.append(tab)

	_count_label = Label.new()
	_count_label.position = PANEL_RECT.position + Vector2(0.0, 80.0)
	_count_label.size = Vector2(PANEL_RECT.size.x, 22.0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 14)
	_count_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_count_label)

	for i in ROWS_VISIBLE:
		var row_y: float = PANEL_RECT.position.y + ROW_START_Y + float(i) * ROW_HEIGHT

		var icon := TextureRect.new()
		icon.position = Vector2(PANEL_RECT.position.x + 24.0, row_y + 4.0)
		icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		add_child(icon)
		_row_icons.append(icon)

		var name_lbl := Label.new()
		name_lbl.position = Vector2(PANEL_RECT.position.x + 50.0, row_y)
		name_lbl.size = Vector2(420.0, ROW_HEIGHT)
		name_lbl.add_theme_font_size_override("font_size", 16)
		add_child(name_lbl)
		_row_name_labels.append(name_lbl)

		var tag_lbl := Label.new()
		tag_lbl.position = Vector2(PANEL_RECT.position.x + 470.0, row_y)
		tag_lbl.size = Vector2(106.0, ROW_HEIGHT)
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag_lbl.add_theme_font_size_override("font_size", 13)
		add_child(tag_lbl)
		_row_tag_labels.append(tag_lbl)

	_empty_label = Label.new()
	_empty_label.text = "(nothing yet — open loot boxes around the locations)"
	_empty_label.position = Vector2(PANEL_RECT.position.x, PANEL_RECT.position.y + ROW_START_Y)
	_empty_label.size = Vector2(PANEL_RECT.size.x, ROW_HEIGHT)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 14)
	_empty_label.add_theme_color_override("font_color", HINT_COLOR)
	add_child(_empty_label)

	_description_label = Label.new()
	_description_label.position = Vector2(PANEL_RECT.position.x + 24.0, PANEL_RECT.position.y + PANEL_RECT.size.y - 64.0)
	_description_label.size = Vector2(PANEL_RECT.size.x - 48.0, 36.0)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_description_label.add_theme_font_size_override("font_size", 14)
	_description_label.add_theme_color_override("font_color", NORMAL_COLOR)
	add_child(_description_label)

	var hint := Label.new()
	hint.text = "<- -> Character     UP / DOWN Select     ESC Back"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 26.0)
	hint.size = Vector2(PANEL_RECT.size.x, 22.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)

func _current_name() -> String:
	return _name_a if _char_index == 0 else _name_b

func _refresh() -> void:
	for i in 2:
		var name: String = _name_a if i == 0 else _name_b
		var tab: Label = _tab_labels[i]
		var is_sel: bool = (i == _char_index)
		tab.text = ("> " if is_sel else "") + (name.to_upper() if name != "" else "---")
		tab.add_theme_color_override("font_color", TAB_ACTIVE_COLOR if is_sel else TAB_IDLE_COLOR)

	var name: String = _current_name()
	_ids = GameManager.inventories.get(name.to_lower(), []) if name != "" else []
	_cursor = clampi(_cursor, 0, maxi(_ids.size() - 1, 0))
	_scroll = clampi(_scroll, 0, maxi(_ids.size() - ROWS_VISIBLE, 0))
	if _cursor < _scroll:
		_scroll = _cursor
	elif _cursor >= _scroll + ROWS_VISIBLE:
		_scroll = _cursor - ROWS_VISIBLE + 1

	_count_label.text = "%d item%s carried" % [_ids.size(), "" if _ids.size() == 1 else "s"]
	_empty_label.visible = _ids.is_empty()

	for i in ROWS_VISIBLE:
		var idx: int = _scroll + i
		var icon: TextureRect = _row_icons[i]
		var name_lbl: Label = _row_name_labels[i]
		var tag_lbl: Label = _row_tag_labels[i]
		if idx >= _ids.size():
			icon.visible = false
			name_lbl.visible = false
			tag_lbl.visible = false
			continue
		var item: ItemData = _load_item(_ids[idx])
		icon.visible = true
		name_lbl.visible = true
		tag_lbl.visible = true
		icon.texture = _get_icon(item)
		var is_selected: bool = (idx == _cursor)
		name_lbl.text = (">  " if is_selected else "    ") + item.display_name
		name_lbl.add_theme_color_override("font_color", SELECTED_COLOR if is_selected else NORMAL_COLOR)
		tag_lbl.text = "JUNK" if item.is_junk else "FUNCTIONAL"
		tag_lbl.add_theme_color_override("font_color", JUNK_TAG_COLOR if item.is_junk else FUNCTIONAL_TAG_COLOR)

	_description_label.text = _load_item(_ids[_cursor]).description if not _ids.is_empty() else ""

func _load_item(id: String) -> ItemData:
	return load("res://data/items/%s.tres" % id)

func _get_icon(item: ItemData) -> ImageTexture:
	if item.id not in _icon_cache:
		_icon_cache[item.id] = PlaceholderArt.make_item_icon(item.icon_color, item.is_junk)
	return _icon_cache[item.id]

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		if not _ids.is_empty():
			_cursor = (_cursor - 1 + _ids.size()) % _ids.size()
			_refresh()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		if not _ids.is_empty():
			_cursor = (_cursor + 1) % _ids.size()
			_refresh()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left") \
			or event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		if _name_b != "":
			_char_index = 1 - _char_index
			_cursor = 0
			_scroll = 0
			_refresh()
			Audio.play("ui_move")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		close()
		get_viewport().set_input_as_handled()
