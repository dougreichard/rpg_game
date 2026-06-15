extends Level3D
## The Old Parish Church (3D) — dialogue-heavy, NO combat. A nave with Father Aldric
## and four congregation members: two open up to QUINN, two to ERIN, so you must SWAP
## the duo to talk to each. Talk to all four to win (unlocks Evan). Plus Aldric's
## choice dialog and a secret passage. Reuses GameManager flags + DialogBox/DialogTree.

const LOCATION_ID := "old_parish_church"
const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
# DialogBox is provided by Level3D (make_dialog/open_dialog/dialog_input).

const STONE := Color(0.52, 0.50, 0.47)
const FLOOR_COL := Color(0.40, 0.35, 0.30)
const HALF_W := 6.5
const HALF_D := 8.5
const WALL_H := 3.4
const ALDRIC_POS := Vector3(0.0, 0.0, -HALF_D + 1.8)
const LEVER_POS := Vector3(HALF_W - 0.6, 0.0, -HALF_D + 1.6)
const REACH := 2.0

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
var _secret_wall: Node3D = null
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
	build_env(Color(0.06, 0.06, 0.09), Color(0.5, 0.46, 0.42), 0.55, 0.8)
	point_light(Vector3(0, 3.0, -6.0), Color(1.0, 0.85, 0.55), 2.5, 9.0)        # altar
	point_light(Vector3(-HALF_W + 0.5, 2.6, -2.0), Color(0.5, 0.6, 1.0), 1.6, 6.0)  # stained glass
	point_light(Vector3(HALF_W - 0.5, 2.6, 1.0), Color(1.0, 0.5, 0.5), 1.6, 6.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
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
	var p := spawn_duo([QUINN, ERIN], Vector3(0.0, 0.1, HALF_D - 2.0))
	p.special_used.connect(_on_special)

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), STONE)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), STONE)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), STONE)
	wall(Vector3(-HALF_W + 2.0, WALL_H * 0.5, HALF_D), Vector3(4.0, WALL_H, 0.4), STONE)
	wall(Vector3(HALF_W - 2.0, WALL_H * 0.5, HALF_D), Vector3(4.0, WALL_H, 0.4), STONE)
	_secret_wall = StaticBody3D.new()
	(_secret_wall as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, WALL_H, 0.4); cs.shape = bs
	_secret_wall.add_child(cs)
	_secret_wall.add_child(box_mesh(Vector3(2.4, WALL_H, 0.4), STONE, Vector3.ZERO))
	_secret_wall.position = Vector3(HALF_W - 1.2, WALL_H * 0.5, -HALF_D + 0.2)
	add_child(_secret_wall)

func _furnish() -> void:
	prop("res://assets/models/props/altar.glb", Vector3(0, 0, -HALF_D + 1.0))
	prop("res://assets/models/props/candles.glb", Vector3(-1.5, 0, -HALF_D + 1.0))
	prop("res://assets/models/props/candles.glb", Vector3(1.5, 0, -HALF_D + 1.0))
	for row: int in range(4):
		var z: float = -1.0 + float(row) * 2.2
		prop("res://assets/models/props/pew.glb", Vector3(-2.4, 0, z))
		prop("res://assets/models/props/pew.glb", Vector3(2.4, 0, z))
	# lever behind the altar
	add_child(box_mesh(Vector3(0.1, 0.4, 0.1), Color(0.8, 0.2, 0.2), LEVER_POS + Vector3(0, 1.3, 0)))

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
	_npc_mesh("aldric", ALDRIC_POS, deg_to_rad(180))

func _congregant(id: String) -> void:
	var d: Dictionary = CONGREGATION[id]
	_npc_mesh(d["mesh"], d["pos"], deg_to_rad(180))

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if char_name == "Quinn" and not _secret_revealed and _near(pp, LEVER_POS):
		_reveal_secret(); return
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
		"good": {"lines": ["\"A polite sort -- refreshing. They're scattered about the nave; I hope they'll open up.\""],
			"effects": {"set_flag": "father_aldric_impression", "flag_value": "good"}},
		"cool": {"lines": ["Aldric stiffens. \"...He asked after old parish records. My congregation saw more than I did. Ask them.\""],
			"effects": {"set_flag": "father_aldric_impression", "flag_value": "cool"}},
	}
	GameManager.set_level_flag(LOCATION_ID, "manager_met", true)
	open_dialog("Father Aldric", Color(0.55, 0.5, 0.42), tree, char_name)

func _reveal_secret() -> void:
	_secret_revealed = true
	GameManager.set_level_flag(LOCATION_ID, "secret_revealed", true)
	create_tween().tween_property(_secret_wall, "position:y", -WALL_H, 0.6)
	_hud_hint.text = "Behind the altar, the sealed loft grinds open."
	Audio.play("special")

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	_hud_goal = _label(cl, 24, 22)
	_hud_hint = _label(cl, -60, 22); _hud_hint.anchor_top = 1.0; _hud_hint.anchor_bottom = 1.0
	_hud_banner = _label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

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
		GameManager.complete_location(LOCATION_ID)
		_hud_goal.text = ""
		_hud_banner.text = "The congregation opens up.\nEvan joins the search!"
		_hud_banner.visible = true
		Audio.play("puzzle_complete")

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()
