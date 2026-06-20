extends Level3D
## The Grand Marquee Cinema (3D) — ENDGAME. Quinn + Ben. Multi-room: an ornate combat-free
## GRAND LOBBY (usher Cecil + exit + Doug's clue-board), the AUDITORIUM (Grunts + the
## cinema-guardian Boss; projector, house organ, house-lights), and the PROJECTION BOOTH
## (Uncle Doug), behind a jammed door Quinn forces. Quinn restores the projector + forces
## the booth; Ben plays the organ. With the theatre cleared, both repaired, the booth
## forced, and all five movie tickets, Doug is revealed → Result3D. Carpet/brick, gold trim.
## Win = enemies + projector + organ + booth forced + 5 tickets.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")
const TicketQuinn: ItemData = preload("res://data/items/ticket_quinn.tres")
const TicketErin: ItemData  = preload("res://data/items/ticket_erin.tres")
const TicketEvan: ItemData  = preload("res://data/items/ticket_evan.tres")
const TicketBen: ItemData   = preload("res://data/items/ticket_ben.tres")
const TicketEthan: ItemData = preload("res://data/items/ticket_ethan.tres")

# --- thematic surfaces (red carpet / brick / gold trim) ---
const FLOOR_CARPET := "res://assets/art/tiles/synty_floor_carpet.png"
const WALL_BRICK := "res://assets/art/tiles/synty_wall_brick.png"
const FT_HOUSE := Color(0.7, 0.3, 0.3)
const WT_HOUSE := Color(0.72, 0.5, 0.45)
const FT_LOBBY := Color(0.78, 0.4, 0.4)
const CARPET := Color(0.45, 0.10, 0.12)
const GOLD := Color(0.8, 0.65, 0.25)
const WALL_H := 5.0   # grand cinema ceiling
const REACH := 2.4

# Uncle-Doug clue trail (assembled at the lobby board)
const DOUG_CLUES := ["faded_photograph", "pressed_flower", "doug_locker_tag", "doug_recording",
	"doug_pocketwatch", "doug_crate_tag", "doug_checkout_card", "doug_photo_strip",
	"doug_flashlight", "doug_carabiner", "doug_vr_log", "doug_flyer"]

# Enlarged grand house: auditorium 22x20 at origin, lobby/booth pushed out behind longer halls.
const LOBBY_C := Vector3(0, 0, 20.0)
const USHER_POS := Vector3(3.5, 0, 21.0)
const BOARD_POS := Vector3(-5.5, 0, 21.5)
const PROJECTOR_POS := Vector3(-7.0, 0.0, 7.0)   # projector at the back of the house
const ORGAN_POS := Vector3(6.0, 0.0, -6.0)       # house organ by the stage
const LIGHTS_POS := Vector3(-8.0, 0.0, -5.0)
const BOOTH_DOOR := Vector3(15.0, 0.0, 0.0)
const BOOTH_C := Vector3(20.0, 0.0, 0.0)
const DOUG_POS := Vector3(20.0, 0.0, 0.0)

var _cleared := false
var _enemies_cleared := false
var _projector_repaired := false
var _organ_played := false
var _lights_on := false
var _booth_forced := false
var _doug_revealed := false
var _spawned := 0
var _usher = null
var _doug = null
var _projector_light: MeshInstance3D = null
var _organ_node: MeshInstance3D = null
var _booth_wall: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "grand_marquee"
	multi_room = true
	build_env(Color(0.04, 0.02, 0.03), Color(0.45, 0.30, 0.30), 0.5, 0.8)
	point_light(Vector3(0, 4.2, 0), Color(1.0, 0.85, 0.7), 2.0, 18.0)
	point_light(Vector3(0, 3.0, -9.0), Color(0.9, 0.9, 1.0), 2.2, 9.0)       # screen wash
	point_light(LOBBY_C + Vector3(0, 3.0, 0), Color(1.0, 0.85, 0.6), 2.0, 12.0)
	point_light(BOOTH_C + Vector3(0, 2.6, 0), Color(1.0, 0.9, 0.7), 1.6, 8.0)
	_rooms()
	_screen()
	_seating()
	_projector_booth()
	_organ()
	_lights_rig()
	_clue_board()
	make_dialog()
	_build_hud()
	_usher = spawn_npc("aldric", USHER_POS, PI)   # uniformed chief usher
	_doug = spawn_npc("uncle_doug", DOUG_POS, deg_to_rad(-90))
	_doug.visible = false
	add_exit_portal(LOBBY_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, BEN], LOBBY_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Auditorium — red carpet, brick walls. Combat. Openings: south (lobby), east (booth).
	set_theme(FLOOR_CARPET, WALL_BRICK)
	room(Vector3.ZERO, 22, 20, FT_HOUSE, WT_HOUSE, WALL_H, ["s", "e"], 4.0, true)
	add_child(box_mesh(Vector3(5.0, 0.04, 20.0), CARPET, Vector3(0, 0.05, 0)))     # aisle runner
	corridor(Vector3(0, 0, 10), "s", 4.5, FT_HOUSE, WT_HOUSE, 4.0, WALL_H, true, GOLD)      # → lobby
	corridor(Vector3(11, 0, 0), "e", 4.0, FT_HOUSE, WT_HOUSE, 4.0, WALL_H, true, GOLD)      # → booth
	_booth_wall = _gate_panel(BOOTH_DOOR, WALL_H)
	# Grand lobby — carpet, brick (combat-free). South vestibule = exit.
	set_theme(FLOOR_CARPET, WALL_BRICK)
	room(LOBBY_C, 16, 11, FT_LOBBY, WT_HOUSE, WALL_H, ["n", "s"], 4.0, true)
	corridor(LOBBY_C + Vector3(0, 0, 5.5), "s", 2.0, FT_LOBBY, WT_HOUSE, 4.0, WALL_H, true, GOLD)
	# Projection booth — where Doug is.
	room(BOOTH_C, 10, 8, FT_HOUSE, WT_HOUSE, 3.4, ["w"], 4.0, true)

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(0.4, h, 4.0)   # doorway runs along Z (panel thin in X)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, GOLD.darkened(0.3), Vector3(0, h * 0.5, 0)))
	sb.position = pos
	add_child(sb)
	return sb

func _screen() -> void:
	# big silver screen on the north wall + a proscenium frame of velvet drapes
	add_child(box_mesh(Vector3(10.0, 4.4, 0.2), Color(0.92, 0.92, 0.95), Vector3(0, 2.6, -9.7), 0.5))
	add_child(box_mesh(Vector3(1.0, 4.8, 0.6), CARPET.darkened(0.1), Vector3(-5.4, 2.5, -9.5)))
	add_child(box_mesh(Vector3(1.0, 4.8, 0.6), CARPET.darkened(0.1), Vector3(5.4, 2.5, -9.5)))
	add_child(box_mesh(Vector3(12.0, 0.8, 0.6), GOLD.darkened(0.1), Vector3(0, 4.8, -9.5)))   # proscenium pelmet

func _seating() -> void:
	for row: int in range(5):
		var z: float = -3.5 + float(row) * 1.8
		for sx: float in [-3.2, 3.2]:
			add_child(box_mesh(Vector3(2.2, 0.5, 0.6), Color(0.35, 0.10, 0.12), Vector3(sx, 0.4, z)))
			add_child(box_mesh(Vector3(2.2, 0.8, 0.2), Color(0.30, 0.08, 0.10), Vector3(sx, 0.7, z - 0.35)))

func _projector_booth() -> void:
	add_child(box_mesh(Vector3(2.0, 1.2, 1.2), Color(0.18, 0.10, 0.10), PROJECTOR_POS + Vector3(0, 0.6, 0)))
	add_child(box_mesh(Vector3(0.8, 0.6, 1.0), Color(0.25, 0.25, 0.28), PROJECTOR_POS + Vector3(0, 1.4, 0)))
	_projector_light = box_mesh(Vector3(0.2, 0.2, 0.2), Color(0.7, 0.2, 0.2), PROJECTOR_POS + Vector3(0, 1.4, -0.6), 1.2)
	add_child(_projector_light)

func _organ() -> void:
	var wood := Color(0.30, 0.16, 0.12)
	add_child(box_mesh(Vector3(2.4, 1.4, 0.7), wood, ORGAN_POS + Vector3(0, 0.7, 0)))
	for i: int in range(7):
		var x: float = -0.9 + float(i) * 0.3
		var h: float = 0.8 + 0.5 * sin(float(i))
		var pipe := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.09; cm.bottom_radius = 0.09; cm.height = h
		var mat := StandardMaterial3D.new(); mat.albedo_color = GOLD; mat.metallic = 0.6
		cm.material = mat; pipe.mesh = cm; pipe.position = ORGAN_POS + Vector3(x, 1.6 + h * 0.5, -0.2)
		add_child(pipe)
	_organ_node = box_mesh(Vector3(2.0, 0.08, 0.35), Color(0.9, 0.88, 0.82), ORGAN_POS + Vector3(0, 1.46, 0.3))
	add_child(_organ_node)

func _lights_rig() -> void:
	add_child(box_mesh(Vector3(0.5, 1.4, 0.4), Color(0.2, 0.12, 0.12), LIGHTS_POS + Vector3(0, 0.7, 0)))
	add_child(box_mesh(Vector3(0.16, 0.5, 0.1), Color(0.85, 0.25, 0.2), LIGHTS_POS + Vector3(0.28, 1.0, 0), 1.0))  # dead breaker

func _clue_board() -> void:
	add_child(box_mesh(Vector3(0.2, 2.2, 2.6), Color(0.2, 0.12, 0.12), BOARD_POS + Vector3(0, 1.3, 0)))
	add_child(box_mesh(Vector3(0.1, 1.8, 2.2), Color(0.85, 0.8, 0.6), BOARD_POS + Vector3(0.12, 1.3, 0), 0.3))  # pinned papers

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, 2.0), Vector3(2.5, 0.1, 1.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BOSS, Vector3(0.0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb", 1.9, Color(0.5, 0.2, 0.25)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_projector_repaired = GameManager.get_level_flag(location_id, "projector_repaired", false)
	_organ_played = GameManager.get_level_flag(location_id, "organ_played", false)
	_lights_on = GameManager.get_level_flag(location_id, "lights_on", false)
	_booth_forced = GameManager.get_level_flag(location_id, "booth_forced", false)
	if _projector_repaired: _set_projector_solved()
	if _organ_played: _organ_node.material_override = _glow()
	if _booth_forced: _open_booth(false)
	_maybe_reveal_doug()
	if _all_done():
		_win(false)

func _has_all_tickets() -> bool:
	var chars := ["Quinn", "Erin", "Evan", "Ben", "Ethan"]
	for item: ItemData in [TicketQuinn, TicketErin, TicketEvan, TicketBen, TicketEthan]:
		var held := false
		for ch: String in chars:
			if GameManager.has_item(ch, item.id):
				held = true; break
		if not held:
			return false
	return true

func _all_done() -> bool:
	return _enemies_cleared and _projector_repaired and _organ_played and _booth_forced and _has_all_tickets()

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if _doug_revealed and near3(pp, DOUG_POS, REACH): _talk_doug(char_name); return
	if near3(pp, USHER_POS, REACH): _talk_usher(char_name); return
	if near3(pp, BOARD_POS, REACH): _read_board(char_name); return
	# projector (Quinn)
	if char_name == "Quinn" and not _projector_repaired and near3(pp, PROJECTOR_POS, REACH):
		_projector_repaired = true
		GameManager.set_level_flag(location_id, "projector_repaired", true)
		_set_projector_solved()
		_hud_hint.text = "Quinn restores the projector — the screen flickers to life."
		Audio.play("special"); _maybe_reveal_doug(); return
	# organ (Ben)
	if char_name == "Ben" and not _organ_played and near3(pp, ORGAN_POS, REACH):
		_organ_played = true
		GameManager.set_level_flag(location_id, "organ_played", true)
		_organ_node.material_override = _glow()
		_hud_hint.text = "Ben plays the house organ — the theatre swells with sound."
		Audio.play("special"); _maybe_reveal_doug(); return
	# house-lights circuit (Quinn, optional flavour)
	if char_name == "Quinn" and not _lights_on and near3(pp, LIGHTS_POS, REACH):
		_lights_on = true
		GameManager.set_level_flag(location_id, "lights_on", true)
		point_light(Vector3(0, 4.4, 2.0), GOLD, 2.2, 20.0)
		_hud_hint.text = "Quinn throws the house-lights breaker — the chandeliers blaze back on."
		Audio.play("special"); return
	# jammed booth door (Quinn forces it open → the way to Doug)
	if not _booth_forced and near3(pp, BOOTH_DOOR, REACH + 0.6):
		if char_name == "Quinn":
			_booth_forced = true
			GameManager.set_level_flag(location_id, "booth_forced", true)
			_open_booth(true)
			_hud_hint.text = "Quinn pries the jammed booth door open — a stairway up to the projection booth."
			Audio.play("special"); _maybe_reveal_doug()
		else:
			_hud_hint.text = "The booth door's jammed solid — Quinn can force it."
		return
	# wrong-character hints
	if char_name != "Quinn" and not _projector_repaired and near3(pp, PROJECTOR_POS, REACH):
		_hud_hint.text = "The projector needs Quinn's tools."
	elif char_name != "Ben" and not _organ_played and near3(pp, ORGAN_POS, REACH):
		_hud_hint.text = "The house organ needs Ben."

func _open_booth(animate: bool) -> void:
	(_booth_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_booth_wall, "position:y", -WALL_H, 0.6)
	else:
		_booth_wall.position.y = -WALL_H

func _maybe_reveal_doug() -> void:
	if _doug_revealed:
		return
	if _all_done():
		_doug_revealed = true
		_doug.visible = true
		_doug.call("say", "You found me!")
		_hud_hint.text = "Uncle Doug is here — in the projection booth!"

func _read_board(char_name: String) -> void:
	var n := 0
	for id: String in DOUG_CLUES:
		for ch: String in ["Quinn", "Erin", "Evan", "Ben", "Ethan"]:
			if GameManager.has_item(ch, id):
				n += 1; break
	var lines: Array
	if n >= DOUG_CLUES.size():
		lines = ["You pin the last clue to the board. Photo, flower, watch, reel, flyer -- every thread.",
			"They all point to one place, one night: here, the Grand Marquee. He's behind that booth door.",
			"Doug's trail: %d/%d clues -- complete." % [n, DOUG_CLUES.size()]]
	elif n > 0:
		lines = ["A cork board of pinned notes and photos -- the trail you've gathered chasing Uncle Doug.",
			"Every clue you've found circles back to this theatre.",
			"Doug's trail: %d/%d clues gathered." % [n, DOUG_CLUES.size()]]
	else:
		lines = ["An empty cork board by the door. \"PIN YOUR LEADS HERE,\" reads a faded card.",
			"You haven't gathered any of Doug's clues yet -- they're scattered across town."]
	open_dialog("Doug's Clue-Board", GOLD, {"start": {"lines": lines}}, char_name)

func _set_projector_solved() -> void:
	var m := (_projector_light.mesh as BoxMesh).material as StandardMaterial3D
	m.albedo_color = Color(0.4, 1.0, 0.6); m.emission = Color(0.4, 1.0, 0.6)

func _glow() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 1.0, 0.6); m.emission_enabled = true; m.emission = Color(0.4, 1.0, 0.5); m.emission_energy_multiplier = 1.5
	return m

func _talk_usher(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared:
		tree = {"start": {"lines": [
			"\"Quite a performance.\" Cecil straightens his pillbox hat.",
			"\"The booth's through the east doors -- jammed, I'm afraid. And do pin your leads to the board.\""]}}
	else:
		tree = {
			"start": {
				"lines": [
					"\"Welcome to the Grand Marquee. I'm Cecil -- chief usher.\" He sweeps his torch toward the house.",
					"\"Rough night for a visit. Something's very wrong in the auditorium.\""],
				"choices": [
					{"text": "\"What's in the auditorium?\"", "next": "guardian_hint"},
					{"text": "\"Where's the projection booth?\"", "next": "booth_hint"}]},
			"guardian_hint": {"lines": [
				"\"A guardian machine took the aisle. Clear it, fix the projector, and have Ben wake the organ.\"",
				"\"You'll want all five tickets, too -- the booth won't open its secret otherwise.\""],
				"effects": {"set_flag": "usher_met", "flag_value": true}},
			"booth_hint": {"lines": [
				"\"East doors, up the stairs -- but they've jammed. Quinn could force them.\"",
				"\"Whoever was up there left in a hurry.\""],
				"effects": {"set_flag": "usher_met", "flag_value": true}},
		}
	open_dialog("Cecil", GOLD, tree, char_name)

func _talk_doug(char_name: String) -> void:
	var tree := {
		"start": {
			"lines": ["\"I knew you'd find me. Took you long enough -- I've been running this projector for three days.\""],
			"choices": [
				{"text": "\"What happened to you?\"", "next": "what_happened"},
				{"text": "\"We need to go. Now.\"", "next": "farewell"}]},
		"what_happened": {"lines": [
			"\"The Consortium locked me in here. They didn't want anyone to see what's on that reel.\"",
			"\"There's evidence of everything they've been doing. All of it. Right here.\""],
			"next": "farewell"},
		"farewell": {"lines": ["\"Let's get out of here before they send more. I'll explain everything on the way.\""],
			"effects": {"set_flag": "doug_talked", "flag_value": true}},
	}
	open_dialog("Uncle Doug", Color(0.70, 0.63, 0.48), tree, char_name)

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
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_maybe_reveal_doug()
	if not _cleared:
		var bits := []
		bits.append("guardian " + ("OK" if _enemies_cleared else "..."))
		bits.append("projector " + ("OK" if _projector_repaired else "..."))
		bits.append("organ " + ("OK" if _organ_played else "..."))
		bits.append("booth " + ("OK" if _booth_forced else "..."))
		bits.append("tickets " + ("5/5" if _has_all_tickets() else "?/5"))
		_hud_goal.text = "Clear the guardian; Quinn fixes the projector + forces the booth, Ben plays the organ. All 5 tickets to find Doug. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
	if not _cleared and _all_done():
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_doug.visible = true
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "UNCLE DOUG FOUND!\nThe search is over.  ★ THE END ★"
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
		# roll to the endgame/result screen after a celebratory beat
		get_tree().create_timer(4.5).timeout.connect(func() -> void:
			if is_inside_tree():
				get_tree().change_scene_to_file("res://scenes/3d/Result3D.tscn"))
