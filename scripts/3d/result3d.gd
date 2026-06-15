extends Node3D
## 3D-build endgame / result screen. Shown after the Grand Marquee Cinema is
## cleared (Uncle Doug found). Celebrates, shows a couple of run stats, and
## returns to the title. Replaces the 2D ResultScreen for the native-3D flow.

const TITLE_3D := "res://scenes/3d/Title3D.tscn"

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.07, 0.06)
	we.environment = env
	add_child(we)
	add_child(Camera3D.new())
	_build_ui()
	Audio.play_music("victory")

func _build_ui() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var bg := ColorRect.new(); bg.color = Color(0.10, 0.07, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); cl.add_child(bg)

	_label(cl, "★  UNCLE DOUG FOUND  ★", 130, 64, UITheme.GOLD)
	_label(cl, "The search is over. Hunkle Bunkle, reunited.", 220, 28, UITheme.CREAM)

	var found: int = GameManager.completed_locations.size()
	_label(cl, "Locations cleared: %d / 13" % min(found, 13), 320, 26, UITheme.TEXT)
	_label(cl, "Characters reunited: %d / 5" % GameManager.unlocked_characters.size(), 360, 26, UITheme.TEXT)

	_label(cl, "Thanks for playing.", 470, 30, UITheme.ACCENT)
	_label(cl, "F / Enter — Back to Title", 620, 24, UITheme.TEXT_DIM)

func _label(cl: CanvasLayer, text: String, y: float, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.anchor_right = 1.0; l.offset_top = y; l.offset_bottom = y + size + 12
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	cl.add_child(l)
	return l

func _unhandled_input(_e: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		Audio.play("ui_select")
		get_tree().change_scene_to_file(TITLE_3D)
