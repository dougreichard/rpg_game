extends Node2D

const GEAR_COUNT: int = 4
const MOTE_COUNT: int = 28

var _press_label: Label
var _blink_timer: float = 0.0
var _blink_visible: bool = true
var _time: float = 0.0

var _gears: Array = []
var _motes: Array = []

func _ready() -> void:
	_build_ui()
	_build_background()

func _build_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var gear_specs: Array = [
		{"pos": Vector2(150.0, 560.0), "radius": 90.0, "teeth": 10, "speed": 0.18},
		{"pos": Vector2(1130.0, 580.0), "radius": 120.0, "teeth": 12, "speed": -0.13},
		{"pos": Vector2(60.0, 130.0), "radius": 60.0, "teeth": 8, "speed": -0.24},
		{"pos": Vector2(1220.0, 110.0), "radius": 75.0, "teeth": 9, "speed": 0.2},
	]
	for spec: Dictionary in gear_specs:
		_gears.append({
			"pos": spec["pos"], "radius": spec["radius"],
			"teeth": spec["teeth"], "speed": spec["speed"], "angle": rng.randf() * TAU,
		})
	for i in MOTE_COUNT:
		_motes.append({
			"pos": Vector2(rng.randf() * 1280.0, rng.randf() * 720.0),
			"speed": rng.randf_range(8.0, 26.0),
			"size": rng.randf_range(1.5, 3.5),
		})

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.position = Vector2(0.0, 190.0)
	title.size = Vector2(1280.0, 110.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var sub := Label.new()
	sub.text = "Find Uncle Doug"
	sub.position = Vector2(0.0, 310.0)
	sub.size = Vector2(1280.0, 40.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.65, 0.6, 0.9))
	canvas.add_child(sub)

	_press_label = Label.new()
	_press_label.text = "PRESS  ENTER"
	_press_label.position = Vector2(0.0, 460.0)
	_press_label.size = Vector2(1280.0, 50.0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 34)
	_press_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	canvas.add_child(_press_label)

	var controls := Label.new()
	controls.text = "WASD Move   F Attack   V Dash   G Special   Tab Swap   B Bies Mode"
	controls.position = Vector2(0.0, 670.0)
	controls.size = Vector2(1280.0, 30.0)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
	canvas.add_child(controls)

func _process(delta: float) -> void:
	_time += delta
	for gear: Dictionary in _gears:
		gear["angle"] += gear["speed"] * delta
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
		get_tree().change_scene_to_file("res://scenes/overworld/OverworldMap.tscn")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.04, 0.13))
	for gear: Dictionary in _gears:
		_draw_gear(gear["pos"], gear["radius"], gear["teeth"], gear["angle"])
	for mote: Dictionary in _motes:
		draw_circle(mote["pos"], mote["size"], Color(0.5, 0.45, 0.75, 0.35))

func _draw_gear(center: Vector2, radius: float, teeth: int, angle: float) -> void:
	var rim_col := Color(0.18, 0.16, 0.3, 0.55)
	draw_arc(center, radius, 0.0, TAU, 48, rim_col, 6.0, true)
	draw_circle(center, radius * 0.22, rim_col)
	var tooth_len: float = radius * 0.18
	for i in teeth:
		var a: float = angle + TAU * float(i) / float(teeth)
		var dir := Vector2(cos(a), sin(a))
		var inner: Vector2 = center + dir * radius
		var outer: Vector2 = center + dir * (radius + tooth_len)
		draw_line(inner, outer, rim_col, 7.0, true)
	for i in 6:
		var a2: float = angle * 1.6 + TAU * float(i) / 6.0
		var spoke_end: Vector2 = center + Vector2(cos(a2), sin(a2)) * radius * 0.7
		draw_line(center, spoke_end, rim_col, 4.0, true)
