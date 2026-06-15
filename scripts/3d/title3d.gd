extends Node3D
## 3D-build title screen. Minimal warm menu over a sky backdrop: New Game /
## Continue / How to Play, driving SaveManager and entering Overworld3D. Replaces
## the 2D TitleScreen for the native-3D flow.

const OVERWORLD_3D := "res://scenes/3d/Overworld3D.tscn"
const HowToPlayOverlayScript: Script = preload("res://scripts/ui/how_to_play_overlay.gd")
const SLOT := 0

var _items: Array = []
var _labels: Array = []
var _cursor: int = 0
var _can_continue: bool = false
var _how_to_play = null
var _busy: bool = false

func _ready() -> void:
	_can_continue = SaveManager.get_last_slot() >= 0 and SaveManager.has_save(SaveManager.get_last_slot())
	_build_backdrop()
	_build_menu()
	_how_to_play = HowToPlayOverlayScript.new()
	_how_to_play.layer = 30
	add_child(_how_to_play)
	_how_to_play.closed.connect(func() -> void: _busy = false)
	Audio.play_music("title")

func _build_backdrop() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.11, 0.10)
	we.environment = env
	add_child(we)
	var cam := Camera3D.new(); cam.current = true; add_child(cam)

func _build_menu() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.07, 0.06, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.anchor_right = 1.0; title.offset_top = 120; title.offset_bottom = 200
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font())
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	cl.add_child(title)

	var sub := Label.new()
	sub.text = "Find Uncle Doug."
	sub.anchor_right = 1.0; sub.offset_top = 206; sub.offset_bottom = 246
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.font())
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", UITheme.CREAM)
	cl.add_child(sub)

	_items = (["Continue", "New Game", "How to Play"] if _can_continue else ["New Game", "How to Play"])
	_cursor = 0
	for i in _items.size():
		var l := Label.new()
		l.text = _items[i]
		l.anchor_right = 1.0; l.offset_top = 340 + i * 56; l.offset_bottom = 392 + i * 56
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UITheme.font())
		l.add_theme_font_size_override("font_size", 34)
		cl.add_child(l)
		_labels.append(l)
	var hint := Label.new()
	hint.text = "W/S or ↑/↓ to choose   ·   F / Enter to select"
	hint.anchor_right = 1.0; hint.anchor_top = 1.0; hint.anchor_bottom = 1.0
	hint.offset_top = -56; hint.offset_bottom = -20
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", UITheme.font())
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	cl.add_child(hint)
	_refresh()

func _refresh() -> void:
	for i in _labels.size():
		var sel: bool = i == _cursor
		_labels[i].add_theme_color_override("font_color", UITheme.ACCENT if sel else UITheme.TEXT_DIM)
		_labels[i].text = ("> %s <" % _items[i]) if sel else _items[i]

func _unhandled_input(_e: InputEvent) -> void:
	if _busy:
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_cursor = (_cursor - 1 + _items.size()) % _items.size(); Audio.play("ui_move"); _refresh()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_cursor = (_cursor + 1) % _items.size(); Audio.play("ui_move"); _refresh()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_select()

func _select() -> void:
	Audio.play("ui_select")
	match _items[_cursor]:
		"Continue":
			SaveManager.load_game(SaveManager.get_last_slot())
			get_tree().change_scene_to_file(OVERWORLD_3D)
		"New Game":
			SaveManager.start_new_game(SLOT)
			get_tree().change_scene_to_file(OVERWORLD_3D)
		"How to Play":
			_busy = true
			_how_to_play.open()
