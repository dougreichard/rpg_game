extends Node2D

const TOTAL_LOCATIONS: int = 13
const TOTAL_CHARACTERS: int = 5
const TOTAL_ITEMS: int = 29
const MOTE_COUNT: int = 36

# Character chip row — colors from each character's sprite_color in their .tres
const CHIP_W: float = 66.0
const CHIP_H: float = 46.0
const CHIP_SPACING: float = 14.0
const CHIP_TOP_Y: float = 330.0
const CHAR_NAMES: Array = ["Quinn", "Erin", "Evan", "Ben", "Ethan"]
const CHAR_COLORS: Array = [
	Color(0.3, 0.45, 0.85),
	Color(0.9, 0.35, 0.1),
	Color(0.55, 0.42, 0.18),
	Color(0.75, 0.25, 0.55),
	Color(0.2, 0.65, 0.6),
]

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
			"drift": rng.randf_range(-10.0, 10.0),
		})

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var title := Label.new()
	title.text = "UNCLE DOUG IS FOUND!"
	title.position = Vector2(0.0, 100.0)
	title.size = Vector2(1280.0, 70.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var story := Label.new()
	story.text = (
		"In the projection booth of the Grand Marquee Cinema, the search\n" +
		"finally ends — Uncle Doug, safe at last, thanks to the team who\n" +
		"never stopped looking for him."
	)
	story.position = Vector2(0.0, 200.0)
	story.size = Vector2(1280.0, 100.0)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 22)
	story.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	canvas.add_child(story)

	# Character name labels — the colored chips they sit below are drawn in _draw()
	var total_row_w: float = float(CHAR_NAMES.size()) * CHIP_W + float(CHAR_NAMES.size() - 1) * CHIP_SPACING
	var start_x: float = (1280.0 - total_row_w) * 0.5
	for i in CHAR_NAMES.size():
		var name_lbl := Label.new()
		name_lbl.text = CHAR_NAMES[i]
		name_lbl.position = Vector2(start_x + float(i) * (CHIP_W + CHIP_SPACING), CHIP_TOP_Y + CHIP_H + 6.0)
		name_lbl.size = Vector2(CHIP_W, 26.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
		canvas.add_child(name_lbl)

	# Count total collected items across all characters
	var total_items_found: int = 0
	for char_key in GameManager.inventories:
		total_items_found += (GameManager.inventories[char_key] as Array).size()

	var stats := Label.new()
	stats.text = "%d / %d locations cleared    •    %d / %d heroes united    •    %d / %d items found" % [
		GameManager.completed_locations.size(), TOTAL_LOCATIONS,
		GameManager.unlocked_characters.size(), TOTAL_CHARACTERS,
		total_items_found, TOTAL_ITEMS,
	]
	stats.position = Vector2(0.0, 430.0)
	stats.size = Vector2(1280.0, 36.0)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.65, 0.6, 0.9))
	canvas.add_child(stats)

	var thanks := Label.new()
	thanks.text = "Thanks for playing Hunkle Bunkle"
	thanks.position = Vector2(0.0, 490.0)
	thanks.size = Vector2(1280.0, 34.0)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override("font_size", 24)
	thanks.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	canvas.add_child(thanks)

	_press_label = Label.new()
	_press_label.text = "PRESS  ENTER  FOR  THE  TITLE  SCREEN"
	_press_label.position = Vector2(0.0, 575.0)
	_press_label.size = Vector2(1280.0, 40.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 26)
	_press_label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
	canvas.add_child(_press_label)

func _process(delta: float) -> void:
	for mote: Dictionary in _motes:
		var pos: Vector2 = mote["pos"]
		pos.y -= mote["speed"] * delta
		pos.x += mote["drift"] * delta
		if pos.y < -4.0:
			pos.y = 724.0
			pos.x = randf() * 1280.0
		elif pos.x < -4.0 or pos.x > 1284.0:
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

	# Character roster chips — filled rect (darkened) with colored border per character;
	# dimmed if not unlocked (shouldn't happen at endgame, but defensive)
	var total_row_w: float = float(CHAR_NAMES.size()) * CHIP_W + float(CHAR_NAMES.size() - 1) * CHIP_SPACING
	var start_x: float = (1280.0 - total_row_w) * 0.5
	for i in CHAR_NAMES.size():
		var chip_x: float = start_x + float(i) * (CHIP_W + CHIP_SPACING)
		var chip_rect := Rect2(chip_x, CHIP_TOP_Y, CHIP_W, CHIP_H)
		var unlocked: bool = CHAR_NAMES[i] in GameManager.unlocked_characters
		var chip_color: Color = CHAR_COLORS[i] if unlocked else Color(0.3, 0.3, 0.3)
		draw_rect(chip_rect, chip_color.darkened(0.55))
		draw_rect(chip_rect, chip_color, false, 2.5)

	for mote: Dictionary in _motes:
		draw_circle(mote["pos"], mote["size"], Color(0.95, 0.85, 0.45, 0.4))
