extends Level3D
## The Carnival & Fairground (3D) — Quinn + Erin. Multi-room: a combat-free ENTRANCE
## PLAZA (barker Pearl + exit), the MIDWAY (Grunts ×2 + Brute; carousel + photo booth),
## the BACKSTAGE behind Marco's curtain gate (Doug's poster — the lead), and a side
## FUNHOUSE (a lever-sequence prize vault → a library card). Quinn re-belts the carousel
## and fixes the photo booth; Erin talks down Marco (or a backstage pass). Dirt/bright-
## wood surfaces, candy-red trim. Win: midway cleared + ride repaired + backstage opened.

const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const BackstagePassItem: ItemData = preload("res://data/items/backstage_pass.tres")
const LibraryCardItem: ItemData = preload("res://data/items/library_card.tres")
const PhotoStripItem: ItemData = preload("res://data/items/doug_photo_strip.tres")

# --- thematic surfaces (dirt / bright wood / candy-red trim) ---
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const FLOOR_GROUND := "res://assets/art/tiles/synty_ground.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const FT_MID := Color(0.85, 0.72, 0.55)
const WT_MID := Color(0.86, 0.5, 0.55)
const FT_PLAZA := Color(0.82, 0.74, 0.6)
const FT_BACK := Color(0.6, 0.5, 0.55)
const WT_BACK := Color(0.55, 0.3, 0.4)
const CORNER_COL := Color(0.85, 0.18, 0.22)   # solid candy-red trim

const WALL_H := 3.4
const REACH := 2.4

const PLAZA_C := Vector3(0, 0, 13.0)
const PEARL_POS := Vector3(3.5, 0, 14.5)
const RIDE_POS := Vector3(-3.5, 0.0, 0.0)
const PHOTO_POS := Vector3(5.0, 0.0, 3.0)
const MARCO_POS := Vector3(0.0, 0.0, -7.0)
const GATE_POS := Vector3(0.0, 0.0, -8.5)
const BACK_C := Vector3(0, 0, -13.0)
const POSTER_POS := Vector3(0.0, 0.0, -16.5)
const FUN_C := Vector3(-14.0, 0, 0.0)
const FUN_LEVERS := [Vector3(-14.0, 0, -2.0), Vector3(-14.0, 0, 0.0), Vector3(-14.0, 0, 2.0)]
const FUN_VAULT := Vector3(-16.0, 0, 0.0)

const RIDE_COLORS := [Color(0.9, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.3, 0.7, 0.9), Color(0.5, 0.85, 0.4)]

var _cleared := false
var _enemies_cleared := false
var _ride_repaired := false
var _backstage_talked := false
var _photo_taken := false
var _fun_seq: Array = []
var _fun_open := false
var _spawned := 0
var _marco = null
var _pearl = null
var _carousel: Node3D = null
var _gate: Node3D = null
var _fun_lights: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "carnival"
	multi_room = true
	build_env(Color(0.05, 0.04, 0.08), Color(0.55, 0.45, 0.55), 0.6, 0.9)
	point_light(RIDE_POS + Vector3(0, 3.4, 0), Color(1.0, 0.7, 0.8), 2.4, 9.0)
	point_light(PLAZA_C + Vector3(0, 3.0, 0), Color(0.7, 0.8, 1.0), 1.9, 11.0)
	point_light(BACK_C + Vector3(0, 2.8, 0), Color(0.9, 0.5, 0.6), 1.6, 9.0)
	point_light(FUN_C + Vector3(0, 2.6, 0), Color(0.6, 0.9, 0.7), 1.4, 7.0)
	_rooms()
	_carousel_ride()
	_photo_booth()
	_string_lights()
	_stalls()
	_funhouse()
	_backstage()
	make_dialog()
	_build_hud()
	_marco = spawn_npc("bellows", MARCO_POS, PI)     # burly gatekeeper
	_pearl = spawn_npc("congregant_f", PEARL_POS, PI) # plaza barker
	add_exit_portal(PLAZA_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, ERIN], PLAZA_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Midway — dirt floor, bright wood walls. Combat. Openings: south (plaza), north
	# (backstage), west (funhouse).
	set_theme(FLOOR_DIRT, WALL_WOOD)
	room(Vector3.ZERO, 18, 16, FT_MID, WT_MID, WALL_H, ["s", "n", "w"], 3.0, true)
	corridor(Vector3(0, 0, 8), "s", 1.0, FT_MID, WT_MID, 3.0, WALL_H, true, CORNER_COL)         # → plaza
	corridor(Vector3(0, 0, -8), "n", 1.0, FT_MID, WT_MID, 3.0, WALL_H, true, CORNER_COL)        # → backstage
	corridor(Vector3(-9, 0, 0), "w", 1.5, FT_MID, WT_MID, 3.0, WALL_H, true, CORNER_COL)        # → funhouse
	_gate = _backstage_gate()
	# Plaza — ground floor, wood walls (combat-free). South vestibule = exit.
	set_theme(FLOOR_GROUND, WALL_WOOD)
	room(PLAZA_C, 14, 8, FT_PLAZA, WT_MID, 3.2, ["n", "s"], 3.0, true)
	corridor(PLAZA_C + Vector3(0, 0, 4.0), "s", 2.0, FT_PLAZA, WT_MID, 3.0, 3.2, true, CORNER_COL)
	# Backstage — dim, behind the curtain gate.
	set_theme(FLOOR_DIRT, WALL_WOOD)
	room(BACK_C, 12, 8, FT_BACK, WT_BACK, 3.2, ["s"], 3.0, true)
	# Funhouse — the lever-sequence prize room.
	room(FUN_C, 7, 8, FT_MID, WT_MID, 3.0, ["e"], 3.0, true)

# Marco's curtain gate (between midway and backstage), opened by Erin / a backstage pass.
func _backstage_gate() -> Node3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(3.0, 2.8, 0.3); cs.shape = bs; cs.position = Vector3(0, 1.4, 0)
	sb.add_child(cs); sb.add_child(box_mesh(Vector3(3.0, 2.8, 0.3), Color(0.5, 0.1, 0.15), Vector3(0, 1.4, 0)))
	sb.position = GATE_POS
	add_child(sb)
	return sb

func _carousel_ride() -> void:
	_carousel = Node3D.new()
	_carousel.position = RIDE_POS
	add_child(box_mesh(Vector3(4.2, 0.2, 4.2), Color(0.3, 0.2, 0.3), RIDE_POS + Vector3(0, 0.1, 0)))
	add_child(box_mesh(Vector3(0.3, 3.0, 0.3), Color(0.7, 0.6, 0.3), RIDE_POS + Vector3(0, 1.5, 0)))
	var canopy := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.2; cm.bottom_radius = 2.2; cm.height = 0.9
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.25, 0.35)
	cm.material = mat; canopy.mesh = cm; canopy.position = Vector3(0, 3.0, 0)
	_carousel.add_child(canopy)
	for i: int in range(4):
		var a: float = TAU * float(i) / 4.0
		_carousel.add_child(box_mesh(Vector3(0.5, 0.8, 1.0), RIDE_COLORS[i], Vector3(cos(a) * 1.6, 0.9, sin(a) * 1.6)))
		_carousel.add_child(box_mesh(Vector3(0.06, 1.6, 0.06), Color(0.8, 0.8, 0.4), Vector3(cos(a) * 1.6, 1.6, sin(a) * 1.6)))
	add_child(_carousel)

func _photo_booth() -> void:
	add_child(box_mesh(Vector3(1.4, 2.4, 1.4), Color(0.3, 0.25, 0.5), PHOTO_POS + Vector3(0, 1.2, 0)))
	add_child(box_mesh(Vector3(1.0, 1.0, 0.1), Color(0.6, 0.8, 0.9), PHOTO_POS + Vector3(0, 1.4, 0.72), 0.4))  # curtain/screen
	add_child(box_mesh(Vector3(1.5, 0.2, 1.5), Color(0.9, 0.85, 0.4), PHOTO_POS + Vector3(0, 2.5, 0)))

func _string_lights() -> void:
	for i: int in range(10):
		var t: float = float(i) / 9.0
		var x: float = lerp(-8.0, 8.0, t)
		var y: float = 2.6 + 0.5 * sin(t * PI)
		add_child(box_mesh(Vector3(0.12, 0.12, 0.12), RIDE_COLORS[i % RIDE_COLORS.size()], Vector3(x, y, 7.0), 1.6))

func _stalls() -> void:
	for x: float in [-6.5, 6.5]:
		add_child(box_mesh(Vector3(2.4, 1.6, 1.2), Color(0.7, 0.4, 0.5), Vector3(x, 0.8, -5.0)))
		add_child(box_mesh(Vector3(2.6, 0.2, 1.4), Color(0.95, 0.9, 0.85), Vector3(x, 1.7, -5.0)))

func _funhouse() -> void:
	for i: int in range(FUN_LEVERS.size()):
		add_child(box_mesh(Vector3(0.2, 0.8, 0.2), Color(0.3, 0.3, 0.34), FUN_LEVERS[i] + Vector3(0, 0.9, 0)))
		var glow := box_mesh(Vector3(0.12, 0.4, 0.12), Color(0.9, 0.3, 0.3), FUN_LEVERS[i] + Vector3(0, 1.3, 0), 1.5)
		add_child(glow)
		_fun_lights.append(glow)
		_floating_label(str(i + 1), FUN_LEVERS[i] + Vector3(0, 1.7, 0), Color(1.0, 0.8, 0.4))
	add_child(box_mesh(Vector3(0.8, 1.2, 0.8), Color(0.5, 0.4, 0.2), FUN_VAULT + Vector3(0, 0.6, 0)))

func _backstage() -> void:
	add_child(box_mesh(Vector3(1.4, 1.8, 0.1), Color(0.85, 0.8, 0.6), POSTER_POS + Vector3(0, 1.8, 0), 0.3))  # Doug poster

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-1.5, 0.1, 2.0), Vector3(2.0, 0.1, 1.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -1.5), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.7, 0.55, 0.6)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_ride_repaired = GameManager.get_level_flag(location_id, "ride_repaired", false)
	_backstage_talked = GameManager.get_level_flag(location_id, "backstage_talked", false)
	_photo_taken = GameManager.get_level_flag(location_id, "photo_taken", false)
	_fun_open = GameManager.get_level_flag(location_id, "fun_open", false)
	if _backstage_talked: _open_gate(false)
	if _fun_open:
		for f in _fun_lights: f.visible = true
	if _enemies_cleared and _ride_repaired and _backstage_talked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, PEARL_POS, REACH + 0.6):
		_talk_pearl(char_name); return
	if near3(pp, MARCO_POS, REACH):
		_talk_marco(char_name); return
	# carousel (Quinn)
	if not _ride_repaired and near3(pp, RIDE_POS, REACH + 1.0):
		if char_name == "Quinn":
			_ride_repaired = true
			GameManager.set_level_flag(location_id, "ride_repaired", true)
			_hud_hint.text = "Quinn re-belts the motor and winds the band-organ — the carousel spins to life."
			Audio.play("special")
		else:
			_hud_hint.text = "The ride's motor needs Quinn's tools."
		return
	# photo booth (Quinn → Doug strip)
	if not _photo_taken and near3(pp, PHOTO_POS, REACH):
		if char_name == "Quinn":
			_fix_photo(char_name)
		else:
			_hud_hint.text = "The photo booth's jammed — Quinn could coax a print out of it."
		return
	# funhouse lever sequence (optional → library card)
	if not _fun_open:
		for i: int in range(FUN_LEVERS.size()):
			if near3(pp, FUN_LEVERS[i], REACH):
				_try_lever(char_name, i); return

func _talk_pearl(char_name: String) -> void:
	var tree := {"start": {"lines": [
		"A carnival barker leans out of the ticket booth, all teeth and sequins.",
		"Pearl: \"Step right up! Bad news first -- some roughnecks took over the midway and stopped my carousel.\"",
		"\"Quinn, sugar, you look handy -- get my ride spinning, and the photo booth too. Erin, sweet-talk Marco at the curtain.\"",
		"\"And the funhouse? Pull the levers in order and the prize cage pops. Folks always forget the order.\""]}}
	GameManager.set_level_flag(location_id, "pearl_met", true)
	open_dialog("Pearl", Color(0.7, 0.5, 0.6), tree, char_name)

func _fix_photo(char_name: String) -> void:
	_photo_taken = true
	GameManager.set_level_flag(location_id, "photo_taken", true)
	GameManager.grant_item(char_name, PhotoStripItem.id)
	open_dialog("Photo Booth", Color(0.4, 0.35, 0.55),
		{"start": {"lines": [
			"Quinn clears the jam and the booth coughs up a forgotten strip of photos.",
			"Four frames: Uncle Doug, grinning, holding a ticket stub -- \"GRAND MARQUEE, opening night.\"",
			"Picked up: Photo-Booth Strip."]}}, char_name)
	Audio.play("special")

func _try_lever(char_name: String, i: int) -> void:
	if _fun_lights[i].visible:
		return
	if i == _fun_seq.size():
		_fun_seq.append(i)
		_fun_lights[i].visible = true
		Audio.play("special")
		if _fun_seq.size() == FUN_LEVERS.size():
			_fun_open = true
			GameManager.set_level_flag(location_id, "fun_open", true)
			GameManager.grant_item(char_name, LibraryCardItem.id)
			_hud_hint.text = "The prize cage pops open — among the junk, a real library card. (Found Library Card)"
		else:
			_hud_hint.text = "Lever %d set. Pull them 1, 2, 3." % (i + 1)
	else:
		_fun_seq.clear()
		for f in _fun_lights: f.visible = false
		_hud_hint.text = "A buzzer blares — wrong order. The levers reset."

func _talk_marco(char_name: String) -> void:
	if _backstage_talked:
		open_dialog("Marco", Color(0.4, 0.35, 0.3),
			{"start": {"lines": ["\"All right, you're professionals. You can stay.\"", "\"Whatever that poster means to you, I hope you find him.\""]}}, char_name)
		return
	var has_pass := GameManager.has_item("Quinn", BackstagePassItem.id) or GameManager.has_item("Erin", BackstagePassItem.id)
	if has_pass:
		_backstage_talked = true
		GameManager.set_level_flag(location_id, "backstage_talked", true)
		_open_gate(true)
		open_dialog("Marco", Color(0.4, 0.35, 0.3),
			{"start": {"lines": ["You show a backstage pass. Marco waves you through. \"Should've led with that.\""]}}, char_name)
		return
	var tree := {
		"start": {
			"lines": ["\"Backstage is for performers only. You two don't look like performers.\""],
			"choices": [
				{"text": "\"We're totally in the show.\" (Erin fast-talks)", "best_with": "Erin",
					"next": "erin_wins", "next_alt": "blunt_fail"},
				{"text": "\"We need to get backstage. Now.\"", "next": "blunt_fail"}]},
		"erin_wins": {
			"lines": [
				"Erin: \"Look, I'm totally in the show -- Quinn here is my roadie.\"",
				"Marco squints... then his shoulders drop. \"...Roadie. Sure. Don't touch the rigging.\""],
			"effects": {"set_flag": "backstage_talked", "flag_value": true}},
		"blunt_fail": {
			"lines": [
				"Marco crosses his arms. \"Come back with credentials. Both of you.\"",
				"He's not moving. Erin would have to do the talking."],
			"effects": {"set_flag": "marco_impression", "flag_value": "talked"}},
	}
	open_dialog("Marco", Color(0.4, 0.35, 0.3), tree, char_name)

func _open_gate(animate: bool) -> void:
	(_gate as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_gate, "position:y", -3.0, 0.6)
	else:
		_gate.position.y = -3.0

func _on_dialog_closed_default(effects: Array) -> void:
	super._on_dialog_closed_default(effects)
	if not _backstage_talked and GameManager.get_level_flag(location_id, "backstage_talked", false):
		_backstage_talked = true
		_open_gate(true)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	if _ride_repaired and _carousel != null:
		_carousel.rotation.y += d * 0.6
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("midway " + ("OK" if _enemies_cleared else "..."))
		bits.append("ride " + ("OK" if _ride_repaired else "..."))
		bits.append("backstage " + ("OK" if _backstage_talked else "..."))
		_hud_goal.text = "Clear the midway; Quinn fixes the ride, Erin talks past Marco. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _ride_repaired and _backstage_talked:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "CARNIVAL CLEARED!\nThe poster points the way."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
