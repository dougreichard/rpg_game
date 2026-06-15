extends Level3D
## The Clocktower (3D) — Quinn + Ben enter the tower interior. A clockwork-guardian
## Boss and grunts guard the works. Quinn repairs the great gear escapement (it
## starts turning); Ben plays the correct belfry bell sequence (the bells glow and
## ring). Clear all three to unlock the tower. Hieronymus theorises from the landing.
## Boss = a large, dark clockwork grunt (AOE telegraph TODO; uses windup red flash).

const QUINN := preload("res://data/characters/quinn.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BOSS := preload("res://data/enemies/boss.tres")

const FLOOR_COL := Color(0.24, 0.20, 0.16)
const WALL_COL := Color(0.33, 0.28, 0.22)
const BRASS := Color(0.72, 0.6, 0.32)
const HALF_W := 7.5
const HALF_D := 8.5
const WALL_H := 4.0
const GEAR_POS := Vector3(-3.0, 0.0, -2.0)
const BELLS_POS := Vector3(3.6, 0.0, -HALF_D + 1.4)
const HIERO_POS := Vector3(-HALF_W + 1.6, 0.0, 4.5)
const REACH := 2.2

var _cleared := false
var _enemies_cleared := false
var _gear_repaired := false
var _bells_played := false
var _spawned := 0
var _hiero = null
var _gear: Node3D = null
var _bells: Array = []
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "clocktower"
	build_env(Color(0.06, 0.05, 0.05), Color(0.5, 0.42, 0.32), 0.5, 0.95)
	point_light(Vector3(0, 3.6, 0), Color(1.0, 0.8, 0.5), 2.6, 16.0)
	point_light(BELLS_POS + Vector3(0, 3.0, 0), Color(1.0, 0.9, 0.6), 1.6, 6.0)
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_walls()
	_gear_mechanism()
	_bell_rack()
	_pendulum()
	make_dialog()
	_build_hud()
	_hiero = spawn_npc("aldric", HIERO_POS, deg_to_rad(80))   # robed theorist mesh
	var p := spawn_duo([QUINN, BEN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	# a giant clock-face disc on the back wall
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 2.4; cm.bottom_radius = 2.4; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.85, 0.8, 0.65); mat.emission_enabled = true; mat.emission = Color(0.4, 0.35, 0.2); mat.emission_energy_multiplier = 0.4
	cm.material = mat; face.mesh = cm
	face.rotation.x = deg_to_rad(90); face.position = Vector3(-3.0, 2.6, -HALF_D + 0.3)
	add_child(face)

func _gear_mechanism() -> void:
	_gear = _make_gear(0.9, 16, BRASS)
	_gear.position = GEAR_POS + Vector3(0, 0.6, 0)
	_gear.rotation.x = deg_to_rad(90)
	add_child(_gear)
	var g2 := _make_gear(0.55, 12, Color(0.55, 0.45, 0.28))
	g2.position = GEAR_POS + Vector3(1.3, 0.4, 0.2)
	g2.rotation.x = deg_to_rad(90)
	add_child(g2)

func _make_gear(radius: float, teeth: int, col: Color) -> Node3D:
	var root := Node3D.new()
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = radius; cm.bottom_radius = radius; cm.height = 0.2
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; mat.metallic = 0.6; mat.roughness = 0.4
	cm.material = mat; disc.mesh = cm
	root.add_child(disc)
	for i: int in range(teeth):
		var a: float = TAU * float(i) / float(teeth)
		var tooth := box_mesh(Vector3(0.16, 0.22, 0.2), col, Vector3(cos(a) * radius, 0, sin(a) * radius))
		root.add_child(tooth)
	return root

func _bell_rack() -> void:
	# support beam
	add_child(box_mesh(Vector3(3.2, 0.18, 0.18), Color(0.3, 0.22, 0.14), BELLS_POS + Vector3(0, 2.8, 0)))
	for i: int in range(4):
		var x: float = -1.1 + float(i) * 0.75
		var bell := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.32; cm.height = 0.6
		var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS.darkened(0.15); mat.metallic = 0.7; mat.roughness = 0.35
		cm.material = mat; bell.mesh = cm
		bell.position = BELLS_POS + Vector3(x, 2.2, 0)
		add_child(bell)
		_bells.append(bell)

func _pendulum() -> void:
	add_child(box_mesh(Vector3(0.08, 3.0, 0.08), Color(0.3, 0.25, 0.16), Vector3(3.0, 1.8, -2.0)))
	var bob := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.4; cm.bottom_radius = 0.4; cm.height = 0.1
	var mat := StandardMaterial3D.new(); mat.albedo_color = BRASS; mat.metallic = 0.7
	cm.material = mat; bob.mesh = cm; bob.rotation.x = deg_to_rad(90); bob.position = Vector3(3.0, 0.5, -2.0)
	add_child(bob)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-1.5, 0.1, 2.0), Vector3(2.5, 0.1, 1.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	# clockwork-guardian Boss — large + dark brass tint
	spawn_enemy(BOSS, Vector3(0.0, 0.1, -1.0), "res://assets/models/enemies/grunt.glb", 1.9, Color(0.55, 0.45, 0.3)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_gear_repaired = GameManager.get_level_flag(location_id, "gear_repaired", false)
	_bells_played = GameManager.get_level_flag(location_id, "bells_played", false)
	if _bells_played:
		_light_bells()
	if _enemies_cleared and _gear_repaired and _bells_played:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, HIERO_POS, REACH + 0.6):
		_talk_hiero(char_name); return
	if char_name == "Quinn" and not _gear_repaired and near3(pp, GEAR_POS, REACH):
		_gear_repaired = true
		GameManager.set_level_flag(location_id, "gear_repaired", true)
		_hud_hint.text = "Quinn re-seats the escapement — the great gear turns again."
		Audio.play("special"); return
	if char_name == "Ben" and not _bells_played and near3(pp, BELLS_POS, REACH + 0.6):
		_bells_played = true
		GameManager.set_level_flag(location_id, "bells_played", true)
		_light_bells()
		_hud_hint.text = "Ben strikes the belfry sequence — the bells ring true."
		Audio.play("special"); return
	if char_name != "Quinn" and not _gear_repaired and near3(pp, GEAR_POS, REACH):
		_hud_hint.text = "The escapement needs Quinn's tools."
	elif char_name != "Ben" and not _bells_played and near3(pp, BELLS_POS, REACH + 0.6):
		_hud_hint.text = "The bells need Ben's ear for pitch."

func _light_bells() -> void:
	for bell in _bells:
		var m := (bell as MeshInstance3D).mesh as CylinderMesh
		m.material.albedo_color = Color(1.0, 0.85, 0.4)
		m.material.emission_enabled = true; m.material.emission = Color(1.0, 0.8, 0.3); m.material.emission_energy_multiplier = 0.8

func _talk_hiero(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _gear_repaired and _bells_played:
		tree = {"start": {"lines": ["\"Remarkable. Thirty years I couldn't silence that guardian. You've done it in one visit.\""]}}
	elif _gear_repaired or _bells_played:
		tree = {"start": {"lines": ["\"The gear mechanism and the belfry bells both need attention before the tower unlocks.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"The guardian woke when I tried to fix the gear floor myself. I'm afraid I'm more theorist than fighter.\"",
			"\"Quinn -- the escapement needs your tools. Ben, the belfry bells want a pitch sequence; check my notes or the tuning fork up there.\""]}}
	open_dialog("Hieronymus", Color(0.5, 0.45, 0.55), tree, char_name)

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
	if _gear_repaired and _gear != null:
		_gear.rotation.z += d * 0.8   # the escapement turns once repaired
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		if _hiero != null:
			_hiero.call("say", "The guardian's down! Now the works!")
	var g := "Clear the guardian; Quinn repairs the gear, Ben rings the bells. (G interact, Tab swap)"
	if not _cleared:
		var bits := []
		bits.append("guardian " + ("OK" if _enemies_cleared else "..."))
		bits.append("gear " + ("OK" if _gear_repaired else "..."))
		bits.append("bells " + ("OK" if _bells_played else "..."))
		_hud_goal.text = g + "\n[" + "  ".join(bits) + "]"
	if not _cleared and _enemies_cleared and _gear_repaired and _bells_played:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "THE TOWER WAKES!\nClocktower cleared."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
