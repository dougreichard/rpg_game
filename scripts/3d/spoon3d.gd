extends Node3D
## Gimme Dat Spoon — 3D set-piece (interactive + broadcast presentation).
## Six leads seated round a table running the REAL SpoonGame. The camera JUMP-CUTS
## across the table to whoever's turn it is, then slowly DOLLIES in (poker-broadcast
## feel). The player controls ONE seat — their active lead — and on that turn the
## camera holds while they pick a spoon from a scrollable list. Everyone else is AI.
## A poker-style lower-third shows the active player + spoon count, and a PiP
## "announcer" gives run-aware colour commentary.

const SpoonGameScript: Script = preload("res://scripts/systems/spoon_game.gd")
const SEAT_KEYS: Array = ["quinn", "erin", "evan", "ben", "ethan", "uncle_doug"]
const SEAT_NAMES: Array = ["Quinn", "Erin", "Evan", "Ben", "Ethan", "Uncle Doug"]
const SEAT_COL: Array = [Color(0.55,0.6,0.95), Color(0.95,0.5,0.5), Color(0.55,0.85,0.55),
	Color(0.95,0.8,0.4), Color(0.6,0.85,0.95), Color(0.85,0.7,0.5)]
const RING_R: float = 1.75
const SEAT_Y: float = -0.35
const TABLE_GLB := "res://assets/models/props/table.glb"
const CHAIR_GLB := "res://assets/models/props/chair.glb"
const DOLLY_TIME: float = 0.8       # slow dolly-in after each jump cut
const AI_BEAT: float = 1.4          # how long to hold on an AI seat before it acts
const SPOON_LABEL := {"standard": "Standard Spoon", "anchor": "Anchor Spoon",
	"magnet": "Magnet Spoon", "spinner": "Spinner Spoon", "switch": "Switch Spoon",
	"reverse": "Reverse Spoon", "anchorless": "Anchorless Spoon"}

enum St { CUT, AI_WAIT, HUMAN, OVER }

var _game = null
var _cam: Camera3D = null
var _seat_pos: Array = []
var _seat_char: Array = []
var _alive: Array = []
var _human_seat: int = 0
var _state: int = St.CUT
var _timer: float = 0.0
var _pending: Dictionary = {}        # begin_turn() result for the human
var _shot_frames: int = -1

# HUD
var _lt_name: Label = null           # lower-third
var _lt_count: Label = null
var _lt_panel: Panel = null
var _ann_text: Label = null          # announcer commentary
var _sel_panel: Panel = null         # human spoon selection
var _sel_list: VBoxContainer = null
var _sel_title: Label = null
var _banner: Label = null

func _ready() -> void:
	_build_env()
	_floor()
	_prop(TABLE_GLB, Vector3.ZERO, 0.0)
	for i: int in range(SEAT_KEYS.size()):
		var ang: float = TAU * float(i) / float(SEAT_KEYS.size())
		var pos := Vector3(sin(ang) * RING_R, 0.0, cos(ang) * RING_R)
		_seat_pos.append(pos)
		_alive.append(true)
		var face_center: float = atan2(-pos.x, -pos.z)
		_prop(CHAIR_GLB, pos, face_center)
		_seat_char.append(_seat_character(SEAT_KEYS[i], pos, face_center))
	_cam = Camera3D.new()
	_cam.current = true
	add_child(_cam)
	_human_seat = _resolve_human_seat()
	_build_hud()
	_start_game()
	if "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_shot_frames = 90

# The player controls their active lead (the duo's lead from the last level); Doug
# and the other leads are AI. Falls back to Quinn.
func _resolve_human_seat() -> int:
	var key := "quinn"
	if GameManager.last_level_duo.size() > 0:
		key = String(GameManager.last_level_duo[0]).to_lower()
	var idx: int = SEAT_KEYS.find(key)
	return idx if idx >= 0 else 0

func _build_env() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(30.0), 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var key := OmniLight3D.new()
	key.position = Vector3(0, 3.2, 0)
	key.light_color = Color(1.0, 0.92, 0.78)
	key.light_energy = 2.5
	key.omni_range = 8.0
	add_child(key)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.46, 0.42)
	env.ambient_light_energy = 0.5
	we.environment = env
	add_child(we)

func _floor() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.26, 0.23)
	mat.roughness = 1.0
	pm.material = mat
	mi.mesh = pm
	add_child(mi)

func _prop(path: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		return
	var n := ps.instantiate()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)

func _seat_character(key: String, pos: Vector3, yaw: float) -> Node3D:
	var ps: PackedScene = load("res://assets/models/characters/%s.glb" % key)
	if ps == null:
		return null
	var n := ps.instantiate()
	n.position = pos + Vector3(0.0, SEAT_Y, 0.0)
	n.rotation.y = yaw
	add_child(n)
	var ap := _find_anim(n)
	if ap != null and ap.has_animation("sit"):
		ap.play("sit")
	return n

func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

# --- HUD ---------------------------------------------------------------------
func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	# Poker-style lower-third (bottom-left): coloured chip + name + spoon count.
	_lt_panel = Panel.new()
	_lt_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_lt_panel.position = Vector2(24, -96); _lt_panel.size = Vector2(360, 72)
	_lt_panel.add_theme_stylebox_override("panel", UITheme.panel_box())
	cl.add_child(_lt_panel)
	_lt_name = _mk(_lt_panel, Vector2(16, 8), 26, UITheme.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 320)
	_lt_count = _mk(_lt_panel, Vector2(16, 40), 18, UITheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 320)
	# PiP announcer (top-right): framed "broadcast" box + commentary.
	var ann := Panel.new()
	ann.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ann.position = Vector2(-372, 24); ann.size = Vector2(348, 116)
	ann.add_theme_stylebox_override("panel", UITheme.panel_box())
	cl.add_child(ann)
	var mic := _mk(ann, Vector2(14, 6), 16, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 320)
	mic.text = "🎙  ON THE CALL"
	_ann_text = _mk(ann, Vector2(14, 32), 16, UITheme.CREAM, HORIZONTAL_ALIGNMENT_LEFT, 320)
	_ann_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ann_text.size = Vector2(320, 76)
	_ann_text.text = "\"Welcome to the rooftop, folks — six players, one spoon to rule 'em.\""
	# Big win banner (centre).
	_banner = _mk(cl, Vector2(0, 0), 48, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 0)
	_banner.set_anchors_preset(Control.PRESET_CENTER); _banner.anchor_left = 0.0; _banner.anchor_right = 1.0
	_banner.visible = false
	# Human spoon-selection panel (bottom-centre) with a scrollable list.
	_sel_panel = Panel.new()
	_sel_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sel_panel.position = Vector2(-220, -300); _sel_panel.size = Vector2(440, 280)
	_sel_panel.add_theme_stylebox_override("panel", UITheme.panel_box())
	cl.add_child(_sel_panel)
	_sel_title = _mk(_sel_panel, Vector2(16, 10), 20, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 408)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 46); scroll.size = Vector2(408, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sel_panel.add_child(scroll)
	_sel_list = VBoxContainer.new()
	_sel_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sel_list.custom_minimum_size = Vector2(388, 0)
	scroll.add_child(_sel_list)
	_sel_panel.visible = false

func _mk(parent: Node, pos: Vector2, size: int, col: Color, align: int, width: float) -> Label:
	var l := Label.new()
	l.position = pos
	if width > 0: l.size = Vector2(width, size + 12)
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l

# --- Game flow ---------------------------------------------------------------
func _start_game() -> void:
	var colors: Array = []
	for c in SEAT_COL:
		colors.append(c)
	_game = SpoonGameScript.new()
	_game.spoon_passed.connect(_on_pass)
	_game.power_activated.connect(_on_power)
	_game.player_eliminated.connect(_on_elim)
	_game.game_over.connect(_on_over)
	_game.turn_changed.connect(_on_turn)
	_game.start(SEAT_NAMES.duplicate(), colors)
	_begin_turn_for(_game.active_idx)

func _begin_turn_for(idx: int) -> void:
	_update_lower_third(idx)
	_cut_to(idx)
	if idx == _human_seat and _alive[idx]:
		# wait for the dolly, then hand control to the player
		_state = St.CUT
		_timer = DOLLY_TIME
	else:
		_state = St.CUT
		_timer = DOLLY_TIME + AI_BEAT

func _on_turn(idx: int) -> void:
	if _state == St.OVER:
		return
	_begin_turn_for(idx)

func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			if _state == St.CUT:
				if _game != null and _game.active_idx == _human_seat and _alive[_human_seat]:
					_open_selection()
				elif _game != null:
					_game.take_ai_turn()
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png("res://_arena3d_shot.png")
			print("SHOT_SAVED")
			get_tree().quit()

func _update_lower_third(idx: int) -> void:
	_lt_name.add_theme_color_override("font_color", SEAT_COL[idx] if idx == _human_seat else UITheme.GOLD)
	var tag := "  (you)" if idx == _human_seat else ""
	_lt_name.text = "%s%s" % [SEAT_NAMES[idx], tag]
	var n: int = _game.players[idx]["hand"].size() if _game != null else 0
	_lt_count.text = "Spoons in hand: %d" % n

# --- Human selection ---------------------------------------------------------
func _open_selection() -> void:
	_state = St.HUMAN
	_pending = _game.begin_turn()
	for c in _sel_list.get_children():
		c.queue_free()
	var hand: Array = _game.players[_human_seat]["hand"]
	if _pending.get("discard", false):
		_sel_title.text = "You rolled a 6 — discard a spoon to the middle"
		for sp: String in hand:
			_add_spoon_button("Discard %s" % SPOON_LABEL.get(sp, sp), sp, false, true)
	else:
		var to: int = _pending["recipient_idx"]
		_sel_title.text = "You rolled %d — pass to %s" % [_pending["roll"], SEAT_NAMES[to]]
		for sp: String in hand:
			if sp in SpoonGameScript.POWER_TYPES:
				_add_spoon_button("Pass %s" % SPOON_LABEL.get(sp, sp), sp, false, false)
				_add_spoon_button("PLAY %s!" % SPOON_LABEL.get(sp, sp), sp, true, false)
			else:
				_add_spoon_button("Pass %s" % SPOON_LABEL.get(sp, sp), sp, false, false)
	_sel_panel.visible = true

func _add_spoon_button(text: String, spoon: String, activate: bool, discard: bool) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_override("font", UITheme.font())
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func() -> void: _resolve_human(spoon, activate, discard))
	_sel_list.add_child(b)

func _resolve_human(spoon: String, activate: bool, discard: bool) -> void:
	_sel_panel.visible = false
	if discard:
		_game.resolve_discard(spoon)
	else:
		_game.resolve_turn(spoon, activate)

# --- Game events -------------------------------------------------------------
func _on_pass(from_idx: int, _to_idx: int, spoon_type: String) -> void:
	if from_idx == _human_seat:
		_say(_human_commentary())
	_update_lower_third(_game.active_idx if _game != null else from_idx)

func _on_power(idx: int, spoon_type: String) -> void:
	_say("\"%s drops the %s — what a move!\"" % [SEAT_NAMES[idx], SPOON_LABEL.get(spoon_type, spoon_type)])
	CombatFX.shake(0.2)

func _on_elim(idx: int) -> void:
	_alive[idx] = false
	_say("\"%s is OUT! Brutal.\"" % SEAT_NAMES[idx])
	var ch: Node3D = _seat_char[idx]
	if ch != null:
		var tw := create_tween()
		tw.tween_property(ch, "rotation:x", deg_to_rad(30.0), 0.4)
		for mi in ch.find_children("*", "MeshInstance3D"):
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.4, 0.4, 0.42)
			(mi as MeshInstance3D).material_override = m

func _on_over(winner_idx: int) -> void:
	_state = St.OVER
	_timer = 0.0
	_sel_panel.visible = false
	if winner_idx == _human_seat:
		_banner.text = "YOU WIN THE SPOON!"
	elif winner_idx >= 0:
		_banner.text = "%s wins the spoon!" % SEAT_NAMES[winner_idx]
	else:
		_banner.text = "The middle takes it!"
	_banner.visible = true
	if winner_idx >= 0:
		_cut_to(winner_idx, true)
		GameManager.spoon_game_won.emit()

# Run-aware colour commentary for the human's plays.
func _human_commentary() -> String:
	var pool: Array = [
		"\"%s plays it cool — you don't clear %d locations without nerves like that.\"" % [SEAT_NAMES[_human_seat], GameManager.completed_locations.size()],
		"\"That's the hands that fixed half this town, folks.\"",
		"\"%s keeps the power spoons close — smart, real smart.\"" % SEAT_NAMES[_human_seat],
		"\"Cooler under pressure than a Bies-mode dodge!\"",
		"\"The crowd loves it!\"",
	]
	return pool[randi() % pool.size()]

func _say(text: String) -> void:
	if _ann_text != null:
		_ann_text.text = text

# --- Camera: JUMP CUT across the table, then slow DOLLY in -------------------
func _cut_to(seat: int, hero: bool = false) -> void:
	var sp: Vector3 = _seat_pos[seat]
	var look: Vector3 = sp + Vector3(0.0, 0.95, 0.0)
	var n: Vector3 = sp.normalized()
	var far: Vector3 = -n * (RING_R + (2.6 if hero else 3.4)) + Vector3(0.0, 2.8, 0.0)
	var near: Vector3 = -n * (RING_R + (1.5 if hero else 1.9)) + Vector3(0.0, 2.3, 0.0)
	_cam.global_position = far                 # hard jump cut
	_cam.look_at(look, Vector3.UP)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(t: float) -> void:
		_cam.global_position = far.lerp(near, t)
		_cam.look_at(look, Vector3.UP), 0.0, 1.0, DOLLY_TIME)
