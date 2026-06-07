extends Node2D

const TOTAL_LOCATIONS: int = 13
const TOTAL_CHARACTERS: int = 5
const MOTE_COUNT: int = 36

var _press_label: Label
var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _motes: Array = []

func _ready() -> void:
	_build_background()
	_build_ui()

func _build_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in MOTE_COUNT:
		_motes.append({
			"pos": Vector2(rng.randf() * 1280.0, rng.randf() * 720.0),
			"speed": rng.randf_range(6.0, 22.0),
			"size": rng.randf_range(1.5, 4.0),
		})

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var title := Label.new()
	title.text = "UNCLE DOUG IS FOUND!"
	title.position = Vector2(0.0, 130.0)
	title.size = Vector2(1280.0, 70.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var story := Label.new()
	story.text = (
		"In the projection booth of the Grand Marquee Cinema, the search\n" +
		"finally ends — Uncle Doug, safe at last, thanks to the duo who\n" +
		"never stopped looking for him."
	)
	story.position = Vector2(0.0, 240.0)
	story.size = Vector2(1280.0, 100.0)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 22)
	story.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	canvas.add_child(story)

	var stats := Label.new()
	stats.text = "%d / %d locations cleared    •    %d / %d heroes united" % [
		GameManager.completed_locations.size(), TOTAL_LOCATIONS,
		GameManager.unlocked_characters.size(), TOTAL_CHARACTERS,
	]
	stats.position = Vector2(0.0, 380.0)
	stats.size = Vector2(1280.0, 36.0)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	stats.add_theme_color_override("font_color", Color(0.65, 0.6, 0.9))
	canvas.add_child(stats)

	var thanks := Label.new()
	thanks.text = "Thanks for playing Hunkle Bunkle"
	thanks.position = Vector2(0.0, 470.0)
	thanks.size = Vector2(1280.0, 34.0)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override("font_size", 24)
	thanks.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	canvas.add_child(thanks)

	_press_label = Label.new()
	_press_label.text = "PRESS  ENTER  FOR  THE  TITLE  SCREEN"
	_press_label.position = Vector2(0.0, 560.0)
	_press_label.size = Vector2(1280.0, 40.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 26)
	_press_label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
	canvas.add_child(_press_label)

func _process(delta: float) -> void:
	for mote: Dictionary in _motes:
		var pos: Vector2 = mote["pos"]
		pos.y -= mote["speed"] * delta
		if pos.y < -4.0:
			pos.y = 724.0
			pos.x = randf() * 1280.0
		mote["pos"] = pos

	_blink_timer += delta
	if _blink_timer >= 0.5:
		_blink_timer = 0.0
		_blink_visible = not _blink_visible
		_press_label.visible = _blink_visible

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		Audio.play("ui_select")
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.06, 0.05, 0.1))
	for mote: Dictionary in _motes:
		draw_circle(mote["pos"], mote["size"], Color(0.95, 0.85, 0.45, 0.4))
