extends Node2D

const LOCS: Array = [
	{
		"id": "pipe_organ_works", "name": "Bellows & Sons Pipe Organ Works",
		"short": "Organ\nWorks", "scene": "res://scenes/levels/PipeOrganWorks.tscn",
		"pos": Vector2(165, 450), "requires": "", "icon": "gear",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "old_parish_church", "name": "The Old Parish Church",
		"short": "Parish\nChurch", "scene": "res://scenes/levels/OldParishChurch.tscn",
		"pos": Vector2(325, 375), "requires": "pipe_organ_works", "icon": "arch",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "iron_strings_gym", "name": "Iron & Strings Gym",
		"short": "Gym", "scene": "res://scenes/levels/IronStringsGym.tscn",
		"pos": Vector2(490, 340), "requires": "old_parish_church", "icon": "dumbbell",
		"duo": ["Quinn", "Evan"],
	},
	{
		"id": "recording_studio", "name": "The Recording Studio",
		"short": "Studio", "scene": "res://scenes/levels/RecordingStudio.tscn",
		"pos": Vector2(665, 375), "requires": "iron_strings_gym", "icon": "note",
		"duo": ["Quinn", "Ben"],
	},
	{
		"id": "clocktower", "name": "The Clocktower",
		"short": "Clock-\ntower", "scene": "res://scenes/levels/Clocktower.tscn",
		"pos": Vector2(595, 205), "requires": "recording_studio", "icon": "clock",
		"duo": ["Quinn", "Ben"],
	},
	{
		"id": "harbor_docks", "name": "The Harbor & Docks",
		"short": "Harbor\n& Docks", "scene": "res://scenes/levels/HarborDocks.tscn",
		"pos": Vector2(900, 470), "requires": "recording_studio", "icon": "anchor",
		"duo": ["Quinn", "Evan"],
	},
	{
		"id": "library", "name": "The Public Library & Archive",
		"short": "Library", "scene": "res://scenes/levels/LibraryArchive.tscn",
		"pos": Vector2(455, 200), "requires": "recording_studio", "icon": "book",
		"duo": ["Erin", "Ethan"],
	},
	{
		"id": "carnival", "name": "The Carnival & Fairground",
		"short": "Carnival", "scene": "res://scenes/levels/Carnival.tscn",
		"pos": Vector2(840, 225), "requires": "recording_studio", "icon": "star",
		"duo": ["Quinn", "Erin"],
	},
	{
		"id": "underground", "name": "The Underground Tunnels",
		"short": "Tunnels", "scene": "res://scenes/levels/UndergroundTunnels.tscn",
		"pos": Vector2(630, 490), "requires": "recording_studio", "icon": "tunnel",
		"duo": ["Evan", "Ethan"],
	},
	{
		"id": "zip_line", "name": "Zip Line Park",
		"short": "Zip Line\nPark", "scene": "res://scenes/levels/ZipLinePark.tscn",
		"pos": Vector2(975, 330), "requires": "recording_studio", "icon": "zipline",
		"duo": ["Ethan", "Ben"],
	},
	{
		"id": "vr_room", "name": "VR Escape Room",
		"short": "VR Room", "scene": "res://scenes/levels/VrEscapeRoom.tscn",
		"pos": Vector2(795, 155), "requires": "recording_studio", "icon": "hex",
		"duo": ["Quinn", "Ethan"],
	},
	{
		"id": "the_drop", "name": "The Drop",
		"short": "The\nDrop", "scene": "res://scenes/levels/TheDrop.tscn",
		"pos": Vector2(385, 155), "requires": "vr_room", "icon": "chevron",
		"duo": ["Evan", "Ethan"],
	},
	{
		"id": "grand_marquee", "name": "The Grand Marquee Cinema",
		"short": "Grand\nMarquee", "scene": "res://scenes/levels/GrandMarqueeCinema.tscn",
		"pos": Vector2(595, 100), "requires": "the_drop", "icon": "film",
		"duo": ["Quinn", "Ben"],
	},
]

const CONNECTIONS: Array = [
	["pipe_organ_works", "old_parish_church"],
	["old_parish_church", "iron_strings_gym"],
	["iron_strings_gym", "recording_studio"],
	["recording_studio", "clocktower"],
	["recording_studio", "harbor_docks"],
	["clocktower", "library"],
	["clocktower", "carnival"],
	["clocktower", "vr_room"],
	["library", "underground"],
	["harbor_docks", "zip_line"],
	["carnival", "zip_line"],
	["vr_room", "the_drop"],
	["the_drop", "grand_marquee"],
	["vr_room", "grand_marquee"],
]

var _id_to_idx: Dictionary = {}
var _cursor_idx: int = 0
var _pulse_time: float = 0.0
var _font: Font
var _name_label: Label
var _status_label: Label

func _ready() -> void:
	_font = ThemeDB.fallback_font
	for i in LOCS.size():
		_id_to_idx[LOCS[i]["id"]] = i
	_build_ui()
	_update_info()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var title := Label.new()
	title.text = "HUNKLE BUNKLE"
	title.position = Vector2(0.0, 8.0)
	title.size = Vector2(1280.0, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
	canvas.add_child(title)

	var map_sub := Label.new()
	map_sub.text = "WORLD MAP"
	map_sub.position = Vector2(0.0, 50.0)
	map_sub.size = Vector2(1280.0, 26.0)
	map_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_sub.add_theme_font_size_override("font_size", 16)
	map_sub.add_theme_color_override("font_color", Color(0.55, 0.5, 0.75))
	canvas.add_child(map_sub)

	var panel := ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.75)
	panel.position = Vector2(0.0, 608.0)
	panel.size = Vector2(1280.0, 112.0)
	canvas.add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(0.0, 614.0)
	_name_label.size = Vector2(1280.0, 46.0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	canvas.add_child(_name_label)

	_status_label = Label.new()
	_status_label.position = Vector2(0.0, 658.0)
	_status_label.size = Vector2(1280.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.68, 0.68, 0.7))
	canvas.add_child(_status_label)

	var hint := Label.new()
	hint.text = "A / D  or  Arrow Keys  --  Navigate     Enter / F  --  Enter Location"
	hint.position = Vector2(0.0, 690.0)
	hint.size = Vector2(1280.0, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
	canvas.add_child(hint)

func _update_info() -> void:
	var loc: Dictionary = LOCS[_cursor_idx]
	_name_label.text = loc["name"]
	if _is_completed(_cursor_idx):
		_status_label.text = "Completed"
		_name_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	elif _is_unlocked(_cursor_idx):
		if loc["scene"] == "":
			_status_label.text = "Unlocked   --   Coming soon"
		else:
			_status_label.text = "Unlocked   --   Press Enter to play"
		_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		var req: String = loc["requires"]
		var req_idx: int = _id_to_idx.get(req, -1)
		var req_name: String = LOCS[req_idx]["name"] if req_idx >= 0 else req
		_status_label.text = "Locked   --   Complete \"" + req_name + "\" first"
		_name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))

func _is_unlocked(idx: int) -> bool:
	var req: String = LOCS[idx]["requires"]
	return req == "" or req in GameManager.completed_locations

func _is_completed(idx: int) -> bool:
	return LOCS[idx]["id"] in GameManager.completed_locations

func _process(delta: float) -> void:
	_pulse_time += delta
	var moved: bool = false
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		_cursor_idx = (_cursor_idx - 1 + LOCS.size()) % LOCS.size()
		moved = true
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		_cursor_idx = (_cursor_idx + 1) % LOCS.size()
		moved = true
	if moved:
		Audio.play("ui_move")
		_update_info()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_launch()
	queue_redraw()

func _launch() -> void:
	var loc: Dictionary = LOCS[_cursor_idx]
	if not _is_unlocked(_cursor_idx):
		_status_label.text = "Locked   --   Complete the previous location first"
		return
	if loc["scene"] == "":
		_status_label.text = "Coming soon!"
		return
	Audio.play("ui_select")
	GameManager.pending_level = loc["scene"]
	GameManager.pending_level_name = loc["name"]
	GameManager.pending_level_duo = loc.get("duo", [])
	GameManager.preferred_active = loc.get("duo", [""])[0]
	TransitionManager.change_scene("res://scenes/ui/CharacterSelect.tscn")

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color(0.05, 0.04, 0.13))

	# Connection lines
	for conn: Array in CONNECTIONS:
		var ai: int = _id_to_idx.get(conn[0], -1)
		var bi: int = _id_to_idx.get(conn[1], -1)
		if ai < 0 or bi < 0:
			continue
		var a_pos: Vector2 = LOCS[ai]["pos"]
		var b_pos: Vector2 = LOCS[bi]["pos"]
		var both_open: bool = _is_unlocked(ai) and _is_unlocked(bi)
		var line_col: Color = Color(0.35, 0.4, 0.55) if both_open else Color(0.17, 0.17, 0.21)
		draw_line(a_pos, b_pos, line_col, 1.5, true)

	# Location nodes
	for i: int in LOCS.size():
		var loc: Dictionary = LOCS[i]
		var p: Vector2 = loc["pos"]
		var dot_col: Color
		if _is_completed(i):
			dot_col = Color(0.22, 0.9, 0.38)
		elif _is_unlocked(i):
			dot_col = Color(0.65, 0.8, 1.0)
		else:
			dot_col = Color(0.2, 0.2, 0.26)
		draw_circle(p, 11.0, dot_col)
		_draw_icon(loc.get("icon", ""), p, Color(0.05, 0.04, 0.13))
		var label_col: Color = dot_col if i != _cursor_idx else Color(1, 1, 1)
		var short: String = loc["short"]
		var lines: PackedStringArray = short.split("\n")
		for li: int in lines.size():
			var ly: float = p.y + 24.0 + li * 12.0
			draw_string(_font, Vector2(p.x - 38.0, ly), lines[li],
					HORIZONTAL_ALIGNMENT_CENTER, 76.0, 10, label_col)

	# Cursor ring
	var cp: Vector2 = LOCS[_cursor_idx]["pos"]
	var pulse_r: float = 15.5 + sin(_pulse_time * 5.0) * 1.8
	draw_arc(cp, pulse_r, 0.0, TAU, 32, Color(1.0, 0.92, 0.3), 2.0, true)

func _draw_icon(kind: String, p: Vector2, color: Color) -> void:
	match kind:
		"gear":
			draw_arc(p, 5.5, 0.0, TAU, 14, color, 2.0, true)
			for i in 6:
				var a: float = TAU * float(i) / 6.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(p + dir * 5.5, p + dir * 8.5, color, 2.0, true)
		"arch":
			draw_arc(p + Vector2(0.0, -1.0), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, -1.0), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, -1.0), p + Vector2(5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(-5.5, 6.0), p + Vector2(5.5, 6.0), color, 2.0)
		"dumbbell":
			draw_circle(p + Vector2(-6.0, 0.0), 3.5, color)
			draw_circle(p + Vector2(6.0, 0.0), 3.5, color)
			draw_line(p + Vector2(-3.5, 0.0), p + Vector2(3.5, 0.0), color, 3.0)
		"note":
			draw_circle(p + Vector2(-3.0, 4.0), 3.0, color)
			draw_line(p + Vector2(0.0, 4.0), p + Vector2(0.0, -6.0), color, 2.0)
			draw_line(p + Vector2(0.0, -6.0), p + Vector2(5.0, -4.0), color, 2.0)
		"clock":
			draw_arc(p, 6.0, 0.0, TAU, 16, color, 2.0, true)
			draw_line(p, p + Vector2(0.0, -3.5), color, 1.5, true)
			draw_line(p, p + Vector2(2.5, 1.5), color, 1.5, true)
		"anchor":
			draw_arc(p + Vector2(0.0, 2.5), 3.5, 0.0, PI, 10, color, 2.0, true)
			draw_line(p + Vector2(0.0, -5.0), p + Vector2(0.0, 2.5), color, 2.0)
			draw_line(p + Vector2(-3.5, -3.0), p + Vector2(3.5, -3.0), color, 2.0)
		"book":
			draw_rect(Rect2(p.x - 5.5, p.y - 4.5, 11.0, 9.0), color, false, 2.0)
			draw_line(p + Vector2(0.0, -4.5), p + Vector2(0.0, 4.5), color, 1.5)
		"star":
			var pts := PackedVector2Array()
			for i in 5:
				var a: float = -PI / 2.0 + TAU * float(i) / 5.0
				pts.append(p + Vector2(cos(a), sin(a)) * 6.5)
			for i in 5:
				draw_line(pts[i], pts[(i + 2) % 5], color, 2.0, true)
		"tunnel":
			draw_arc(p + Vector2(0.0, 2.5), 5.5, PI, TAU, 12, color, 2.0, true)
			draw_line(p + Vector2(-5.5, 2.5), p + Vector2(-5.5, 6.0), color, 2.0)
			draw_line(p + Vector2(5.5, 2.5), p + Vector2(5.5, 6.0), color, 2.0)
		"zipline":
			draw_line(p + Vector2(-6.0, -4.5), p + Vector2(6.0, 4.5), color, 2.0, true)
			draw_circle(p + Vector2(3.5, 2.5), 2.2, color)
		"hex":
			var hpts := PackedVector2Array()
			for i in 6:
				var a2: float = TAU * float(i) / 6.0
				hpts.append(p + Vector2(cos(a2), sin(a2)) * 6.0)
			hpts.append(hpts[0])
			draw_polyline(hpts, color, 2.0, true)
		"chevron":
			draw_line(p + Vector2(-5.5, -2.5), p + Vector2(0.0, 4.5), color, 2.5, true)
			draw_line(p + Vector2(0.0, 4.5), p + Vector2(5.5, -2.5), color, 2.5, true)
		"film":
			draw_rect(Rect2(p.x - 6.0, p.y - 4.5, 12.0, 9.0), color, false, 2.0)
			draw_circle(p + Vector2(-3.5, 0.0), 1.4, color)
			draw_circle(p + Vector2(3.5, 0.0), 1.4, color)
		_:
			pass
