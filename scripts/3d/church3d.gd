extends Level3D
## The Old Parish Church (3D) — dialogue-heavy, NO combat. Multi-room now: a NAVE
## (lobby — Father Aldric + four congregation members + the choir leader + exit), a
## VESTRY to the east (gated by Quinn's candle-sequence puzzle; holds the memorial
## register — the Uncle Doug objective), and a CRYPT to the west (gated by Erin's
## false-plaque observation puzzle; reuses `secret_revealed`). Two congregants open up
## to QUINN, two to ERIN, so you must SWAP to talk to each. Win = all four (unlocks
## Evan); the vestry/crypt are extra puzzle + Doug content, not required to clear.
## Reuses GameManager flags + DialogBox/DialogTree.

const LOCATION_ID := "old_parish_church"
const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const FlowerItem: ItemData = preload("res://data/items/pressed_flower.tres")
const EvanTicketItem: ItemData = preload("res://data/items/ticket_evan.tres")
const HankyItem: ItemData = preload("res://data/items/embroidered_handkerchief.tres")
# DialogBox is provided by Level3D (make_dialog/open_dialog/dialog_input).

# --- thematic surfaces (church floor / stone walls / dark-wood corner trim) ---
const FLOOR_CHURCH := "res://assets/art/tiles/synty_floor_church.png"
const FLOOR_CARPET := "res://assets/art/tiles/synty_floor_carpet.png"
const FLOOR_CONCRETE := "res://assets/art/tiles/synty_floor_concrete.png"
const WALL_STONE := "res://assets/art/tiles/synty_wall_stone.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const NAVE_FT := Color(0.86, 0.80, 0.70)
const NAVE_WT := Color(0.80, 0.78, 0.74)
const VESTRY_FT := Color(0.74, 0.56, 0.50)
const VESTRY_WT := Color(0.72, 0.58, 0.42)
const CRYPT_FT := Color(0.62, 0.62, 0.64)
const CRYPT_WT := Color(0.60, 0.60, 0.60)
const CORNER_COL := Color(0.20, 0.15, 0.10)   # solid dark-wood trim
const STONE := Color(0.52, 0.50, 0.47)

# Enlarged nave (16x22, was 13x17) with a grand north chancel — organ loft + choir.
const HALF_W := 8.0
const HALF_D := 11.0
const WALL_H := 4.0
const ALDRIC_POS := Vector3(0.0, 0.0, -HALF_D + 3.5)
const REACH := 2.0

# North chancel — organ loft (off to the NW) + choir stalls + the altar centre.
const ALTAR_POS := Vector3(0.0, 0.0, -HALF_D + 2.0)
const ORGAN_POS := Vector3(-4.5, 0.0, -HALF_D + 1.0)   # organ on its dais, NW chancel
const ORGAN_HIT := Vector3(-4.5, 0.0, -HALF_D + 2.6)   # Quinn repairs it from the front
const PIPE_RACKS := [Vector3(-6.6, 0, -HALF_D + 0.7), Vector3(-2.6, 0, -HALF_D + 0.7)]
const CHOIR_STALLS := [Vector3(4.5, 0, -HALF_D + 1.5), Vector3(4.5, 0, -HALF_D + 3.2)]
const NICHE_POS := Vector3(-7.0, 0.0, -HALF_D + 2.2)   # hidden niche revealed when the organ plays

# Candle-sequence puzzle (Quinn) — light 1→2→3 to open the vestry.
const CANDLES := [Vector3(6.7, 0, -2.0), Vector3(6.7, 0, -3.5), Vector3(6.7, 0, -5.0)]
const VESTRY_DOOR := Vector3(10.0, 0, 0.0)
const REGISTER_POS := Vector3(13.5, 0, -2.0)
# Crypt false-plaque puzzle (Erin) — find the forged plaque among three.
const PLAQUES := [Vector3(-6.7, 0, -2.0), Vector3(-6.7, 0, -3.5), Vector3(-6.7, 0, -5.0)]
const FALSE_PLAQUE := 1   # index into PLAQUES — the forged one
const CRYPT_DOOR := Vector3(-10.0, 0, 0.0)
const CRYPT_LORE := Vector3(-13.5, 0, -2.0)

# id -> {pos, mesh, who, flag, name, ok, hint}. Wrong-character "hint" lines
# give a breadcrumb toward a different NPC rather than a flat refusal.
const CONGREGATION := {
	"elder":     {"pos": Vector3(-3.2, 0, -3.0), "mesh": "uncle_doug",    "who": "Quinn",
		"flag": "quinn_npc1_done", "name": "Elder",
		"ok": ["An old man looks up from his hymnal. Sixty years in this pew, at least.\nElder: \"You remind me of how folk used to come to church. Quiet. Respectful.\"",
			"\"The stranger asked after the old parish records. Made my skin crawl. The deacon by the altar saw more than I did.\""],
		"hint": ["The old man glances up from his hymnal, then gently back down.\nElder: \"I don't mean to be rude, dear -- but could you come back with your friend?\""]},
	"deacon":    {"pos": Vector3(3.2, 0, -3.0), "mesh": "bellows",        "who": "Quinn",
		"flag": "quinn_npc2_done", "name": "Deacon",
		"ok": ["A stiff, formal man turns from the candles. He measures you a moment, then nods.\nDeacon: \"You carry yourself well. Unusual these days.\"",
			"\"He left a name in the registry that wasn't his own. Kept glancing at the north wall, above the altar.\""],
		"hint": ["The deacon sizes you up in a glance. \"I appreciate directness -- but not here, not now.\"",
			"\"The choir member by the east pews might be more your speed.\""]},
	"choir":     {"pos": Vector3(-3.2, 0, 1.5), "mesh": "congregant_f",   "who": "Erin",
		"flag": "erin_npc1_done", "name": "Choir Member",
		"ok": ["A young woman near the east pews looks up -- uneasy for weeks.\nChoir Member: \"Finally. Someone who doesn't seem fine with all this.\"",
			"\"I heard a sound in the walls the night he came, near the altar end. The caretaker works the west side -- he saw it.\""],
		"hint": ["The young woman shakes her head gently. \"I appreciate the kind words. I really do.\"",
			"\"But I need someone who thinks something's actually wrong here.\""]},
	"caretaker": {"pos": Vector3(3.2, 0, 1.5), "mesh": "congregant_m",    "who": "Erin",
		"flag": "erin_npc2_done", "name": "Caretaker",
		"ok": ["A practical man in work clothes looks up near the chapel doorway.\nCaretaker: \"Right. You're the one actually asking questions. Good.\"",
			"\"He went up toward the altar end and then -- gone. Like he found something up there the rest of us don't know about.\""],
		"hint": ["The caretaker shrugs at your polite approach. \"No offence -- you look like you'd accept whatever I told you.\"",
			"\"Talk to someone who asks the hard questions.\""]},
}

# Red-herring parishioners: flavor only, no flag, no progress. Reuse meshes.
const RED_HERRINGS := {
	"widow":    {"pos": Vector3(-1.4, 0, -1.2), "mesh": "congregant_f", "name": "Parishioner",
		"lines": ["A woman in dark clothes sits motionless, head bowed.\nParishioner: \"I'm waiting for a sign.\"",
			"Her eyes don't meet yours. She doesn't seem to hear the next question."]},
	"confused": {"pos": Vector3(1.4, 0, 3.2), "mesh": "uncle_doug", "name": "Parishioner",
		"lines": ["An elderly man turns at your approach, cupping one ear.\nParishioner: \"Eh? A dog, you say? Haven't seen any dogs in here since old Father Clement's spaniel, God rest him.\"",
			"\"The roof's been leaking since 1987, you know. Right above the third pew.\"",
			"He nods firmly to himself and turns away."]},
}

# Wandering Choir Leader — atmospheric, non-interactive, barks quips via a floating
# Label3D as he paces the centre aisle. Mirrors the 2D choir leader.
const CL_MESH := "congregant_m"
const CL_SPEED := 1.6
const CL_IDLE_TIME := 2.2
const CL_YELL_MIN := 5.0
const CL_YELL_MAX := 11.0
const CL_BUBBLE_DUR := 3.0
const CL_WAYPOINTS := [Vector3(0, 0, -2.0), Vector3(-0.9, 0, 1.0), Vector3(0.9, 0, 1.0), Vector3(0, 0, 4.5)]
const CL_QUIPS := ["Hands. Pockets. OUT. Am I clear?", "I can see you from here.",
	"Eyes forward! This is a house of worship!", "I said OUT of your pockets, not into mine.",
	"Hands out of your pockets!"]

var _secret_revealed := false
var _cleared := false
var _vestry_wall: Node3D = null
var _crypt_wall: Node3D = null
var _candles_lit := false
var _candle_seq: Array = []
var _candle_flames: Array = []
var _register_read := false
var _organ_played := false
var _niche_wall: Node3D = null
var _niche_box: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

var _cl_node: Node3D = null
var _cl_bubble: Label3D = null
var _cl_anim: AnimationPlayer = null
var _cl_target: int = 0
var _cl_idle: float = 0.0
var _cl_yell: float = 6.0
var _cl_bubble_t: float = 0.0

func _build_level() -> void:
	location_id = LOCATION_ID
	multi_room = true
	music_track = "overworld"   # combat-free, dialogue-heavy → the calmer theme, not combat
	build_env(Color(0.06, 0.06, 0.09), Color(0.5, 0.46, 0.42), 0.55, 0.8)
	point_light(Vector3(0, 3.0, -6.0), Color(1.0, 0.85, 0.55), 2.5, 9.0)        # altar
	point_light(Vector3(-HALF_W + 0.5, 2.6, -2.0), Color(0.5, 0.6, 1.0), 1.6, 6.0)  # stained glass
	point_light(Vector3(HALF_W - 0.5, 2.6, 1.0), Color(1.0, 0.5, 0.5), 1.6, 6.0)
	point_light(VESTRY_DOOR + Vector3(3.5, 2.6, 0), Color(1.0, 0.8, 0.5), 1.6, 7.0)  # vestry
	point_light(CRYPT_DOOR + Vector3(-3.5, 2.6, 0), Color(0.6, 0.7, 0.9), 1.3, 7.0)  # crypt
	_rooms()
	_furnish()
	make_dialog()
	_build_hud()
	_aldric()
	for id: String in CONGREGATION:
		_congregant(id)
	for id: String in RED_HERRINGS:
		var r: Dictionary = RED_HERRINGS[id]
		_npc_mesh(r["mesh"], r["pos"], deg_to_rad(180))
	_create_choir_leader()
	add_exit_portal(Vector3(0, 0, HALF_D + 1.6), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, ERIN], Vector3(0.0, 0.1, HALF_D - 2.0))
	p.special_used.connect(_on_special)
	_restore()

func _rooms() -> void:
	# Nave — church floor, stone walls. Openings: south (entrance), east (vestry),
	# west (crypt). Built as a room with its own floor (no global slab).
	set_theme(FLOOR_CHURCH, WALL_STONE)
	room(Vector3.ZERO, HALF_W * 2.0, HALF_D * 2.0, NAVE_FT, NAVE_WT, WALL_H, ["s", "e", "w"], 3.0, true)
	# entrance vestibule (holds the exit portal)
	set_theme(FLOOR_CHURCH, WALL_STONE)
	corridor(Vector3(0, 0, HALF_D), "s", 2.0, NAVE_FT, NAVE_WT, 3.0, WALL_H, true, CORNER_COL)
	# East corridor → vestry (warm wood sacristy). Threshold sealed by the candle gate.
	corridor(Vector3(HALF_W, 0, 0), "e", 2.0, NAVE_FT, NAVE_WT, 3.0, WALL_H, true, CORNER_COL)
	set_theme(FLOOR_CARPET, WALL_WOOD)
	room(Vector3(13.5, 0, 0), 7, 8, VESTRY_FT, VESTRY_WT, 3.0, ["w"], 3.0, true)
	_vestry_wall = _gate_panel(VESTRY_DOOR, 3.0, "x")
	# West corridor → crypt (cold concrete + stone). Threshold sealed by the false-plaque gate.
	set_theme(FLOOR_CHURCH, WALL_STONE)
	corridor(Vector3(-HALF_W, 0, 0), "w", 2.0, NAVE_FT, NAVE_WT, 3.0, WALL_H, true, CORNER_COL)
	set_theme(FLOOR_CONCRETE, WALL_STONE)
	room(Vector3(-13.5, 0, 0), 7, 7, CRYPT_FT, CRYPT_WT, 2.8, ["e"], 3.0, true)
	_crypt_wall = _gate_panel(CRYPT_DOOR, 2.8, "x")

# A removable doorway panel (matches the wall texture) filling a `gap`-wide opening.
# `axis` "x" = the doorway runs along Z (panel thin in X). Drops out of sight when opened.
func _gate_panel(pos: Vector3, h: float, axis: String) -> Node3D:
	var size := Vector3(0.4, h, 3.0) if axis == "x" else Vector3(3.0, h, 0.4)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, NAVE_WT, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _furnish() -> void:
	prop("res://assets/models/props/altar.glb", ALTAR_POS)
	prop("res://assets/models/props/candles.glb", ALTAR_POS + Vector3(-1.4, 0, 0.3))
	prop("res://assets/models/props/candles.glb", ALTAR_POS + Vector3(1.4, 0, 0.3))
	for row: int in range(6):
		var z: float = -1.0 + float(row) * 2.2
		prop("res://assets/models/props/pew.glb", Vector3(-2.8, 0, z), deg_to_rad(180))  # face the altar (north)
		prop("res://assets/models/props/pew.glb", Vector3(2.8, 0, z), deg_to_rad(180))
	_organ_loft()
	# Candle sconces (Quinn's sequence puzzle) — numbered posts with a hideable flame.
	for i: int in range(CANDLES.size()):
		add_child(box_mesh(Vector3(0.18, 1.0, 0.18), Color(0.85, 0.82, 0.7), CANDLES[i] + Vector3(0, 0.5, 0)))
		var flame := box_mesh(Vector3(0.14, 0.24, 0.14), Color(1.0, 0.7, 0.2), CANDLES[i] + Vector3(0, 1.12, 0), 3.0)
		flame.visible = false
		add_child(flame)
		_candle_flames.append(flame)
		_floating_label(str(i + 1), CANDLES[i] + Vector3(0, 1.6, 0), Color(1.0, 0.85, 0.4))
	# Memorial register on its lectern in the vestry (the Doug objective).
	prop("res://assets/models/props/lectern.glb", REGISTER_POS, PI)
	# Crypt plaques (Erin's observation puzzle) + a lore plaque deeper in.
	for i: int in range(PLAQUES.size()):
		var col: Color = Color(0.7, 0.72, 0.6) if i == FALSE_PLAQUE else Color(0.5, 0.5, 0.52)
		add_child(box_mesh(Vector3(0.12, 0.9, 0.6), col, PLAQUES[i] + Vector3(0, 1.1, 0)))
	add_child(box_mesh(Vector3(0.15, 1.0, 0.7), Color(0.45, 0.42, 0.4), CRYPT_LORE + Vector3(0, 1.1, 0)))

# Organ loft + choir area at the north chancel: the organ on a low dais flanked by tall pipe
# ranks (the 'loft'), choir stalls beside it, and a hidden niche the organ's hymn reveals.
func _organ_loft() -> void:
	add_child(box_mesh(Vector3(4.6, 0.3, 2.2), STONE.lightened(0.06), ORGAN_POS + Vector3(0, 0.15, -0.1)))  # dais
	prop("res://assets/models/props/organ.glb", ORGAN_POS + Vector3(0, 0.3, 0), 0.0)
	for r: Vector3 in PIPE_RACKS:
		prop("res://assets/models/props/pipe_rack.glb", r + Vector3(0, 0.3, 0), 0.0)
	# choir stalls (pews turned to face the centre aisle, west)
	for s: Vector3 in CHOIR_STALLS:
		prop("res://assets/models/props/pew.glb", s, deg_to_rad(-90))
	# hidden niche behind the organ (a removable panel that drops when the hymn plays)
	_niche_wall = box_mesh(Vector3(0.3, 2.0, 1.4), NAVE_WT, NICHE_POS + Vector3(0, 1.0, 0), 0.0, wall_tex)
	add_child(_niche_wall)
	_niche_box = box_mesh(Vector3(0.5, 0.4, 0.5), Color(0.4, 0.3, 0.22), NICHE_POS + Vector3(0, 0.25, 0))
	_niche_box.visible = false
	add_child(_niche_box)

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font = UITheme.font()
	l.font_size = 40
	l.outline_size = 12
	l.modulate = col
	l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.001
	l.position = pos
	add_child(l)

func _npc_mesh(key: String, pos: Vector3, yaw: float) -> Node3D:
	var ps: PackedScene = load("res://assets/models/characters/%s.glb" % key)
	if ps == null:
		return null
	var m := ps.instantiate()
	m.position = pos
	m.rotation.y = yaw
	var ap := _find_in(m)
	if ap != null and ap.has_animation("idle"):
		ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")
	add_child(m)
	return m

func _create_choir_leader() -> void:
	_cl_node = Node3D.new()
	add_child(_cl_node)
	var m := _npc_mesh(CL_MESH, Vector3.ZERO, 0.0)
	if m != null:
		remove_child(m)         # _npc_mesh add_child'd it to the level; reparent under leader
		_cl_node.add_child(m)
		_cl_anim = _find_in(m)
	_cl_node.position = Vector3(0.0, 0.0, 0.5)
	_cl_bubble = Label3D.new()
	_cl_bubble.text = ""
	_cl_bubble.font = UITheme.font()
	_cl_bubble.font_size = 48
	_cl_bubble.outline_size = 16
	_cl_bubble.modulate = UITheme.CREAM
	_cl_bubble.outline_modulate = Color(0, 0, 0, 0.95)
	_cl_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_cl_bubble.no_depth_test = true
	_cl_bubble.fixed_size = true
	_cl_bubble.pixel_size = 0.0011
	_cl_bubble.position = Vector3(0.0, 2.6, 0.0)
	_cl_bubble.visible = false
	_cl_node.add_child(_cl_bubble)

func _update_choir_leader(d: float) -> void:
	if _cl_node == null:
		return
	if _cl_bubble_t > 0.0:
		_cl_bubble_t -= d
		if _cl_bubble_t <= 0.0:
			_cl_bubble.visible = false
	_cl_yell -= d
	if _cl_yell <= 0.0:
		_cl_yell = randf_range(CL_YELL_MIN, CL_YELL_MAX)
		_cl_bubble.text = CL_QUIPS[randi() % CL_QUIPS.size()]
		_cl_bubble.visible = true
		_cl_bubble_t = CL_BUBBLE_DUR
	var tgt: Vector3 = CL_WAYPOINTS[_cl_target]
	var to: Vector3 = tgt - _cl_node.position; to.y = 0.0
	if to.length() < 0.15:
		_cl_idle -= d
		if _cl_idle <= 0.0:
			_cl_idle = CL_IDLE_TIME
			_cl_target = (_cl_target + 1) % CL_WAYPOINTS.size()
		if _cl_anim != null and _cl_anim.current_animation != "idle" and _cl_anim.has_animation("idle"):
			_cl_anim.play("idle")
	else:
		var step: Vector3 = to.normalized() * CL_SPEED * d
		_cl_node.position += step
		_cl_node.get_child(0).rotation.y = atan2(step.x, step.z)
		if _cl_anim != null and _cl_anim.has_animation("walk") and _cl_anim.current_animation != "walk":
			_cl_anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
			_cl_anim.play("walk")

func _find_in(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_in(c)
		if r != null: return r
	return null

func _aldric() -> void:
	_npc_mesh("aldric", ALDRIC_POS, 0.0)   # face the camera/congregation

func _congregant(id: String) -> void:
	var d: Dictionary = CONGREGATION[id]
	_npc_mesh(d["mesh"], d["pos"], deg_to_rad(180))

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	# Candle sequence (Quinn) — opens the vestry
	if not _candles_lit:
		for i: int in range(CANDLES.size()):
			if _near(pp, CANDLES[i]):
				_try_candle(char_name, i); return
	# Crypt false-plaque (Erin) — opens the crypt
	if not _secret_revealed:
		for i: int in range(PLAQUES.size()):
			if _near(pp, PLAQUES[i]):
				_try_plaque(char_name, i); return
	# Organ loft (Quinn repairs the organ → a hymn plays → the hidden niche opens)
	if not _organ_played and _near(pp, ORGAN_HIT):
		_try_organ(char_name); return
	if _organ_played and _niche_box != null and _niche_box.visible and _near(pp, NICHE_POS):
		_take_niche(char_name); return
	# Memorial register (Doug objective)
	if _near(pp, REGISTER_POS):
		_read_register(char_name); return
	if _near(pp, CRYPT_LORE):
		_read_crypt_lore(char_name); return
	if _near(pp, ALDRIC_POS):
		_talk_aldric(char_name); return
	for id: String in CONGREGATION:
		var d: Dictionary = CONGREGATION[id]
		if _near(pp, d["pos"]):
			_talk_congregant(id, char_name); return
	for id: String in RED_HERRINGS:
		var r: Dictionary = RED_HERRINGS[id]
		if _near(pp, r["pos"]):
			open_dialog(r["name"], Color(0.5, 0.5, 0.55), {"start": {"lines": r["lines"]}}, char_name); return

func _near(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < REACH

func _try_candle(char_name: String, i: int) -> void:
	if char_name != "Quinn":
		_hud_hint.text = "These altar candles want a careful, reverent hand — Quinn's touch."
		return
	if _candle_flames[i].visible:
		return
	if i == _candle_seq.size():           # correct next in the 1→2→3 order
		_candle_seq.append(i)
		_candle_flames[i].visible = true
		Audio.play("special")
		if _candle_seq.size() == CANDLES.size():
			_open_vestry()
		else:
			_hud_hint.text = "Candle %d lit. Light them in order." % (i + 1)
	else:                                  # wrong order — gutter them all out
		_candle_seq.clear()
		for f in _candle_flames:
			f.visible = false
		_hud_hint.text = "Out of order — the candles gutter out. Begin with the first."

func _open_vestry() -> void:
	GameManager.set_level_flag(LOCATION_ID, "candles_lit", true)
	create_tween().tween_property(_vestry_wall, "position:y", -3.6, 0.6)
	(_vestry_wall as StaticBody3D).collision_layer = 0
	_hud_hint.text = "The candles hold. The vestry door unlatches to the east."
	Audio.play("puzzle_complete")

func _try_plaque(char_name: String, i: int) -> void:
	if char_name != "Erin":
		_hud_hint.text = "Something's off about these memorial plaques — Erin would spot it."
		return
	if i == FALSE_PLAQUE:
		_reveal_crypt()
	else:
		open_dialog("Memorial Plaque", Color(0.5, 0.5, 0.55),
			{"start": {"lines": ["Erin reads the worn dates and names. \"Genuine. Decades of grime in the lettering.\""]}}, char_name)

func _reveal_crypt() -> void:
	_secret_revealed = true
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)
	create_tween().tween_property(_crypt_wall, "position:y", -3.4, 0.6)
	(_crypt_wall as StaticBody3D).collision_layer = 0
	_hud_hint.text = "Erin: \"This plaque's fresh — the screws aren't even rusted.\" It swings aside; cold air, stairs down to the crypt."
	Audio.play("special")

func _try_organ(char_name: String) -> void:
	if char_name != "Quinn":
		_hud_hint.text = "The old organ's wind-chest is split — Quinn could mend it."
		return
	_organ_played = true
	GameManager.set_level_flag(LOCATION_ID, "organ_played", true)
	if _niche_wall != null:
		create_tween().tween_property(_niche_wall, "position:y", -2.0, 0.6)
		(_niche_wall as MeshInstance3D).visible = true
	if _niche_box != null:
		_niche_box.visible = true
	_hud_hint.text = "Quinn mends the wind-chest and the organ swells into a hymn — a stone niche grinds open behind it."
	Audio.play("special")

func _take_niche(char_name: String) -> void:
	GameManager.set_level_flag(LOCATION_ID, "niche_taken", true)
	GameManager.grant_item(player.active_name(), HankyItem.id)
	if _niche_box != null: _niche_box.visible = false
	open_dialog("Hidden Niche", Color(0.5, 0.48, 0.42),
		{"start": {"lines": [
			"In the niche behind the organ: a folded handkerchief, monogrammed with a looping 'D'.",
			"Someone tucked it here for safekeeping. Doug's, surely.",
			"Picked up: Embroidered Handkerchief."]}}, char_name)
	Audio.play("special")

func _read_register(char_name: String) -> void:
	if _register_read:
		open_dialog("Memorial Register", Color(0.5, 0.5, 0.55),
			{"start": {"lines": ["The register lies open to the marked page — Doug's false name, and the pressed flower."]}}, char_name)
		return
	_register_read = true
	GameManager.set_level_flag(LOCATION_ID, "register_read", true)
	GameManager.grant_item(player.active_name(), FlowerItem.id)
	open_dialog("Memorial Register", Color(0.55, 0.5, 0.42),
		{"start": {"lines": [
			"The vestry register is open on its stand. Most signatures are decades old.",
			"One is fresh: a looping hand signing just the initials \"UD\" — then crossed out, re-signed under a name that isn't his.",
			"A flower is pressed flat against the page, marking it. You take it as a clue.",
			"Picked up: Pressed Flower."]}}, char_name)
	_hud_hint.text = "Doug was here — and didn't want to be found by name."
	Audio.play("special")

func _read_crypt_lore(char_name: String) -> void:
	open_dialog("Crypt Dedication", Color(0.5, 0.5, 0.55),
		{"start": {"lines": [
			"A dedication slab, recently disturbed. Scratched into the dust beneath: an arrow, and a single word.",
			"\"CLOCKTOWER.\" Doug's hand. He was pointing the way before he vanished."]}}, char_name)

func _talk_congregant(id: String, char_name: String) -> void:
	var d: Dictionary = CONGREGATION[id]
	var done: bool = GameManager.get_level_flag(LOCATION_ID, d["flag"], false)
	var lines: Array
	if done:
		lines = ["%s: \"You've already given me more comfort than I've had in weeks. Bless you both.\"" % d["name"]]
	elif char_name == d["who"]:
		lines = d["ok"]
		GameManager.set_level_flag(LOCATION_ID, d["flag"], true)
	else:
		lines = d["hint"]   # wrong character — breadcrumb toward another NPC
	open_dialog(d["name"], Color(0.5, 0.5, 0.55), {"start": {"lines": lines}}, char_name)

func _talk_aldric(char_name: String) -> void:
	var tree := {
		"start": {"lines": [
			"An older priest looks up from the altar candles.",
			"Father Aldric: \"A stranger came through and left my congregation unsettled. Would you speak with them?\""],
			"choices": [
				{"text": "Of course, Father. A kind word costs nothing.", "best_with": "Quinn", "next": "good", "next_alt": "good"},
				{"text": "What aren't you telling us about him?", "best_with": "Erin", "next": "cool", "next_alt": "cool"}]},
		"good": {"lines": ["\"A polite sort -- refreshing. They're scattered about the nave; I hope they'll open up.\"",
			"\"If you'd light the vestry candles in the old order, you're welcome to the records within.\""],
			"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"}},
		"cool": {"lines": ["Aldric stiffens. \"...He asked after old parish records. My congregation saw more than I did. Ask them.\"",
			"\"And mind the memorial plaques in the west aisle. One of them is... newer than it should be.\""],
			"effects": {"set_flag": "father_aldric_impression", "flag_value": "cool"}},
	}
	GameManager.set_level_flag(LOCATION_ID, "manager_met", true)
	open_dialog("Father Aldric", Color(0.55, 0.5, 0.42), tree, char_name)

# --- restore (mid-level persistence) -----------------------------------------
func _restore() -> void:
	if GameManager.get_level_flag(LOCATION_ID, "candles_lit", false):
		_candles_lit = true
		for f in _candle_flames:
			f.visible = true
		_vestry_wall.position.y = -3.6
		(_vestry_wall as StaticBody3D).collision_layer = 0
	if GameManager.get_level_flag(LOCATION_ID, "secret_revealed", false):
		_secret_revealed = true
		_crypt_wall.position.y = -3.4
		(_crypt_wall as StaticBody3D).collision_layer = 0
	_register_read = GameManager.get_level_flag(LOCATION_ID, "register_read", false)
	if GameManager.get_level_flag(LOCATION_ID, "organ_played", false):
		_organ_played = true
		if _niche_wall != null: _niche_wall.position.y = -2.0
		var taken: bool = GameManager.get_level_flag(LOCATION_ID, "niche_taken", false)
		if _niche_box != null: _niche_box.visible = not taken

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon

func _label(cl: CanvasLayer, y: float, size: int) -> Label:
	var l := Label.new()
	l.anchor_left = 0.0; l.anchor_right = 1.0; l.offset_top = y; l.offset_bottom = y + 60
	l.offset_left = 40; l.offset_right = -40
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UITheme.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	cl.add_child(l)
	return l

func _done_count() -> int:
	var n := 0
	for id: String in CONGREGATION:
		if GameManager.get_level_flag(LOCATION_ID, CONGREGATION[id]["flag"], false):
			n += 1
	return n

func _process(_d: float) -> void:
	super._process(_d)
	_update_choir_leader(_d)
	var n := _done_count()
	if not _cleared:
		_hud_goal.text = "Win the congregation over  (%d/4)\nSome open up to Quinn, some to Erin — Tab to swap, G to talk." % n
	if not _cleared and n >= 4:
		_cleared = true
		GameManager.set_level_flag(LOCATION_ID, "quinn_done", true)
		GameManager.set_level_flag(LOCATION_ID, "erin_done", true)
		GameManager.grant_item("Evan", EvanTicketItem.id)   # Evan joins → his Grand Marquee ticket
		GameManager.complete_location(LOCATION_ID)
		_hud_goal.text = ""
		_hud_banner.text = "The congregation opens up.\nEvan joins the search!"
		_hud_banner.visible = true
		Audio.play("puzzle_complete")

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()
