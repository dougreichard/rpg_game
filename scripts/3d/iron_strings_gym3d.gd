extends Level3D
## Iron & Strings Gym (3D) — Quinn + Evan fight through a gym taken over by toughs
## to reach Ben, caged in a back alcove behind a loaded barbell rack. Clear the
## floor, then Evan's strength shoves the rack aside to free Ben (unlocks him).
## Ben cheers them on from the cage via speech bubbles, then talks once freed.
## Enemy mix: Grunts + a Brute (a larger, darker grunt mesh).

const QUINN := preload("res://data/characters/quinn.tres")
const EVAN := preload("res://data/characters/evan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const TicketBenItem: ItemData = preload("res://data/items/ticket_ben.tres")

const FLOOR_COL := Color(0.26, 0.27, 0.30)
const WALL_COL := Color(0.34, 0.35, 0.39)
const MAT_COL := Color(0.20, 0.30, 0.36)   # rubber gym mat accent
const HALF_W := 8.0
const HALF_D := 9.0
const WALL_H := 3.4
const BEN_POS := Vector3(0.0, 0.0, -HALF_D + 1.4)
const RACK_POS := Vector3(0.0, 0.0, -HALF_D + 3.2)   # barbell rack blocking the cage
const REACH := 2.2

const BEN_QUIPS := [
	"Watch the big one — he telegraphs the left hook!",
	"Behind you! ...okay, you got it.",
	"Rhythm, Evan! Hit on the beat!",
	"Two more days in here and I'd have written a whole album.",
]

var _cleared := false
var _enemies_cleared := false
var _rack_moved := false
var _ben_freed := false
var _spawned := 0
var _ben = null            # Npc3D
var _rack: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "iron_strings_gym"
	build_env(Color(0.07, 0.08, 0.10), Color(0.55, 0.56, 0.6), 0.55, 1.1)
	point_light(Vector3(0, 3.2, 2.0), Color(0.95, 0.97, 1.0), 2.2, 14.0)
	point_light(Vector3(0, 2.8, -HALF_D + 2.5), Color(1.0, 0.8, 0.5), 2.0, 8.0)  # warm light on Ben's cage
	floor_box(HALF_W * 2.0 + 1.0, HALF_D * 2.0 + 1.0, FLOOR_COL)
	_mat_strip()
	_walls()
	_equipment()
	_rack_barrier()
	make_dialog()
	_build_hud()
	_ben = spawn_npc("ben", BEN_POS, PI, BEN_QUIPS)
	_ben.set("yell_min", 4.0); _ben.set("yell_max", 8.0)
	var p := spawn_duo([QUINN, EVAN], Vector3(0.0, 0.1, HALF_D - 1.5))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _mat_strip() -> void:
	# a coloured training-mat lane down the centre of the floor
	add_child(box_mesh(Vector3(3.0, 0.06, HALF_D * 1.6), MAT_COL, Vector3(0, 0.03, 1.0)))

func _walls() -> void:
	wall(Vector3(0, WALL_H * 0.5, -HALF_D), Vector3(HALF_W * 2.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(-HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(HALF_W, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, HALF_D * 2.0), WALL_COL)
	wall(Vector3(-HALF_W + 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	wall(Vector3(HALF_W - 2.5, WALL_H * 0.5, HALF_D), Vector3(5.0, WALL_H, 0.4), WALL_COL)
	# cage alcove side walls framing Ben at the back
	wall(Vector3(-2.4, WALL_H * 0.5, -HALF_D + 2.4), Vector3(0.3, WALL_H, 3.0), WALL_COL.darkened(0.1))
	wall(Vector3(2.4, WALL_H * 0.5, -HALF_D + 2.4), Vector3(0.3, WALL_H, 3.0), WALL_COL.darkened(0.1))
	# cage bars across the top of the alcove opening (decor only)
	for i: int in range(7):
		var x: float = -2.1 + float(i) * 0.7
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.05; cm.height = WALL_H
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.5, 0.5, 0.55); mat.metallic = 0.7; mat.roughness = 0.3
		cm.material = mat; bar.mesh = cm
		bar.position = Vector3(x, WALL_H * 0.5, -HALF_D + 3.4)
		add_child(bar)

func _equipment() -> void:
	# benches (box) + a dumbbell rack along the right wall; weight tree on the left
	for z: float in [-1.0, 2.5, 5.5]:
		_bench(Vector3(HALF_W - 1.8, 0, z))
	_dumbbell_rack(Vector3(HALF_W - 0.9, 0, 3.0))
	_weight_tree(Vector3(-HALF_W + 1.2, 0, 0.0))
	_weight_tree(Vector3(-HALF_W + 1.2, 0, 4.0))
	prop("res://assets/models/props/barrel.glb", Vector3(-HALF_W + 1.4, 0, -3.5))

func _bench(pos: Vector3) -> void:
	add_child(box_mesh(Vector3(0.5, 0.45, 1.6), Color(0.15, 0.15, 0.18), pos + Vector3(0, 0.45, 0)))
	add_child(box_mesh(Vector3(0.5, 0.12, 0.5), Color(0.6, 0.1, 0.12), pos + Vector3(0, 0.78, -0.55)))  # incline pad

func _dumbbell_rack(pos: Vector3) -> void:
	add_child(box_mesh(Vector3(0.6, 0.9, 2.6), Color(0.22, 0.22, 0.26), pos + Vector3(0, 0.45, 0)))
	for i: int in range(4):
		var z: float = -0.9 + float(i) * 0.6
		add_child(box_mesh(Vector3(0.5, 0.2, 0.22), Color(0.4, 0.42, 0.46), pos + Vector3(0, 0.9, z)))

func _weight_tree(pos: Vector3) -> void:
	add_child(box_mesh(Vector3(0.4, 1.5, 0.4), Color(0.2, 0.2, 0.24), pos + Vector3(0, 0.75, 0)))
	for i: int in range(3):
		var plate := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.35 - float(i) * 0.06; cm.bottom_radius = cm.top_radius; cm.height = 0.12
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.12, 0.12, 0.14)
		cm.material = mat; plate.mesh = cm
		plate.rotation.z = deg_to_rad(90)
		plate.position = pos + Vector3(0.3, 0.4 + float(i) * 0.4, 0)
		add_child(plate)

# The loaded barbell rack barring the cage — Evan slides it aside.
func _rack_barrier() -> void:
	_rack = StaticBody3D.new()
	(_rack as StaticBody3D).collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(4.2, 1.6, 0.5); cs.shape = bs; cs.position = Vector3(0, 0.9, 0)
	_rack.add_child(cs)
	# upright posts
	_rack.add_child(box_mesh(Vector3(0.18, 1.8, 0.5), Color(0.22, 0.22, 0.26), Vector3(-1.9, 0.9, 0)))
	_rack.add_child(box_mesh(Vector3(0.18, 1.8, 0.5), Color(0.22, 0.22, 0.26), Vector3(1.9, 0.9, 0)))
	# the bar
	var bar := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.07; cm.bottom_radius = 0.07; cm.height = 4.4
	var bmat := StandardMaterial3D.new(); bmat.albedo_color = Color(0.6, 0.6, 0.65); bmat.metallic = 0.8; bmat.roughness = 0.3
	cm.material = bmat; bar.mesh = cm; bar.rotation.z = deg_to_rad(90); bar.position = Vector3(0, 1.4, 0)
	_rack.add_child(bar)
	for sx: float in [-1.7, 1.7]:
		var plate := MeshInstance3D.new()
		var pm := CylinderMesh.new(); pm.top_radius = 0.45; pm.bottom_radius = 0.45; pm.height = 0.18
		var pmat := StandardMaterial3D.new(); pmat.albedo_color = Color(0.1, 0.1, 0.12)
		pm.material = pmat; plate.mesh = pm; plate.rotation.z = deg_to_rad(90); plate.position = Vector3(sx, 1.4, 0)
		_rack.add_child(plate)
	_rack.position = RACK_POS
	add_child(_rack)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.5, 0.1, 1.0), Vector3(3.0, 0.1, -0.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	# Brute: a bigger, darker grunt
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -2.0), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.7, 0.55, 0.55)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_rack_moved = GameManager.get_level_flag(location_id, "barbell_moved", false)
	if _rack_moved:
		_slide_rack(false)
		_ben_freed = true
		_ben.set("quips", [])
	if _enemies_cleared and _rack_moved:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if char_name == "Evan" and not _rack_moved and _enemies_cleared and near3(pp, RACK_POS, REACH + 0.6):
		_free_ben(char_name); return
	if near3(pp, BEN_POS, REACH + 0.8):
		_talk_ben(char_name); return
	if char_name == "Evan" and not _enemies_cleared and near3(pp, RACK_POS, REACH + 0.6):
		_hud_hint.text = "Clear the gym floor first — Ben's not going anywhere."

func _free_ben(char_name: String) -> void:
	_rack_moved = true
	_ben_freed = true
	GameManager.set_level_flag(location_id, "barbell_moved", true)
	_slide_rack(true)
	GameManager.grant_item(char_name, TicketBenItem.id)
	_ben.set("quips", [])
	_ben.call("say", "Freedom! Let's GO.")
	_hud_hint.text = "Evan heaves the rack aside. Ben is free! (Found Ben's movie ticket)"
	Audio.play("special")

func _slide_rack(animate: bool) -> void:
	var to := RACK_POS + Vector3(HALF_W - 1.5, 0, 0)
	if animate:
		create_tween().tween_property(_rack, "position", to, 0.6)
	else:
		_rack.position = to

func _talk_ben(char_name: String) -> void:
	var tree: Dictionary
	if _ben_freed:
		tree = {"start": {"lines": ["\"Freedom! My fingers haven't touched keys in two days. Let's go -- I have THOUGHTS.\""]}}
	elif _enemies_cleared:
		tree = {"start": {"lines": ["\"Now shove that barbell rack, Evan -- it's blocking the cage door. You've got this.\""]}}
	else:
		tree = {"start": {"lines": ["\"Hey! Over here! They grabbed me after the show -- watch yourself, the big one telegraphs the left hook.\""]}}
		GameManager.set_level_flag(location_id, "ben_met", true)
	open_dialog("Ben", Color(0.42, 0.60, 0.72), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_goal.text = "Clear the gym, then Evan shoves the barbell rack to free Ben. (G interact, Tab swap)"
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(_d: float) -> void:
	super._process(_d)
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
		_hud_hint.text = "Floor clear! Bring Evan to the barbell rack at Ben's cage."
		if _ben != null:
			_ben.call("say", "Nice! Now the rack, Evan!")
	if not _cleared and _enemies_cleared and _rack_moved:
		_win(true)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""
	_hud_banner.text = "GYM CLEARED!\nBen joins the band!"
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
