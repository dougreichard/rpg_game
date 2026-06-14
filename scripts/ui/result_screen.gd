extends Node2D

const TOTAL_LOCATIONS: int = 13
const TOTAL_CHARACTERS: int = 5
const TOTAL_ITEMS: int = 29
const MOTE_COUNT: int = 36

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

# Reveal timeline (seconds)
const T_TITLE: float = 0.6
const T_STORY: float = 1.8
const T_CHIPS_START: float = 3.2
const T_CHIPS_STEP: float = 0.38
const T_STATS: float = 5.4
const T_STATS_COUNT_DUR: float = 1.2
const T_THANKS: float = 6.8
const T_ENTER: float = 8.0
const FADE_DUR: float = 0.5

var _time: float = 0.0
var _fully_revealed: bool = false
var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _motes: Array = []

var _title_label: Label = null
var _story_label: Label = null
var _chip_name_labels: Array = []
var _stats_label: Label = null
var _thanks_label: Label = null
var _press_label: Label = null

var _locs_found: int = 0
var _chars_found: int = 0
var _items_found: int = 0

func _ready() -> void:
	_locs_found = GameManager.completed_locations.size()
	_chars_found = GameManager.unlocked_characters.size()
	for char_key in GameManager.inventories:
		_items_found += (GameManager.inventories[char_key] as Array).size()
	Audio.play_music("victory")
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

	_title_label = Label.new()
	_title_label.text = "UNCLE DOUG IS FOUND!"
	_title_label.position = Vector2(0.0, 100.0)
	_title_label.size = Vector2(1280.0, 70.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.modulate = Color(0.95, 0.85, 0.2, 0.0)
	canvas.add_child(_title_label)

	_story_label = Label.new()
	_story_label.text = (
		"In the projection booth of the Grand Marquee Cinema, the search\n" +
		"finally ends  --  Uncle Doug, safe at last, thanks to the team who\n" +
		"never stopped looking for him."
	)
	_story_label.position = Vector2(0.0, 200.0)
	_story_label.size = Vector2(1280.0, 100.0)
	_story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_label.add_theme_font_size_override("font_size", 16)
	_story_label.modulate = Color(0.85, 0.85, 0.92, 0.0)
	canvas.add_child(_story_label)

	var total_row_w: float = float(CHAR_NAMES.size()) * CHIP_W + float(CHAR_NAMES.size() - 1) * CHIP_SPACING
	var start_x: float = (1280.0 - total_row_w) * 0.5
	for i in CHAR_NAMES.size():
		var name_lbl := Label.new()
		name_lbl.text = CHAR_NAMES[i]
		name_lbl.position = Vector2(start_x + float(i) * (CHIP_W + CHIP_SPACING), CHIP_TOP_Y + CHIP_H + 6.0)
		name_lbl.size = Vector2(CHIP_W, 26.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.modulate = Color(0.80, 0.80, 0.90, 0.0)
		canvas.add_child(name_lbl)
		_chip_name_labels.append(name_lbl)

	_stats_label = Label.new()
	_stats_label.text = _stats_text(0, 0, 0)
	_stats_label.position = Vector2(0.0, 430.0)
	_stats_label.size = Vector2(1280.0, 36.0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.modulate = Color(0.65, 0.6, 0.9, 0.0)
	canvas.add_child(_stats_label)

	_thanks_label = Label.new()
	_thanks_label.text = "Thanks for playing Hunkle Bunkle"
	_thanks_label.position = Vector2(0.0, 490.0)
	_thanks_label.size = Vector2(1280.0, 34.0)
	_thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_thanks_label.add_theme_font_size_override("font_size", 24)
	_thanks_label.modulate = Color(0.92, 0.92, 0.92, 0.0)
	canvas.add_child(_thanks_label)

	_press_label = Label.new()
	_press_label.text = "PRESS  ENTER  FOR  THE  TITLE  SCREEN"
	_press_label.position = Vector2(0.0, 575.0)
	_press_label.size = Vector2(1280.0, 40.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 24)
	_press_label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
	_press_label.visible = false
	canvas.add_child(_press_label)

func _stats_text(locs: int, chars: int, items: int) -> String:
	return "%d / %d locations cleared      |    %d / %d heroes united      |    %d / %d items found" % [
		locs, TOTAL_LOCATIONS, chars, TOTAL_CHARACTERS, items, TOTAL_ITEMS,
	]

func _alpha_for(start_t: float) -> float:
	return clampf((_time - start_t) / FADE_DUR, 0.0, 1.0)

func _chip_alpha(i: int) -> float:
	return clampf((_time - (T_CHIPS_START + float(i) * T_CHIPS_STEP)) / FADE_DUR, 0.0, 1.0)

func _chip_scale(i: int) -> float:
	return lerpf(0.4, 1.0, _chip_alpha(i))

func _snap_fully_revealed() -> void:
	_fully_revealed = true
	_title_label.modulate.a = 1.0
	_story_label.modulate.a = 1.0
	for i in CHAR_NAMES.size():
		_chip_name_labels[i].modulate.a = 1.0
	_stats_label.text = _stats_text(_locs_found, _chars_found, _items_found)
	_stats_label.modulate.a = 1.0
	_thanks_label.modulate.a = 1.0
	_press_label.visible = true
	_blink_visible = true

func _process(delta: float) -> void:
	if _fully_revealed:
		_blink_timer += delta
		if _blink_timer >= 0.5:
			_blink_timer = 0.0
			_blink_visible = not _blink_visible
			_press_label.visible = _blink_visible
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
			Audio.play("ui_select")
			TransitionManager.change_scene("res://scenes/ui/TitleScreen.tscn")
		for mote: Dictionary in _motes:
			_tick_mote(mote, delta)
		queue_redraw()
		return

	_time += delta

	# Skip animation on button press — snap to fully revealed
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		Audio.play("ui_select")
		_time = T_ENTER + 0.01
		_snap_fully_revealed()
		for mote: Dictionary in _motes:
			_tick_mote(mote, delta)
		queue_redraw()
		return

	_title_label.modulate.a = _alpha_for(T_TITLE)
	_story_label.modulate.a = _alpha_for(T_STORY)

	for i in CHAR_NAMES.size():
		_chip_name_labels[i].modulate.a = _chip_alpha(i)

	var stats_a: float = _alpha_for(T_STATS)
	_stats_label.modulate.a = stats_a
	var count_t: float = clampf((_time - T_STATS) / T_STATS_COUNT_DUR, 0.0, 1.0)
	_stats_label.text = _stats_text(
		roundi(float(_locs_found) * count_t),
		roundi(float(_chars_found) * count_t),
		roundi(float(_items_found) * count_t),
	)

	_thanks_label.modulate.a = _alpha_for(T_THANKS)

	if _time >= T_ENTER:
		_snap_fully_revealed()

	for mote: Dictionary in _motes:
		_tick_mote(mote, delta)
	queue_redraw()

func _tick_mote(mote: Dictionary, delta: float) -> void:
	var pos: Vector2 = mote["pos"]
	pos.y -= mote["speed"] * delta
	pos.x += mote["drift"] * delta
	if pos.y < -4.0:
		pos.y = 724.0
		pos.x = randf() * 1280.0
	elif pos.x < -4.0 or pos.x > 1284.0:
		pos.x = randf() * 1280.0
	mote["pos"] = pos

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.09, 0.07, 0.05))

	var total_row_w: float = float(CHAR_NAMES.size()) * CHIP_W + float(CHAR_NAMES.size() - 1) * CHIP_SPACING
	var start_x: float = (1280.0 - total_row_w) * 0.5
	for i in CHAR_NAMES.size():
		var a: float = _chip_alpha(i)
		if a <= 0.0:
			continue
		var scale: float = _chip_scale(i)
		var chip_x: float = start_x + float(i) * (CHIP_W + CHIP_SPACING)
		var cx: float = chip_x + CHIP_W * 0.5
		var cy: float = CHIP_TOP_Y + CHIP_H * 0.5
		var hw: float = CHIP_W * scale * 0.5
		var hh: float = CHIP_H * scale * 0.5
		var chip_rect := Rect2(cx - hw, cy - hh, hw * 2.0, hh * 2.0)
		var unlocked: bool = CHAR_NAMES[i].to_lower() in GameManager.unlocked_characters
		var chip_color: Color = CHAR_COLORS[i] if unlocked else Color(0.3, 0.3, 0.3)
		var bg_col: Color = chip_color.darkened(0.55)
		bg_col.a = a
		draw_rect(chip_rect, bg_col)
		var border_col: Color = chip_color
		border_col.a = a
		draw_rect(chip_rect, border_col, false, 2.5)

		# Brief cross-sparkle as chip pops in
		if a > 0.05 and a < 0.6:
			var spark_a: float = sinf(a * PI / 0.6) * 0.85
			var spark_col := Color(1.0, 1.0, 0.8, spark_a)
			var sr: float = CHIP_W * 0.6
			draw_line(Vector2(cx - sr, cy), Vector2(cx + sr, cy), spark_col, 2.0, true)
			draw_line(Vector2(cx, cy - sr * 0.65), Vector2(cx, cy + sr * 0.65), spark_col, 2.0, true)

	for mote: Dictionary in _motes:
		draw_circle(mote["pos"], mote["size"], Color(0.95, 0.85, 0.45, 0.4))
