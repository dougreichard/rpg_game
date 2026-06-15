extends Level3D
## The Grand Marquee Cinema (3D) — ENDGAME. Quinn + Ben. A cinema-guardian Boss and
## grunts hold the aisle. Quinn repairs the projection booth; Ben plays the house
## organ on the balcony. With the theatre cleared, both repaired, and all five
## character movie tickets in hand, Uncle Doug is revealed in the projection booth.
## Cecil the usher greets from the lobby. Win = enemies + projector + organ + 5 tickets.

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")
const TicketQuinn: ItemData = preload("res://data/items/ticket_quinn.tres")
const TicketErin: ItemData  = preload("res://data/items/ticket_erin.tres")
const TicketEvan: ItemData  = preload("res://data/items/ticket_evan.tres")
const TicketBen: ItemData   = preload("res://data/items/ticket_ben.tres")
const TicketEthan: ItemData = preload("res://data/items/ticket_ethan.tres")

const FLOOR_COL := Color(0.18, 0.08, 0.10)
const WALL_COL := Color(0.26, 0.12, 0.14)
const CARPET := Color(0.45, 0.10, 0.12)
const GOLD := Color(0.8, 0.65, 0.25)
const HALF_W := 8.0
const HALF_D := 9.5
const WALL_H := 4.0
const PROJECTOR_POS := Vector3(-5.0, 0.0, HALF_D - 2.2)   # booth at the back by the entrance
const ORGAN_POS := Vector3(5.0, 0.0, -HALF_D + 2.2)       # organ down by the screen/balcony
const DOUG_POS := Vector3(-5.0, 0.0, HALF_D - 3.4)
const USHER_POS := Vector3(0.0, 0.0, HALF_D - 2.6)
const REACH := 2.4

var _cleared := false
var _enemies_cleared := false
var _projector_repaired := false
var _organ_played := false
var _doug_revealed := false
var _spawned := 0
var _usher = null
var _doug = null
var _projector_light: MeshInstance3D = null
var _organ_node: MeshInstance3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "grand_marquee"
	build_env(Color(0.04, 0.02, 0.03), Color(0.45, 0.30, 0.30), 0.5, 0.8)
	point_light(Vector3(0, 4.2, 0), Color(1.0, 0.85, 0.7), 2.0, 18.0)
	point_light(Vector3(0, 3.0, -HALF_D + 1.5), Color(0.9, 0.9, 1.0), 2.2, 9.0)   # screen wash
	point_light(PROJECTOR_POS + Vector3(0, 2.0, 0), Color(1.0, 0.9, 0.6), 1.4, 5.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	add_child(box_mesh(Vector3(5.0, 0.04, HALF_D * 2.0), CARPET, Vector3(0, 0.04, 0)))  # aisle runner
	_walls()
	_screen()
	_seating()
	_projector_booth()
	_organ()
	make_dialog()
	_build_hud()
	_usher = spawn_npc("aldric", USHER_POS, PI)   # uniformed chief usher
	_doug = spawn_npc("uncle_doug", DOUG_POS, PI)
	_doug.visible = false
	var p := spawn_duo([QUINN, BEN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(0, WALL_H * 0.5, HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)

func _screen() -> void:
	add_child(box_mesh(Vector3(7.0, 3.4, 0.2), Color(0.92, 0.92, 0.95), Vector3(0, 2.0, -HALF_D + 0.4), 0.5))
	# proscenium curtains
	add_child(box_mesh(Vector3(0.8, 3.8, 0.6), CARPET.darkened(0.1), Vector3(-3.8, 1.9, -HALF_D + 0.6)))
	add_child(box_mesh(Vector3(0.8, 3.8, 0.6), CARPET.darkened(0.1), Vector3(3.8, 1.9, -HALF_D + 0.6)))

func _seating() -> void:
	for row: int in range(5):
		var z: float = -4.5 + float(row) * 1.8
		for sx: float in [-3.0, 3.0]:
			add_child(box_mesh(Vector3(2.2, 0.5, 0.6), Color(0.35, 0.10, 0.12), Vector3(sx, 0.4, z)))
			add_child(box_mesh(Vector3(2.2, 0.8, 0.2), Color(0.30, 0.08, 0.10), Vector3(sx, 0.7, z - 0.35)))

func _projector_booth() -> void:
	add_child(box_mesh(Vector3(2.6, 1.2, 1.4), Color(0.18, 0.10, 0.10), PROJECTOR_POS + Vector3(0, 0.6, 0)))
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

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.0, 0.1, 2.0), Vector3(2.5, 0.1, 1.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BOSS, Vector3(0.0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb", 1.9, Color(0.5, 0.2, 0.25)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_projector_repaired = GameManager.get_level_flag(location_id, "projector_repaired", false)
	_organ_played = GameManager.get_level_flag(location_id, "organ_played", false)
	if _projector_repaired: _set_projector_solved()
	if _organ_played: _organ_node.material_override = _glow()
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
	return _enemies_cleared and _projector_repaired and _organ_played and _has_all_tickets()

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if _doug_revealed and near3(pp, DOUG_POS, REACH): _talk_doug(char_name); return
	if near3(pp, USHER_POS, REACH): _talk_usher(char_name); return
	if char_name == "Quinn" and not _projector_repaired and near3(pp, PROJECTOR_POS, REACH):
		_projector_repaired = true
		GameManager.set_level_flag(location_id, "projector_repaired", true)
		_set_projector_solved()
		_hud_hint.text = "Quinn restores the projector — the screen flickers to life."
		Audio.play("special"); _maybe_reveal_doug(); return
	if char_name == "Ben" and not _organ_played and near3(pp, ORGAN_POS, REACH):
		_organ_played = true
		GameManager.set_level_flag(location_id, "organ_played", true)
		_organ_node.material_override = _glow()
		_hud_hint.text = "Ben plays the house organ — the theatre swells with sound."
		Audio.play("special"); _maybe_reveal_doug(); return
	if char_name != "Quinn" and not _projector_repaired and near3(pp, PROJECTOR_POS, REACH):
		_hud_hint.text = "The projector needs Quinn's tools."
	elif char_name != "Ben" and not _organ_played and near3(pp, ORGAN_POS, REACH):
		_hud_hint.text = "The house organ needs Ben."

func _maybe_reveal_doug() -> void:
	if _doug_revealed:
		return
	if _enemies_cleared and _projector_repaired and _organ_played and _has_all_tickets():
		_doug_revealed = true
		_doug.visible = true
		_doug.call("say", "You found me!")
		_hud_hint.text = "Uncle Doug is here — in the projection booth!"

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
			"\"West corridor for the booth, if you still need it. I hope you find whoever you're looking for.\""]}}
	else:
		tree = {
			"start": {
				"lines": [
					"\"Welcome to the Grand Marquee. I'm Cecil -- chief usher.\" He sweeps his torch toward the lobby.",
					"\"Rough night for a visit. Something's very wrong backstage.\""],
				"choices": [
					{"text": "\"What's blocking the backstage?\"", "next": "guardian_hint"},
					{"text": "\"Is the projection booth still open?\"", "next": "booth_hint"}]},
			"guardian_hint": {"lines": [
				"\"Machinery's gone haywire in the aisle. Whatever it is, it's been stopping everyone from getting through.\"",
				"\"Clear that and the whole theatre's yours.\""],
				"effects": {"set_flag": "usher_met", "flag_value": true}},
			"booth_hint": {"lines": [
				"\"West corridor, up the stairs. Projector's untouched -- whoever was running it cleared out in a hurry.\"",
				"\"Equipment's still in there if you need it.\""],
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
		bits.append("tickets " + ("5/5" if _has_all_tickets() else "?/5"))
		_hud_goal.text = "Clear the guardian; Quinn fixes the projector, Ben plays the organ. All 5 tickets to find Doug. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
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
