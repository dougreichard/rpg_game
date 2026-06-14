extends CanvasLayer

# Quest Log — opened from PauseMenu's "Quests" entry, in both levels and the
# overworld (quest progress is global GameManager.level_progress["town"]
# state, not tied to either context). Mirrors achievements_overlay.gd's
# programmatic CanvasLayer construction (same colors, layering,
# Engine.time_scale-paused-friendly PROCESS_MODE_ALWAYS, and
# _unhandled_input + set_input_as_handled() pattern).
#
# Lists only quests the player has discovered (not_started quests stay
# hidden -- no spoilers about who's even a quest-giver). Active quests show
# what item to bring back; completed quests show a COMPLETE tag and any
# reward received.

signal closed

const PANEL_RECT := Rect2(340.0, 24.0, 600.0, 672.0)
const BORDER_COLOR: Color = UITheme.GOLD_DIM
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.2)
const SELECTED_COLOR: Color = Color(0.95, 0.85, 0.2)
const NORMAL_COLOR: Color = Color(0.72, 0.72, 0.82)
const HINT_COLOR: Color = Color(0.45, 0.45, 0.55)
const ACTIVE_TAG_COLOR: Color = Color(0.95, 0.75, 0.3)
const COMPLETE_TAG_COLOR: Color = Color(0.4, 0.85, 0.5)

const ROW_HEIGHT: float = 26.0
const ROW_START_Y: float = 76.0
const ICON_SIZE: float = 16.0
# QuestData.TOWN_QUEST_IDS has 12 entries -- one row per quest, no scrolling needed.
const ROWS_VISIBLE: int = 12

# All 12 quests, in QuestData.TOWN_QUEST_IDS order, each as
# {id, npc_name, color, want_item, give_item}.
var _all_entries: Array = []
# Subset of _all_entries the player has discovered (state != "not_started").
var _entries: Array = []
var _cursor: int = 0

var _progress_label: Label = null
var _row_icons: Array = []
var _row_name_labels: Array = []
var _row_status_labels: Array = []
var _description_label: Label = null
var _empty_label: Label = null

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for quest_id: String in QuestData.TOWN_QUEST_IDS:
		var npc: Dictionary = QuestData.get_npc(quest_id)
		var quest: Dictionary = QuestData.get_quest(quest_id)
		_all_entries.append({
			"id": quest_id,
			"npc_name": npc.get("name", quest_id.capitalize()),
			"color": npc.get("color", Color.WHITE),
			"want_item": quest.get("want_item", ""),
			"give_item": quest.get("give_item", ""),
		})
	_build_ui()
	GameManager.level_flag_set.connect(_on_level_flag_set)

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
	title.text = "QUEST LOG"
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

	for i in ROWS_VISIBLE:
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

	_empty_label = Label.new()
	_empty_label.text = "(talk to townsfolk around the map to find quests)"
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
	hint.text = "UP / DOWN  Select     ESC  Back"
	hint.position = PANEL_RECT.position + Vector2(0.0, PANEL_RECT.size.y - 26.0)
	hint.size = Vector2(PANEL_RECT.size.x, 22.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	add_child(hint)

func _quest_state(id: String) -> String:
	return GameManager.get_level_flag(QuestData.TOWN_ID, "quest_" + id, "not_started")

func _refresh() -> void:
	_entries = []
	for entry: Dictionary in _all_entries:
		if _quest_state(entry["id"]) != "not_started":
			_entries.append(entry)
	_cursor = clampi(_cursor, 0, maxi(_entries.size() - 1, 0))

	_empty_label.visible = _entries.is_empty()

	var active_count: int = 0
	var complete_count: int = 0
	for entry: Dictionary in _entries:
		if _quest_state(entry["id"]) == "complete":
			complete_count += 1
		else:
			active_count += 1
	_progress_label.text = "%d active · %d completed" % [active_count, complete_count]

	for i in ROWS_VISIBLE:
		var icon: ColorRect = _row_icons[i]
		var name_lbl: Label = _row_name_labels[i]
		var status_lbl: Label = _row_status_labels[i]
		if i >= _entries.size():
			icon.visible = false
			name_lbl.visible = false
			status_lbl.visible = false
			continue
		var entry: Dictionary = _entries[i]
		var is_complete: bool = _quest_state(entry["id"]) == "complete"
		var is_selected: bool = (i == _cursor)
		icon.visible = true
		name_lbl.visible = true
		status_lbl.visible = true
		icon.color = entry["color"]
		name_lbl.text = (">  " if is_selected else "    ") + entry["npc_name"]
		name_lbl.add_theme_color_override("font_color", SELECTED_COLOR if is_selected else NORMAL_COLOR)
		status_lbl.text = "COMPLETE" if is_complete else "ACTIVE"
		status_lbl.add_theme_color_override("font_color", COMPLETE_TAG_COLOR if is_complete else ACTIVE_TAG_COLOR)

	_description_label.text = _objective_text(_entries[_cursor]) if not _entries.is_empty() else ""

func _objective_text(entry: Dictionary) -> String:
	if _quest_state(entry["id"]) == "complete":
		if entry["give_item"] != "":
			return "Completed. Reward: %s" % _item_name(entry["give_item"])
		return "Completed."
	if entry["want_item"] != "":
		return "Find: %s. Bring it to %s." % [_item_name(entry["want_item"]), entry["npc_name"]]
	return "Talk to %s." % entry["npc_name"]

func _item_name(item_id: String) -> String:
	var item: ItemData = load("res://data/items/%s.tres" % item_id)
	return item.display_name if item != null else item_id

func _on_level_flag_set(location_id: String, key: String, _value) -> void:
	if visible and location_id == QuestData.TOWN_ID and key.begins_with("quest_"):
		_refresh()

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
	elif event.is_action_pressed("ui_cancel"):
		Audio.play("ui_select")
		close()
		get_viewport().set_input_as_handled()
