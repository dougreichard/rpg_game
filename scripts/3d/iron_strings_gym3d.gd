extends Level3D
## Iron & Strings Gym (3D) — Quinn + Evan. Multi-room: a combat-free LOBBY (front-desk
## clerk Marv + exit + Uncle Doug's locker), the WEIGHT FLOOR (Grunts + a Brute; Ben
## caged at the back behind a loaded barbell rack), and a BOILER ROOM to the east
## (reached by Evan jamming a weight onto a pressure plate; Quinn's valve yields the
## boiler key). Clear the floor, then Evan shoves the rack aside to free Ben (unlocks
## him). Concrete/steel surfaces. Win = floor cleared + rack moved; boiler/locker are
## optional puzzle + Doug content.

const QUINN := preload("res://data/characters/quinn.tres")
const EVAN := preload("res://data/characters/evan.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const BRUTE := preload("res://data/enemies/brute.tres")
const TicketBenItem: ItemData = preload("res://data/items/ticket_ben.tres")
const BoilerKeyItem: ItemData = preload("res://data/items/boiler_key.tres")
const LockerTagItem: ItemData = preload("res://data/items/doug_locker_tag.tres")

# --- thematic surfaces (concrete + steel trim) ---
const FLOOR_CONCRETE := "res://assets/art/tiles/synty_floor_concrete.png"
const FLOOR_TILE := "res://assets/art/tiles/synty_floor_tile.png"
const WALL_CONCRETE := "res://assets/art/tiles/synty_wall_concrete.png"
const WALL_BRICK := "res://assets/art/tiles/synty_wall_brick.png"
const FT_GYM := Color(0.78, 0.80, 0.82)
const WT_GYM := Color(0.74, 0.76, 0.78)
const FT_LOBBY := Color(0.82, 0.82, 0.80)
const FT_BOILER := Color(0.70, 0.70, 0.72)
const WT_BOILER := Color(0.72, 0.62, 0.56)
const CORNER_COL := Color(0.30, 0.32, 0.36)   # solid steel trim
const MAT_COL := Color(0.20, 0.30, 0.36)       # rubber gym mat accent

const HALF_W := 8.0       # weight-floor half extents
const HALF_D := 9.0
const WALL_H := 3.4
const BEN_POS := Vector3(0.0, 0.0, -HALF_D + 1.4)
const RACK_POS := Vector3(0.0, 0.0, -HALF_D + 3.2)   # barbell rack blocking the cage
const REACH := 2.2

# lobby/boiler pushed out behind longer (4m) corridors
const LOBBY_C := Vector3(0, 0, 17.0)
const DESK_POS := Vector3(3.5, 0, 18.5)
const LOCKER_POS := Vector3(-5.0, 0, 17.0)
const PLATE_POS := Vector3(5.5, 0, 0.0)
const BOILER_GATE := Vector3(12.0, 0, 0.0)
const BOILER_C := Vector3(15.5, 0, 0.0)
const VALVE_POS := Vector3(15.5, 0, -2.0)

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
var _boiler_gate_open := false
var _boiler_key_taken := false
var _locker_opened := false
var _spawned := 0
var _ben = null            # Npc3D
var _marv = null           # Npc3D (front desk)
var _rack: Node3D = null
var _plate: Node3D = null
var _boiler_wall: Node3D = null
var _locker: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "iron_strings_gym"
	multi_room = true
	build_env(Color(0.07, 0.08, 0.10), Color(0.55, 0.56, 0.6), 0.55, 1.1)
	point_light(Vector3(0, 3.2, 2.0), Color(0.95, 0.97, 1.0), 2.2, 14.0)
	point_light(Vector3(0, 2.8, -HALF_D + 2.5), Color(1.0, 0.8, 0.5), 2.0, 8.0)   # warm light on Ben's cage
	point_light(LOBBY_C + Vector3(0, 2.8, 0), Color(0.95, 0.95, 1.0), 2.0, 11.0)  # lobby
	point_light(BOILER_C + Vector3(0, 2.6, 0), Color(1.0, 0.6, 0.4), 1.8, 8.0)    # boiler glow
	_rooms()
	_mat_strip()
	_cage()
	_equipment()
	_rack_barrier()
	_boiler()
	_locker_stand()
	_plate_pad()
	make_dialog()
	_build_hud()
	_ben = spawn_npc("ben", BEN_POS, PI, BEN_QUIPS)
	_ben.set("yell_min", 4.0); _ben.set("yell_max", 8.0)
	_marv = spawn_npc("congregant_m", DESK_POS, PI)
	add_exit_portal(LOBBY_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([QUINN, EVAN], LOBBY_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Weight floor — concrete, the main combat room. Openings: south (lobby), east (boiler).
	set_theme(FLOOR_CONCRETE, WALL_CONCRETE)
	room(Vector3.ZERO, HALF_W * 2.0, HALF_D * 2.0, FT_GYM, WT_GYM, WALL_H, ["s", "e"], 4.0, true)
	corridor(Vector3(0, 0, HALF_D), "s", 4.0, FT_GYM, WT_GYM, 4.0, WALL_H, true, CORNER_COL)        # → lobby
	corridor(Vector3(HALF_W, 0, 0), "e", 4.0, FT_GYM, WT_GYM, 4.0, WALL_H, true, CORNER_COL)        # → boiler
	# Lobby — tile floor, concrete walls (combat-free entry). South vestibule = exit.
	set_theme(FLOOR_TILE, WALL_CONCRETE)
	room(LOBBY_C, 14, 9, FT_LOBBY, WT_GYM, 3.2, ["n", "s"], 4.0, true)
	corridor(LOBBY_C + Vector3(0, 0, 4.5), "s", 2.0, FT_LOBBY, WT_GYM, 4.0, 3.2, true, CORNER_COL)  # entrance vestibule
	# Boiler room — concrete floor, brick walls (utility). Threshold sealed by the pressure plate.
	set_theme(FLOOR_CONCRETE, WALL_BRICK)
	room(BOILER_C, 8, 9, FT_BOILER, WT_BOILER, 3.0, ["w"], 4.0, true)
	_boiler_wall = _gate_panel(BOILER_GATE, 3.0)

# A removable doorway panel (thin in X — doorway runs along Z) filling a 3-wide gap.
func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(0.4, h, 4.0)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, WT_BOILER, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _mat_strip() -> void:
	add_child(box_mesh(Vector3(3.0, 0.06, HALF_D * 1.6), MAT_COL, Vector3(0, 0.03, 1.0)))

func _cage() -> void:
	# cage alcove side walls framing Ben at the back of the weight floor
	wall(Vector3(-2.4, WALL_H * 0.5, -HALF_D + 2.4), Vector3(0.3, WALL_H, 3.0), WT_GYM.darkened(0.1))
	wall(Vector3(2.4, WALL_H * 0.5, -HALF_D + 2.4), Vector3(0.3, WALL_H, 3.0), WT_GYM.darkened(0.1))
	for i: int in range(7):
		var x: float = -2.1 + float(i) * 0.7
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.05; cm.height = WALL_H
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.5, 0.5, 0.55); mat.metallic = 0.7; mat.roughness = 0.3
		cm.material = mat; bar.mesh = cm
		bar.position = Vector3(x, WALL_H * 0.5, -HALF_D + 3.4)
		add_child(bar)

func _equipment() -> void:
	for z: float in [-1.0, 2.5, 5.5]:
		_bench(Vector3(HALF_W - 1.8, 0, z))
	_dumbbell_rack(Vector3(HALF_W - 0.9, 0, 3.0))
	_weight_tree(Vector3(-HALF_W + 1.2, 0, 0.0))
	_weight_tree(Vector3(-HALF_W + 1.2, 0, 4.0))
	prop("res://assets/models/props/barrel.glb", Vector3(-HALF_W + 1.4, 0, -3.5))

func _bench(pos: Vector3) -> void:
	prop("res://assets/models/props/weight_bench.glb", pos, deg_to_rad(90))   # Prop-Farm bench + barbell

func _dumbbell_rack(pos: Vector3) -> void:
	prop("res://assets/models/props/dumbbell_rack.glb", pos, deg_to_rad(-90))   # Prop-Farm dumbbell rack

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
	_rack.add_child(box_mesh(Vector3(0.18, 1.8, 0.5), Color(0.22, 0.22, 0.26), Vector3(-1.9, 0.9, 0)))
	_rack.add_child(box_mesh(Vector3(0.18, 1.8, 0.5), Color(0.22, 0.22, 0.26), Vector3(1.9, 0.9, 0)))
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

# Boiler room contents — big boiler tank + the valve wheel Quinn turns for the key.
func _boiler() -> void:
	prop("res://assets/models/props/gym_boiler.glb", BOILER_C + Vector3(1.3, 0, 2.0), deg_to_rad(180))  # Prop-Farm boiler (re-rolled)
	prop("res://assets/models/props/valve_wheel.glb", VALVE_POS, 0.0)   # Quinn's boiler valve (reused prop)

# Uncle Doug's gym locker in the lobby — Evan forces it open.
func _locker_stand() -> void:
	# a Prop-Farm locker bank dressing the lobby; Doug's locker (the interactive one Evan forces)
	# stays a primitive panel set just in front so its open-state recolour still reads.
	prop("res://assets/models/props/gym_lockers.glb", LOCKER_POS + Vector3(-1.5, 0, -0.2), 0.0)
	_locker = box_mesh(Vector3(0.9, 2.2, 0.7), Color(0.25, 0.4, 0.5), LOCKER_POS + Vector3(0, 1.1, 0))
	add_child(_locker)
	add_child(box_mesh(Vector3(0.92, 0.1, 0.72), Color(0.18, 0.3, 0.38), LOCKER_POS + Vector3(0, 1.7, 0.02)))  # vent line

# Pressure plate — Evan jams a weight onto it to hold the boiler gate open.
func _plate_pad() -> void:
	_plate = box_mesh(Vector3(1.4, 0.12, 1.4), Color(0.5, 0.45, 0.2), PLATE_POS + Vector3(0, 0.06, 0))
	add_child(_plate)

func _spawn_enemies() -> void:
	for spot: Vector3 in [Vector3(-2.5, 0.1, 1.0), Vector3(3.0, 0.1, -0.5)]:
		spawn_enemy(GRUNT, spot, "res://assets/models/enemies/grunt.glb"); _spawned += 1
	spawn_enemy(BRUTE, Vector3(0.0, 0.1, -2.0), "res://assets/models/enemies/grunt.glb", 1.45, Color(0.7, 0.55, 0.55)); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_rack_moved = GameManager.get_level_flag(location_id, "barbell_moved", false)
	_boiler_gate_open = GameManager.get_level_flag(location_id, "boiler_gate_open", false)
	_boiler_key_taken = GameManager.get_level_flag(location_id, "boiler_key_taken", false)
	_locker_opened = GameManager.get_level_flag(location_id, "locker_opened", false)
	if _rack_moved:
		_slide_rack(false)
		_ben_freed = true
		_ben.set("quips", [])
	if _boiler_gate_open:
		_open_boiler_gate(false)
	if _locker_opened:
		_locker.position += Vector3(0, 0, -0.25)   # forced ajar
	if _enemies_cleared and _rack_moved:
		_win(false)

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	# free Ben (Evan, after the floor is clear)
	if char_name == "Evan" and not _rack_moved and _enemies_cleared and near3(pp, RACK_POS, REACH + 0.6):
		_free_ben(char_name); return
	if char_name == "Evan" and not _enemies_cleared and near3(pp, RACK_POS, REACH + 0.6):
		_hud_hint.text = "Clear the gym floor first — Ben's not going anywhere."; return
	# pressure plate → boiler gate (Evan)
	if not _boiler_gate_open and near3(pp, PLATE_POS, REACH):
		if char_name == "Evan":
			_jam_plate()
		else:
			_hud_hint.text = "This plate needs serious weight on it — Evan's job."
		return
	# boiler valve → boiler key (Quinn)
	if not _boiler_key_taken and near3(pp, VALVE_POS, REACH):
		if not _boiler_gate_open:
			_hud_hint.text = "The boiler room's sealed — find a way to hold that gate open."
		elif char_name == "Quinn":
			_turn_valve(char_name)
		else:
			_hud_hint.text = "That seized valve wants Quinn's wrench hand."
		return
	# Doug's locker (Evan)
	if not _locker_opened and near3(pp, LOCKER_POS, REACH):
		if char_name == "Evan":
			_force_locker(char_name)
		else:
			_hud_hint.text = "The padlock's rusted solid — Evan can wrench it off."
		return
	if near3(pp, BEN_POS, REACH + 0.8):
		_talk_ben(char_name); return
	if near3(pp, DESK_POS, REACH + 0.6):
		_talk_marv(char_name); return

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

func _jam_plate() -> void:
	_boiler_gate_open = true
	GameManager.set_level_flag(location_id, "boiler_gate_open", true)
	create_tween().tween_property(_plate, "position:y", -0.04, 0.3)
	_open_boiler_gate(true)
	_hud_hint.text = "Evan drops a loaded barbell on the plate — the boiler gate grinds open to the east."
	Audio.play("special")

func _open_boiler_gate(animate: bool) -> void:
	(_boiler_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_boiler_wall, "position:y", -3.4, 0.6)
	else:
		_boiler_wall.position.y = -3.4

func _turn_valve(char_name: String) -> void:
	_boiler_key_taken = true
	GameManager.set_level_flag(location_id, "boiler_key_taken", true)
	GameManager.grant_item(char_name, BoilerKeyItem.id)
	_hud_hint.text = "Quinn cranks the seized valve; a brass boiler key drops into her hand. (Found Boiler Key)"
	Audio.play("special")

func _force_locker(char_name: String) -> void:
	_locker_opened = true
	GameManager.set_level_flag(location_id, "locker_opened", true)
	GameManager.grant_item(char_name, LockerTagItem.id)
	create_tween().tween_property(_locker, "position:z", LOCKER_POS.z - 0.25, 0.3)
	open_dialog("Doug's Locker", Color(0.5, 0.55, 0.6),
		{"start": {"lines": [
			"Evan pops the rusted padlock with two fingers. Inside: chalk, a frayed lifting belt — and a locker tag.",
			"Scratched on the back, a barbell doodle and one word: \"HARBOR.\"",
			"Picked up: Doug's Locker Tag."]}}, char_name)
	Audio.play("special")

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

func _talk_marv(char_name: String) -> void:
	var tree := {"start": {"lines": [
		"A wiry clerk leans over the front desk, towel round his neck.",
		"Marv: \"Those toughs muscled in and locked your musician friend in the cage at the back. Floor's all theirs now.\"",
		"\"Big Doug? Sure, trained here for years. His locker's right there -- never cleared it out. Padlock's seized, mind.\"",
		"\"Boiler room's east, but the door sticks unless there's weight on the floor plate. Don't ask.\""]}}
	GameManager.set_level_flag(location_id, "marv_met", true)
	open_dialog("Marv", Color(0.6, 0.55, 0.4), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	build_default_hud()
	_hud_goal = hud_goal; _hud_hint = hud_toast; _hud_banner = hud_ribbon
	_hud_goal.text = "Clear the gym, then Evan shoves the barbell rack to free Ben. (G interact, Tab swap)"

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
