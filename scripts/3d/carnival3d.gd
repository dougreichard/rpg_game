extends Level3D
## The Carnival & Fairground (3D) — Quinn + Erin. Quinn repairs the broken carousel;
## Erin talks down Marco at the backstage gate (choice dialog) or a backstage pass
## skips him. Clear the midway of grunts + a brute. A Doug poster backstage is the
## lead. Win: enemies cleared + ride repaired + backstage gate opened.

const QUINN := preload("res://data/characters/quinn.tres")
const ERIN := preload("res://data/characters/erin.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const BackstagePassItem: ItemData = preload("res://data/items/backstage_pass.tres")

const FLOOR_COL := Color(0.20, 0.16, 0.24)
const WALL_COL := Color(0.30, 0.18, 0.30)
const HALF_W := 8.5
const HALF_D := 8.5
const WALL_H := 3.4
const RIDE_POS := Vector3(-3.5, 0.0, -1.0)
const MARCO_POS := Vector3(4.0, 0.0, -HALF_D + 3.4)
const GATE_POS := Vector3(4.0, 0.0, -HALF_D + 2.6)
const REACH := 2.4

const RIDE_COLORS := [Color(0.9, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.3, 0.7, 0.9), Color(0.5, 0.85, 0.4)]

var _cleared := false
var _enemies_cleared := false
var _ride_repaired := false
var _backstage_talked := false
var _spawned := 0
var _marco = null
var _carousel: Node3D = null
var _gate: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "carnival"
	build_env(Color(0.05, 0.04, 0.08), Color(0.55, 0.45, 0.55), 0.6, 0.9)
	point_light(RIDE_POS + Vector3(0, 3.4, 0), Color(1.0, 0.7, 0.8), 2.4, 9.0)
	point_light(Vector3(3.0, 3.0, 2.0), Color(0.6, 0.8, 1.0), 1.8, 9.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_carousel_ride()
	_string_lights()
	_stalls()
	_backstage_gate()
	make_dialog()
	_build_hud()
	_marco = spawn_npc("bellows", MARCO_POS, PI)   # burly gatekeeper
	var p := spawn_duo([QUINN, ERIN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)

func _carousel_ride() -> void:
	_carousel = Node3D.new()
	_carousel.position = RIDE_POS
	# base + central pole
	add_child(box_mesh(Vector3(4.2, 0.2, 4.2), Color(0.3, 0.2, 0.3), RIDE_POS + Vector3(0, 0.1, 0)))
	add_child(box_mesh(Vector3(0.3, 3.0, 0.3), Color(0.7, 0.6, 0.3), RIDE_POS + Vector3(0, 1.5, 0)))
	# spinning canopy + horses live under _carousel (rotates when repaired)
	var canopy := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.2; cm.bottom_radius = 2.2; cm.height = 0.9
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.25, 0.35)
	cm.material = mat; canopy.mesh = cm; canopy.position = Vector3(0, 3.0, 0)
	_carousel.add_child(canopy)
	for i: int in range(4):
		var a: float = TAU * float(i) / 4.0
		var horse := box_mesh(Vector3(0.5, 0.8, 1.0), RIDE_COLORS[i], Vector3(cos(a) * 1.6, 0.9, sin(a) * 1.6))
		_carousel.add_child(horse)
		var pole := box_mesh(Vector3(0.06, 1.6, 0.06), Color(0.8, 0.8, 0.4), Vector3(cos(a) * 1.6, 1.6, sin(a) * 1.6))
		_carousel.add_child(pole)
	add_child(_carousel)

func _string_lights() -> void:
	for i: int in range(10):
		var t: float = float(i) / 9.0
		var x: float = lerp(-HALF_W + 1.0, HALF_W - 1.0, t)
		var y: float = 2.6 + 0.5 * sin(t * PI)
		var c: Color = RIDE_COLORS[i % RIDE_COLORS.size()]
		add_child(box_mesh(Vector3(0.12, 0.12, 0.12), c, Vector3(x, y, HALF_D - 1.0), 1.6))

func _stalls() -> void:
	for x: float in [-6.0, 6.0]:
		add_child(box_mesh(Vector3(2.4, 1.6, 1.2), Color(0.7, 0.4, 0.5), Vector3(x, 0.8, 4.5)))
		add_child(box_mesh(Vector3(2.6, 0.2, 1.4), Color(0.95, 0.9, 0.85), Vector3(x, 1.7, 4.5)))  # striped awning slab

func _backstage_gate() -> void:
	# Doug poster on the back wall behind the gate
	add_child(box_mesh(Vector3(1.4, 1.8, 0.1), Color(0.85, 0.8, 0.6), Vector3(4.0, 1.8, -HALF_D + 0.3), 0.3))
	# the curtain gate barrier Marco guards
	_gate = StaticBody3D.new()
	(_gate as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 2.6, 0.3); cs.shape = bs; cs.position = Vector3(0, 1.3, 0)
	_gate.add_child(cs)
	_gate.add_child(box_mesh(Vector3(2.6, 2.6, 0.3), Color(0.5, 0.1, 0.15), Vector3(0, 1.3, 0)))
	_gate.position = GATE_POS
	add_child(_gate)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-1.5, 0.1, 2.0), Vector3(2.0, 0.1, 1.0)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -1.5), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.7, 0.55, 0.6)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_ride_repaired = GameManager.get_level_flag(location_id, "ride_repaired", false)
	_backstage_talked = GameManager.get_level_flag(location_id, "backstage_talked", false)
	if _backstage_talked:
		_open_gate(false)
	if _enemies_cleared and _ride_repaired and _backstage_talked:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, MARCO_POS, REACH):
		_talk_marco(char_name); return
	if char_name == "Quinn" and not _ride_repaired and near3(pp, RIDE_POS, REACH + 1.0):
		_ride_repaired = true
		GameManager.set_level_flag(location_id, "ride_repaired", true)
		_hud_hint.text = "Quinn re-belts the motor — the carousel spins to life."
		Audio.play("special"); return
	if char_name != "Quinn" and not _ride_repaired and near3(pp, RIDE_POS, REACH + 1.0):
		_hud_hint.text = "The ride's motor needs Quinn's tools."

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
	var to := GATE_POS + Vector3(0, 0, -2.4)
	if animate:
		create_tween().tween_property(_gate, "position", to, 0.6)
	else:
		_gate.position = to

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
