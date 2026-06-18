extends Level3D
## Zip Line Park (3D) — Ethan + Ben. Multi-room: a combat-free LANDING (warden Lena +
## exit), the MID PLATFORM (Grunt + 2 Runners; Ethan's control panel + lock-sequence +
## winch), and the HIGH PLATFORM (Ben's timed release + the snagged clue bag + a rhythm
## crate), reached once Ethan re-sequences the platform locks. Ethan restores power and
## aligns the locks; Ben catches the TIMING windows (press G while the pulse reads OPEN).
## Grass/wood surfaces, forest-green trim. Win: enemies cleared + panel hacked + release timed.

const ETHAN := preload("res://data/characters/ethan.tres")
const BEN := preload("res://data/characters/ben.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const RUNNER := preload("res://data/enemies/runner.tres")
const TreatItem: ItemData = preload("res://data/items/animal_treat.tres")
const BiesCharmItem: ItemData = preload("res://data/items/bies_charm.tres")
const CarabinerItem: ItemData = preload("res://data/items/doug_carabiner.tres")

# --- thematic surfaces (grass / wood / forest-green trim) ---
const FLOOR_GRASS := "res://assets/art/tiles/synty_floor_grass.png"
const FLOOR_DIRT := "res://assets/art/tiles/synty_floor_dirt.png"
const WALL_WOOD := "res://assets/art/tiles/synty_wall_wood.png"
const FT_PARK := Color(0.74, 0.82, 0.66)
const WT_PARK := Color(0.34, 0.50, 0.28)   # deep hedge-green (walls use the grass tile → read as hedges)
const CORNER_COL := Color(0.10, 0.30, 0.15)   # solid forest-green trim

const PULSE_SPEED := 2.0    # slower pulse → easier to catch
const PULSE_OPEN := 0.72    # wider OPEN window (was 0.82 — too tight)
const WALL_H := 1.6   # low hedge-height boundary (green walls/corners now read as hedges, fronted by hedge props)
const REACH := 2.2

# Expanded outdoor layout (z+ = south/landing/start, z- = north/high summit). Rooms spaced
# apart with long tree-lined trails between them. Mid 24x22 @0 · Landing 18x14 @+26 · High 18x16 @-27.
const LANDING_C := Vector3(0, 0, 26.0)
const POND_C := Vector3(18.0, 0, 26.0)   # peaceful pond clearing, a detour east of the landing
const LENA_POS := Vector3(3.0, 0, 26.5)
const PANEL_POS := Vector3(-4.0, 0.0, -2.0)
const LOCKS := [Vector3(4.0, 0, -4.0), Vector3(4.0, 0, -2.0), Vector3(4.0, 0, 0.0)]
const WINCH_POS := Vector3(-6.0, 0, 3.0)
const LOCK_GATE := Vector3(0.0, 0, -15.0)          # on the mid→high trail
const HIGH_C := Vector3(0, 0, -27.0)
# zip-line rider path (cable deck points, trolley hangs just under the cable): high -> mid -> low
const ZIP_TOP := Vector3(0, 4.6, -28.0)
const ZIP_MID := Vector3(0, 3.4, -2.0)
const ZIP_LOW := Vector3(-6.0, 2.2, 6.0)
const ZIP_HANG := Vector3(0, -0.32, 0)
const RELEASE_POS := Vector3(-1.5, 0.0, -24.0)    # release post (Ben TIMES) — in FRONT of the high tower
const HIGH_PANEL_POS := Vector3(1.5, 0.0, -24.0)  # release control panel (Ethan ARMS) — beside the post
const CLUE_POS := Vector3(-3.5, 0.0, -30.0)
const RHYTHM_POS := Vector3(3.5, 0.0, -30.0)

var _cleared := false
var _enemies_cleared := false
var _panel_hacked := false
var _locks_done := false
var _release_armed := false   # Ethan powered the release; Ben can now time it
var _release_timed := false
var _clue_taken := false
var _winch_done := false
var _rhythm_done := false
var _lock_seq: Array = []
var _spawned := 0
var _pulse := 0.0
var _lena = null
var _panel_lights: Array = []
var _high_panel_lights: Array = []
var _lock_lights: Array = []
var _release_light: MeshInstance3D = null
var _zip_rider: Node3D = null    # trolley that sits on the high cable, ready, and zips on release
var _lock_wall: Node3D = null
var _hud_goal: Label = null
var _hud_hint: Label = null
var _hud_pulse: Label = null
var _hud_banner: Label = null

func _build_level() -> void:
	location_id = "zip_line"
	multi_room = true
	walls_visible = false   # collision-only walls; the visible boundary is hedges + bushes (_hedges)
	build_env(Color(0.53, 0.70, 0.90), Color(0.62, 0.66, 0.68), 0.95, 1.5)  # daytime park sky
	point_light(Vector3(0, 3.4, 0), Color(0.9, 1.0, 0.95), 2.0, 16.0)
	point_light(LANDING_C + Vector3(0, 2.6, 0), Color(0.85, 1.0, 0.9), 1.8, 11.0)
	point_light(PANEL_POS + Vector3(0, 2.0, 0), Color(0.4, 0.7, 1.0), 1.4, 5.0)
	point_light(RELEASE_POS + Vector3(0, 2.0, 0), Color(1.0, 0.7, 0.4), 1.4, 6.0)
	point_light(HIGH_PANEL_POS + Vector3(0, 2.0, 0), Color(0.4, 0.7, 1.0), 1.3, 5.0)
	# outer ground so the forest ring / perimeter foliage isn't floating over the void
	set_theme(FLOOR_GRASS, FLOOR_GRASS)
	floor_box(56, 104, FT_PARK.darkened(0.08), Vector3(0, -0.06, -3.0))
	_rooms()
	_towers()
	_ziplines()
	_build_zip_rider()
	_panel()
	_locks()
	_winch()
	_release()
	_high_extras()
	_set_dressing()
	_pond_clearing()
	_trail_dressing()
	_tower_dressing()
	_hedges()
	_forest_ring()
	make_dialog()
	_build_hud()
	_lena = spawn_npc("congregant_f", LENA_POS, PI)
	_park_visitors()
	add_exit_portal(LANDING_C + Vector3(0, 0, 5.0), Vector3(3, 3, 1.4))
	var p := spawn_duo([ETHAN, BEN], LANDING_C + Vector3(0.0, 0.1, 1.0))
	p.special_used.connect(_on_special)
	_spawn_enemies()
	_restore()

func _rooms() -> void:
	# Mid platform — big grassy combat field. Openings: south (landing trail), north (high trail).
	set_theme(FLOOR_GRASS, FLOOR_GRASS)
	room(Vector3.ZERO, 24, 22, FT_PARK, WT_PARK, WALL_H, ["s", "n"], 4.0, true)
	corridor(Vector3(0, 0, 11), "s", 8.0, FT_PARK, WT_PARK, 4.0, WALL_H, true, CORNER_COL)    # long trail → landing
	corridor(Vector3(0, 0, -11), "n", 8.0, FT_PARK, WT_PARK, 4.0, WALL_H, true, CORNER_COL)   # long trail → high (gated)
	_lock_wall = _gate_panel(LOCK_GATE, WALL_H)
	# Landing — grassy entry plaza (combat-free). South vestibule = exit; east path → pond.
	set_theme(FLOOR_GRASS, FLOOR_GRASS)
	room(LANDING_C, 18, 14, FT_PARK, WT_PARK, WALL_H, ["n", "s", "e"], 4.0, true)
	corridor(LANDING_C + Vector3(0, 0, 7.0), "s", 3.0, FT_PARK, WT_PARK, 4.0, WALL_H, true, CORNER_COL)
	# Pond clearing — peaceful detour east of the landing (forest ring locally opened for it).
	room(POND_C, 12, 12, FT_PARK, WT_PARK, WALL_H, ["w"], 4.0, true)
	corridor(Vector3(9, 0, 26), "e", 3.0, FT_PARK, WT_PARK, 4.0, WALL_H, true, CORNER_COL)
	# High platform — dirt launch summit up top.
	set_theme(FLOOR_DIRT, FLOOR_GRASS)
	room(HIGH_C, 18, 16, FT_PARK, WT_PARK, WALL_H, ["s"], 4.0, true)

func _gate_panel(pos: Vector3, h: float) -> Node3D:
	var size := Vector3(4.4, h, 0.4)
	var sb := StaticBody3D.new()
	sb.collision_layer = Combat3D.L_WORLD
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = size; cs.shape = bs; cs.position = Vector3(0, h * 0.5, 0)
	sb.add_child(cs); sb.add_child(box_mesh(size, WT_PARK, Vector3(0, h * 0.5, 0), 0.0, wall_tex))
	sb.position = pos
	add_child(sb)
	return sb

func _towers() -> void:
	_tower(Vector3(-6.0, 0, 6.0), 2.2, Color(0.4, 0.5, 0.4))
	_tower(Vector3(0.0, 0, -2.0), 3.4, Color(0.35, 0.45, 0.55))
	_tower(HIGH_C + Vector3(0, 0, -1.0), 4.6, Color(0.5, 0.45, 0.35))

func _tower(pos: Vector3, h: float, _col: Color) -> void:
	# Generated timber zip-line tower (synty-prop-gen, painted) — visual-only over the room
	# floor. Mesh is ~4.5m tall; scale to this tower's height so the deck sits near h (where
	# the cables attach). (yaw 0; verify deck facing in-engine.)
	prop("res://assets/models/props/zip_tower.glb", pos, 0.0, h / 4.5)

func _ziplines() -> void:
	_cable(Vector3(-6.0, 2.2, 6.0), Vector3(0.0, 3.4, -2.0))
	_cable(Vector3(0.0, 3.4, -2.0), HIGH_C + Vector3(0, 4.6, -1.0))

func _cable(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var line := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 0.03; cm.bottom_radius = 0.03; cm.height = a.distance_to(b)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.1, 0.1, 0.1); mat.metallic = 0.5
	cm.material = mat; line.mesh = cm
	line.position = mid
	line.look_at_from_position(mid, b, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	add_child(line)

func _panel() -> void:
	prop("res://assets/models/props/zip_control_panel.glb", PANEL_POS, 0.0)  # Ethan's hack kiosk (painted)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.85, 0.25, 0.2), PANEL_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip)
		_panel_lights.append(pip)

func _locks() -> void:
	for i: int in range(LOCKS.size()):
		add_child(box_mesh(Vector3(0.3, 0.9, 0.3), Color(0.3, 0.3, 0.34), LOCKS[i] + Vector3(0, 0.45, 0)))
		var glow := box_mesh(Vector3(0.18, 0.18, 0.18), Color(0.85, 0.3, 0.3), LOCKS[i] + Vector3(0, 1.0, 0), 1.5)
		add_child(glow); _lock_lights.append(glow)
		_floating_label(str(i + 1), LOCKS[i] + Vector3(0, 1.4, 0), Color(0.7, 0.9, 1.0))

func _winch() -> void:
	prop("res://assets/models/props/zip_winch.glb", WINCH_POS, 0.0)  # generated cable winch (painted)

func _release() -> void:
	# Release POST (Ben times) + a separate control PANEL (Ethan arms), both in front of the
	# high launch tower so neither is buried in it.
	prop("res://assets/models/props/zip_release.glb", RELEASE_POS, 0.0)        # signal/gate post — Ben
	prop("res://assets/models/props/zip_control_panel.glb", HIGH_PANEL_POS, 0.0)  # release control panel — Ethan (faces +Z, same as the mid panel)
	# matching button pips on the high panel's face (yaw 0 → front at +Z, like the first panel)
	for i: int in range(3):
		var pip := box_mesh(Vector3(0.16, 0.06, 0.1), Color(0.85, 0.25, 0.2), HIGH_PANEL_POS + Vector3(-0.3 + float(i) * 0.3, 1.0, 0.28), 1.2)
		add_child(pip)
		_high_panel_lights.append(pip)
	_release_light = box_mesh(Vector3(0.3, 0.3, 0.12), Color(0.6, 0.6, 0.2), RELEASE_POS + Vector3(0, 1.1, 0.22), 1.0)
	add_child(_release_light)

func _high_extras() -> void:
	# the snagged clue bag (generated duffel, up on the high line) + a rhythm-rig crate (town barrel)
	prop("res://assets/models/props/clue_bag.glb", CLUE_POS + Vector3(0, 1.5, 0), 0.5)
	prop("res://assets/models/props/barrel.glb", RHYTHM_POS, 0.0)


const TOWN := "res://assets/models/town/"
const BUSH_STEP := 1.45   # town bush is ~1.9m wide → ~1.45m spacing overlaps into a continuous hedge

func _hedge_run(start: Vector3, axis: String, length: float) -> void:
	# a continuous bushy hedge: overlapping Synty town bushes (~1.75m tall) along the wall line,
	# with deterministic yaw/scale jitter so it reads natural (no generated hedge — looked bad)
	if length <= 0.1:
		return
	var n := maxi(1, int(round(length / BUSH_STEP)))
	var step := length / n
	for i: int in range(n + 1):
		var off := step * float(i)
		var pos := start + (Vector3(off, 0, 0) if axis == "x" else Vector3(0, 0, off))
		var seed := pos.x * 1.7 + pos.z * 2.3
		prop(TOWN + "bush.glb", pos, fmod(absf(seed), 1.0) * TAU, 1.0 + 0.18 * sin(seed))

func _hedge_side(c: Vector3, side: String, w: float, d: float, open: bool, gap: float) -> void:
	# hedge a wall side; on an opening side, hedge the two segments and leave the central gap
	var horiz := side == "n" or side == "s"
	var span := w if horiz else d
	var inset := 0.5
	var fixed := 0.0   # the run's fixed coordinate (z for n/s, x for e/w), inset inward
	match side:
		"n": fixed = -d * 0.5 + inset
		"s": fixed = d * 0.5 - inset
		"w": fixed = -w * 0.5 + inset
		"e": fixed = w * 0.5 - inset
	var segs := [[0.0, span]]
	if open:
		var seg := (span - gap) * 0.5
		segs = [[0.0, seg], [(span + gap) * 0.5, seg]] if seg > 0.1 else []
	for s: Array in segs:
		var a: float = -span * 0.5 + float(s[0])
		var L: float = float(s[1])
		if horiz:
			_hedge_run(Vector3(c.x + a, 0, c.z + fixed), "x", L)
		else:
			_hedge_run(Vector3(c.x + fixed, 0, c.z + a), "z", L)

func _hedge_room(c: Vector3, w: float, d: float, openings: Array, gap := 3.0) -> void:
	for side: String in ["n", "s", "e", "w"]:
		_hedge_side(c, side, w, d, side in openings, gap)
	# one bush at each corner to fill the right-angle seam where two runs meet
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var corner := c + Vector3(sx * (w * 0.5 - 0.4), 0, sz * (d * 0.5 - 0.4))
			prop(TOWN + "bush.glb", corner, (sx + sz) * 0.7, 1.1)

func _hedges() -> void:
	_hedge_room(Vector3.ZERO, 24, 22, ["s", "n"], 4.0)
	_hedge_room(LANDING_C, 18, 14, ["n", "s", "e"], 4.0)
	_hedge_room(HIGH_C, 18, 16, ["s"], 4.0)
	_hedge_room(POND_C, 12, 12, ["w"], 4.0)
	# line the two long trails between the rooms with bushes (open gateways stay clear)
	_hedge_run(Vector3(-2.0, 0, 11), "z", 8.0); _hedge_run(Vector3(2.0, 0, 11), "z", 8.0)     # mid→landing
	_hedge_run(Vector3(-2.0, 0, -19), "z", 8.0); _hedge_run(Vector3(2.0, 0, -19), "z", 8.0)   # mid→high
	_hedge_run(Vector3(10.5, 0, 24), "x", 3.0); _hedge_run(Vector3(10.5, 0, 28), "x", 3.0)    # landing→pond

func _forest_ring() -> void:
	# a denser tree/bush border OUTSIDE the room walls (taller trees peek over the 2.8m walls
	# for an enclosed-park backdrop). Deterministic RNG so it's stable across runs.
	var town := "res://assets/models/town/"
	var rng := RandomNumberGenerator.new(); rng.seed = 4242
	var kinds := ["tree", "tree", "tree_large", "bush"]
	var xb := 16.0
	var z := -42.0
	while z <= 40.0:                                   # east + west borders
		for sx: float in [-xb, xb]:
			# the pond clearing pushes east to x~24 around z26 — skip east-ring trees in that
			# band (they'd land inside the pond room) and back the clearing further out instead
			if sx > 0 and z > 19.0 and z < 33.0:
				continue
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(sx + rng.randf_range(-1.5, 1.5), 0.0, z + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)
		z += rng.randf_range(2.6, 3.6)
	# back the pond clearing with a tree line just east of its wall (x24)
	var pz := 20.0
	while pz <= 32.0:
		prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
			Vector3(25.5 + rng.randf_range(-0.8, 0.8), 0.0, pz + rng.randf_range(-0.8, 0.8)), rng.randf() * TAU)
		pz += rng.randf_range(2.6, 3.4)
	for sz: float in [-43.0, 41.0]:                    # north + south caps
		var x := -xb
		while x <= xb:
			prop(town + kinds[rng.randi() % kinds.size()] + ".glb",
				Vector3(x + rng.randf_range(-1.0, 1.0), 0.0, sz + rng.randf_range(-1.0, 1.0)), rng.randf() * TAU)
			x += rng.randf_range(2.6, 3.6)

# The zip rider = a container (so trolley + kid move together) parked on the high cable,
# ready to ride. The trolley hangs from the cable; a seated kid (sit clip = legs forward,
# as in a harness seat) hangs just below the handlebar. On release it zips down (#payoff).
func _build_zip_rider() -> void:
	_zip_rider = Node3D.new()
	add_child(_zip_rider)
	_zip_rider.position = ZIP_TOP + ZIP_HANG
	var trolley: Node3D = load("res://assets/models/props/zip_trolley.glb").instantiate()
	trolley.scale = Vector3(0.6, 0.6, 0.6)
	_zip_rider.add_child(trolley)
	var kid: Node3D = load("res://assets/models/characters/kid_explorer.glb").instantiate()
	kid.position = Vector3(0, -0.85, 0)   # seated, hanging just below the handlebar
	kid.rotation.y = 0.0                  # face along the cable (toward +Z descent)
	_zip_rider.add_child(kid)
	var ap := _find_anim(kid)
	if ap != null and ap.has_animation("sit"):
		ap.get_animation("sit").loop_mode = Animation.LOOP_LINEAR
		ap.play("sit")

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func _play_zip() -> void:
	# the ready trolley zips the cable: high deck -> mid deck -> low deck
	if _zip_rider == null:
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(_zip_rider, "position", ZIP_MID + ZIP_HANG, 1.2).set_ease(Tween.EASE_IN)
	tw.tween_property(_zip_rider, "position", ZIP_LOW + ZIP_HANG, 1.2).set_ease(Tween.EASE_OUT)

# Atmospheric park-goers in the combat-free landing/lobby: animated Synty Kids
# (idle/walk/sit via the authored-clip pipeline) plus a strolling adult. Pure
# ambience — speech bubbles only, no quests. Kids sit on the bench/grass or wander
# a small loop clear of Lena, the exit portal and the spawn point.
const KID_QUIPS := [
	"Did you SEE that zip line?!", "I wanna go again!", "Mom, can we ride it?",
	"Whoaaa, so high up!", "Bet I can go faster than you.", "Look how fast they went!",
]
const ADULT_QUIPS := [
	"Stay where I can see you, you two.", "Careful near the edge!",
	"Lovely day for the park.", "Don't run on the platforms!",
]
func _park_visitors() -> void:
	# All grounded standing/wandering kids (idle/walk read correctly at y=0; the seated
	# pose only looks right on a seat, so the one seated kid is the zip-line rider). Distinct
	# meshes so no two look alike. The seated payoff rides the trolley (see _build_zip_rider).
	# A kid standing near the picnic table, watching the zip line (-Z / north)
	spawn_npc("kid_casual", Vector3(-4.0, 0, 26.0), 0.0, KID_QUIPS)
	# wandering kids — small loops on the open landing, clear of Lena(3,26.5)/exit(0,31)/spawn(0,27)
	spawn_npc("kid_adventure", Vector3(6.5, 0, 23.5), 0.0, KID_QUIPS, [
		Vector3(6.5, 0, 23.5), Vector3(7.5, 0, 29.0), Vector3(5.0, 0, 30.5), Vector3(4.5, 0, 24.5),
	])
	spawn_npc("kid_dress", Vector3(-5.0, 0, 22.0), 0.0, KID_QUIPS, [
		Vector3(-5.0, 0, 22.0), Vector3(-7.5, 0, 27.0), Vector3(-4.0, 0, 31.0), Vector3(-2.0, 0, 24.0),
	])
	# strolling adult (chaperone) — small interior loop near the centre, clear of the exit
	# door (z31), the south hedge (z33), the spawn (z27) and the north trail mouth (z19)
	spawn_npc("congregant_m", Vector3(0, 0, 23.0), PI, ADULT_QUIPS, [
		Vector3(-2.5, 0, 22.0), Vector3(2.5, 0, 22.0), Vector3(2.5, 0, 24.0), Vector3(-2.5, 0, 24.0),
	])

# Peaceful pond clearing east of the landing: the baked Synty pond + curved footbridge,
# ringed by boulders/reeds, with a bench to sit and view it and a trail sign at the mouth.
func _pond_clearing() -> void:
	var town := "res://assets/models/town/"
	prop(town + "park_pond.glb", POND_C + Vector3(0, 0.02, 0), 0.0, 0.4)              # ~7.4 x 8.2 m pond
	prop(town + "bridge_curved.glb", POND_C + Vector3(0, 0.1, 0), 0.0, 0.7)           # curved footbridge across it
	# boulders + reeds around the rim
	for r: Array in [[14.8, 22.0, 1.0], [21.3, 23.0, 0.8], [21.6, 29.5, 1.1], [14.5, 30.2, 0.9]]:
		prop(town + "rock_round.glb", Vector3(r[0], 0, r[1]), float(r[0]), float(r[2]))
	for b: Vector2 in [Vector2(15.4, 21.6), Vector2(20.8, 30.6), Vector2(13.9, 28.2), Vector2(22.0, 26.0)]:
		prop(town + "bush.glb", Vector3(b.x, 0, b.y), b.x, 0.8)
	# a bench at the west edge, facing east into the pond
	prop(town + "park_seat.glb", Vector3(13.2, 0, 26.0), -PI * 0.5)
	# trail sign at the landing→pond path mouth
	prop("res://assets/models/props/trail_marker.glb", Vector3(8.0, 0, 23.8), deg_to_rad(60))

# Wayfinding + flowers along the trails so the long paths between rooms feel tended.
# All accents sit at room-side trail mouths (more room than the 4-wide path itself).
func _trail_dressing() -> void:
	var town := "res://assets/models/town/"
	# hero directional signpost in the landing (points to the zip line / pond / exit)
	prop("res://assets/models/props/park_sign.glb", Vector3(6.0, 0, 23.0), deg_to_rad(-30))
	# flowerbeds + planters flanking the trail mouths (room side, clear of the path lanes)
	var beds := [
		["flowerbed", 3.5, 19.8], ["flowerbed", -3.5, 19.8],     # landing ← north trail mouth
		["flowerbed", 3.5, 9.0], ["planter", -3.5, 9.0],         # mid → south trail mouth
		["planter", 3.2, -8.8], ["planter", -3.2, -8.8],         # mid → north trail mouth
		["flowerbed", -3.5, -19.5], ["flowerbed", 3.5, -19.5],   # high ← north trail mouth
		["potplant", 7.2, 19.6], ["potplant", -7.2, 19.6],       # landing front corners
	]
	for b: Array in beds:
		prop(town + str(b[0]) + ".glb", Vector3(b[1], 0, b[2]), deg_to_rad(int(b[1] * 17.0) % 360))

# Make the three towers read as real launch decks: stacked crates, a leaning ladder, and
# park-fence railing segments at their bases. Clear of the cable line + release puzzle spots.
func _tower_dressing() -> void:
	var town := "res://assets/models/town/"
	# low tower (-6,6): supply crates + a fence rail
	prop(town + "deck_crate.glb", Vector3(-7.8, 0, 4.6), 0.4)
	prop(town + "wood_box.glb", Vector3(-7.4, 0, 7.6), 1.2)
	prop(town + "park_fence.glb", Vector3(-8.0, 0, 6.0), deg_to_rad(90))
	# mid tower (0,-2): a couple of crates off to the side (clear of the cable + winch)
	prop(town + "deck_crate.glb", Vector3(2.4, 0, -3.6), -0.5)
	prop(town + "wood_box.glb", Vector3(2.6, 0, -0.4), 0.3)
	# high launch deck (tower at 0,-28): crates + fence rails, clear of release/clue/rhythm spots
	prop(town + "deck_crate.glb", Vector3(-2.8, 0, -29.5), 0.6)
	prop(town + "wood_box.glb", Vector3(2.8, 0, -29.6), -0.4)
	prop(town + "park_fence.glb", Vector3(0, 0, -31.0), 0.0)
	prop(town + "park_fence.glb", Vector3(-3.2, 0, -31.0), 0.0)
	prop(town + "park_fence.glb", Vector3(3.2, 0, -31.0), 0.0)

func _set_dressing() -> void:
	# Outdoor-park dressing from the Synty town pack (scale 1.0, like the overworld), placed
	# around each area's perimeter — clear of the puzzle spots, paths, spawn/exit and towers.
	# [kind, x, z, yaw_deg]
	var town := "res://assets/models/town/"
	# [kind, x, z, yaw_deg] — accents near room edges, clear of puzzle spots / trails
	var items := [
		# --- mid (24x22 @0): edges x±10.5 / z±9; avoid panel(-4,-2)/locks(4,*)/winch(-6,3)/towers ---
		["tree_large", 10.5, 9.0, 20], ["tree", 10.5, -9.0, 120], ["tree", -10.5, -9.0, 210], ["tree", -10.5, 9.0, 300],
		["bush", 11.0, 3.0, 0], ["bush", 11.0, -3.0, 0], ["bush", -11.0, -6.0, 0],
		["park_lamp", 10.5, 9.5, 0], ["park_lamp", -10.5, 9.5, 0],
		# --- landing (18x14 @+26): Lena/kiosk/picnic ---
		["tree", 7.5, 31.0, 40], ["tree", -7.5, 31.0, 300], ["tree", -7.5, 20.5, 150],
		["flowerbed", 7.0, 21.0, 0], ["planter", -3.0, 31.5, 0], ["park_lamp", 7.5, 27.0, 0],
		# --- high (18x16 @-27): avoid release(-1.5,-24)/panel(1.5,-24)/clue(-3.5,-30)/rhythm(3.5,-30)/tower(0,-28) ---
		["tree", 7.5, -33.0, 60], ["tree", -7.5, -33.0, 250], ["tree", 7.5, -21.0, 140], ["tree", -7.5, -21.0, 30],
		["bush", -7.5, -27.0, 0], ["bush", 7.5, -27.0, 0], ["park_lamp", 7.5, -21.0, 0],
	]
	for it: Array in items:
		prop(town + str(it[0]) + ".glb", Vector3(it[1], 0.0, it[2]), deg_to_rad(it[3]), 1.0)
	prop("res://assets/models/props/warden_kiosk.glb", Vector3(4.5, 0.0, 30.5), PI)   # Lena's hut, back of landing
	# picnic rest area at the landing (baked Kids "Park" set)
	prop(town + "picnic_table.glb", Vector3(-5.0, 0.0, 28.5), deg_to_rad(20))
	prop(town + "park_seat.glb", Vector3(-6.8, 0.0, 24.5), deg_to_rad(90))
	prop(town + "park_bin.glb", Vector3(-7.8, 0.0, 30.5), 0.0)
	# park fences flanking the entrance path (south of the landing)
	prop(town + "park_fence.glb", Vector3(-3.0, 0.0, 34.5), 0.0)
	prop(town + "park_fence.glb", Vector3(3.0, 0.0, 34.5), 0.0)
	# scattered boulders (baked rock)
	prop(town + "rock_round.glb", Vector3(9.0, 0.0, -9.5), 0.0, 1.0)
	prop(town + "rock_round.glb", Vector3(-9.5, 0.0, 5.0), 1.5, 0.8)
	prop(town + "rock_round.glb", Vector3(7.5, 0.0, -31.5), 2.4, 1.1)
	# hay-bale crash pad under the low zip tower (mid, unchanged)
	prop("res://assets/models/props/hay_bale.glb", Vector3(-6.0, 0.0, 7.2), 0.0)
	prop("res://assets/models/props/hay_bale.glb", Vector3(-5.1, 0.0, 7.0), 1.0)
	prop("res://assets/models/props/hay_bale.glb", Vector3(-6.5, 0.0, 6.2), 2.2)

func _floating_label(txt: String, pos: Vector3, col: Color) -> void:
	var l := Label3D.new()
	l.text = txt; l.font = UITheme.font(); l.font_size = 40; l.outline_size = 12
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
	l.fixed_size = true; l.pixel_size = 0.001; l.position = pos
	add_child(l)

func _spawn_enemies() -> void:
	spawn_enemy(GRUNT, Vector3(0.0, 0.1, 0.5), "res://assets/models/enemies/grunt.glb"); _spawned += 1
	for spot: Vector3 in [Vector3(-2.5, 0.1, -1.0), Vector3(2.5, 0.1, 1.0)]:
		spawn_enemy(RUNNER, spot, "res://assets/models/enemies/runner.glb"); _spawned += 1

func _restore() -> void:
	_enemies_cleared = GameManager.get_level_flag(location_id, "enemies_cleared", false)
	_panel_hacked = GameManager.get_level_flag(location_id, "panel_hacked", false)
	_locks_done = GameManager.get_level_flag(location_id, "locks_done", false)
	_release_armed = GameManager.get_level_flag(location_id, "release_armed", false)
	_release_timed = GameManager.get_level_flag(location_id, "release_timed", false)
	_clue_taken = GameManager.get_level_flag(location_id, "clue_taken", false)
	_winch_done = GameManager.get_level_flag(location_id, "winch_done", false)
	_rhythm_done = GameManager.get_level_flag(location_id, "rhythm_done", false)
	if _panel_hacked: _set_panel_solved()
	if _locks_done:
		for g in _lock_lights: ((g as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		_open_lock_gate(false)
	if _release_armed:
		_set_high_panel_armed()
	if _release_armed and not _release_timed and _release_light != null:
		((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.95, 0.7, 0.2)  # armed (amber)
	if _release_timed and _release_light != null:
		((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
		if _zip_rider != null: _zip_rider.position = ZIP_LOW + ZIP_HANG   # already zipped down

	if _enemies_cleared and _panel_hacked and _release_timed:
		_win(false)

func _open() -> bool:
	return abs(sin(_pulse)) > PULSE_OPEN

# --- interaction -------------------------------------------------------------
func _on_special(char_name: String) -> void:
	if dialog.is_open():
		return
	var pp: Vector3 = player.global_position
	if near3(pp, LENA_POS, REACH): _talk_lena(char_name); return
	# Ethan: control panel (power)
	if char_name == "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_panel_hacked = true
		GameManager.set_level_flag(location_id, "panel_hacked", true)
		_set_panel_solved()
		_hud_hint.text = "Power restored! Now align the platform locks, then Ben times the release up top."
		Audio.play("special"); return
	# Ethan: platform-lock sequence (1→2→3) → opens the gate to the High Platform.
	# Pick the NEAREST UNSET lock in range — posts sit closer together than REACH, so a plain
	# first-match would keep re-hitting an already-set neighbour and dead-end the sequence.
	if not _locks_done:
		var best := -1
		var best_d := REACH
		for i: int in range(LOCKS.size()):
			if _lock_seq.has(i):
				continue
			var d := Vector2(pp.x - LOCKS[i].x, pp.z - LOCKS[i].z).length()
			if d < best_d:
				best_d = d; best = i
		if best >= 0:
			_try_lock(char_name, best); return
	# Ethan: winch (optional → animal treat)
	if not _winch_done and near3(pp, WINCH_POS, REACH):
		if char_name == "Ethan":
			_winch_done = true
			GameManager.set_level_flag(location_id, "winch_done", true)
			GameManager.grant_item(char_name, TreatItem.id)
			_hud_hint.text = "Ethan winches the slack line taut — a supply pouch rolls down. (Found Animal Treat)"
			Audio.play("special")
		else:
			_hud_hint.text = "The winch motor's locked out — Ethan can drive it."
		return
	# High release — co-op: Ethan ARMS it at the control PANEL, then Ben TIMES the release POST.
	if _panel_hacked and not _release_armed and near3(pp, HIGH_PANEL_POS, REACH):
		if char_name == "Ethan":
			_release_armed = true
			GameManager.set_level_flag(location_id, "release_armed", true)
			((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.95, 0.7, 0.2)  # amber: armed
			_set_high_panel_armed()
			_hud_hint.text = "Ethan powers the release from the panel — now swap to Ben (Tab) and time the post."
			Audio.play("special")
		else:
			_hud_hint.text = "The release panel is Ethan's — swap to Ethan to power it."
		return
	if _panel_hacked and not _release_armed and near3(pp, RELEASE_POS, REACH):
		_hud_hint.text = "The release post is dead — Ethan has to power it at the control panel first."
		return
	# armed → Ben reads the timing window at the post
	if _panel_hacked and _release_armed and not _release_timed and near3(pp, RELEASE_POS, REACH):
		if char_name != "Ben":
			_hud_hint.text = "It's powered — swap to Ben (Tab) to time the release."
			return
		if _open():
			_release_timed = true
			GameManager.set_level_flag(location_id, "release_timed", true)
			((_release_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color = Color(0.3, 0.95, 0.4)
			_hud_hint.text = "Perfect timing! The high line releases."; _play_zip()
			Audio.play("special")
		else:
			_hud_hint.text = "Mistimed — wait for the window to read OPEN, then press G."
			Audio.play("hurt")
		return
	# Ben: snagged clue bag (timing → Doug carabiner)
	if not _clue_taken and near3(pp, CLUE_POS, REACH):
		if char_name != "Ben":
			_hud_hint.text = "Ben has to grab the bag on the beat — Tab to swap to Ben."
			return
		if _open():
			_clue_taken = true
			GameManager.set_level_flag(location_id, "clue_taken", true)
			GameManager.grant_item(char_name, CarabinerItem.id)
			open_dialog("Snagged Bag", Color(0.4, 0.55, 0.4),
				{"start": {"lines": [
					"Ben swings out on the beat and snatches the bag off the high line.",
					"Inside: a climbing carabiner filed 'D.H.', and a map corner ringed around the Grand Marquee.",
					"Picked up: Doug's Carabiner."]}}, char_name)
			Audio.play("special")
		else:
			_hud_hint.text = "The bag's swinging — Ben has to grab it on the beat (press G when OPEN)."
		return
	# Ben: rhythm crate (optional → bies charm)
	if char_name == "Ben" and not _rhythm_done and near3(pp, RHYTHM_POS, REACH):
		if _open():
			_rhythm_done = true
			GameManager.set_level_flag(location_id, "rhythm_done", true)
			GameManager.grant_item(char_name, BiesCharmItem.id)
			_hud_hint.text = "Ben hits the chimes on the beat — a supply crate drops. (Found Bies Charm)"
			Audio.play("special")
		else:
			_hud_hint.text = "Hit the rig on the beat — press G when the window reads OPEN."
		return
	# wrong-character / not-yet hints
	if char_name == "Ben" and not _panel_hacked and near3(pp, RELEASE_POS, REACH):
		_hud_hint.text = "The line's dead — Ethan must restore power at the Mid panel first."
	elif char_name != "Ethan" and not _panel_hacked and near3(pp, PANEL_POS, REACH):
		_hud_hint.text = "The control panel needs Ethan's hacking."

func _try_lock(char_name: String, i: int) -> void:
	if char_name != "Ethan":
		_hud_hint.text = "The platform locks are electronic — Ethan re-sequences them."
		return
	if _lock_seq.has(i):
		return
	if i == _lock_seq.size():
		_lock_seq.append(i)
		((_lock_lights[i] as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.3, 0.95, 0.4)
		Audio.play("special")
		if _lock_seq.size() == LOCKS.size():
			_locks_done = true
			GameManager.set_level_flag(location_id, "locks_done", true)
			_open_lock_gate(true)
			_hud_hint.text = "Locks aligned — the gate to the High Platform opens."
		else:
			_hud_hint.text = "Lock %d set. Sequence them 1, 2, 3." % (i + 1)
	else:
		_lock_seq.clear()
		for g in _lock_lights: ((g as MeshInstance3D).mesh as BoxMesh).material.albedo_color = Color(0.85, 0.3, 0.3)
		_hud_hint.text = "Out of sequence — the locks reset. Try 1, 2, 3."

func _open_lock_gate(animate: bool) -> void:
	(_lock_wall as StaticBody3D).collision_layer = 0
	if animate:
		create_tween().tween_property(_lock_wall, "position:y", -WALL_H, 0.6)
	else:
		_lock_wall.position.y = -WALL_H

func _set_panel_solved() -> void:
	for pip in _panel_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _set_high_panel_armed() -> void:
	for pip in _high_panel_lights:
		var m := ((pip as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D
		m.albedo_color = Color(0.3, 0.95, 0.4); m.emission = m.albedo_color

func _talk_lena(char_name: String) -> void:
	var tree: Dictionary
	if _enemies_cleared and _panel_hacked and _release_timed:
		tree = {"start": {"lines": ["\"Lines fully restored. Unusual technique on that timing window -- but it worked.\""]}}
	elif _panel_hacked:
		tree = {"start": {"lines": ["\"Ethan: align the platform locks 1-2-3 to open the high gate. Then Ben catches the timed release up top.\""]}}
	else:
		tree = {"start": {"lines": [
			"\"Safety briefing: all riders clip in. Someone cut the release power and scrambled the platform locks -- lines are dead.\"",
			"\"Ethan: the Mid panel restores power, then sequence the locks. Ben: up top, the release and a snagged bag both want a timed grab -- press G when the ring pulses green.\""]}}
	open_dialog("Lena", Color(0.45, 0.55, 0.5), tree, char_name)

func _unhandled_input(_e: InputEvent) -> void:
	dialog_input()

# --- HUD + win ---------------------------------------------------------------
func _build_hud() -> void:
	var cl := make_hud_layer()
	_hud_goal = hud_label(cl, 24)
	_hud_pulse = hud_label(cl, 84, 26)
	_hud_hint = hud_label(cl, -70, 22, true)
	_hud_banner = hud_label(cl, 0, 40); _hud_banner.anchor_top = 0.5; _hud_banner.anchor_bottom = 0.5
	_hud_banner.visible = false

func _process(d: float) -> void:
	super._process(d)
	_pulse += d * PULSE_SPEED
	if not _enemies_cleared and _spawned > 0 and enemies_alive() == 0:
		_enemies_cleared = true
		GameManager.set_level_flag(location_id, "enemies_cleared", true)
	if not _cleared:
		var bits := []
		bits.append("riders " + ("OK" if _enemies_cleared else "..."))
		bits.append("panel " + ("OK" if _panel_hacked else "..."))
		bits.append("locks " + ("OK" if _locks_done else "..."))
		bits.append("release " + ("OK" if _release_timed else "..."))
		_hud_goal.text = "Ethan hacks the panel, aligns the locks + powers the release; then Ben times the release window. (G interact, Tab swap)\n[" + "  ".join(bits) + "]"
		_update_pulse_hud()
	if not _cleared and _enemies_cleared and _panel_hacked and _release_timed:
		_win(true)

func _update_pulse_hud() -> void:
	# Show the timing bar ONLY when standing at a pending timed action, so it appears where the
	# action is (not globally at the panel): the armed release, or the snagged clue bag.
	if player == null:
		_hud_pulse.text = ""; return
	var pp: Vector3 = player.global_position
	var at_release := _release_armed and not _release_timed and near3(pp, RELEASE_POS, REACH + 0.6)
	var at_clue := not _clue_taken and near3(pp, CLUE_POS, REACH + 0.6)
	if not (at_release or at_clue):
		_hud_pulse.text = ""
		return
	var what := "RELEASE" if at_release else "CLUE BAG"
	var mag: float = abs(sin(_pulse))
	var filled := int(round(mag * 10.0))
	var bar := "▮".repeat(filled) + "▯".repeat(10 - filled)
	if _open():
		_hud_pulse.text = "%s TIMING  [%s]  ● OPEN — press G (Ben)!" % [what, bar]
		_hud_pulse.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		_hud_pulse.text = "%s TIMING  [%s]  ○ wait for OPEN" % [what, bar]
		_hud_pulse.add_theme_color_override("font_color", UITheme.CREAM)

func _win(fanfare: bool) -> void:
	_cleared = true
	GameManager.complete_location(location_id)
	_hud_goal.text = ""; _hud_hint.text = ""; _hud_pulse.text = ""
	_hud_banner.text = "PARK ONLINE!\nThe lines run again."
	_hud_banner.visible = true
	if fanfare:
		Audio.play("puzzle_complete")
