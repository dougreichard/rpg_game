extends CanvasLayer

const OPTIONS: Array[String] = ["Resume", "Quit to Map"]
const PANEL_RECT := Rect2(440.0, 260.0, 400.0, 220.0)

var _option_labels: Array = []
var _cursor: int = 0

func _ready() -> void:
	layer = 25
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
	panel.color = Color(0.1, 0.09, 0.16, 0.96)
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	add_child(panel)

	var title := Label.new()
	title.text = "PAUSED"
	title.position = PANEL_RECT.position + Vector2(0.0, 24.0)
	title.size = Vector2(PANEL_RECT.size.x, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	add_child(title)

	for i in OPTIONS.size():
		var lbl := Label.new()
		lbl.position = PANEL_RECT.position + Vector2(40.0, 100.0 + float(i) * 46.0)
		lbl.size = Vector2(PANEL_RECT.size.x - 80.0, 38.0)
		lbl.add_theme_font_size_override("font_size", 24)
		add_child(lbl)
		_option_labels.append(lbl)
	_refresh_options()

func _on_paused() -> void:
	_cursor = 0
	_refresh_options()
	visible = true

func _on_unpaused() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("move_up"):
		_cursor = (_cursor - 1 + OPTIONS.size()) % OPTIONS.size()
		_refresh_options()
		Audio.play("ui_move")
	elif Input.is_action_just_pressed("move_down"):
		_cursor = (_cursor + 1) % OPTIONS.size()
		_refresh_options()
		Audio.play("ui_move")
	elif Input.is_action_just_pressed("ui_accept"):
		_select()

func _select() -> void:
	match _cursor:
		0:
			GameManager.toggle_pause()
		1:
			GameManager.toggle_pause()
			get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")

func _refresh_options() -> void:
	for i in _option_labels.size():
		var lbl: Label = _option_labels[i]
		lbl.text = ("> " if i == _cursor else "  ") + OPTIONS[i]
		lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2) if i == _cursor else Color(0.78, 0.78, 0.85))
