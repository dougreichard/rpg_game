extends Node3D
## 3D-build title screen. Warm menu over a sky backdrop with a 3-slot save system:
## Continue (last slot), New Game (pick a slot, overwrites), Load (pick a saved
## slot), How to Play. Options (audio) live in the in-game Pause menu. Drives
## SaveManager and enters Overworld3D.

const OVERWORLD_3D := "res://scenes/3d/Overworld3D.tscn"
const HowToPlayOverlayScript: Script = preload("res://scripts/ui/how_to_play_overlay.gd")

enum Mode { MAIN, NEW, LOAD }

var _menu: CanvasLayer = null
var _item_nodes: Array = []
var _items: Array = []          # {text, enabled, tag, slot}
var _cursor: int = 0
var _mode: int = Mode.MAIN
var _how_to_play = null
var _busy: bool = false

func _ready() -> void:
	_build_backdrop()
	_menu = CanvasLayer.new(); add_child(_menu)
	_how_to_play = HowToPlayOverlayScript.new(); _how_to_play.layer = 30; add_child(_how_to_play)
	_how_to_play.closed.connect(func() -> void: _busy = false)
	_show_main()
	Audio.play_music("title")

func _build_backdrop() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.11, 0.10)
	we.environment = env
	add_child(we)
	add_child(Camera3D.new())

# --- menu construction -------------------------------------------------------
func _show_main() -> void:
	_mode = Mode.MAIN
	var last: int = SaveManager.get_last_slot()
	var can_continue: bool = last >= 0 and SaveManager.has_save(last)
	var any_save: bool = false
	for s in SaveManager.SAVE_SLOT_COUNT:
		if SaveManager.has_save(s):
			any_save = true
	_items = []
	if can_continue:
		_items.append({"text": "Continue", "enabled": true, "tag": "continue"})
	_items.append({"text": "New Game", "enabled": true, "tag": "new"})
	if any_save:
		_items.append({"text": "Load", "enabled": true, "tag": "load"})
	_items.append({"text": "How to Play", "enabled": true, "tag": "htp"})
	_cursor = 0
	_render("HUNKLE BUNKLE", "Find Uncle Doug.")

func _show_slots(mode: int) -> void:
	_mode = mode
	_items = []
	for s in SaveManager.SAVE_SLOT_COUNT:
		var sm: Dictionary = SaveManager.get_slot_summary(s)
		var occupied: bool = sm.get("exists", false)
		var label: String
		if occupied:
			var n: int = sm.get("completed_count", 0)
			var tail: String = "  ★ DONE" if sm.get("doug_found", false) else ("  %d/13 locations" % n)
			label = "Slot %d —%s" % [s + 1, tail]
			if mode == Mode.NEW:
				label += "   (overwrite)"
		else:
			label = "Slot %d — Empty" % (s + 1)
		# Load can only pick occupied slots; New Game can pick any.
		var enabled: bool = occupied if mode == Mode.LOAD else true
		_items.append({"text": label, "enabled": enabled, "tag": "slot", "slot": s})
	_items.append({"text": "Back", "enabled": true, "tag": "back"})
	_cursor = 0
	while _cursor < _items.size() and not _items[_cursor]["enabled"]:
		_cursor += 1
	var header: String = "New Game — choose a slot" if mode == Mode.NEW else "Load — choose a slot"
	_render(header, "")

func _render(header: String, sub: String) -> void:
	for c in _menu.get_children():
		c.queue_free()
	_item_nodes.clear()

	var bg := ColorRect.new(); bg.color = Color(0.10, 0.07, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); _menu.add_child(bg)
	_title_label(header, 110, 64, UITheme.GOLD)
	if sub != "":
		_title_label(sub, 196, 24, UITheme.CREAM)
	for i in _items.size():
		var b := UITheme.menu_button(_items[i]["text"], 28, false)
		b.anchor_left = 0.5; b.anchor_right = 0.5
		b.offset_left = -200; b.offset_right = 200
		b.offset_top = 320 + i * 58; b.offset_bottom = 372 + i * 58
		b.pressed.connect(_on_item_pressed.bind(i))
		b.mouse_entered.connect(_on_item_hover.bind(i))
		_menu.add_child(b)
		_item_nodes.append(b)
	_title_label("W/S or ↑/↓ choose   ·   F / Enter select   ·   Esc back", 648, 18, UITheme.TEXT_DIM)
	_refresh()

func _title_label(text: String, y: float, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.anchor_right = 1.0; l.offset_top = y; l.offset_bottom = y + size + 14
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	_menu.add_child(l)
	return l

func _refresh() -> void:
	for i in _item_nodes.size():
		var it: Dictionary = _items[i]
		var b: Button = _item_nodes[i]
		b.text = it["text"]
		b.disabled = not it["enabled"]   # themed disabled stylebox
		if it["enabled"]:
			UITheme.set_button_selected(b, i == _cursor)

# --- input -------------------------------------------------------------------
func _unhandled_input(_e: InputEvent) -> void:
	if _busy:
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_move(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_move(1)
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_select()
	elif Input.is_action_just_pressed("ui_cancel"):
		if _mode != Mode.MAIN:
			Audio.play("ui_move"); _show_main()

func _move(dir: int) -> void:
	var n: int = _items.size()
	var c: int = _cursor
	for _i in n:
		c = (c + dir + n) % n
		if _items[c]["enabled"]:
			break
	_cursor = c
	Audio.play("ui_move"); _refresh()

func _on_item_pressed(i: int) -> void:
	if _busy or i >= _items.size() or not _items[i]["enabled"]:
		return
	_cursor = i
	_refresh()
	_select()

func _on_item_hover(i: int) -> void:
	if _busy or i >= _items.size() or not _items[i]["enabled"] or _cursor == i:
		return
	_cursor = i
	Audio.play("ui_move"); _refresh()

func _select() -> void:
	var it: Dictionary = _items[_cursor]
	if not it["enabled"]:
		return
	Audio.play("ui_select")
	match it["tag"]:
		"continue":
			SaveManager.load_game(SaveManager.get_last_slot())
			get_tree().change_scene_to_file(OVERWORLD_3D)
		"new":
			_show_slots(Mode.NEW)
		"load":
			_show_slots(Mode.LOAD)
		"htp":
			_busy = true; _how_to_play.open()
		"back":
			_show_main()
		"slot":
			var slot: int = it["slot"]
			if _mode == Mode.NEW:
				SaveManager.start_new_game(slot)
			else:
				SaveManager.load_game(slot)
			get_tree().change_scene_to_file(OVERWORLD_3D)

